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
