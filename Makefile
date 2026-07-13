.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

## link [name=<skill>]    Symlink a skill into ~/.claude/skills + ~/.agents/skills (no name → picker)
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

## security [name=<skill>] Heuristic security scan (local stand-in for skills.sh scanners)
security:
	@scripts/security.sh $(name)

## help                   Show this help
help:
	@echo "mimukit/skills — targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'

.PHONY: link unlink list lint security help
