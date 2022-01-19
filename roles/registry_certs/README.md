registry_certs
==============

This role is to generate certificates for use by the different registry implementations available. The `cert_style` variable determines which type of certificate is generated, but from there the certificate and key are staged in the same location. If using the `byo` `cert_style`, you should also provide `registry_certificate` and `registry_certificate_key`. `cert_directory` determines where the cert and key will be dropped, but they will always be named `ssl.cert` and `ssl.key` to ensure compatibility with Quay's naming scheme.
