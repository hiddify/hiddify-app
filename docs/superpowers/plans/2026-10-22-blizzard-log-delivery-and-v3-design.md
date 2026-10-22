# Blizzard: log delivery and v3 design — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Получить проверяемую доставку диагностики с iPhone и привести интерфейс следующего релиза к актуальным макетам Blizzard v3.

**Architecture:** Два независимых направления — диагностика доставки и визуальное соответствие — сходятся в одном кандидате релиза. Сначала воспроизводим конкретный отказ, затем пишем RED-тест и минимальную правку; выпуск разрешается только после отдельных доказательств тестов, визуальной приёмки и готовности TestFlight. Получение события с установленной сборки подтверждается отдельно после установки на телефон.

**Tech Stack:** Flutter 3.38.5, Dart, Riverpod, UIKit, iOS Simulator/Xcode, Better Stack HTTP ingest/Logs, существующий GitHub release controller, Pencil MCP.

## Global Constraints

- Этот запрос — план расследования и исправлений. При подготовке плана не менять приложение, секреты, лимиты сервиса, signing readiness и TestFlight.
- Сохранить все текущие незакоммиченные исправления. Не откатывать рабочую папку к HEAD и не переносить исторические тестовые результаты на новый код.
- Приложение: `/Users/stasyudkin/Documents/KVN/blizzard-delivery-v3`, base HEAD `f485e7b2671f94256da3b13714ff0501594a11c7`.
- Отдельный controller: `/Users/stasyudkin/Documents/KVN/blizzard-build20-controller`. Историю исходников приложения не сливать в controller/main.
- Нужные проверки поведения пишутся до новых изменений: RED → минимальная правка → GREEN.
- Не менять VPN core, маршруты, идентичность приложения, выбор сервера или системное согласие VPN ради диагностики/дизайна.
- Не читать и не выводить значения токенов, DSN, Authorization, содержимое приватного defines-файла, профили или подписочные URL. Проверки конфигурации возвращают только закрытые результаты.
- Не создавать новые Sources/Applications/tester groups и не подключать платные сервисы без необходимости.
- Предлагаемый локальный бюджет — 256 КиБ на установку за UTC-сутки, включая неудачные попытки; старый счётчик не обнулять. Exceptions оставить ≤1/сутки и ≤10/месяц на установку.
- Для 10 установок: максимум 75 МиБ тел запросов за 30 дней, 77,5 МиБ за 31 день. Это не подтверждение общей бесплатной квоты аккаунта: отдельно учитываются другие источники и учёт Better Stack.
- Отправитель остаётся ограниченным: outbox 100 событий /64 КиБ /24 часа; без бесконечных повторов и обхода бюджета ручным тестом.
- Последний подтверждённый ping сохраняется при сворачивании; после возврата — «Обновление…» до свежего результата. Не менять это поведение при визуальном переносе.

## 1. Подтверждённое состояние и открытые вопросы

| Факт | Что он доказывает / чего не доказывает |
| --- | --- |
| Source 2805644 `WIR Baseline` сейчас Active, HTTP, us-west-2a | Источник существует и не помечен paused; это не проверка токена установленного IPA |
| Последняя сохранённая проверка: 99 событий build 20, последнее 22 октября 13:05:42 МСК; build 22 не найден | Доступ к чтению есть; историческое окно не заменяет новый контрольный поиск |
| На телефоне в 19:47: build 22, budgetLimited, 100 событий, 74880 использованных байт, 0 осталось | Текущий локальный запрет отправки доказан; причина первых сетевых отказов неизвестна |
| Ранний бюджет был 256 КиБ, новый 64 КиБ, preference key общий | 74880 совместимо с унаследованным расходом; не доказано превышение лимита самой сборкой 22 |
| Pending-статус мог скрывать retry/budget blocker; локальная правка уже готова | Не повторять выполненную правку; её тесты не доказывают приём в облаке |
| Sentry и Logs связаны политикой сборки и порядком init | Проверить эту зависимость; не объявлять её причиной текущего сбоя, поскольку sender на телефоне уже инициализировался |
| HTTP attempt/result не сохраняются в outbox; таймер не заводится при дневной блокировке/исчерпании retries | Есть пробелы наблюдаемости и автоматического возобновления, которые надо воспроизвести отдельными тестами |
| Локально уже исправлены меню, метель, стекло, power icon; есть 800 PASS /4 host-only skips | Это предыдущий локальный результат; полный лог и receipt надо связать с финальным кандидатом |
| Capture harness падает при завершении на SemanticsHandle; полный v3 verdict NOT_APPROVED | Скриншоты существуют, но этот job нельзя считать GREEN |

