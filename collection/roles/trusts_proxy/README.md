trusts_proxy
============

This role will enable hosts to trust the Proxy and registry (if not using a proxy-signed cert). It is designed to be applied to the bastion. Additionally, you may provide extra CA certificates to trust in the following variable format:

```yaml
extra_ca_certificates:
- name: some_funky_internal_ca
  content: |-
    -----BEGIN CERTIFICATE-----
    MIIFTjCCAzagAwIBAgIURClW0PJLAVTr9OBPGhTmM9mLBQUwDQYJKoZIhvcNAQEL
    < ... TRIMMED FOR BREVITY ... >
    bOF51v8vw8s8uN+F50nS8NX6
    -----END CERTIFICATE-----
```

Note that it may make sense to use a [lookup plugin](https://docs.ansible.com/ansible/latest/plugins/lookup.html) like `file` to fill out the content, or to [slurp](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/slurp_module.html) it.
