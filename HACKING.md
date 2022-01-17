# oc-mirror E2E testing environment

This Ansible content is designed to consume the [disconnected testbed terraform](https://github.com/jharmison-redhat/disconnected-openshift-testbed) and configure the instances for [oc-mirror](https://github.com/openshift/oc-mirror) E2E testing in a properly isolated environment.

These instructions will help you to make changes to it and work on it as a developer.

## Setup

You need Python 3, podman or docker, and `make` installed on your system, with `pip` in $PATH resolving to the correct `pip` for your python 3 installation. I do this inside a [Toolbox](https://github.com/containers/toolbox) with `podman` and the like in `$PATH` as `flatpak-spawn --host podman "${@}"`, but it's up to you how to get there.

```sh
git clone https://github.com/jharmison-redhat/oc-mirror-e2e.git
cd oc-mirror-e2e
make prereqs
```

This will get you installations of Ansible, Ansible-builder, and Yasha. You will need these to use the other targets in the makefile.

## Use

### Collection building

To build the collection using the present work directory:

```sh
make
```

To build a specific version of a collection:

```sh
VERSION=0.2.0 make
```

#### NOTE

The `VERSION` variable will affect every command that depends on a locally built collection, including most follow-on commands.

### Collection publishing

To publish the locally built collection to [Ansible Galaxy](https://galaxy.ansible.com/jharmison_redhat/oc_mirror_e2e):

```sh
make publish
```

### Execution Environment building

To build an execution environment with the locally built collection preinstalled (does not rely on publishing):

```sh
make ee
```

To use something other than `podman` to build the EE:

```sh
RUNTIME=docker make ee
```

#### NOTE

The `RUNTIME` variable will affect every command that uses a container runtime for its operation, including most follow-on commands.

### Execution Environment publishing

To push an EE image to a registry:

```sh
make ee-publish
```

### Running the content

To run the `create` playbook from the collection, using the EE as a normal Ansible Runner image:

```sh
make run
```

To run the `delete` playbook, to clean up the environment, using the EE as a normal Ansible Runner image:

```sh
make destroy
```

### Cleaning up build artifacts

To remove built copies of the collection, rendered `galaxy.yml` metadata files, and any Ansible Runner artifacts:

```sh
make clean
```

Note that this cleanup doesn't touch the Terraform state created by the `community.general.terraform` module - only artifacts of the collection building and ansible-runner artifacts. You should, therefore, be able to run `terraform destroy` from the `example/output/terraform` directory manually, or run `make destroy clean` to tear down the terraform-provisioned infrastructure using Ansible before running the clean target.

Also, in the event that something goes wrong with your terraform state for local hacking, you may also find the script at [example/teardown.sh](example/teardown.sh) useful, as it will tear down all of the Terraform-managed resources using [awscli](https://pypi.org/project/awscli/) without needing Terraform state.

### Makefile variables

| Variable | Description | Default |
| --- | --- | --- |
| `VERSION` | The version of the collection and EE to package/use | 0.1.1 |
| `GALAXY_TOKEN` | The API token from Ansible Galaxy for publishing a collection | Read at runtime from `.galaxy-token` |
| `PUSH_IMAGE` | The container image name that the EE will be pushed to for publishing | registry.jharmison.com/ansible/oc-mirror-e2e |
| `RUNTIME` | The OCI container runtime to use for operations that need one | `podman` |
