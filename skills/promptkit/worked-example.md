## A worked `task` run

The default mode, with no questions asked, because the tree answered them.

**In.** What the user pasted:

> fix the login bug, the session thing is broken. make sure tests pass and don't break anything else

**Grounding.** Three reads, no questions. A search for the session helper lands on `src/lib/session.ts` and the function that actually holds the bug; `package.json` gives the real commands; the repo's agent instruction file already mandates the error-handling convention, so the prompt points at that file instead of restating it.

**Out.** The prompt, ready to paste:

```
`refreshSession()` in `src/lib/session.ts` returns the stale token when the
refresh call fails, so an expired session reads as valid downstream.

Scope: `src/lib/session.ts` and its test file. Leave `src/middleware/auth.ts`
as it is, because the routing there is correct and out of scope for this fix.

Constraints: follow the conventions in the repo's agent instruction file. Keep
`refreshSession()`'s signature, since three call sites depend on it.

Task: make a failed refresh in `refreshSession()` end the session instead of
returning the stale token.

Done when a new failed-refresh case in `src/lib/session.test.ts` fails before the
fix, on the stale token coming back, and passes after it; the rest of
`pnpm test src/lib/session.test.ts` stays green, and `pnpm typecheck` is clean.

Stop there. Leave the surrounding token helpers as they are, and do not commit.
```

**What changed.** The ledger:

```
resolved "the session thing" → src/lib/session.ts, refreshSession()
resolved "make sure tests pass" → pnpm test <file> && pnpm typecheck
resolved "don't break anything else" → named auth.ts as explicitly out of scope
assumed the bug is the stale-token return path; stated in the prompt, correct it if wrong
```

The order follows the contract's layout rule: the context the receiver needs (the bug, the scope, the constraints) comes first, and the ask, its done signal, and its stop condition come last, where the receiver reads them just before it acts.
