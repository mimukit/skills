# Publish a mockup round

Use one secret GitHub gist per repository. Anyone with the URL can see its contents. Git keeps deleted files in the gist history. Deleting the gist breaks every embed.

### Find the gist

1. Get the repository name with `gh repo view --json nameWithOwner -q .nameWithOwner`.
2. List all gist pages with `gh api --paginate /gists`. Match the exact description `mockups: <owner>/<repo>`. Keep the gist ID only for the current operation.
3. If the lookup fails, stop and report the error. If more than one gist matches, ask the user which gist to use before proceeding.
4. If zero gists match, create `0000-<repo>.md` in a temporary directory. Use the project name as the heading. Add a short description of the collection's purpose. Keep the file free of file lists and image indexes.
5. Create the secret gist from the temporary directory with `gh gist create 0000-<repo>.md -d "mockups: <owner>/<repo>"`. Reuse an existing match, including its description file if present.

If GitHub reports that the token lacks the `gist` scope, tell the user. Leave authentication unchanged.

**Done when** you have one gist for the repository or report the blocker.

### Upload and share the round

1. Use the plan serial, round, and tracking issue from the current work. Ask for any of these that you cannot determine.
2. Clone the gist with `git clone --depth 1 https://gist.github.com/<id>.git` into a temporary directory.
3. Name each PNG `<plan serial>-r<round>-<screen>-<theme>-<width>.png`. Put the files at the gist root. Use a new round for changed images so each published filename keeps the same bytes.
4. Commit and push the PNG files with Git in the gist clone. Keep mockup images out of code repository commits, including plans and orphan branches.
5. Embed each image with `https://gist.githubusercontent.com/<user>/<id>/raw/<file>`. Use the gist owner's login for `<user>`.
6. Post all images from the round in one tracking issue comment. On a retry, reuse the comment if it already contains the round.
7. Show the same images in chat. Give the user the issue comment URL.

**Done when** each raw URL serves its PNG and the issue comment embeds the complete round.

### Record approval

When the user approves the round, record the date, round, gist URL, filename prefix, and issue comment URL in the plan's **Mockup approved** row. Use the published links in the approval record.

**Done when** the plan links to the approved round, or there is no plan to update.
