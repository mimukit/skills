# retrokit trigger cases

retrokit sets `disable-model-invocation: true`, so the model never fires it on its own. Run each prompt in a fresh session as `/retrokit` or by name, and record whether the right branch ran. A near-miss that runs retrokit means a sibling routes to it by mistake.

## Should fire

**default (current or named session)**

- "/retrokit"
- "Retro this session, it took far too long to find the config"
- "Run a retro on the last afkkit run"
- "/retrokit ~/.claude/projects/-home-dev-projects-skills/6056dfc3-d7f9-491a-9c2f-481e4b17978e.jsonl"

**all**

- "/retrokit all"
- "Retro all sessions on this box, the primeshopr one kept failing lint"

## Should not fire

- "Review my changes" (reviewkit: a diff, not a session)
- "Write a handoff for the next agent" (handoffkit: carries state forward)
- "Why is this test failing?" (debugkit: a symptom in the code)
- "I changed afkkit, check it" (skillkit: one skill you already suspect)
- "Where should I refactor?" (refactorkit: the code, not the session)
