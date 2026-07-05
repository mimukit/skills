.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

## link [name=<skill>]    Symlink a skill into ~/.claude/skills (no name → picker)
link:
	@scripts/link.sh $(name)

## unlink [name=<skill>]  Remove a dev symlink (no name → picker of linked skills)
unlink:
	@scripts/unlink.sh $(name)

## list                   List all skills with their link status
list:
	@scripts/list.sh

## lint [name=<skill>]    Check skills against AGENTS.md conventions
lint:
	@scripts/lint.sh $(name)

## diff [name=<skill>]    Diff a skill's upstream baseline vs snapshot (no name → picker)
diff:
	@scripts/baseline.sh diff $(name)

## save [name=<skill>]    Refresh a skill's baseline snapshot to current upstream
save:
	@scripts/baseline.sh save $(name)

## help                   Show this help
help:
	@echo "mimukit/skills — targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'

.PHONY: link unlink list lint diff save help
