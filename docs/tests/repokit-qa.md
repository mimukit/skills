# repokit — QA / test plan

> **Scratch file, untracked.** This is a disposable test plan for a live trial of `repokit`. Delete it (or gitignore `docs/tests/`) when you're done — it isn't meant to ship.

## Setup

```sh
make link name=repokit      # symlink the repo copy into ~/.claude/skills + ~/.agents/skills
make lint name=repokit      # must pass with no E:, address any W:
```

Then **start a fresh session** — the skill list loads at startup, so a running session won't see the new skill.

Run the trigger prompts against a **throwaway GitHub repo you own** (or one where changing the About/labels is harmless), since the skill mutates real repo metadata. `gh auth status` should be green first.

## Cleanup

```sh
make unlink name=repokit    # restore any swapped real install
```

Delete this file when finished.

---

## Trigger prompts — these SHOULD fire repokit

Each should invoke repokit, hit preflight, route to the right mode, and **preview before mutating** (nothing changes on GitHub without an OK).

- [ ] **1. Bare invocation** — "repokit"
  - *Expect:* asks which mode (about / labels) since none is implied; doesn't guess.
- [ ] **2. About, description** — "write an About description for this repo and set it"
  - *Expect:* `about` mode. Reads current description + topics, reads README/manifest, proposes a one-liner (no trailing period) + topics, shows a current-vs-proposed table, applies via `gh repo edit` only after approval, echoes the command.
- [ ] **3. About, topics** — "add some good topics/tags to this repo"
  - *Expect:* `about` mode focused on topics; generated topics obey GitHub format (lowercase, hyphens, ≤20); reconciles against existing topics rather than blindly replacing.
- [ ] **4. Labels** — "provision the issuekit workflow labels on this repo" (or "the `blocked` label is missing, set up the labels")
  - *Expect:* `labels` mode. Runs `gh label list`, diffs against the canonical 8-label set, previews missing/drifted/matches, creates/updates only on approval with correct colors, leaves unrelated labels (`bug`, `enhancement`) untouched.
- [ ] **5. Vague both** — "set up this repo's metadata"
  - *Expect:* offers to run `about` then `labels`; still previews each mutation.

## Near-miss prompts — these should NOT fire repokit

- [ ] **A. Issue work** — "create issues from this plan" / "triage the backlog"
  - *Why silent:* that's **issuekit**. repokit provisions labels but doesn't create/triage issues.
- [ ] **B. PR work** — "open a PR for this branch"
  - *Why silent:* that's **prkit**. repokit doesn't touch pull requests.
- [ ] **C. Local README edit** — "improve the README's intro paragraph"
  - *Why silent:* repokit sets the GitHub *About* blurb + topics + labels, not file contents. Editing a README is ordinary editing.

---

## Behavioral assertions — checklist for a real run

- [ ] **Preflight runs first** — checks `gh` installed + authed + a GitHub remote; stops with guidance if any is missing.
- [ ] **Degrades without `gh`** — in a no-shell/no-`gh` context, prints the exact `gh` commands (description/topics lines, `gh label create` block) as a codeblock instead of failing.
- [ ] **Routes by mode** — picks `about` vs `labels` from the ask; asks when it's ambiguous.
- [ ] **Never clobbers silently** — `about` mode always shows current values and lets the user decide per field; `labels` mode never deletes labels outside the canonical set.
- [ ] **Previews every mutation + echoes commands** — nothing changes on GitHub before an OK; every `gh` command run is printed.
- [ ] **Topic hygiene enforced** — proposed topics are lowercase, hyphenated, ≤50 chars each, ≤20 total.
- [ ] **Label set matches issuekit** — the 8 labels, colors, and descriptions are identical to issuekit's lifecycle-labels table (shared contract).
- [ ] **`make lint name=repokit` passes** — no `E:`; portability warnings addressed (public skill: self-contained, no repo-relative links, degrades without a filesystem/shell).
- [ ] **Stops at the hand-off** — proposes a commit message; does **not** commit on its own.
