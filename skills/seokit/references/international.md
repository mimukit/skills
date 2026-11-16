# International checks

Read this when a page carries hreflang links, locale path prefixes (`/en/`, `/de/`), or locale subdomains. Add these rows to the evaluation; they follow the root's verdict and evidence rules. Fetch every hreflang target with `extract` to check its status, canonical, and return links.

| ID | Passes when |
|----|-------------|
| `INTL-SELF` | The page lists itself in its own hreflang set |
| `INTL-RECIP` | Every target links back to this page with its own hreflang |
| `INTL-CODES` | Codes are ISO 639-1 language plus optional ISO 3166-1 region (`en`, `en-GB`, `pt-BR`); `en-UK` is invalid, because the region code is `GB` |
| `INTL-XDEFAULT` | One `x-default` points at the fallback page (a selector or the default locale) |
| `INTL-TARGETS` | Every target returns 200, is indexable, and is its own canonical |
| `INTL-CANON` | Each locale page canonicals to itself, and that canonical appears in the hreflang set |
| `INTL-AGREE` | HTML `<link>`, HTTP `Link` headers, and sitemap `xhtml:link` entries agree, when more than one is used |
| `INTL-CONTENT` | The main content is translated, not only the navigation; for a locale you cannot make useful, the fix is to not publish it, rather than `noindex` or a cross-locale canonical |
| `INTL-ROUTING` | No redirect by IP address or `Accept-Language`; Googlebot crawls mostly from US addresses with no `Accept-Language`, so it never sees the other locales |

- Next.js `alternates.languages` does not add the current page's own entry; add it explicitly.
- Bing treats hreflang as a weak signal and leans on `<html lang>` and `content-language`; set both.

In `local`, check the hreflang targets on the production origin path by path against the local server, the same way the root maps canonicals.
