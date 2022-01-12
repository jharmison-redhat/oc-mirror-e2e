proxy
=====

This role converts the targeted node into a Squid proxy and Linux router. The configuration for the Squid proxy aims to do transparent TLS splicing, but in cases where an error occurs in some way it will instead generate an SSL certificate for the host so the CA used should be trusted by clients to better troubleshoot issues.

It is implemented with a whitelist that enables specific HTTP Host headers or TLS SNI headers on the requests.

It is intended to allow AWS communication transparently, and can be extended to allow more URLs by the "allowed_urls" variable, which should be a list of strings designed for squid whitelist format. For example, the following would allow `example.com` and all subdomains, as well as the AWS URLs:

```yaml
allowed_urls:
- .example.com
```

By default, the extra `allowed_urls` allows all subdomains of `{{ cluster_name }}.{{ cluster_domain }}`, where `cluster_name` and `cluster_domain` are `disco` and `example.com` respectively. This configuration is designed for the use case of emulating a disconnected OpenShift cluster, and using those variables to allow clients to access the domains for the cluster.

It will also look for the RHUI certificate on the system and, if present, will trust that certificate to allow for `allowed_urls` to include the RHUI domains, but it will not add them by default.
