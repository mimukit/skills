# Recover a wedged dev link

You ran `make link`, and `make list` shows something other than `● linked` or `⇄ swapped` — so your agent isn't reading the repo copy. Or `make link` printed a warning and did nothing.

Start by finding out what's actually on disk. The badge is an aggregate across both destinations, so the two can disagree:

```sh
make list
ls -la ~/.claude/skills/<name>* ~/.agents/skills/<name>*
```

Then match the symptom below.

## `◑ partial` — the destinations disagree

Some destinations have a clean link and others don't. This is the signature of an interrupted `link` or `unlink` — a `Ctrl-C` partway through the loop, or one directory that didn't exist.

Re-running the link is idempotent and fixes it:

```sh
make link name=<name>
```

Destinations that are already correct report `already linked` and are skipped. `link` also creates a missing destination directory rather than failing on it.

## `◆ foreign` — a symlink points somewhere else

A symlink is there, but not at this repo's copy. Usually an older checkout, another clone, or the link skills.sh drops in `~/.claude/skills` pointing at the real copy under `~/.agents/skills`.

```sh
make link name=<name>
```

`link` treats `foreign` exactly like `real`: it moves the existing entry aside to a `<name>.skshbak` sibling and symlinks over it. Nothing is deleted, so if that symlink was load-bearing you can still get it back.

## `■ real` — a published install is in the way

A genuine directory is sitting at the path, almost always a skills.sh install. Plain operations deliberately won't touch it.

```sh
make link name=<name>
```

You'll see it move aside:

```
backing up existing install: /Users/you/.claude/skills/<name> -> /Users/you/.claude/skills/<name>.skshbak
linked /Users/you/.claude/skills/<name> -> /Users/you/Github/skills/skills/<name>
```

The status becomes `⇄ swapped`. Your published install is parked next to the symlink, and `make unlink name=<name>` restores it.

## `make link` warned about an existing backup and skipped

```
warn: /Users/you/.claude/skills/<name> collides with an existing install but a
backup already exists at /Users/you/.claude/skills/<name>.skshbak — skipping to
avoid clobbering it
```

This is the one case the tooling refuses to resolve on its own, and the refusal is deliberate: overwriting the backup would destroy the published install it's protecting, irreversibly.

It means a previous `link` already backed something up, and something *else* has since taken the live path. You have two copies and the tooling won't guess which one you want.

Look at both before deciding:

```sh
ls -la ~/.claude/skills/<name> ~/.claude/skills/<name>.skshbak
cat ~/.claude/skills/<name>.skshbak/SKILL.md | head -20
```

Then pick one.

**Keep the backup** (the usual case — it's your published install):

```sh
rm -rf ~/.claude/skills/<name>          # remove the live entry
make unlink name=<name>                 # restores the backup into place
make link name=<name>                   # re-backs-it-up and links cleanly
```

**Discard the backup** (you've confirmed it's stale and want it gone):

```sh
rm -rf ~/.claude/skills/<name>.skshbak
make link name=<name>
```

Do this per destination directory — `~/.claude/skills` and `~/.agents/skills` each carry their own backup, and they can be in different states.

## `make unlink` said "not a symlink (real install) — leaving it alone"

Working as designed. `unlink` only removes symlinks it can account for; it will not delete a real install. If you want that install gone, remove it with the tool that put it there, or by hand.

Note that `unlink` still restores a backup even when there's no symlink to remove — so if the live path is empty and a `.skshbak` exists, running `make unlink name=<name>` is the way to bring it back.

## Verify

```sh
make list
```

`● linked` means the repo copy is live everywhere with nothing backed up. `⇄ swapped` means the same, over a preserved install. Either is a good resting state.

## Next

To understand why the tooling backs up instead of overwriting, and how the aggregate badge is computed from the per-directory states, see [the status model](../architecture.md#the-status-model).

_Verified against `main`@`fd96414` on 2026-08-07._
