FROM registry.redhat.io/ansible-automation-platform-21/ansible-builder-rhel8:latest

COPY hashicorp.repo /etc/yum.repos.d/hashicorp.repo
COPY jharmison_redhat-oc_mirror_e2e-latest.tar.gz /extras/
