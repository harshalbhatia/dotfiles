---
name: pr-review-safe
description: Hard-gated PR review — fetches live state, drafts to file, creates sentinel only on explicit POST. PreToolUse hook blocks gh writes without a matching sentinel.
---

# PR Review (Safe)

Use when the user wants extra-strict gating on a PR review. The system hook at `~/.claude/hooks/block-pr-write.sh` will refuse any `gh pr review`, `gh pr comment`, or `gh api ... pulls/N/{reviews,comments}` POST/PATCH/PUT unless a fresh, SHA-matching sentinel exists for that exact owner/repo/PR.

## Steps

1. **Capture live state.**
   - `gh pr view <num> -R <owner>/<repo> --json state,headRefOid,updatedAt`
   - `gh pr diff <num> -R <owner>/<repo>`
   - Refuse to proceed on cached/stale dumps. Record the head SHA — you'll need it for the sentinel.
2. **Walk findings issue-by-issue.** Get per-item decision; never one long summary dump.
3. **Draft to scratch file.** Write all proposed inline comments to `~/.claude/pr-reviews/<owner>-<repo>-<num>.md` with file:line anchors.
4. **Self-critique pass.** Flag em-dashes (`—`), `?` in non-questions, and vague comments ("nit", "consider", "maybe") in the draft. Fix or call out before showing the user.
5. **Show the full draft. Wait for explicit `POST`.**
6. **On POST: create sentinel.**
   ```bash
   sha=$(gh pr view <num> -R <owner>/<repo> --json headRefOid -q .headRefOid)
   slug=$(echo "<owner>/<repo>" | tr '/' '-')
   echo "$sha" > ~/.claude/pr-reviews/${slug}-<num>.approved
   ```
   The sentinel:
   - is scoped to that exact `<owner>/<repo>` + PR# (cannot authorize any other PR/repo)
   - expires after 20 min
   - is invalidated if the PR head SHA changes (force-push, new commit)
7. **Submit.** Single `gh pr review --request-changes` (or `--approve`) call with all inline comments. Hook will let it through.
8. **Cleanup.** Sentinel persists until expiry; let it die naturally or `rm` it after successful post.

## If the hook blocks

- "No approval sentinel" → user hasn't said POST yet; don't bypass — confirm with them.
- "Sentinel expired" → re-show draft, re-confirm, re-create sentinel.
- "Head SHA drift" → PR was updated since draft; refetch `gh pr diff`, redraft affected anchors, re-confirm.
- Never `--no-verify` or edit the sentinel file to bypass.
