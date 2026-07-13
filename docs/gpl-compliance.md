# GPL Compliance — Woman in Red (Hiddify fork)

**Base:** [hiddify/hiddify-app](https://github.com/hiddify/hiddify-app) — "Hiddify Extended GNU General Public License v3" (GPLv3 + additional conditions under GPL v3 Section 7).
**Our fork:** https://github.com/maikrais98/hiddify-app
**Verdict for our use case (rebrand to a distinct name, non-commercial, TestFlight to ~20–30 friends): GO.**

## The 7 additional conditions and how we satisfy them

| # | Condition | Our compliance |
|---|---|---|
| 1 | Publish source as a fork of hiddify-app, kept up to date with releases | Fork created (`maikrais98/hiddify-app`); keep it public and push our changes |
| 2 | **All releases must be made using GitHub Actions** | **Mandatory.** iOS/TestFlight release must run through GitHub Actions (macOS runner + fastlane), not manual Xcode upload |
| 3 | Attribution: credit Hiddify + link the license + document changes in README | Add attribution + changelog section to our README |
| 4 | No malware | N/A — we add none |
| 5 | No app-store publish with a name/UI **closely resembling Hiddify** (Hiddify, Hidy*, Hiddy*, *Ify, similar UI) | "Woman in Red" + our red/Nova UI do not resemble Hiddify — compliant |
| 6 | **Non-commercial only** (no selling/advertising) without written consent | Free distribution to friends = compliant. **Blocks future monetization** without Hiddify's written consent |
| 7 | ShareAlike — derivatives under the same license, as an open-source fork | We keep the fork open under the same license |

## Consequences to carry forward

- **Releases via GitHub Actions are a license requirement, not just good practice** (condition 2). The Apple/TestFlight release pipeline must be a GitHub Actions workflow.
- **Monetization is off the table** without written consent from Hiddify (condition 6). If the product ever needs to be commercial, revisit the base (e.g., OneXray under clean GPL-3.0).
- **Keep the fork public and current** with any release we ship (conditions 1 & 7).
- **README must carry attribution + a changelog of our modifications** (condition 3) — to add during the rebrand phase.

## Note on enforceability (informational, not legal advice)

Condition 6 (NonCommercial) and condition 5 (naming/UI) are "further restrictions" beyond plain GPLv3. Their strict GPL-compatibility is debatable, but this is irrelevant to us: our intended use complies with all of them anyway. If the project's goals ever change (commercial, or a Hiddify-adjacent brand), get proper legal review before relying on removing these terms.
