VERSION = 0.1.0
GALAXY_TOKEN := $(shell cat .galaxy-token)

.PHONY: all collection publish ee

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
