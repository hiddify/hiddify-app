# M1 — permissions

- Source: https://m1.material.io/patterns/permissions.html
- Captured: 2026-08-13
- Older Material site; M3 has no equivalent page. Condensed in our own words, not a copy.

## When to ask
- **On first launch** — only for permissions that are critical and obvious.
- **In context** — for everything else, wait until the user starts the feature that needs it.

## Explaining why
- Use onboarding to warn about a permission the user would not expect.
- Explain a non-obvious permission at the moment you ask for it.
- Ask only for what the feature actually needs, nothing extra.
- The request itself should be simple, transparent and understandable: the feature name or a short
  explanation must make the reason clear.

## When the user says no
- Always give feedback on a denial — never fail silently.
- For a critical permission, explain why it has to be allowed and offer a button that opens
  Settings.
- When the denial only blocks one feature, say the permission is needed and give a way to grant it,
  for example in a snackbar.
