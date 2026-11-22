# Mode `mockup`: show a screen as an image

A mockup is a picture a person looks at to compare or approve a screen before the real build. **The output is an image.** Code appears only when the user asks for code ("as code", "the HTML", "the component"), and that ask is a [`build`](build.md).

A request for options is one mockup run with N options, each from a different design read. N is at most 4. A request for more gets four, with the cap said in one line.

No code ships from this mode, so the stack layer, the mobile layer, and the accessibility floor do not apply. The catalog and the design read do.

### 1. Ground it

Walk [the ladder](../SKILL.md#the-precedence-ladder) and name the rung that matched. When a `DESIGN.md` exists, read it, because its tokens are the palette, type, spacing, and radii of every option. List every screen the request names, and set the option count. State [the design read](../SKILL.md#the-design-read) once per option, with a different signature in each.

**Done when** the rung, the screen list, the option count, and one design read per option are named, and no two options share a signature.

### 2. Pick the image path

Use the built-in Codex image generator if the session already runs Codex on the latest Sol model and exposes the generator. Use the host's model list to find the latest Sol model it offers. If the host has no model list, check the `*-sol` entries in `~/.codex/models_cache.json`. If the current session cannot use that path, start a Codex subagent with the host's delegation tool when it supports the provider and model. Where the host uses the CLI to run Codex, use `codex exec -m <sol-model>`. Give the runner the prompt and PNG output path. Confirm that the runner returns the PNG.

If this path is unavailable or fails, tell the user what is missing. Ask the user to choose among available image generators or offer to prepare a prompt they can run elsewhere. Wait for the choice. In an unattended run, report the blocker and stop. Use HTML only if the user asks for code, which routes to `build`.

**Done when** the generator is selected or the user has the available options.

### 3. Produce it

Write one prompt per option. Include the design read, the screen's real copy, the `DESIGN.md` token values, and the surface. Follow the [catalog](../SKILL.md#the-anti-slop-catalog) rules on content. Save the PNG files outside the code repository. Show the options labeled A to D in one reply.

Collect all requested changes before you generate the next round.

**Done when** every option exists as an image and the user has seen all of them in one reply.

### 4. Check

Look at each option against [the catalog](../SKILL.md#the-anti-slop-catalog), filtered to the declared surface. Check that each option has exactly one signature. Take one decoration out of each option that has one to spare. Report what you fixed and what you leave, with a reason. Never claim a check that did not happen: an image you could not open is unchecked, and you say so.

**Done when** each option has a catalog result and a signature result.

### 5. Publish the round if requested

When the user asks to publish a round or the project instructions require publication, read [the mockup gist workflow](../mockup-gist.md). Follow it once you have authorization to publish and post the issue comment. Use this step for an existing round when the user asks to publish it. In that case, start here with the supplied PNG files.

**Done when** the issue comment contains the round, or the user has the image paths and the reason publication stopped.

### 6. Hand off

**Called by a build skill** (implementkit, afkkit, or another kit that runs uikit as a step)? Return the image paths and the design read of each option, then stop.

**What changed.** List the image files created or published.

**Where it landed.** Give the image paths and the design read of each option verbatim. Include the gist and issue comment URLs when available.

**Next.** Ask the user to pick an option or send all changes at once. If the user approves a published mockup for a plan, record approval as specified in [the mockup gist workflow](../mockup-gist.md). For a local mockup, record the date and visual reference in the plan's Design decisions row. Use the approved design read for the next [`build`](build.md).
