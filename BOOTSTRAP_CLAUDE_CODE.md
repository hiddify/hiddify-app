# BOOTSTRAP: VPN-клиент «Woman in Red» на базе форка Karing — v0.1

> Куда вставлять: в Claude Code, запущенный в директории проекта.
> Источник истины по выбору: `docs/sources/VPN_OSS_Research.md` (уже в папке).
> Роли: этот промт — execution-контракт для Claude Code. Planning ведётся в Cowork.
> Задача проекта: форкнуть Karing → обернуть брендом «Woman in Red» → подключить подписку Remnawave → собрать под iOS → раздать 20–30 своим через TestFlight. Без монетизации, без публичного стора обязательно.

---

## ЗНАЧЕНИЯ ПРОЕКТА

- **Имя приложения:** `Woman in Red`
- **Bundle id:** приложение = `com.womaninred.app`, Network Extension = `com.womaninred.app.ne`, Android `applicationId` = `com.womaninred`
- **Форк (origin):** `https://github.com/maikrais98/karing`
- **Upstream:** `https://github.com/KaringX/karing`
- **Тестовая Remnawave-подписка:** ⚠️ содержит токен — НЕ вписана сюда и НЕ коммитится. Пользователь вставит ссылку напрямую в чат на этапе 4 (Phase 4). В коде боевые/тестовые URL не хранятся.

Пред-условия (уже сделано пользователем): форк создан на GitHub, Actions включить в форке если ещё нет (GPL-3.0 требует публичный GitHub-форк и релизы через Actions).

---

## Контекст и окружение

