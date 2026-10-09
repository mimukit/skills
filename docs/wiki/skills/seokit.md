# seokit

Audit a web page, or crawl a whole site, for SEO and AEO gaps, then write an evidence-backed fix report and a long-term search and AI-visibility plan.

**Reach for it when** you want to know what keeps a page out of Google or out of ChatGPT's answers, and you would rather find out on your local dev server than after the deploy.

| | |
|---|---|
| Modes | [`audit`](#audit) · [`crawl`](#crawl) |
| Tools | `Bash`, `Read`, `Write`, `WebFetch`, `WebSearch`, `AskUserQuestion` |
| Writes | `docs/seo/NNNN-seo-<slug>-YYYY-MM-DD.md` inside a git repo; asks first anywhere else |
| Triggering | model-invocable |
| Visibility | public |

## What it does

seokit reads a page the way a crawler does, checks it against a fixed catalog of about forty checks, and writes a report a site owner can act on. Each finding quotes what was actually on the page, carries a severity and an effort estimate, and comes with a fix written for that page: the proposed title, the exact `robots.txt` line, the JSON-LD block. When it runs inside the site's repository, each fix also names the file that controls it.

The report ends with a plan in three horizons: what to fix this week, what to build over the next one to three months, and what to keep doing on a cadence. Every item points back at a finding or at the playbook for the site's type, so the plan cannot drift into advice that would fit any website.

It never edits the site. The fixes go to [`implementkit`](./implementkit.md) or to whoever owns the code.

## Why SEO and AEO are one audit

Answer engines and search engines read the same thing first: the raw HTML the server sends. Whether Googlebot can index a page and whether OAI-SearchBot can quote it are mostly the same question, so two separate skills would fetch the same page twice and give the owner two reports to reconcile. seokit keeps one catalog and tags each finding `search`, `ai`, or `both`.

The one place they split is the AI crawler policy, and that split is where most advice goes wrong. A `robots.txt` that blocks GPTBot is a training opt-out, not a visibility problem; blocking OAI-SearchBot is the one that keeps a site out of ChatGPT's search answers. seokit sorts crawlers by purpose (search discovery, user-triggered retrieval, training, product control tokens) and passes the check when each purpose has a deliberate rule, whatever the rule is.

## Why local first

Most runs point at `http://localhost:3000` from inside the repository, before the change ships. A finding there lands next to the file that fixes it, and it costs nothing to fix before anyone has crawled the mistake.

The environment comes from the URL, never from a question. A local host gets local rules: checks that only make sense at the production edge (HTTPS, the CDN's redirects, the WAF, the brand's presence on the public web) read `n/a` and move to a "verify at the preview or production stage" line. Canonical and sitemap URLs are judged against the production origin, which seokit reads from the framework config, so a local page whose canonical points at the real domain passes. A `noindex` or a `Disallow: /` on a local or preview build reads as a warning to confirm, because staging builds block crawlers on purpose.

## Why it stops on a dev server

A dev server is not what ships. It serves code that is not minified, injects hot-reload scripts, skips caching, and some frameworks render metadata and sitemap routes differently in dev. An audit against it produces performance numbers that mean nothing, and some structure verdicts that will not hold after the build.

So when the page carries a hot-reload client, seokit stops before gathering anything else, says so, and gives the commands to run this particular project in production mode: the project's own scripts first, then the framework's gotchas, such as Next.js static export having no server, Astro's Vercel adapter refusing `astro preview`, or Rails forcing HTTPS locally. You can let seokit build and start the server (it stops it afterwards, and confirms the port closed), start it yourself, or carry on against the dev server with structure checks only and a banner on the report.

## Why `unverified` is a verdict

The tools an agent fetches with cannot see everything. `curl` gets the HTML before any JavaScript runs, and a fetch tool that converts pages to text drops `<script>` tags entirely, which is where JSON-LD lives. Many CMS plugins inject structured data with JavaScript, so "no schema found" from raw HTML is often simply false.

A check the method cannot see therefore reads `unverified`, never `fail`, and names the tool that would settle it. The same rule makes the gap between raw and rendered HTML a finding of its own: most AI crawlers run no JavaScript, so content that only appears after rendering does not exist for them.

## Why there is no score

Every SEO tool prints a number out of a hundred, and none of them can say what the number predicts. A single score reads as a ranking forecast, and the weights behind it are invented. seokit reports pass counts per area, a severity tally, and one headline line ("2 Critical, 5 High, 31 of 40 checks pass"), which is enough to compare two runs honestly. For the same reason it quotes a statistic only with its source and date, and never as a forecast of traffic.

## Modes

### `audit`

Examine one page closely, plus the `robots.txt`, sitemap, and `llms.txt` that govern it, with up to five URLs for cross-page checks.

Given no URL ("check SEO before I deploy"), it looks for the running local server on the port the project's scripts use. On a public URL it adds what only exists there: the host redirects, one probe per AI crawler to see whether a WAF turns it away, PageSpeed field data, and a comparison with the two pages that outrank it for the main query. Every run writes a new report rather than updating the last one, so the history stays intact, and a second run on the same page adds a "since last audit" section, so "did my fixes land" needs no separate mode.

### `crawl`

Examine a whole site broadly, from its sitemap and its links, to find the template bugs and structural gaps a single page cannot show.

It fetches up to 100 pages by default, taking turns across site sections so ninety blog posts cannot crowd out everything else, and runs the mechanical checks on every page and the full catalog on one sample per section, five samples at most. Six site-level checks come out of that: duplicate titles and descriptions, sitemap URLs nothing links to, linked pages missing from the sitemap, pages buried more than three clicks deep, and clusters of pages pointing their canonical at one target.

On a public site it identifies itself as `seokit/1.0`, obeys `robots.txt`, and waits a second between requests, because it may be crawling a site you do not own. On your local server it goes as fast as the server answers and reads `robots.txt` without obeying it, since a staging `Disallow: /` would otherwise stop the audit of your own build.

## The extractor

The skill ships a small Node script, `bin/extract.mjs`, with no dependencies. It fetches pages and reports what is on them as JSON, and judges nothing; the verdicts stay with the agent and the catalog. It exists because an agent reading a hundred HTML files by hand gives different answers every run, and because some facts are easy to get wrong by eye: `robots.txt` matching follows longest-rule-wins, and dev servers announce themselves only in their script tags.

The script needs Node 18 or later. Without Node, `audit` falls back to reading the HTML with `curl` and says so in the report's coverage line, and `crawl` stops, because a hundred pages read by hand is the variance the script exists to remove. When a page is a client-rendered app shell and no browser is available, seokit offers a one-time Chromium install through `npx playwright install chromium` rather than guessing at what JavaScript would render. PageSpeed field data uses `PAGESPEED_API_KEY` when it is set, or a key you paste for the run, and the key is never written to disk.

## Hands off to

[`implementkit`](./implementkit.md) to apply the fixes when the run happened inside the site's repository, or a developer otherwise. [`issuekit`](./issuekit.md) to file each finding as an issue, or `gh issue create` without it. After a local audit, the next run is the same page on the preview or production URL, which clears the checks that could not run locally. After a `crawl`, the runner-up is an `audit` of the worst sample page, for the content and competitor verdicts the crawl skips.

## Install

```sh
npx skills add mimukit/skills -s seokit
```

Source: [`skills/seokit/SKILL.md`](../../../skills/seokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`4e88ae7` on 2026-10-09._
