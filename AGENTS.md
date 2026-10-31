# Agent guide: pull requests in hiddify-app

PRs go to `hiddify/hiddify-app`, base `main`, from a branch pushed to the fork 
Never open a PR inside the fork.

## Before opening
- One feature or fix per PR. Split unrelated changes into separate branches first.
- Branch from the latest `upstream/main` and rebase right before pushing:
  `git fetch upstream && git rebase upstream/main`.
  `git log --oneline upstream/main..HEAD` must list only this change's commits.
- Commits follow Conventional Commits: `type(scope): summary`, e.g. `fix(core): …`, `feat(settings): …`.
- **Never hide a hiddify-core or hiddify-sing-box bug in the app.** No retries, delays, extra `if`s,
  swallowed errors, state guessing, or other workarounds that make a core failure invisible. If the root
  cause is in the core, say so in the PR (with logs and steps to reproduce), fix it in that repo or open an
  issue there, and link it. The app may only add handling that is correct regardless of the bug (e.g. showing
  the error clearly), never logic that papers over it.
- Never commit generated files (`*.g.dart`, `*.freezed.dart`, generated translations), core libs, the
  `hiddify-core` submodule pointer, build output, recorded videos, keys, or real profile links, IPs or tokens.
- Verified on Android and on a desktop platform. For UI changes, record before/after videos (see below).

## Short description (the PR title)
- Conventional Commit style, under 70 characters, imperative, saying what the user gets:
  `fix(home): keep the connect button disabled until the core has stopped`.
- Scope is the area touched: `home`, `settings`, `profile`, `proxy`, `core`, `android`, `linux`, `windows`,
  `macos`, `ios`, `build`, `ci`, …

## Full description (the PR body)
Keep it short and complete. Write nothing the reviewer doesn't need.

```markdown
## Problem
<1–3 sentences on what was wrong or missing, as the user sees it. For bugs, the root cause in one line.>

## Change
- <one bullet per logical change, naming the main file(s)>

## Videos (before | after)
| | English | فارسی |
|---|---|---|
| Mobile light | ![](<m-light-en.webp>) | ![](<m-light-fa.webp>) |
| Mobile dark | ![](<m-dark-en.webp>) | ![](<m-dark-fa.webp>) |
| Desktop light | ![](<d-light-en.webp>) | ![](<d-light-fa.webp>) |
| Desktop dark | ![](<d-dark-en.webp>) | ![](<d-dark-fa.webp>) |

## Tested
- <what was verified, on which platform (Android emulator/device, Linux, Windows, macOS, iOS)>

## Review
- **Confidence:** High (>90%) | Needs review — <one line why>
- **Complexity:** Simple | Complex — <one line why>
```

- Leave out **Videos** for changes with no UI effect. For UI changes the section is required, with all
  8 views: mobile and desktop × light and dark × English and Persian. Each animated webp shows before | after
  side by side, both starting at the same moment, with the shorter one holding its last frame.
- Store the videos on the orphan branch e.g., `screenshots` of the repo you push to (created once with
  `git switch --orphan screenshots`), one folder per PR branch, and link their raw URLs in the table:
  ```bash
  wt=$(mktemp -d)
  git fetch origin screenshots 2>/dev/null
  git worktree add $wt origin/screenshots 2>/dev/null || { git worktree add --detach $wt && git -C $wt switch --orphan screenshots; }
  mkdir -p $wt/<branch-slug> && cp <video dir>/*.webp $wt/<branch-slug>/
  git -C $wt add <branch-slug> && git -C $wt commit -m "videos: <branch-slug>" && git -C $wt push origin HEAD:screenshots
  git worktree remove $wt
  # https://raw.githubusercontent.com/<owner>/hiddify-app/screenshots/<branch-slug>/<view>.webp
  ```
- **Confidence High** only when the root cause is understood, the change is local, it was verified on
  several platforms, and there is no data or migration risk. Otherwise **Needs review**, saying what to look at.
- **Complexity Simple**: small, one area, no native code, migration, or API change. **Complex**: several areas,
  native code, connection/core logic, DB migrations, or security-relevant code.
- If the change spans repos (e.g. hiddify-core), link the related PR.

## Opening
```bash
git push -u origin <branch>
gh pr create --repo hiddify/hiddify-app --base main --head <repo>:<branch> \
  --title "<short description>" --body-file <body.md>
```
