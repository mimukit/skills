## Mode: `exam`

Measures and never teaches. Ask, grade, record, refuse to explain.

`exam` runs twice per track, and its verdict decides where lesson 1 starts or whether the track closes. Never grade a cue in `exam`, and never write a status in `drill`.

### At track start, placement

Pose **3–5 scenario predictions, broad to narrow**, graded on the same three-level scale. **Stop early on two consecutive misses.**

Write `placed: <rung>` and **every wrong belief, in the user's own words** into `PROGRESS.md`. Those wrong beliefs become lesson 1's target. Done when `PROGRESS.md` holds the rung and every wrong belief the predictions exposed.

### At track end, the transfer test

Pose a problem the user has not seen, which needs the concept without naming it.

**A topic goes `learned` in `INDEX.md` only when both gates pass:** the transfer test is solved, **and** every cue has reached step `60d`. `exam` is the only mode that writes that status. When one gate passes and the other does not, say which one held it and leave the status `active`. Done when both gates have a pass or fail result, and the status in `INDEX.md` matches them.

**A `learned` topic keeps its cues.** They keep coming due, and the fill order in `drill` stops them displacing a live track.

`exam` writes `PROGRESS.md` at both ends and touches `INDEX.md` only to close a track. It never writes `MISSION.md`. Then go to [Hand off](../SKILL.md#hand-off).
