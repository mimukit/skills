## Mode `list`: the morning dashboard

What is waiting on you, in one table:

```sh
gh pr list --state open --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision,author,updatedAt
```

Gather four more facts per PR:

- **Unresolved review threads.** REST does not expose thread resolution state at all; only GraphQL does, via a `reviewThreads` connection carrying `isResolved` and `isOutdated`. Query it with `gh api graphql`.
- **Behind the base branch.** Run `git fetch origin` once, then compare each head against `origin/<base>`.
- **A QA plan and proof.** Look for the artifacts your repo's conventions produce (a QA plan doc, a proof bundle, whatever the PR body links). Print an absence as a fact.
- **Stack position.** A PR whose base is another feature branch is a layer: its diff is only its own slice, and merging it merges everything below it. Mark the layer and its depth (`layer 2 of 3`), and group a stack's PRs together in the table rather than scattering them by update time.

Print one table, most-ready first, with drafts and PRs authored by others clearly marked. Ends when every open PR has a row, and each row carries all four facts above or names the one it could not read. **Do not crown a "next" PR**; ranking work belongs to a project-status skill. Within a stack, print the bottom layer first, in merge order.

### Hand off

**What changed.** Nothing. `list` reads and prints only.

**Where it landed.** The table above.

**Next.** Pick a PR from the table and run `start <n>` to set it up for review.