- Текущая директория уже содержит git-репозиторий и два research-файла: `VPN_OSS_Research.md`, `VPN_App_Research_and_Design_System.docx`. Их НЕ теряем — переносим в `docs/sources/`.
- **Разделение машин (важно):** папка на Windows (`F:\`). Весь код/ребренд/Remnawave/docs делаем здесь. **iOS-сборка/подпись/TestFlight выполняются на Mac** (у пользователя есть macOS + Xcode + Apple Developer). CC под Windows НЕ собирает iOS — только готовит код и пишет чек-лист. Android-сборку можно проверить здесь для sanity.
- Ядро: Karing = Flutter (Dart) поверх форка sing-box. Поддерживает VLESS+Reality+Hysteria2+TUIC. Совместим с Remnawave (подписка отдаётся в sing-box формате автоматически по User-Agent клиента).

## Инварианты проекта (не нарушать)

- GPL-3.0: НЕ удалять LICENSE, сохранить атрибуцию Karing в README, документировать изменения, форк — публичный.
- Никаких секретов в коде/коммитах: subscription-URL (в т.ч. тестовый — содержит токен), ключи серверов, приватные конфиги Remnawave — только runtime-ввод/подписка, не в git.
- Никакой телеметрии/малвари поверх апстрима (нарушает и GPL, и ревью сторов).
- Ребренд держим **изолированным** в отдельных файлах (иконки/тема/строки/bundle id), минимум правок в «ядровых» файлах Karing — чтобы легко подтягивать upstream через rebase.
- Network Extension entitlement у Apple подаётся РАНО — без него VPN в TestFlight-сборке не заработает.
- Ветки: `upstream/main` (чистый Karing, только pull), `brand/main` (наши изменения). Cherry-pick/rebase наших патчей на upstream, не merge.

---

## Phase 1 — READ & VERIFY (СТОП)

1. Прочитай этот промт целиком.
2. Прочитай `VPN_OSS_Research.md` (обоснование выбора Karing, роадмап этапов 1–10) и извлеки из `.docx` дизайн-систему (палитра, one-button UX, экраны) — понадобится на этапе 3. Палитра бренда «Woman in Red» — красный акцент; сверься с design-system перед фиксацией токенов.
3. Открой форк `https://github.com/maikrais98/karing`: прочитай `README`, `LICENSE`, `CONTRIBUTING`, инструкции сборки, зафиксируй требуемые версии Flutter/Dart/Go/Xcode (из `.tool-versions`/README/CI). НЕ бери «последние» — бери те, что указал апстрим.
4. Выдай план Phase 2–7 по подзадачам с оценкой времени и списком версий тулчейна.

СТОП. Жди «ок, фаза 2».

## Phase 2 — SETUP (сначала собери апстрим КАК ЕСТЬ)

1. Склонируй `https://github.com/maikrais98/karing` в текущую директорию (сохранив research-файлы — перенеси их в `docs/sources/` после клона).
2. Настрой remotes: `origin` = `github.com/maikrais98/karing`, `upstream` = `github.com/KaringX/karing`. Создай ветки `upstream/main` и рабочую `brand/main`.
3. Установи тулчейн нужных версий (Flutter/Dart/Go по Phase 1).
4. **Собери немодифицированный Karing** (Android debug-сборка под Windows ОК как sanity; iOS-сборку — отметь как задачу для Mac). Цель — убедиться, что апстрим компилируется ДО любых правок. Если не собирается — СТОП, эскалируй.

СТОП перед этапом 3. Покажи, что апстрим собрался.

## Phase 3 — REBRAND в «Woman in Red» (изолированно)

Меняем, держа правки в выделенных файлах:

1. **Имя приложения** → `Woman in Red`: `pubspec.yaml`, iOS `Info.plist` (`CFBundleDisplayName`), Android `strings.xml`/`AndroidManifest`, локализации.
2. **Bundle/Application id**: iOS `com.womaninred.app`, Network Extension target `com.womaninred.app.ne`, Android `applicationId com.womaninred`. Меняй **везде** — включая entitlements, App Groups, NE target, keychain access groups.
3. **Иконки**: сгенерь набор размеров iOS/Android из иконки бренда (App Icon генератор), замени `Assets.xcassets`/`mipmap`.
4. **Тема/цвета**: примени палитру «Woman in Red» (красный акцент) из design-system (`docs/sources/*.docx`) в theme-файле Flutter. Не переписывай виджеты — только токены/тему.
5. **Убрать/переориентировать Karing-специфику**: iCloud/WebDAV-синхронизацию — отключить или заменить нейтральной. Ссылки на karing.app, донаты, telemetry-эндпоинты — убрать/заменить.
6. **grep-проверка**: поиск остаточных `karing`, `com.nebula.karing`, оригинальных bundle id, доменов апстрима. 0 совпадений вне LICENSE/атрибуции/`docs/sources/`.

## Phase 4 — REMNAWAVE WIRING

1. Изучи, как Karing импортирует подписку (URL → sing-box JSON). Remnawave отдаёт корректный формат по User-Agent.
2. Настрой дефолтный онбординг: экран ввода/вставки subscription-ссылки (или QR). Боевые/тестовые URL НЕ вшивать в код.
3. **Пользователь вставит тестовую subscription-ссылку прямо в чат на этом этапе.** Проверь импортом: подписка парсится, серверы появляются, VLESS+Reality-конфиг валиден. Зафиксируй формат в `docs/remnawave-integration.md`. Тестовый URL в git НЕ сохранять. Если формат расходится — опиши расхождение и предложи конвертер, НЕ костыль в ядре.

## Phase 5 — DOCS (лёгкий процессный слой)

Создай:
- `docs/README.md` — индекс.
- `docs/01-overview.md` — что за проект, архитектура (Flutter+sing-box), поток Remnawave.
- `docs/decisions/` — ADR-001 (база = Karing; альтернативы: Hiddify отклонён — лицензия запрещает ребренд/публикацию в сторах под своим именем; OneXray — учебный), ADR-002 (Remnawave wiring), ADR-003 (изоляция ребренда для rebase), ADR-004 (build/release: Windows=код/Android, Mac=iOS/TestFlight, релизы через GitHub Actions per GPL), ADR-005 (multi-agent контракт Cowork+CC). + `ADR-TEMPLATE.md`.
- `docs/rebrand-isolation.md` — список файлов, где живёт ребренд «Woman in Red» (для будущих upstream-rebase).
- `docs/remnawave-integration.md` — формат подписки, User-Agent, troubleshooting.
- `docs/ios-release-checklist.md` — пошагово для Mac (см. Handoff ниже).
- `docs/gpl-compliance.md` — атрибуция, ссылка на upstream, список изменений, публичность форка.
- `docs/tasks/` (TEMPLATE.md + archive/), `docs/journal/log.md` (append-only).

## Phase 6 — VERIFY (СТОП перед коммитом)

1. `flutter analyze` — 0 errors в затронутых файлах.
2. Android debug-сборка собирается (sanity под Windows).
3. grep остаточного бренда/bundle id — чисто (Phase 3.6).
4. GPL-комплаенс: LICENSE на месте, атрибуция в README, `docs/gpl-compliance.md` заполнен.
5. Нет вшитых секретов/URL подписок (grep по `sub`, `token`, `sevensense`, доменам).
6. Покажи `git status` + `git diff --stat`.

СТОП. Жди подтверждения.

## Phase 7 — COMMIT & PUSH

```
git add -A
git commit -m "feat(brand): initial Woman in Red rebrand of Karing + Remnawave wiring

Fork of KaringX/karing (GPL-3.0). See docs/gpl-compliance.md.
agent: claude-code"
git push -u origin brand/main
```

---

## HANDOFF на Mac (ручные шаги, CC документирует — не выполняет)

Порядок (детали — в `docs/ios-release-checklist.md`):
1. **Сразу:** в Apple Developer подать заявку на Network Extension entitlement (одобрение занимает время — не откладывать).
2. `git pull` форка на Mac, `flutter build ios`.
3. Xcode: App ID `com.womaninred.app` + `com.womaninred.app.ne`, App Group, Provisioning Profiles, Packet Tunnel Provider entitlement.
4. Собрать Release, проверить на реальном устройстве (не симуляторе — VPN/NE симулятор не эмулирует корректно).
5. Загрузить в App Store Connect → TestFlight → внутреннее тестирование → пригласить 20–30 своих.
6. Privacy Policy обязательна даже для TestFlight VPN — подготовить честный текст (политика логирования).

## Acceptance criteria
- [ ] Апстрим Karing собрался ДО правок (Phase 2)
- [ ] Ребренд «Woman in Red» изолирован, grep чист от `karing`/`com.nebula.karing`
- [ ] Тестовая подписка импортируется, серверы работают; URL не в git
- [ ] docs/ + ADR-001..005 на месте, GPL-атрибуция оформлена
- [ ] Нет секретов/URL подписок в git
- [ ] `docs/ios-release-checklist.md` готов для выполнения на Mac

## НЕ ТРОГАТЬ
- LICENSE и GPL-атрибуцию Karing
- Subscription-URL (тестовый и боевые), ключи серверов, приватные данные Remnawave
- Ядровые файлы sing-box без необходимости (ломает rebase)
- Скрытые директории вне проекта (`~/`, системные пути)