Текущие доказательства: `docs/verification/blizzard/post22-review.md`, `visual-acceptance-contract.md`; артефакты: `/Users/stasyudkin/Documents/KVN/review-evidence/2026-10-22/blizzard-post22/`.

## 2. Карта файлов и ответственность

| Область | Файлы |
| --- | --- |
| Включение/настройки | `lib/core/model/environment.dart`, `lib/bootstrap.dart`, `lib/core/analytics/analytics_controller.dart`, `lib/features/common/general_pref_tiles.dart` |
| Бюджет/HTTP/очередь | `lib/core/observability/telemetry_budget.dart`, `better_stack_log_printer.dart`, `telemetry_delivery_status.dart` |
| Карточка и безопасный отчёт | `lib/features/diagnostics/safe_diagnostics_page.dart`, `safe_diagnostic_journal.dart`, `telemetry_delivery_labels.dart`, `remote_ios_ping_subscription.dart` |
| Тесты отправки | `test/core/observability/telemetry_budget_test.dart`, `better_stack_outbox_test.dart`, `telemetry_delivery_status_test.dart`; существующие analytics/diagnostics tests |
| Build configuration — controller | `scripts/prepare_telemetry.py`, `scripts/setup_betterstack.py`, `.github/workflows/ios-baseline.yml`, `test/ci/test_betterstack_setup.py` |
| Главная/карточки | `lib/features/home/widget/{home_page,connection_button}.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart` |
| Списки/настройки | `lib/features/proxy/{overview/proxies_overview_page,widget/proxy_tile}.dart`, `lib/features/settings/overview/settings_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| Шторки/диалоги | `lib/features/profile/{overview/profiles_modal,add/add_profile_modal}.dart`, `lib/core/router/bottom_sheets/widgets/quick_settings_modal.dart`, `lib/core/router/dialog/widgets/sort_profiles_dialog.dart` |
| Материал/движение | `lib/core/widget/blizzard/{blizzard_glass,blizzard_scene}.dart`, `lib/core/theme/blizzard_{tokens,theme}.dart`, `ios/Runner/BlizzardNativeGlass.swift` |
| Проверки дизайна | `test/visual/`, `test/ui_preservation/`, `test/support/home_fixture.dart`, `integration_test/blizzard_home_control_polish_test.dart` |
| Новые воспроизводимые проверки | `integration_test/blizzard_visual_acceptance_test.dart`, `scripts/blizzard_visual_acceptance.py`, `test/ci/test_blizzard_visual_acceptance.py` |
| Gate — controller | `scripts/verify_visual_receipt.py`, `test/ci/test_visual_receipt.py`, `release/visual-receipts/<source-sha>.json`, `.github/workflows/ios-baseline.yml` |

Существующие временные drivers в `/private/tmp/blizzard-v3-qa-20261022` — диагностический материал, не окончательный release gate.

## Task A1: Проверить, что действительно подключено и разрешено

**Produces:** таблица `delivery-chain-checks.json` с `PASS/FAIL/BLOCKED`, безопасными reason codes и provenance для build 20, build 22 и нового кандидата.

- [ ] Зафиксировать текущие tracked/untracked изменения, исходный SHA, controller SHA и артефакт сборки 22. Использовать существующий подписанный IPA; build 22 повторно не загружать.
- [ ] Проверить действительный путь сборки: protected `release-signing` → `prepare_telemetry.py --require-remote` → приватный defines-файл → `flutter ... --dart-define-from-file` → выбранный IPA. Не считать наличие секретов в настройках доказательством их попадания в бинарник.
- [ ] В доверенной проверке фиксировать только `beta_enabled`, `logs_endpoint_valid`, `source_token_present`, `configuration_injected`, `expected_source_matches`, `release_ios`, `analytics_enabled`, `logs_sender_initialized`. Не сохранять исходные значения/приватный файл в артефактах.
- [ ] Проверить источник 2805644, нужный аккаунт/team, ingest enabled, регион/назначение, актуальность source token; отдельно — доступ оператора к поиску и фактическую бесплатную квоту аккаунта. Если метрик квоты нет в connector, проверить кабинет; при отсутствии доступа поставить BLOCKED, не выдумывать остаток.
- [ ] Разделить три механизма: Logs ingest, Sentry Errors и GitHub AI SRE. Связь GitHub↔Better Stack сама по себе логи с телефона не отправляет. Не подключать GitHub повторно ради исправления Logs.
- [ ] Проверить сохранённый переключатель аналитики и оба startup-пути. Release iOS создаёт sender только при beta=true, валидном HTTPS endpoint и непустом токене; debug намеренно не отправляет.
- [ ] Проверить Info.plist/ATS, фактическую ошибку HTTPS и подпись entitlement. Не добавлять ATT, Local Network, push или background permissions наугад: обычному внешнему HTTPS не нужен отдельный пользовательский «доступ к интернету». Изменять разрешение/исключение только при конкретном доказанном отказе.
- [ ] Проверить, может ли ошибка Sentry init блокировать создание Logs. Существующее требование DSN/same host проверить против реальной конфигурации; развязывать только при воспроизведённом отказе, с RED-тестом, без ослабления fail-closed checks.

**Проверка controller на синтетических значениях, без настоящих секретов:**

```sh
cd /Users/stasyudkin/Documents/KVN/blizzard-build20-controller
python3 -m unittest discover -s test/ci -p 'test_betterstack_setup.py'
```

Ожидается PASS. Дополнить тестами отсутствующего значения, неверного endpoint/источника и гарантии, что ошибка не содержит credentials. Не запускать `setup_betterstack.py --apply` как средство диагностики.

## Task A2: Одним контрольным событием отделить приёмник от приложения

**Produces:** receipt `event_id → HTTP outcome → найденная запись`, без профилей/сырого payload.

- [ ] Выполнить один ограниченный smoke POST из доверенного окружения с той же парой endpoint/source token, которая используется при сборке. Тело — только тестовый marker, уникальный event_id, UTC, версия/build и source provenance. Не печатать credential и тело ответа.
- [ ] При неопределённом исходе сначала искать тот же event_id, а не слать новые события. Автоматические повторения smoke probe не включать.
- [ ] Искать событие в source 2805644 с учётом hot/historical данных и индексации; возвращать только event_id, время, build и факт совпадения источника. Не читать raw частные журналы.
- [ ] Интерпретировать результат по таблице ниже. Успешный probe сервера не заменяет тест с iPhone.

| Результат | Следующее действие |
| --- | --- |
| Запрос не начат | Проверить config/opt-out/storage/budget gate; сеть пока не обвинять |
| 401/403 | Проверить принадлежность/актуальность ingestion credential; исправить только доказанную конфигурационную ошибку |
| 402 | Проверить состояние тарифа/приёма; не переходить на платный план автоматически |
| 429 | Проверить rate/quota и Retry-After; ограничить интенсивность |
| 408/5xx/timeout/network/TLS | Сохранить закрытый тип отказа; проверить соответствующий участок соединения |
| 2xx, запись найдена | Приёмник и эта пара настроек работают; перейти к устройству |
| 2xx, записи нет | Проверить нужный source/team, время, indexing/filter и права чтения; ACK не переименовывать в «найдено в облаке» |

## Task A3: Сделать причину отказа видимой и устойчивой

**Consumes:** результаты A1/A2. **Produces:** локально проверяемый исход конкретного тестового события и восстановление очереди без спина.

- [ ] Сначала добавить RED-сценарии: timeout, SocketException, TLS exception, 401/403/402/429/5xx, success своего/чужого batch, restart после принятого/отклонённого теста, зависшая запись storage, истечение cooldown и UTC-дня без новых событий.
- [ ] Проверить уже готовую правку blocker→pending и сохранить её. Не превращать ручное нажатие в сброс бюджета/retry counter.
- [ ] Для последней попытки сохранять небольшой закрытый record: UTC, test event_id, версия/build, HTTP-код либо `timeout/network/tls/other`, стадия до/после запроса, ACK своего события. Не сохранять тексты исключений, hostname/IP, headers, credentials, payload и постоянный device ID. DNS не объявлять доказанным только по произвольному SocketException.
- [ ] Не ломать строгий restore старого outbox: локальную квитанцию хранить отдельно либо вводить явную совместимую миграцию. Тестами проверить старое/повреждённое состояние, ограниченный размер, отказ записи и отсутствие рекурсивного логирования отправителя.
- [ ] Карточка показывает различие `не включено / ошибка конфигурации / сохранено / очередь / отправляется / пауза / бюджет / storage error / HTTP rejected / HTTP accepted`. Наличие записи в поиске подтверждает оператор отдельной квитанцией.
- [ ] Таймер в foreground действительно возобновляет разрешённую очередь после cooldown/UTC rollover. В background iOS точное время не обещать; при resume сначала проверить бюджет и продолжить ограниченно. Один таймер, без busy loop; UTC rollback не даёт новый бюджет.
- [ ] При 100 старых событиях ручной тест может находиться за несколькими FIFO batch. Показать ожидание своего ACK; сохранить metadata старых событий, не очищать очередь и не подменять её версией нового sender. Не обещать результат за 20 секунд при таком backlog.

**Команда регрессий:**

```sh
cd /Users/stasyudkin/Documents/KVN/blizzard-delivery-v3
/Users/stasyudkin/fvm/versions/3.38.5/bin/flutter test --no-pub test/core/observability/telemetry_budget_test.dart test/core/observability/better_stack_outbox_test.dart test/core/observability/telemetry_delivery_status_test.dart --reporter expanded
```

Критерий: сначала зафиксирован ожидаемый RED, затем GREEN; по каждому исходу известно, был ли HTTP, что именно принято и что сохранилось после restart.

## Task A4: Бюджет 256 КиБ и экономика диагностики

**Files:** `telemetry_budget.dart`, `telemetry_budget_test.dart`, связанные тесты и текст карточки.

- [ ] Ввести новый тест до изменения default. Самостоятельный тест внутри `main()` существующего набора:

```dart
test('256 KiB default preserves inherited usage and enforces the new boundary', () async {
  String? stored = jsonEncode({
    'day': '2026-10-22', 'log_bytes': 74880, 'exceptions': 0,
    'month': '2026-10', 'monthly_exceptions': 0,
  });
  final client = TelemetryBudget(
    read: () => stored,
    write: (value) async { stored = value; return true; },
    now: () => DateTime.utc(2026, 10, 22, 17),
  );
  expect(client.maxLogBytes, 256 * 1024);
  expect(client.logSnapshot.usedLogBytes, 74880);
  expect(client.logSnapshot.remainingLogBytes, 187264);
  expect((await client.reserveLogs(187264)).outcome, TelemetryBudgetReserveOutcome.reserved);
  expect((await client.reserveLogs(1)).outcome, TelemetryBudgetReserveOutcome.limitExceeded);
});
```

- [ ] Зафиксировать RED с текущими 64 КиБ. Существующий default-cap contract обновить под новое согласованное значение; не удалять проверки исключений/clock rollback/миграции/повторов.
- [ ] Минимальная production-правка конструктора:

```dart
this.maxLogBytes = 256 * 1024,
```

- [ ] Получить GREEN, проверить точный UTF-8 размер FIFO batch, повторное списание при retry, upgrade без обнуления, независимый exception cap.
- [ ] Отдельный обязательный RED: восстановить outbox с `budget_blocked_day=today` и бюджетом 74880 байт, затем запустить sender с лимитом 256 КиБ. Сейчас сохранённый маркер способен запретить HTTP, несмотря на 187264 свободных байта. При upgrade пересчитать актуальную допустимость следующего FIFO batch; снять устаревший budget-only blocker лишь при достаточном остатке. Счётчик расхода, retry/storage blockers и порядок очереди сохраняются. Парный тест с недостаточным остатком должен по-прежнему запрещать запрос. Проверить тот же путь без перезапуска sender после смены UTC-дня.
- [ ] Измерить, сколько событий дают один connect, lock/unlock, открытие меню и измерение ping. Устранять подтверждённые дубли/избыточные повторы и агрегировать штатные измерения; важные failure/lifecycle transitions не терять. Сам sender не пишет ошибки через себя.
- [ ] Сопоставить худший расход до 10 установок с фактической бесплатной квотой. Не повышать дневной лимит выше 256 КиБ как замену этому расчёту.

## Task B1: Закрепить именно актуальный v3 и список отличий

**Consumes:** существующие локальные исправления. **Produces:** versioned design/source manifest и честный coverage checklist.

- [ ] Читать `.pen` только через Pencil MCP. Зафиксировать файл `12d0964c-5822-4806-bfe2-7ef00579dcd9/pencil-welcome-desktop.pen`, ID, размеры, масштаб и хеши актуальных экспортов; дизайн не перерисовывать под реализацию.
- [ ] Обязательные основные references: Home `QjgLs`, Settings `cIxE0`, Servers `X8cuDi`/`b0gIl`, Profiles `zqAyO`, Add Profile `zgf7h`, Quick Settings `DNnfr` и соответствующие состояния из `v3-transfer-map.md`.
- [ ] Для всех 89 сопоставленных состояний указать `PASS/FAIL/BLOCKED/DESIGN_ONLY` и доказательство. Сопоставление ID не считается PASS. Login/cabinet без реализации не добавлять в этот релиз.
- [ ] Закрыть конкретные остатки: profile/server card presentation, status/latency copy, icon treatment и разделители Settings, открытые шторки/списки, контраст и блики материалов. Не удалять import/export/reset/update/выбор профиля ради сходства.
- [ ] Для каждого материала проверить контракт макета: native clear у кнопки, regular у dock; остальные поверхности не делать одинаково стеклянными наугад. Их внешний вид сверять с соответствующим v3 reference.

## Task B2: Реалистичные состояния и исправление capture harness

**Files:** `test/support/home_fixture.dart`, новый `integration_test/blizzard_visual_acceptance_test.dart`, существующие визуальные/семантические tests.

- [ ] Создать детерминированные test data, совпадающие с состоянием макета: Finland/VLESS/84ms/Akonit Premium — исключительно synthetic. Отдельные fixtures: неизвестный ping, timeout, offline, empty/loading/error, длинное имя, истёкшая подписка/квота. Нельзя маскировать реальную ошибку latency как «подключение».
- [ ] Сначала воспроизвести `A SemanticsHandle was active at the end of the test` коротким source-controlled тестом без долгих capture-пауз. Записать безопасные counts `platformDispatcher.semanticsEnabled`, binding/pipeline outstanding handles до/после mount и close.
- [ ] Если подтверждается platform binding 0→1, использовать существующий паттерн blank-app prewarm в `setUpAll` до baseline leak snapshot (`docs/verification/blizzard/home-snowfall.md:49`). Если растёт pipeline count — найти его владельца, а не применять platform workaround.
- [ ] Все собственные handles закрыть; normal leak verification оставить включённой. Не выключать semantics, assertions, FlutterError и не менять production accessibility ради теста.
- [ ] Получить три последовательных GREEN cold-launch прогона с полной очисткой fixture, затем запускать полную съёмку. Случайно зелёный повтор не закрывает race.

## Task B3: Довести визуальные отличия и снять доказательства

- [ ] Каждое изменение компонента начинать с RED: renderer geometry/pixel/semantics test либо воспроизводимый native screenshot failure. Затем минимальная правка и GREEN; guard state/action bindings сохраняется.
- [ ] Снять 393×852 для прямого сравнения с макетом и отдельно responsive 402×874, compact 320pt, крупный текст, длинные названия, Reduce Motion/Reduce Transparency. Записывать реальную геометрию, а не растягивать кадр для сокрытия отличий.
- [ ] Native glass снимать системным compositor. Flutter RepaintBoundary годится для Flutter-контрактов, но не для утверждения об оптике UIKit. Проверить передачу контрастного moving backdrop и реального фона приложения.
- [ ] Записать отдельное непрерывное видео Home: ≥16 секунд actual foreground animation от зафиксированной начальной фазы, включая границу 12-секундного цикла; проверить движение через ~600ms и loop seam. Сворачивание/возврат и переход на Settings/обратно снять отдельной записью: время остановленной анимации не засчитывается в полный цикл. Не считать видео со frozen test clock доказательством анимации.
- [ ] Проверить Home, Servers с выбранным/длинным сервером и тестом задержки, Profiles/Add/Quick Settings sheets, Sort Profiles, Settings/General и вложенные списки. Соответствующие loading/empty/error/timeout states связывать с coverage manifest, а не переносить PASS между состояниями без проверки.
- [ ] Сравнить рядом и наложением по регионам: header, status/ping, control, wave, server/profile, dock, группы Settings, открытые sheets. Допуски для шрифтов/native материалов задавать по региону; единого процента на весь экран недостаточно.
- [ ] Родитель сама открывает и просматривает финальные PNG и кадры видео. Не менять baseline ради зелёного diff. Для каждого расхождения — исправление или явно обоснованное адаптивное отличие; неотработанное существенное расхождение оставляет FAIL.

**Регрессии:**

```sh
cd /Users/stasyudkin/Documents/KVN/blizzard-delivery-v3
/Users/stasyudkin/fvm/versions/3.38.5/bin/flutter test --no-pub test/visual test/ui_preservation --reporter expanded
```

Отдельно запустить native `integration_test/blizzard_visual_acceptance_test.dart` и существующий `blizzard_home_control_polish_test.dart` в закреплённом isolated host. Не использовать root-level `flutter test` как доказательство iOS-запуска: проверять target platform и native compile в receipt.

## Task C1: Воспроизводимый gate перед подписанием

**Interfaces:** receipt содержит exact source SHA, runtime tree/content hash, design node/export hashes, fixture/driver hashes, Flutter/Xcode/iOS versions, viewport, state coverage, capture exit code, ссылки/хеши PNG/video, region verdicts и итог `PASS/FAIL/BLOCKED`.

- [ ] Перенести сбор/проверку артефактов из временной папки в `scripts/blizzard_visual_acceptance.py` и source-controlled native driver. Использовать immutable candidate snapshot; symlink на меняющийся dirty checkout для gate не годится.
- [ ] До/после запуска сравнить source/native/fixture manifests. Отсутствующий файл, изменившийся source, ненулевой exit, неполная обязательная coverage, semantics leak или FAIL региона запрещают итоговый PASS.
- [ ] Добавить RED→GREEN tests runner на эти отказы, а также отсутствие/нулевую длительность видео и ошибочный native target. Runtime goldens создавать только из уже просмотренного и принятого результата.
- [ ] Автоматический capture job не выдаёт visual OK. После просмотра сохранить review receipt, связанный с immutable source/design/artifacts. Любая последующая затронутая правка его инвалидирует.
- [ ] До реализации C1 enforced CI gate отсутствует. Ожидаемые source SHA и design-manifest digest verifier получает из защищённых controller inputs/ref, а не из проверяемого receipt. Отдельный проверяющий (основной агент/ревьюер) фиксирует identity, UTC и явный verdict после просмотра вне capture job; capture job не может самостоятельно создать или утвердить собственное visual OK.
- [ ] В controller добавить проверку receipt перед credential-bearing signing job. Receipt хранить в проверенном controller commit по пути `release/visual-receipts/<source-sha>.json`; существующая доверенная цепочка source pin используется без нового секрета для «подписи вердикта».
- [ ] `verify_visual_receipt.py` принимает только ожидаемый exact source и проверенный manifest. RED tests: mismatch SHA/design/fixture/artifact, FAIL/BLOCKED/NOT RUN, nonzero capture exit, missing coverage, подмена вердикта одним успешным capture.
- [ ] Весь capture/diff/review сначала локальный, без нового платного сервиса и лишних macOS cloud-прогонов. Signing/upload выполняются отдельно существующим controller.

## Task C2: Один кандидат, установка и окончательная приёмка

- [ ] После независимого review обоих направлений зафиксировать один точный source commit; повторить полный Flutter набор и необходимые native проверки именно для него. Не переносить старое число 800 PASS автоматически.
- [ ] До подписания нужны: работающий protected-configuration smoke probe, пройденные sender tests/лимиты, зелёный capture harness и подписанный процессом review visual receipt. Физическую доставку из ещё не установленного IPA до загрузки обещать нельзя.
- [ ] Проверить текущий Apple inventory, выбрать свободный build >22, собрать один exact IPA, проверить metadata/entitlements и доставить существующей группе Test. Source и controller provenance сохраняются отдельно.
- [ ] TestFlight delivery подтверждать только по exact version/build + VALID + assigned Test + READY_FOR_BETA_TESTING/IN_BETA_TESTING. После неопределённой загрузки — status-only recovery, без повторного upload.
- [ ] На установленной сборке выполнить один ручной тест. Дождаться именно его event_id/ACK с учётом очереди; найти тот же event_id/build в source 2805644. Проверить сохранение результата после перезапуска.
- [ ] Проверить на телефоне: Wi‑Fi/VPN off → Wi‑Fi/VPN on; при различии — отдельно cellular. Только нужные для различения причины попытки, без многократного «потыкать». Проверить lock/unlock и повторную доставку после resume без изменения VPN-профиля/маршрутов.
- [ ] Получить реальные Home/Settings/Servers/sheets screenshots и видео установленной версии; связать их с exact version/build, source SHA, controller SHA и установленной app identity. Проверить нормальное движение, Reduce Motion и Reduce Transparency. Device smoke не заменяет полный pre-sign visual matrix; найденное расхождение блокирует итоговую приёмку кандидата и требует исправления с новым build. Simulator UI proof не заменяет физическую VPN/сеть/VoiceOver приёмку.

## Критерии завершения

1. Известна доказанная причина отсутствия приёма — локальный gate, конфигурация/auth, транспорт либо visibility/indexing; исправление подтверждено соответствующим RED→GREEN.
2. Видна цепочка `конкретный IPA → включённый sender → event_id → разрешённая HTTP-попытка → ACK → запись в нужном source → результат после restart`.
3. Бесплатный бюджет ограничен и подтверждён расчётом с доступной квотой аккаунта; увеличение лимита не маскирует отказ.
4. Обязательные v3 состояния имеют актуальные просмотренные доказательства; нет существенных открытых расхождений, capture job GREEN, visual verdict PASS.
5. TestFlight availability, visual acceptance, remote receipt и физическая VPN-проверка отмечены отдельными статусами. Отсутствие любой проверки — BLOCKED/NOT RUN, а не «всё работает».

**Порядок исполнения:** A1 → A2; параллельно B1 → B2. Затем A3/A4 и B3, каждый со своим review; C1 объединяет доказательства, C2 доставляет и проверяет один общий кандидат. При недостающем credential/access указать ровно отсутствующий элемент и продолжить независимую работу по дизайну.
