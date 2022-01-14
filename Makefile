VERSION = 0.1.1
GALAXY_TOKEN := $(shell cat .galaxy-token)
PUSH_IMAGE = registry.jharmison.com/ansible/oc-mirror-e2e

.PHONY: all prereqs collection publish ee run

all: ee

prereqs:
	pip install -r requirements.txt

collection: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz:
	yasha --VERSION=$(VERSION) galaxy.yml.j2
	ansible-galaxy collection build -v .

publish: collection
	-ansible-galaxy collection publish -v --token $(GALAXY_TOKEN) jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

ee: publish
	cd execution-environment ; \
	podman build . -f Containerfile.builder -t extended-builder-image ; \
	podman build . -f Containerfile.base -t extended-base-image ; \
	ansible-builder build -t oc-mirror-e2e:$(VERSION)
	podman push oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):$(VERSION)
	podman push oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):latest

run: ee
	cd example ; \
	podman run --rm -it -e RUNNER_PLAYBOOK=jharmison_redhat.oc_mirror_e2e.create -v "$${PWD}:/runner" oc-mirror-e2e:$(VERSION)
