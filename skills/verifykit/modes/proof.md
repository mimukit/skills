## Mode `proof`: capture and publish evidence for the PR

The output is a bundle with a GIF and a ready-to-embed `proof.md`, published to a hidden git ref. Name the bundle `NNNN-verify-<slug>-YYYY-MM-DD`, with the serial from the shared procedure and the run's ISO creation date at the end.

### 1. Drive and capture

Walk each selected flow along its primary happy path as a user would. Capture a **screenshot at every meaningful state** (initial, mid-flow, error/empty states the change introduces, success), and a **short animated GIF** of the whole flow. Keep the GIF to a few frames per second, modest width, and a short clip. Stitch the frames with `ffmpeg`:

```sh
ffmpeg -y -framerate 2 -i frame-%02d.png -vf "scale=800:-1" flow.gif
```

When `command -v ffmpeg` finds nothing and the driver cannot record a GIF itself, capture screenshots only. Record "no GIF: ffmpeg missing" in `notes.md` and in the hand-off, and name verifykit `setup` as the way to add it.

Stop when every selected flow has a screenshot for each of its meaningful states, and either a GIF or the recorded no-GIF reason.

### 2. Write the bundle

Save the captures to `docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/` (for example, `docs/verify/0004-verify-login-throttle-2026-07-23/`): the screenshots, the GIF, and a fixed `notes.md` recording the flows driven, the capture backend used, per-step pass/fail, the environment, and any auth or action boundary the run stopped at. Open `notes.md` with four fixed lines, one per field, so the PR step can check freshness without reading prose:

```text
commit: <full sha from git rev-parse HEAD>
dirty: <yes|no>
url: <entry URL driven>
captured: <ISO 8601 capture time with offset>
```

Take `commit:` and `dirty:` from the tested revision the shared procedure recorded. A `dirty: yes` bundle shows uncommitted code, so a reader can treat it as matching no commit. A bundle stays fresh across later commits that change only `docs/` (a QA plan, the bundle itself); any other change after `commit:` makes it stale. Commit before you capture when the work is ready, so the bundle can read `dirty: no`. A same-day re-run for the same slug reuses the bundle the shared procedure found, keeps its whole name, and empties it before it saves the new captures, so the bundle holds only the latest run. The bundle directory is **ephemeral**, because the assets publish to a hidden git ref, so add `docs/verify/` to `.gitignore`.

### 3. Publish so a PR can embed the proof

Publish to a **hidden git ref** (`refs/verify-assets/<slug>`), never to the branch. A normal `git clone` never fetches that namespace, and SHA-pinned `raw.githubusercontent.com` URLs render the assets inline in a PR body. This needs a **public** repo (GitHub's image proxy can't authenticate into a private one).

The git plumbing lives in the bundled [`verify-assets.sh`](../verify-assets.sh) in the skill's root directory. Resolve the installed skill directory and call the script there; the current working directory is the target project, not the skill directory. Don't hand-run the plumbing:

```sh
VERIFY_ASSETS="<path-to-this-skill>/verify-assets.sh"

if bash "$VERIFY_ASSETS" check; then
  # publish the bundle; prints the commit SHA to embed
  SHA=$(bash "$VERIFY_ASSETS" publish <slug> docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/*)

  # resolve the inline-rendering URL for each file
  bash "$VERIFY_ASSETS" url <slug> "$SHA" flow.gif
else
  # private repo: skip publishing and write proof.md with local paths
  echo "private repo: link the local bundle in proof.md for manual attachment"
fi
```

The script also offers `list` (show all `refs/verify-assets/*`) and `delete <slug>` (remove a ref once its PR merges).

Then write the ready-to-embed proof into the bundle's fixed **`proof.md`** (`docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/proof.md`), a Markdown fragment embedding the GIF and screenshots by their SHA-pinned raw URLs, captioned per flow. The PR step splices this file into the pull request body as is. On a private repo (publish skipped), write `proof.md` with the local file paths and a note that they need manual attachment.

This step is done when `proof.md` embeds every capture in the bundle, by raw URL or by local path.

### 4. Hand off

**What changed.** Report the flows verified with pass/fail, the capture backend used, the `.gitignore` line added or already present, and, when published, the commit SHA and the ready-to-embed raw URLs. Give the tested `commit:` and `dirty:` values. On a private repo, say that publish was skipped. When ffmpeg was missing, say that the bundle has no GIF.

**Where it landed.** Print the bundle path. Print one line per screenshot and for the GIF: the absolute path, then the state or flow it shows.

**Next.** Open the PR with **prkit** when installed, otherwise `gh pr create`. The artifacts are ready for a pull request's **Proof** section. Do not open the PR from here.
