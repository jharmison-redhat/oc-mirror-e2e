TODO
====

MVP
---

- [x] Fix DNS to use internal names for inter-VPC communication that are more specific than the OpenShift Hosted Zone
  - Need to change the Terraform to not conflict with the OpenShift Hosted Zone, and also create a new hosted zone that's more specific to satisfy Route53 resolving behavior
  - https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html#hosted-zone-private-considerations-public-private-overlapping
- [x] Finish `openshift-install` from bastion
- [ ] Implement mirror-to-disk sneakernet flow
  - [x] Manipulate instance disk size based on mirror flow (disk or registry)

Important for finished product
------------------------------

- [ ] Linting, dependency update tracking, other generic CI
- [ ] Better handle imageset-config.yml to enable multiple CI scenarios
- [ ] E2e test from known good state, using proper Ansible tests
- [ ] CD to publish collection and EE
- [x] Add generic Docker registry
- [ ] Build out an easy-to-execute test matrix interface
  - Things that would be good to include in the matrix:
    - Mirror to registry / mirror to disk and haul
    - Quay / Docker distribution
    - Metadata storage backends
    - OCP versions
    - Catalogs (should do at least one operator from redhat, certified, and a fully custom catalog)
    - Custom CA / Trusted / Self-signed/untrusted
    - docker/podman/custom authfile flows
  - Each flow should go through the following:
    - Initial mirror and publish
    - OpenShift install
      - Validate basic API connectivity
    - Operator install
      - Validate operator operation
    - Additional mirror and publish
      - Validate that catalogs are good and upgrade graph is intact
    - OpenShift upgrade
      - Validate that upgrade picks up and applies cleanly
    - Operator upgrade
      - Validate that OLM sees new channel head and picks up upgrade availability
      - Validate that upgrade applies cleanly and operator remains usable
- [ ] Enable shared tasks between test matrix runs (e.g. compile oc-mirror once, run with different scenarios)
  - Expect that compiled oc-mirror comes from earlier stage, only compile if necessary?
  - Better interface for specifying which oc-mirror to compile might be nice as well

Important for improving usability
---------------------------------

- [ ] User docs
- [ ] Quickstart from scratch, assume nothing

Quay things
-----------

- [ ] Make Quay installation work disconnected (podman save, podman load)
- [ ] Enable [Clair disconnected](https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html/manage_red_hat_quay/clair-intro2#clair-disconnected)
- [ ] Quay hacky tasks moving to proper modules
- [ ] Better backend storage abstractions
  - [ ] Local Storage
  - [ ] Different S3 auth modes
  - [ ] More control over S3 endpoint
