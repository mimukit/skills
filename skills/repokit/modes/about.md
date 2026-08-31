# Mode: `about`

Infer the description and topics, reconcile against what's there, apply on approval. The root's [Preflight](../SKILL.md#preflight-every-mode) and [Detect](../SKILL.md#detect-every-mode) have already run; this file assumes their state and repeats none of it.

## 1. Start from what's already set
You read the current description and topics in Detect, so carry them in and reconcile against curated metadata instead of clobbering it.

## 2. Gather signal from the repo
Read the cheap, high-signal sources first; only dig deeper when they're thin:

- **Primary.** The `README` and the project manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`, …): name, existing description/keywords, dependencies, scripts.
- **Fallback.** Only when the above are missing or uninformative: scan the file tree and language mix (`gh repo view --json languages`, a shallow `ls`/`git ls-files`) to infer what the repo *is*.

## 3. Generate the description and topics
- **Description.** One line, plain, specific about what the repo *is/does*, no trailing period, short enough for GitHub's About panel. Say what it is, not how great it is.
- **Topics.** A focused, high-signal set (language, framework, domain, purpose), not keyword-stuffed. Enforce GitHub's format so they'll be accepted: lowercase, digits and single hyphens only, must start with a letter or number, ≤50 chars each, ≤20 topics total. Prefer widely-used topic slugs (e.g. `typescript`, `cli`, `github-actions`) so the repo surfaces under real topic pages.

## 4. Show current vs proposed, let the user decide per field
Present a side-by-side so nothing is a surprise, and let the user accept, edit, or keep-current **each field independently**:

| Field | Current | Proposed |
|-------|---------|----------|
| Description | `old blurb` | `new blurb` |
| Topics | `a, b` | `a, c, d` (+`c`,`d`; −`b`) |

Don't apply anything until the user signs off on the final values.

## 5. Apply, echoing the commands
On approval, write the approved values and print each command you run:

```sh
gh repo edit --description "the approved one-liner"
# reconcile topics to the approved set:
gh repo edit --add-topic new-one --add-topic another --remove-topic dropped-one
```

To *replace the whole topic set* in one call instead of add/remove reconciliation, the topics API is cleaner: `gh api --method PUT repos/{owner}/{repo}/topics -f 'names[]=a' -f 'names[]=b'`. Either is fine, so pick whichever expresses the change more simply.

## 6. Hand off

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the description and topics as they now stand, and anything the user chose to keep current rather than replace. A field you proposed and they rejected is worth one line; it's the part most likely to come up again.

**Where it landed.** Name the repo's About panel, with its URL, so they can eyeball the result.

**Next.** Name one move and stop. If `labels` hasn't run in this repo, that's it: the lifecycle and priority labels are what an issue workflow needs and the About panel isn't. If both modes are done, repokit is finished with this repo, so point at what the metadata unblocks (**issuekit** to start filing work, when installed) rather than manufacturing more configuration. When this run was delegated from `setup`, skip this hand-off; `setup` closes for the whole span.
