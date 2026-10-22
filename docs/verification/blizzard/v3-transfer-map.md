# Blizzard v3 transfer map

Source: exact visual-tuning chat; preserve latest geometry and wave. Design-only cabinet states are outside implementation scope.

| Source family / state | v1 ID | v3 ID | Existing Flutter files |
|---|---|---|---|
| R02 / Отключено | yEamZ | u3BUv | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Подключение | XyysW | Ra7XH | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Подключено | rdRF8 | QjgLs | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Подключено | K4sH6r | zWUUX | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / AsyncError | QMiCy | lmdw3 | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R03 / populated synthetic server list (design real-display label omitted) | t3YQoV | b0gIl | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R05 / Основной экран | ijHmu | cIxE0 | `lib/features/settings/overview/settings_page.dart` |
| R06 / Основной экран | tcl2A | iOJWe | `lib/features/settings/overview/sections/general_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| S01 / manual-validation | HtzYc | V0zPO | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| D02 / Основное состояние | nDACa | ImH31 | `lib/core/router/dialog/widgets/confirmation_dialog.dart` |
| R11 / WARP включён | YuH7m | pjOuP | `lib/features/settings/overview/sections/warp_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R02 / Нет активного профиля | IBc77 | WDnDd | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Требуется переподключение | nbM3s | DbUIw | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Отключение | a5Jv0 | TTn6g | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Подписка истекла | V52aH | mvj0V | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Квота исчерпана | y3qZU | Tsk3J | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Загрузка состояния | zIBCg | rtAyp | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Подключено | bbZEZ | qN1LZ | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R02 / Длинное имя профиля | bX1KS | e0UefV | `lib/features/home/widget/home_page.dart`, `lib/features/home/widget/connection_button.dart`, `lib/features/profile/widget/profile_tile.dart`, `lib/features/proxy/active/active_proxy_card.dart`, `lib/features/proxy/active/active_proxy_delay_indicator.dart` |
| R01 / Готово | RNqPB | tFll0 | `lib/features/intro/widget/intro_page.dart`, `lib/features/common/general_pref_tiles.dart` |
| R01 / Начать | YYW7C | X9ZVk | `lib/features/intro/widget/intro_page.dart`, `lib/features/common/general_pref_tiles.dart` |
| R07 / Основной экран | tcqFl | a9oDu | `lib/features/settings/overview/sections/route_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R08 / Основной экран | neo9R | zoqwf | `lib/features/settings/overview/sections/dns_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R09 / Основной экран | sYmDL | dJWgi | `lib/features/settings/overview/sections/inbound_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R10 / Основной экран | X2QQ2D | f1SZI | `lib/features/settings/overview/sections/tls_tricks_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R11 / Основной экран | ASzFv | eE7Jd | `lib/features/settings/overview/sections/warp_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R06 / Настройки как на скриншоте пользователя | GPlKu | rDOAr | `lib/features/settings/overview/sections/general_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R08 / Fake DNS включён | lf4uW | SlyhU | `lib/features/settings/overview/sections/dns_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R09 / LAN sharing включён | iOqGe | ZnLf8 | `lib/features/settings/overview/sections/inbound_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R10 / Фрагментация включена | N1c2DJ | BIb1k | `lib/features/settings/overview/sections/tls_tricks_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R10 / Фрагментация и padding включены | R5BroF | C50V3 | `lib/features/settings/overview/sections/tls_tricks_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R11 / Генерация конфигурации WARP | t3wGdy | m7ZVF5 | `lib/features/settings/overview/sections/warp_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R11 / WARP включён | c4jg42 | n6Q3UN | `lib/features/settings/overview/sections/warp_options_page.dart`, `lib/features/settings/widget/preference_tile.dart` |
| R03 / Список | vTFHp | X8cuDi | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R03 / Загрузка | bp4Hu | eYoR0 | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R03 / Пустой список | xaRAu | VONtZ | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R03 / Ошибка | Iaxw1 | Lujub | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R03 / Тест задержки | V0uKUs | MVld7 | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R03 / Тайм-аут задержки | FsRTu | scqgc | `lib/features/proxy/overview/proxies_overview_page.dart`, `lib/features/proxy/widget/proxy_tile.dart` |
| R04 / Удалённый профиль | DDxJW | hbCXn | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Локальный профиль | ve332 | TRcrc | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Изменения | k0t9O | AtqXd | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Сохранение | FgLOj | K2ErT | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Текстовый конфиг | a7AZX | IQQSK | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Загрузка | Ylg9D | h2vhvD | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Ошибка | L6LPo | hdiMW | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R04 / Автообновление отключено | yZMlH | V7siZ | `lib/features/profile/details/profile_details_page.dart`, `lib/features/profile/details/json_editor.dart` |
| R12 / Поток журналов | ctkwc | Skg8L | `lib/features/log/overview/logs_page.dart` |
| R12 / Пауза | w76lAj | u9IQ6f | `lib/features/log/overview/logs_page.dart` |
| R12 / Фильтр | mQ0hC | O232Y | `lib/features/log/overview/logs_page.dart` |
| R12 / Нет записей | vfT7D | oTvGg | `lib/features/log/overview/logs_page.dart` |
| R12 / Загрузка | G0DeuG | gnFhf | `lib/features/log/overview/logs_page.dart` |
| R12 / Ошибка | gL15K | OGuUq | `lib/features/log/overview/logs_page.dart` |
| R13 / Основной экран | EgWE2 | NOB6z | `lib/features/about/widget/about_page.dart` |
| R13 / Проверка обновлений | rLEGl | e9EKp | `lib/features/about/widget/about_page.dart` |
| D01 / Основное состояние | Fxdab | oJxBI | `lib/core/router/dialog/widgets/no_active_profile_dialog.dart` |
| D03 / Основное состояние | Y6dFea | b6xB9 | `lib/core/router/dialog/widgets/experimental_feature_notice.dart` |
| D04 / Основное состояние | YNxBG | nsnXO | `lib/core/router/dialog/widgets/warp_license_dialog.dart` |
| S01 / Основное состояние | Rr2BS | zgf7h | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S01 / manual | pYfcv | pItXu | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S01 / import-loading | oZEtl | LFmUO | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S02 / Основное состояние | el0kJ | zqAyO | `lib/features/profile/overview/profiles_modal.dart`, `lib/features/profile/widget/profile_tile.dart` |
| S03 / Основное состояние | Sg8QN | DNnfr | `lib/core/router/bottom_sheets/widgets/quick_settings_modal.dart` |
| D07 / Основное состояние | LSxGn | BvZ74 | `lib/core/router/dialog/widgets/sort_profiles_dialog.dart` |
| D08 / Основное состояние | zVKn4 | n4vjpy | `lib/core/router/dialog/widgets/proxy_info_dialog.dart` |
| D09 / Основное состояние | b05e4 | JODmt | `lib/core/router/dialog/widgets/unknown_domains_warning_dialog.dart` |
| D10 / Основное состояние | ALgVl | t86NpS | `lib/core/router/dialog/widgets/free_profile_consent_dialog.dart` |
| D11 / Основное состояние | BrhPl | iVqci | `lib/core/router/dialog/widgets/new_version_dialog.dart` |
| D12 / Основное состояние | a6ZYc1 | I43AiS | `lib/core/router/dialog/widgets/custom_alert_dialog.dart` |
| D13 / Основное состояние | VszH0 | KqSRe | `lib/core/router/dialog/widgets/ok_dialog.dart` |
| S01 / free-loading | vLXZB | e8rAla | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S01 / free-data | FIVn4 | b0DvnB | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S01 / free-empty | DsDfF | x7hHM | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S01 / free-error | WSpJH | DWZMI | `lib/features/profile/add/add_profile_modal.dart`, `lib/features/profile/add/widgets/fix_btns.dart`, `lib/features/profile/add/widgets/free_btns.dart`, `lib/features/profile/add/widgets/nav_bar.dart`, `lib/features/profile/add/widgets/loading.dart` |
| S02 / loading | Q7YToY | J8Ve8 | `lib/features/profile/overview/profiles_modal.dart`, `lib/features/profile/widget/profile_tile.dart` |
| S02 / error | HerHJ | iX0jC | `lib/features/profile/overview/profiles_modal.dart`, `lib/features/profile/widget/profile_tile.dart` |
| S03 / warp-on | l89Vle | Hkv50 | `lib/core/router/bottom_sheets/widgets/quick_settings_modal.dart` |
| D05 / camera-ready | T5wExH | c8a4rb | `lib/features/common/qr_code_scanner_screen.dart` |
| D05 / loading | F99Nlq | Llx1J | `lib/features/common/qr_code_scanner_screen.dart` |
| D05 / permission-denied | lndEq | B3r5js | `lib/features/common/qr_code_scanner_screen.dart` |
| D06 / profile-url | bTD0y | yTKH9 | `lib/features/common/qr_code_dialog.dart` |
| D06 / lan-share | z2rADA | MX8gu | `lib/features/common/qr_code_dialog.dart` |
| R05-D01 / Значение из исходников | PQnAc | FbRud | `lib/features/settings/overview/settings_page.dart`, `lib/core/router/dialog/widgets/confirmation_dialog.dart` |
| R06-D01 / Значение из исходников | lHR7B | FloG5 | `lib/features/common/general_pref_tiles.dart`, `lib/core/router/dialog/widgets/setting_picker_dialog.dart` |
| R06-D02 / Значение из исходников | JTcEA | vVHlQ | `lib/features/common/general_pref_tiles.dart`, `lib/core/router/dialog/widgets/setting_picker_dialog.dart` |
| R06-D03 / Значение из исходников | aTSw1 | B8qq19 | `lib/features/settings/overview/sections/general_page.dart`, `lib/core/router/dialog/widgets/ok_dialog.dart` |
| R06-D04 / Значение из исходников | UDwa9 | bQCCe | `lib/features/settings/overview/sections/general_page.dart`, `lib/core/router/dialog/widgets/setting_picker_dialog.dart` |
| R06-D05 / Значение из исходников | rXNLD | BArl3 | `lib/features/settings/overview/sections/general_page.dart`, `lib/core/router/dialog/widgets/setting_input_dialog.dart` |
| R06-D06 / Значение из исходников | tey2x | caPE2 | `lib/features/settings/overview/sections/general_page.dart`, `lib/core/router/dialog/widgets/setting_slider_dialog.dart` |

Latest main screen: QjgLs / u3BUv. Status slot98pt; action148pt; shared vertical anchors. Dock320×64, radius32. Wave353×260,12s loop,2–3pt drift and±2degrees, caption/status cleared. Adapt under Dynamic Type rather than forcing clipping.

The header retains installed version/build despite older design proposal. The runtime controls/providers/routes remain authoritative. New telemetry status is integrated into SafeDiagnosticsPage rather than the legacy raw-log screen.
