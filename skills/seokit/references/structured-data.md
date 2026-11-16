# Structured data: eligibility

Read this when `DATA-VALID` or `DATA-ENTITY` needs a fix, or a page type has no markup.

## Eligibility

Fetch Google's [search gallery](https://developers.google.com/search/docs/appearance/structured-data/search-gallery) before recommending a type; the list changes.

Gone from the gallery, so never promised as a Google rich result:

- **FAQ.** Limited to authoritative government and health sites in August 2023; Google stopped showing FAQ rich results on 2026-05-07 and removed the Search Console report in June 2026. `FAQPage` markup stays valid, and Bing and some AI crawlers still read it. Keep existing markup that matches visible Q&A; add it for those readers, never for a Google feature.
- **HowTo.** Rich results removed in 2023.
- **Sitelinks search box.** Removed in late 2024; `WebSite` with `SearchAction` earns nothing in Google now.

Google's AI features need no special markup, so never sell structured data as a way into AI answers.

## What to check per type

| Type | Required for a Google feature | Worth adding for every engine |
|------|-------------------------------|-------------------------------|
| `Article`, `BlogPosting`, `NewsArticle` | none strictly; `headline`, `image`, `datePublished` recommended | `author` as a `Person` with `url`, `dateModified` |
| `BreadcrumbList` | `itemListElement` with `position`, `name`, `item` | matches the visible breadcrumb |
| `Product` | `name` plus one of `offers`, `review`, `aggregateRating` | `offers.price`, `priceCurrency`, `availability` |
| `Organization` | none strictly; `logo` and `url` recommended | `sameAs` to official profiles, `name` equal to the brand everywhere |
| `LocalBusiness` | `name`, `address` | `telephone`, `openingHoursSpecification`, `geo`; name, address, and phone identical to the Business Profile |
| `SoftwareApplication` | `name`, `offers.price` (0 is valid), plus `aggregateRating` or `review` | `applicationCategory`, `operatingSystem` |
| `Person` (profile, author) | inside `ProfilePage` for that feature | `jobTitle`, `sameAs`, `knowsAbout` |

Use absolute URLs and stable `@id` values (`https://example.com/#organization`) so pages can reference one entity instead of repeating it.

## Validating

Run Google's [Rich Results Test](https://search.google.com/test/rich-results) on a public URL, or paste the rendered code for a local page; it renders JavaScript, so it sees injected blocks that raw HTML misses. The [Schema Markup Validator](https://validator.schema.org/) checks schema.org syntax for every engine. Passing either proves eligibility at most, never display.
