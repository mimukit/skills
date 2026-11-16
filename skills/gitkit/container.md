# Containers and remote boxes

Git worktrees store **absolute** paths. If a repo is bind-mounted into a container at a path different from the host's, every worktree inside it breaks.

- Mount **both** `$WORKTREE_ROOT` and the main checkout. A worktree's real git directory lives under the main repo's `.git/worktrees/`; mounting only the worktree yields a broken checkout.
- Mount both at the **same absolute path** inside and outside the container. This is the robust answer.
- Second belt, on git 2.48+: `git config worktree.useRelativePaths true` and `git worktree repair --relative-paths`. Relative pointers survive remapping *as long as the repo and the worktree root keep their relative positions*, so keep them side by side, e.g. `~/code/<repo>` and `~/worktrees/<repo>`.

A GUI dev tool that manages worktrees may **observe** these. Orca and its peers read `git worktree list` and typically have a setting to surface externally-created worktrees. That is a one-time UI configuration on whichever machine runs the GUI, and it is the only asymmetry between machines.
