TODO
====

MVP
---

- [x] Fix DNS to use internal names for inter-VPC communication that are more specific than the OpenShift Hosted Zone
  - Need to change the Terraform to not conflict with the OpenShift Hosted Zone, and also create a new hosted zone that's more specific to satisfy Route53 resolving behavior
  - https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html#hosted-zone-private-considerations-public-private-overlapping
- [x] Finish `openshift-install` from bastion
- [x] Implement mirror-to-disk sneakernet flow
  - [x] Manipulate instance disk size based on mirror flow (disk or registry)
- [x] Ensure delete playbook always succeeds by making sure failed OCP installed are cleaned up
  - Should be able to `block` and `always` `openshift-install` to recover resources to controller, then run `openshift-install destroy cluster` from controller with appropriate env
  - May need to do some checks to ensure that we don't reprovision and just bring in tfstate anyways....
- [x] Better AWS credential handling
- [x] Make it easy to consume without copying entire directory structure

Important for finished product
------------------------------

- [ ] Linting, dependency update tracking, other generic CI
- [ ] Better handle imageset-config.yml to enable multiple CI scenarios
- [ ] E2e test (for the E2e test environment, yes) from known good state, using proper Ansible tests and very simply checks of functionality
- [ ] CD to publish collection and EE
- [x] Add generic Docker registry
- [x] Build out an easy-to-execute test matrix interface
  - Things that would be good to add to the matrix:
    - [ ] Custom CA / Trusted / Self-signed/untrusted
    - [ ] docker/podman/custom authfile flows
- [ ] Finish E2E flow to include full lifecycle test
  - Each flow should go through the following:
    - [x] Initial mirror and publish
    - [x] OpenShift install
      - [x] Validate basic API connectivity
    - [ ]Operator install
      - [ ] Validate operator operation
    - [ ] Additional mirror and publish
      - [ ] Validate that catalogs are good and upgrade graph is intact
    - [ ] OpenShift upgrade
      - [ ] Validate that upgrade picks up and applies cleanly
    - [ ] Operator upgrade
      - [ ] Validate that OLM sees new channel head and picks up upgrade availability
      - [ ] Validate that upgrade applies cleanly and operator remains usable
- [x] Enable shared tasks between test matrix runs (e.g. compile oc-mirror once, run with different scenarios)
  - [x] Expect that compiled oc-mirror comes from earlier stage, only compile if necessary?
  - [ ] Better interface for specifying which oc-mirror to compile might be nice as well

Important for improving usability
---------------------------------

- [ ] Better user docs
  - Need to get role doc generation up and running, rather than short hand-crafted blurbs
- [ ] Quickstart from scratch, assume nothing

Quay things
-----------

- [ ] Make Quay installation work disconnected (podman save, podman load)
- [ ] Enable [Clair disconnected](https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html/manage_red_hat_quay/clair-intro2#clair-disconnected)
- [ ] Quay [hacky tasks](/roles/redhat_quay/tasks/main.yml#117) moving to proper modules
- [ ] Better backend storage abstractions
  - [ ] Local Storage
  - [ ] Different S3 auth modes
  - [ ] More control over S3 endpoint
