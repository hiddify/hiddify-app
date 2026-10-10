# M1 — errors

- Source: https://m1.material.io/patterns/errors.html
- Captured: 2026-08-13
- Older Material site; M3 has no page on error wording. Condensed in our own words, not a copy.

## Three kinds of error
1. **User input** — something is wrong with what the user typed or chose.
2. **App** — the app or the system failed on its own.
3. **Incompatible state** — the action clashes with a device setting or a missing permission.

## What every error message must do
- Say clearly what is happening.
- Say how the user can fix it.
- Keep as much of what the user typed as possible.

## Tone
Never imply the fault is the user's — this matters most for incompatible-state errors. Explain what
caused the error and where it came from, without assigning blame.

## Retry
Offer "Try again" only when a retry can work. If the app can already tell the operation will fail,
do not offer it. A retry in a snackbar fits a temporary connection problem, where the failure is not
permanent.

## Form fields
- Show the error only after the user has interacted with the field; helper text can turn into error
  text.
- Disable the submit button only when inline validation has already found an error.
- With several errors, gather them at the top of the form and scroll there on submit.
- Error text needs strong contrast against the background.

## Offline and connection
- Keep the rest of the app usable.
- Mark the offline state with a quiet, persistent indicator.
- Offer a way forward instead of a dead end, and separate "temporarily disconnected" from
  "this feature needs to be online".

## Where to put the message
- **Alert dialog** — a critical error that blocks the operation.
- **Snackbar** — a peripheral error that does not block, and incompatible states (with an indicator).
- **Inline text under the field** — a problem with that field.
- A disabled control with explanatory text can carry the message instead of a new component.
