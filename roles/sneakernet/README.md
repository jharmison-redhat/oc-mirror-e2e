# sneakernet

This role has two primary entrypoints, neither of which are `main.yml`.

### connected

This entrypoint is designed for a connected host. It performs the following:

  - Downloads all required clients for disconnected installation.
  - Rebuilds oc-mirror if necessary
  - Either mirrors directly to the registry or disk, depending on the value of the boolean `mirror_directly_to_registry`
  - Hauls OpenShift clients, oc-mirror, and disconnected mirroring artifacts (either the whole ImageSet or at least the ICSPs) back to the controller

### disconnected

This entrypoint is designed for a disconnected host to enable OpenShift installation. It performs the following:

  - Brings all client binaries, including oc-mirror, into `$PATH`
  - Hauls all mirroring artifacts (ImageSets or ICSPs) onto the host for consumption
  - Hydrates the registry (if `mirror_directly_to_registry: false`)

## Variables

```yaml
oc_mirror_source:
  repo: https://github.com/openshift/oc-mirror.git
  version: 3660f79441d753560f33549a725d0339186649e0
```

Overriding this will change the location that oc-mirror is cloned from.

---

```yaml
mirror_directly_to_registry: true
```

Whether to go internet-to-registry or internet-to-disk

---

```yaml
oc_mirror_clone_location: '{{ ansible_env["HOME"] }}/oc-mirror'
oc_mirror_binary_location: '{{ oc_mirror_clone_location }}/bin/oc-mirror'
client_directory: '{{ ansible_env["HOME"] }}/clients'
```

Pathing for downloads/compilation on the connected host

---

```yaml
mirror_directory: '{{ ansible_env["HOME"] }}/mirror-content'
```

This is where the mirror content will be generated (connected) or hauled (disconnected)

---

```yaml
bin_recovery_dir: '{{ playbook_dir }}/tmp/clients'
mirror_data_recovery_dir: '{{ playbook_dir }}/tmp/mirror-data'
```

Where to pull binaries and mirrored data (ICSPs or ImageSets) on the controller

---

```yaml
force_mirror_update: false
```

Whether to run oc-mirror even if there has been no change

---

```yaml
registry_hostname: '{{ hostvars.controller.terraform.outputs.registry_instance.value.hostname }}'
local_registry_pull_secret: |-
  auths:
    {{ registry_hostname }}:
      auth: {{ (registry_admin.username + ":" + registry_admin.password)|b64encode }}
      email: {{ registry_admin.email }}
```

These variables is built to connect to the registry provisioned by the adjacent roles, but in certain circumstances might be overridden. They are used for registry auth as well as configuration of oc-mirror metadata.

---

```yaml
combined_pull_secret: '{{ console_redhat_com_pull_secret|combine(local_registry_pull_secret|from_yaml, recursive=True)|to_json }}'
```

You should probably just not change this. This combined the cloud.redhat.com pull secret for OpenShift installation with the local registry secret for a single authfile.

---

```yaml
compliance_operator_version: '0.1.44'
```

The version of the Compliance Operator that's mirrored in the ImageSetConfig

#### NOTE

This is vestigal and the oc-mirror flow will be changing in the future :)
