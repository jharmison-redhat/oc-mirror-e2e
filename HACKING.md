# oc-mirror E2E testing environment

This Ansible content is designed to consume the [disconnected testbed terraform](https://github.com/jharmison-redhat/disconnected-openshift-testbed) and configure the instances for [oc-mirror](https://github.com/openshift/oc-mirror) E2E testing in a properly isolated environment.

These instructions will help you to make changes to it and work on it as a developer. As there are environment variables to configure, and the option for different scenarios, it's encouraged to review this `HACKING.md` before proceeding.

## Setup

You need Python 3, podman or docker, and GNU make installed on your system to get started. You will also need to authenticate to the [Red Hat Container Registry](https://access.redhat.com/RegistryAuthentication).

```sh
podman login registry.redhat.io
```

To get started, clone the repository and build the prerequisites.

```sh
git clone https://github.com/jharmison-redhat/oc-mirror-e2e.git
cd oc-mirror-e2e
make prereqs
```

This will get you installations of Ansible (mostly for `ansible-galaxy`), Ansible Builder, Yasha, and sshuttle in a python virtual environment. You will need these to use the other targets in the makefile, or some of the scripts in the `example` directory.

If you want to run the content iteratively to validate that your changes are working, you'll need to create the scenario and environment variables:

```sh
cp example/vars/environment.yml.example example/vars/environment.yml
${EDITOR:-vi} example/vars/environment.yml
cp example/vars/scenario.yml.example example/vars/scenario.yml
${EDITOR:-vi} example/vars/scenario.yml
```

Inside these files are comments for how to go about filling out the variables. Once you've updated everything, save the variables file and you're ready to role. The environment variable file is already `.gitignore`'d, since it contains secrets.

You'll need AWS credentials available for consumption. The run.sh script makes an effort to run the container in a way that AWS variables are passed through appropriately. It will bring the entire `~/.aws` directory from your user profile, including the `credentials` file, and export any `AWS_` prefixed variables from your environment. This means you can export an access key ID and secret, or a profile name that exists in your AWS credentials file, and the project will consume them to use with the terraform content to build out the environment. A new set of credentials is created with slightly lower scoped privilege and used in the installation environment. For example, if you have an access key ID and secret, you could run the following before any of the follow-on commands:

```sh
export AWS_ACCESS_KEY_ID='<some-secret-access-key-id>'
export AWS_SECRET_ACCESS_KEY='<some-secret-access-key>'
```

## Quickstart

If you've completed setup and just want to run everything from scratch with the defaults, you can run the following:

```sh
make clean run
```

This will rebuild the collection from your present working copy, rebuild the execution environment, then run the Create, Test, and Delete playbooks sequentially.

- Create
  - Provisions the infrastructure using terraform
  - Updates all provisioned hosts
  - Configures the proxy and registry according to the scenario
  - Validates that the isolated bastion can connect to what it needs to
- Test
  - Imports provisioned nodes and loads scenario variables
  - Downloads OpenShift clients onto the Registry node
  - Compiles oc-mirror if not already present on the controller
  - Runs the connected oc-mirror workflow for imageset generation based on your scenario
    - `mirror_directly_to_regsitry: true` results in the registry publishing to its own OCI registry endpoint
    - `mirror_directly_to_registry: false` results in the imageset being saved to disk and hauled back to the controller, emulating "sneakernet" workflows
  - Completes the "sneakernet" workflow by moving binaries and imageset tarballs (if applicable) to the isolated bastion
  - Installs OpenShift using the sneakernetted content with no internet access at all
  - Installs, leverages, and validates the operators listed in your scenario
  - If `foo` was specified in the operators (or the variable `conduct_second_publish` was specified as `true`), runs a second mirror, publish, validate phase to make sure that the mirrored content was updated for `foo`
- Delete
  - Uninstalls OpenShift directly from the Execution Environment, using the installer directory recovered from the Registry node above
  - Deprovisions the remaining infrastructure using terraform

Failures at any stage abort follow-on execution, potentially leaving you with a partially configured environment. Effort has been made to keep things idempotent, so you should safely be able to rerun specific playbooks. To rerun the `Test` phase, after fixing something in the collection content, you could run the following:

```sh
make clean run ANSIBLE_PLAYBOOKS=test
```

A helpful set of targets to use together, to pull the latest oc-mirror from the main branch (the default) and rebuild everything from scratch, but keep the environment up for you to poke at and manually validate, might look like the following:

```sh
make clean destroy realclean run ANSIBLE_PLAYBOOKS="create test"
```

And iterating on just one section of the scenario while keeping everything else in place could be accomplished with something like the following:

```sh
make clean run ANSIBLE_PLAYBOOKS=test ANSIBLE_TAGS=operators
```

More in-depth usage information is available below.

## Use

### Collection building

To build the collection using the present work directory:

```sh
make
```

To build the collection with a specific version number:

```sh
make VERSION=0.2.0
```

#### NOTE

The `VERSION` variable will affect every command that depends on a locally built collection, including most follow-on commands.

### Collection publishing

To publish the locally built collection to [Ansible Galaxy](https://galaxy.ansible.com/jharmison_redhat/oc_mirror_e2e):

```sh
make publish
```

#### NOTE

This target expects the Ansible Galaxy auth token to exist in a file named `.galaxy-token`, but it can be explicitly provided:

```sh
make publish GALAXY_TOKEN=<some-galaxy-token>
```

### Execution Environment building

To build an execution environment with the locally built collection preinstalled (does not rely on publishing):

```sh
make ee
```

To use something other than `podman` to build the EE:

```sh
make ee RUNTIME=docker
```

#### NOTE

The `RUNTIME` variable will affect every command that uses a container runtime for its operation, including most follow-on commands.

### Execution Environment publishing

To push an EE image to a registry:

```sh
make ee-publish
```

To publish the EE at a non-default registry:

```sh
make ee-publish PUSH_IMAGE=quay.io/some-namespace/some-repo
```

### Running the content

To run the full scenario, using the EE as a normal Ansible Runner image:

```sh
make run
```

To run just the `delete` playbook, to clean up the environment, using the EE as a normal Ansible Runner image:

```sh
make destroy
```

To debug things from inside the EE with an interactive shell:

```sh
make exec
```

#### NOTE

There are a large number of variables passed through to these targets. Please see the [variable definition below](#makefile-variables) to learn what they do.

### Cleaning up build artifacts

To remove built copies of the collection and rendered `galaxy.yml` metadata files:

```sh
make clean
```

Note that this cleanup doesn't touch the Terraform state created by the `community.general.terraform` module - only artifacts of the collection building and ansible-runner artifacts. You should, therefore, be able to run `terraform destroy` from the `example/output/terraform` directory manually, or run `make clean destroy` to tear down the terraform-provisioned infrastructure using Ansible even after running the clean target.

There is an additional target that completely removes anything recovered from outputs, ansible-runner artifacts, and all Makefile empty target markers (forcing recreation of everything when the Makefile is rerun):

```sh
make realclean
```

Note that that output includes terraform state. It is very destructive, and you may find yourself in a bind if using this unwisely. It does not remove .gitignored environment.yml files with secret content.

### Extra scripts

Both of these scripts require that `jq` be in your `$PATH`, as an additional dependency above the rest of the project. `jq` is just too good, sorry.

In the event that something goes wrong with your terraform state for local hacking, you may also find the script at [example/teardown.sh](example/teardown.sh) useful, as it will tear down all of the Terraform-managed resources using [awscli](https://pypi.org/project/awscli/) without needing Terraform state. It does not, however, uninstall OpenShift and will fail if remnants of an OpenShift installation are still in the VPC.

If you'd like to do some troubleshooting, the script at [example/connect.sh](example/connect.sh) is very useful as well. Given a valid Terraform-provisioned environment, it will read from tfstate and create an [sshuttle](https://sshuttle.readthedocs.io/) proxy into the private VPC subnets. This means that an unpublished "isolated" OpenShift instance can be connected to from your browser. It requires `sudo` on your host to run and you will be prompted appropriately.

Both `awscli` and `sshuttle` are included in the `requirements-devel.txt`, so should be available for the scripts if you ran `make prereqs`.

### Makefile variables

| Variable | Description | Default |
| --- | --- | --- |
| `VERSION` | The version of the collection and EE to package/use | Read at runtime from `VERSION` |
| `GALAXY_TOKEN` | The API token from Ansible Galaxy for publishing a collection | Read at runtime from `.galaxy-token` |
| `PUSH_IMAGE` | The container image name that the EE will be pushed to for publishing | registry.jharmison.com/ansible/oc-mirror-e2e |
| `RUNTIME` | The OCI container runtime to use for operations that need one | `podman` |
| `ANSIBLE_TAGS` | The tags to pass to the playbook call | "" |
| `ANSIBLE_SKIP_TAGS` | The tags to skip in the playbook call | "" |
| `ANSIBLE_PLAYBOOKS` | The playbooks to run, and the order to run them in, for the `run` target | create test delete |
| `ANSIBLE_SCENARIO_VARS` | The scenario variables to load for all hosts in the playbooks (expected to be in example/vars with a .yml extension) | "scenario" |
