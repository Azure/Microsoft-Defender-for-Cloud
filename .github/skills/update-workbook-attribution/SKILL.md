---
name: update-workbook-attribution
description: 'Use when standardizing workbook README.md filenames, linking original authors to GitHub profiles, or updating human Contributors from Git history. Verify profile names and co-authors, deduplicate Author/Contributor credits, follow renamed paths, exclude bots and automation, preserve original credit, and validate case-sensitive links.'
---

# Update workbook README attribution

Normalize a selected workbook's README and human attribution using verifiable repository history.
Use this workflow for any workbook folder; do not assume a particular product, tenant, author, branch, or workbook format.

## 1. Establish scope and preserve work

1. Identify the repository, target workbook folders, and intended branch or PR. If the user asks for a trial, start with the selected workbook rather than rewriting the whole repository.
2. Read applicable repository instructions and the existing README. Preserve copyright, licensing, acknowledgments, and established original-author credit.
3. Check Git status. Work in the intended clean branch or isolated worktree; never stage, revert, or overwrite unrelated work.
4. Confirm history is not shallow with `git rev-parse --is-shallow-repository`. If incomplete, fetch the needed history or report the limitation; never present a partial contributor list as exhaustive.

## 2. Collect workbook-specific history

1. Use the complete workbook folder, not only its native workbook file. Include its deployment templates, documentation, images, and other maintained assets.
2. Start with `git log --no-merges --format="%H" HEAD -- "<workbook-folder>"`. Record the reviewed revision and deduplicate by full commit SHA.
3. Inspect renamed files with `git log --follow --name-status HEAD -- "<file>"`, one file at a time. If files or folders moved, include verified old paths in the history search. Directory-scoped GitHub history does not automatically prove pre-rename coverage.
4. Exclude merge-only credit and repository-wide contributors who did not change this workbook's assets. Investigate actual manual merge-resolution changes separately rather than treating every merge committer as a contributor.
5. Include the current PR's human contributions, not only commits already merged into the default branch. Do not count unsubmitted reviewer comments, issue participation, or generic tool authorship as workbook contributions.

## 3. Verify human GitHub identities

1. Prefer official GitHub tools. If needed, use the authenticated GitHub API without printing credentials.
2. Associate each scoped commit with GitHub accounts, not guesses based on names or email prefixes. GitHub GraphQL `Commit.authors` includes linked co-authors; page through all commits and author connections.
3. Verify each unique account using its public GitHub profile. Cache by case-insensitive login so repeated commits do not trigger repeated profile requests.
4. Exclude GitHub accounts of type `Bot`, bot-suffixed logins, and verified service/agent identities such as Copilot, GitHub Actions, Dependabot, and web-flow. Never exclude a human solely because a username contains words such as "bot", "agent", or "automation".
5. Credit authors and verified human co-authors, not a committer who merely applied someone else's change. Existing automation co-author trailers may remain in Git history; excluding them from this list does not authorize rewriting commits.
6. Use the public profile's current display name exactly; if it is blank, use the username. Link to the verified canonical profile URL.
7. Deduplicate aliases by verified account across the entire attribution block, not separately within each section. Do not merge people just because their display names match.
8. If an apparent human cannot be linked confidently, preserve established plain-text credit and report the unresolved identity. Do not invent a profile URL or silently discard a person. Keep emails, tokens, private profile data, and identity guesses out of the README and any evidence.

## 4. Use a consistent attribution block

Prefer **Original author** when retaining the person who introduced the workbook. Do not replace original authorship with the latest or most prolific contributor, and do not imply that a historical author is the current sole maintainer.

```markdown
**Original author:** [Profile display name](https://github.com/original-author)

## Contributors

- [Contributor display name](https://github.com/contributor)
```

- List only additional verified human contributors who are not already credited under **Author**, **Authors**, **Original author**, or **Original authors**, using Markdown profile links.
- Compare verified canonical GitHub logins case-insensitively across all author and contributor entries. An author's contribution is already represented by their author credit; remove only the duplicate contributor entry, not the author credit.
- If no additional contributors remain, omit the Contributors section rather than repeating an author or leaving an empty list.
- Sort deterministically by displayed name, then username. Do not add contribution counts, rankings, inferred roles, or stale employment titles.
- Preserve relevant original organizational/program credit without inventing a current affiliation.
- Add a short scope note: additional human contributors from this workbook folder's history, including the current change set; authors are credited above, and automation and merge-only credits are excluded.
- Escape Markdown punctuation in profile display names without changing the displayed name.
- Treat the list as a reviewed snapshot, not an automatically complete or continuously synchronized service.

## 5. Normalize README casing and links

1. The target basename is exactly `README.md`. If multiple distinct README variants exist, stop and inspect before combining anything.
2. On case-insensitive filesystems, use an intermediate name so Git records the case-only rename:

   ```powershell
   git mv -- "<workbook-folder>\readme.md" "<workbook-folder>\README.case-rename.tmp"
   git mv -- "<workbook-folder>\README.case-rename.tmp" "<workbook-folder>\README.md"
   ```

3. Refuse to overwrite an existing intermediate file. Do not change global Git case-sensitivity settings.
4. Update directly affected relative links, catalog references, and PR-description links. Verify exact casing against tracked Git paths, not only filesystem existence, because Windows can hide Linux/GitHub failures.
5. Leave unrelated README files and workbooks alone unless they are explicitly in scope.

## 6. Validate and report

1. Check that the union of author and contributor links exactly matches the verified human profile set. No account may appear twice within or across sections; exclude bots, service accounts, and guessed identities.
2. Confirm every historical human contributor is represented exactly once, either as an author or an additional contributor, including deployment/documentation-only contributions and verified co-authors.
3. Verify exact `README.md` casing, updated local links, and absence of the temporary rename file. Run the repository's existing Markdown checks and `git diff --check`.
4. For this skill file, validate YAML frontmatter, matching folder/name, meaningful description, and relative resource links.
5. Keep attribution evidence as a small private/session report containing reviewed revisions, relevant commit SHAs, verified public names/logins/profile URLs, exclusions, and unresolved cases. Do not retain email addresses or credentials.
6. Publish only the intended documentation/workflow changes to the agreed branch or PR. Do not alter unrelated runtime behavior or auto-commit other work.
7. Report the scope, verified contributors, exclusions, validation, and any history/identity limitations. Do not claim a repository-wide rollout when only one workbook was piloted.
