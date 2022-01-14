VERSION = 0.1.1
GALAXY_TOKEN := $(shell cat .galaxy-token)
PUSH_IMAGE = registry.jharmison.com/ansible/oc-mirror-e2e

.PHONY: all prereqs collection publish ee run clean

all: run

prereqs:
	pip install -r requirements-devel.txt

collection: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz:
	yasha --VERSION=$(VERSION) galaxy.yml.j2
	ansible-galaxy collection build -v .

publish: collection
	-ansible-galaxy collection publish -v --token $(GALAXY_TOKEN) jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

ee: collection
	cp jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz execution-environment/jharmison_redhat-oc_mirror_e2e-latest.tar.gz
	cd execution-environment ; \
	podman build . -f Containerfile.builder -t extended-builder-image ; \
	podman build . -f Containerfile.base -t extended-base-image ; \
	ansible-builder build -t oc-mirror-e2e:$(VERSION)

ee-publish: ee
	podman push oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):$(VERSION)
	podman push oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):latest

run: ee
	cd example ; \
	podman run --rm -it --privileged --security-opt=label=disable \
		-e RUNNER_PLAYBOOK=jharmison_redhat.oc_mirror_e2e.create \
		-e AWS_CONFIG_FILE=/aws/config \
		-e AWS_SHARED_CREDENTIALS_FILE=/aws/credentials \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_PROFILE \
		-v "$${PWD}:/runner" \
		-v ./output:/output \
		-v ~/.aws:/aws \
		oc-mirror-e2e:$(VERSION)

clean:
	rm -f jharmison_redhat-oc_mirror_e2e-*.tar.gz galaxy.yml
