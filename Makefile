VERSION = 0.4.3
GALAXY_TOKEN := $(shell cat .galaxy-token)
PUSH_IMAGE = registry.jharmison.com/ansible/oc-mirror-e2e
RUNTIME = podman
ANSIBLE_TAGS =
ANSIBLE_SKIP_TAGS =
ANSIBLE_SCENARIO_VARS = scenario
ANSIBLE_PLAYBOOKS = create test delete

.PHONY: all prereqs clean-prereqs collection publish ee ee-publish run clean realclean

all: collection

##############################################################################
#                             DEV ENVIRONMENT                                #
##############################################################################
.venv/bin/pip:
	python3 -m venv .venv
	.venv/bin/pip install --upgrade pip setuptools wheel

.pip-prereqs: .venv/bin/pip
	.venv/bin/pip install -r requirements-devel.txt
	touch .pip-prereqs

.venv/bin/yasha: .pip-prereqs
.venv/bin/ansible-galaxy: .pip-prereqs
.venv/bin/ansible-builder: .pip-prereqs

clean-prereqs:
	rm -rf .venv

prereqs: clean-prereqs .venv/bin/yasha .venv/bin/ansible-galaxy .venv/bin/ansible-builder

##############################################################################
#                               COLLECTION                                   #
##############################################################################
collection/galaxy.yml: .pip-prereqs
	-rm -f collection/galaxy.yml
	.venv/bin/yasha --VERSION=$(VERSION) collection/galaxy.yml.j2

jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz: collection/galaxy.yml
	.venv/bin/ansible-galaxy collection build -v collection

collection: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz

.collection-published: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz
	.venv/bin/ansible-galaxy collection publish -v --token $(GALAXY_TOKEN) jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz
	touch .collection-published

publish: .collection-published

##############################################################################
#                          EXECUTION ENVIRONMENT                             #
##############################################################################
.ee-built: jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz
	cp jharmison_redhat-oc_mirror_e2e-$(VERSION).tar.gz execution-environment/jharmison_redhat-oc_mirror_e2e-latest.tar.gz
	cd execution-environment \
	  && $(RUNTIME) build . -f Containerfile.builder -t extended-builder-image \
	  && $(RUNTIME) build . -f Containerfile.base -t extended-base-image \
	  && ../.venv/bin/ansible-builder build -v 3 --container-runtime $(RUNTIME) -t oc-mirror-e2e:$(VERSION)
	touch .ee-built

ee: .ee-built

.ee-published: .ee-built
	$(RUNTIME) tag oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):$(VERSION)
	$(RUNTIME) push $(PUSH_IMAGE):$(VERSION)
	$(RUNTIME) tag oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):latest
	$(RUNTIME) push $(PUSH_IMAGE):latest
	touch .ee-published

ee-publish: .ee-published

##############################################################################
#                               RUN CONTENT                                  #
##############################################################################
run: .ee-built
	ANSIBLE_TAGS=$(ANSIBLE_TAGS) ANSIBLE_SKIP_TAGS=$(ANSIBLE_SKIP_TAGS) EE_VERSION=$(VERSION) RUNTIME=$(RUNTIME) ANSIBLE_EXTRA_VARS_FILES="$(ANSIBLE_SCENARIO_VARS)" example/run.sh $(ANSIBLE_PLAYBOOKS)
destroy: .ee-built
	ANSIBLE_TAGS=$(ANSIBLE_TAGS) ANSIBLE_SKIP_TAGS=$(ANSIBLE_SKIP_TAGS) EE_VERSION=$(VERSION) RUNTIME=$(RUNTIME) ANSIBLE_EXTRA_VARS_FILES="$(ANSIBLE_SCENARIO_VARS)" example/run.sh delete

##############################################################################
#                                 CLEANUP                                    #
##############################################################################
clean:
	rm -rf jharmison_redhat-oc_mirror_e2e-*.tar.gz collection/galaxy.yml
realclean: clean clean-prereqs
	rm -rf example/output/* example/artifacts/* .pip-prereqs .collection-published .ee-built .ee-published
	-$(RUNTIME) rmi extended-builder-image
	-$(RUNTIME) rmi extended-base-image
	-$(RUNTIME) rmi oc-mirror-e2e:$(VERSION)
