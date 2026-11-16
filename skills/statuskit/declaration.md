# The declaration offer

This offer fires only on an empty-array **unknown** reading from [Resolving the tracker](SKILL.md#resolving-the-tracker), with a user there to answer.

Offer to append one sentence to the repo's agent-guide file, so the next run resolves at the agent-guide rung instead:

> `This project tracks work in Linear, not GitHub Issues.` or `This project manages work in GitHub Issues.`

Four bounds hold it inside statuskit's [write rules](SKILL.md#write-rules):

- **Preview it and wait for an OK**, even though the change is local.
- **Write only to an agent-guide file that already exists**, preferring `CLAUDE.md` and otherwise whichever equivalent the repo keeps. **Never create one.** With no such file, print the line for the user to place.
- **Offer it once per run, as a runner-up**, never as the crowned move.
- **Skip it entirely in an unattended run.**

The offer is done when the sentence is written on approval, printed for the user to place, or declined. The snapshot's runner-up for it carries the key `declare-tracker`.
