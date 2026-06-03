---
name: pr-review
description: Interactive PR review with live-diff verification and draft-approve-post gates
---

# PR Review

1. **Fetch live state first.** Run `gh pr view <num> --json state,headRefOid,updatedAt` + `gh pr diff <num>`. Refuse to proceed on cached/stale dumps. Flag if PR updated since last context.
2. **Walk issue-by-issue.** Present findings one at a time; get per-item decision before moving on. Never dump one long summary.
3. **Draft to scratch file.** Write all proposed inline comments to `.claude/pr-reviews/<repo>-<num>.md` with file:line anchors validated against the current SHA.
4. **Wait for explicit approval.** Show full draft. Do not call any `gh` write API until the user says "post it".
5. **Submit as one review.** Use `gh pr review --request-changes` (or `--approve`) with all inline comments in a single call. No top-level probe comments. No test posts on production repos — use a fork.
