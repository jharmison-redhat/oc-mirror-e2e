provisioner
===========

Performs a series of steps to provision a given set of terraform infrastructure.

1. Generates an OpenSSH keypair in ed25519 format.
1. Applies terraform to provision an AWS VPC and several instances to support disconnected testbed environments. See [the terraform module](https://github.com/jharmison-redhat/ocp-disconnected-testbed) for more information on what's provisioned.
1. Adds the newly provisioned hosts (registry, proxy, and bastion) to the Ansible inventory for the rest of the playbook
1. Generates a new root CA for use in follow-on configurations, including the SSL bump configuration for the proxy.
1. Saves the CA key and certificate in the `ca.stdout` variable
1. Has the CA sign a new certificate for the registry
1. Stores all of these outputs (terraform state, certificates, SSH keys) in a directory, passed in an Ansible variable named "output_dir" which defaults to `{{ playbook_dir }}/output`
