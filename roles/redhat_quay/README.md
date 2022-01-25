redhat_quay
===========

Configures a RHEL host with Red Hat Quay, using a container-based installation with podman.

Requirements
------------

Python dependencies:

- jmespath
    - (for the `json_query` filter)
- cryptography
    - (for advanced X.509 certificate work)

---

```yaml
registry_admin:
  username: quay
  password: password
  email: quay@example.com
```

_The username, password, and email of the admin user to be created for the registry._

---

```yaml
registry_hostname: registry.example.com
```

_The public hostname of the registry (important for certificates!)_

---

```yaml
password_dir: '{{ playbook_dir }}/.passwords'
```

_The directory in which to save generated passwords._

---

```yaml
registry_s3_region: us-east-2
```

_The AWS S3 region to use for object storage. Optional if overriding registry_storage_details below._

---

```yaml
registry_s3_bucket: quay
```

_The name of the existing S3 bucket to use for object storage. Optional if overriding registry_storage_details below._

---

```yaml
registry_storage_type: S3Storage
registry_storage_details:
  host: s3.{{ registry_s3_region }}.amazonaws.com
  s3_bucket: '{{ registry_s3_bucket }}'
registry_storage_path: /datastorage/registry
```

_The storage configuration for the instance. For more information on how this might impact the storage configuration of your Quay instance, please use the config validator (or at least browse [the code](https://github.com/quay/config-tool/blob/redhat-3.6/pkg/lib/fieldgroups/distributedstorage/distributedstorage.go) for the appropriate version to understand the constraints). Note that this configuration assumes an instanceprofile that enables the instance to access the bucket!_

---

```yaml
deploy_clair: true
```

_Whether or not to deploy the Clair image scanner._

---

```yaml
cert_style: letsencrypt
```

_Which cert style to use for the registry, options from:_

  - _letsencrypt_
  - _byo_
  - _selfsigned_

---

```yaml
registry_certificate: ""
registry_certificate_key: ""
```

_When using BYO cert style, the PEM-encoded certificate and private key respectively._

---

```yaml
quay_version: "3.6.2"
```

_The version of Red Hat Quay to deploy - note, only tested on the 3.6 release._

---

```yaml
quay_image: registry.redhat.io/quay/quay-rhel8:v{{ quay_version }}
clair_image: registry.redhat.io/quay/clair-rhel8:v{{ quay_version }}
redis_image: registry.redhat.io/rhel8/redis-5:1
postgres_image: registry.redhat.io/rhel8/postgresql-10:1
```

_The container images to use. Note that registry.redhat.io requires login._
