# Final review fix report

## Scope

Implemented the final dark-theme review fixes from HEAD `b87bce11` without editing translation JSON, generated localization files, Matrix/loading work, onboarding work, iOS assets, or other unrelated dirty files.

## TDD evidence

RED was observed before production edits:

- `NovaRitualHero` did not accept `statusLabel` or `callToActionLabel`.
- Production tertiary text measured `3.992:1` against `NovaColors.voidBackground`, below the required `4.5:1`.
- High-contrast dock border remained `1.0` logical pixel and inactive items still used tertiary text.
- Production Home and dock source tests found hard-coded Russian copy.
- License link spans rendered with hard-coded blue instead of the inherited primary color.
- The profile-site action did not expose inherited semantic icon, hover, and focus colors.

GREEN verification:

- Focused regression suite: `21/21` passed.
- Scoped Flutter analyzer: `No issues found` across 12 implementation/test files.
- Full Flutter suite: `84/84` passed.
- `git diff --check`: clean.

## Implemented fixes

- Dock labels now come from the active `translationsProvider`; English provider/widget coverage verifies all four visible labels and semantic labels.
- Home server, subscription, stats, and ritual strings now use existing translations. `NovaRitualHero` receives localized status and call-to-action strings from Home.
- Ritual errors now use `Theme.of(context).colorScheme.error`.
- Production tertiary text is `#98989F`, giving at least `4.5:1` contrast against root, grouped, surface, and elevated production backgrounds.
- High-contrast dock mode promotes inactive items to semantic secondary text and uses a `1.5` pixel semantic separator border.
- Chain license links use inherited `colorScheme.primary` and `NovaThemeData.accentHover` on focus.
- Profile subscription/site affordances use inherited primary, accent-fill hover, and accent-hover focus colors; link launch behavior is unchanged.

## Existing localization keys used

- `pages.home.title`
- `pages.proxies.title`
- `pages.settings.routing.title`
- `pages.settings.title`
- `pages.profiles.add`
- `pages.profiles.title`
- `components.subscriptionInfo.expireDate`
- `components.stats.downlink`
- `components.stats.uplink`
- `components.stats.totalTransferred`
- `pages.proxies.testDelay`
- `connection.connected`
- `connection.connecting`
- `connection.tapToConnect`
- `errors.connection.connectionError`

## Concerns

- No translation source or generated-localization files were changed. The current English wording therefore follows existing product vocabulary (`Proxies` and `Routing`) rather than introducing new `Servers` or ritual-specific copy.
- No distinct existing localized welcome key is available, so the connected call-to-action is omitted instead of duplicating `connection.connected`.

## Follow-up polish

- Removed the connected call-to-action from the Home adapter because using `connection.connected` for both status and call-to-action duplicated the same visible label.
- Kept `NovaRitualHero.callToActionLabel` optional so a distinct localized call-to-action can be supplied later without restoring hard-coded copy.
- RED: the production wiring regression found `callToActionLabel: isConnected ? t.connection.connected : null`.
- GREEN: focused Home/ritual tests passed `9/9`; scoped analyzer reported no issues; the full Flutter suite passed `84/84`.

## Simulator follow-up

- A fresh disconnected simulator capture showed `Tap to connect` twice: once in `NovaConnectionControl` and once in the ritual status below it.
- Home now passes neither ritual status nor ritual call-to-action for any connection state until distinct localized explanatory copy exists.
- `NovaRitualHero.statusLabel` and `callToActionLabel` remain optional for future localized product copy and focused component states.
- RED: the widget contract failed because `statusLabel` was required, and the production source contract found two `t.connection.tapToConnect` references across Home and ConnectionButton.
- GREEN: focused Home/ritual tests passed `9/9`; scoped analyzer reported no issues; the full Flutter suite passed `84/84`.

## Error-state follow-up

- Restored a ritual status only for `NovaRitualState.error`; connected, connecting, and disconnected continue to omit ritual copy.
- The error uses existing `errors.connection.connectionError` and the already-tested semantic `colorScheme.error` treatment.
- RED: the production source contract found no error-only `statusLabel` wiring.
- GREEN: focused Home/ritual tests passed `9/9` and scoped analyzer reported no issues. The immediately preceding universal-copy commit passed the full suite `84/84`; this follow-up only restores the covered error label wiring.
