VERSION=0.1.0

.PHONY: all collection

all: collection

prereqs:
	@pip install -r requirements.txt

collection: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz:
	@yasha --VERSION=$(VERSION) galaxy.yml.j2
	@ansible-galaxy collection build .
