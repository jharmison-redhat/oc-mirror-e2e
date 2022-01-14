FROM quay.io/ansible/ansible-builder:latest

RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
COPY jharmison_redhat-oc_mirror_e2e-latest.tar.gz /extras/
