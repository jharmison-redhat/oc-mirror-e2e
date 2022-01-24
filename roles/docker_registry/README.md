docker_registry
===============

This role sets up a very minimalistic Docker Distribution registry, expecting `registry_bucket` to be a dictionary containing `region`, `bucket`, `access_key`, and `secret_key` keys with values set to access the bucket. It uses the `registry_certs` role to create certificates according to `cert_style` and uses `htpasswwd` for auth, with `registry_users` consisting of, by default, `registry_admin` (to enable inheritance from the variables in `redhat_quay`. It runs the container as root and exposes port 443.
