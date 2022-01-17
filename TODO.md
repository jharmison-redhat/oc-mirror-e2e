TODO
====

MVP
---

- [ ] Finish `openshift-install` from bastion
- [ ] Implement mirror-to-disk-then-sneakernet flow
- [ ] Manipulate instance disk size based on mirror flow (disk or registry)
- [ ] Linting, dependency update tracking, other generic CI

Important for finished product
------------------------------

- [ ] E2e test from known good state, using proper Ansible tests
- [ ] CD to publish collection and EE
- [ ] Add generic Docker registry

Important for improving usability
---------------------------------

- [ ] User docs
- [ ] Quickstart from scratch, assume nothing

Quay things
----

- [ ] Make Quay installation work disconnected (podman save, podman load)
- [ ] Enable [Clair disconnected](https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html/manage_red_hat_quay/clair-intro2#clair-disconnected)
- [ ] Quay hacky tasks moving to proper modules
- [ ] Better backend storage abstractions
  - [ ] Local Storage
  - [ ] Different S3 auth modes
  - [ ] More control over S3 endpoint
