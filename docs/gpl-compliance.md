# Hiddify license compliance gate

Reviewed: 2026-07-13  
Source: [`LICENSE.md`](../LICENSE.md) from `hiddify/hiddify-app` `main`.

This note is a project compliance checklist, not legal advice.

## Additional terms in plain language

- The complete source must stay public on GitHub as a visible fork of `hiddify/hiddify-app` and must match every published app release.
- Every published release must be produced through GitHub Actions.
- The README must credit Hiddify, link to the upstream repository and original license, and document our changes.
- Malware is prohibited.
- An app-store release must use a name and interface that are clearly different from Hiddify. `Woman in Red` is a distinct name, but the rebrand must also make the interface distinct before distribution.
- Commercial use, including sales or advertising, requires prior written consent from Hiddify.
- Modifications must remain open source under the same Hiddify Extended GPLv3 terms.
- Normal GPLv3 source, license, modification-notice, and corresponding-source obligations also apply when distributing binaries, including TestFlight builds.

## Verdict for this project

**Conditional GO** for the current compile gate and a non-commercial TestFlight prototype, provided that the repository remains a public GitHub fork, TestFlight artifacts are built through GitHub Actions, attribution and change notices are present, and the rebranded UI is clearly distinct.

**NO-GO without prior written consent from Hiddify** for a paid, advertised, otherwise commercial VPN product. **NO-GO** for a closed-source/private-fork distribution model.

The unmodified local iOS build in the current plan is permitted by GPLv3's basic permission to run the program and does not itself publish a release.

## Release checklist

- [ ] Confirm the intended product is non-commercial, or archive Hiddify's written commercial-use consent.
- [ ] Keep `maikrais98/hiddify-app` public and visibly forked from upstream.
- [ ] Build every distributed release with GitHub Actions.
- [ ] Publish source corresponding exactly to each distributed build.
- [ ] Preserve `LICENSE.md` and add Hiddify attribution plus a dated change log to the README.
- [ ] Verify the final name and interface are clearly distinct from Hiddify.
- [ ] Keep all modifications under the same license terms.
