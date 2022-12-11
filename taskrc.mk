# taskrc.mk for complete-alias
#

absdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
REMAKE := $(MAKE) -C $(absdir) -s -f $(lastword $(MAKEFILE_LIST))
TestImage := complete-alias-test:1

.PHONY: help
help:
	@echo "Targets in $(basename $(lastword $(MAKEFILE_LIST))):" >&2
	@$(REMAKE) --print-data-base --question no-such-target 2>/dev/null | \
	grep -Ev  -e '^taskrc.mk' -e '^help' -e '^(Makefile|GNUmakefile|makefile|no-such-target)' | \
	awk '/^[^.%][-A-Za-z0-9_]*:/ \
			{ print substr($$1, 1, length($$1)-1) }' | \
	sort | \
	pr --omit-pagination --width=100 --columns=3
	@echo -e "absdir=\t\t$(absdir)"
	@echo -e "CURDIR=\t\t$(CURDIR)"
	@echo -e "taskrc_dir=\t$${taskrc_dir}"

.PHONY: run-in-docker
run-in-docker:
	[[ -n $$Cmdline ]] || Cmdline="sleep infinity";
		docker run --rm -w /workspace -it -v $$HOME:/host_home:ro -v $(PWD):/workspace $(TestImage) bash -
