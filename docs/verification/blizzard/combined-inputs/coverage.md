# Blizzard v3 — покрытие экранов

22 октября 2026. Обновление в pen.dev.

Комплект содержит 105 самостоятельных макетов: все 89 состояний исходного Blizzard Dark v1, 12 состояний личного кабинета, отдельный iPhone viewport общих настроек и 3 адаптивных/доступных варианта. Дополнительно на canvas есть библиотека и обзор.

Основной раздел canvas: `Blizzard v3 · Все экраны · Компоненты и карта · 22.10.2026` (`F5kNmq`). Превью: `V1MW5x`.

## Материалы и граница макета

Кнопка подключения — спецификация нативного UIGlassEffect(.clear); нижняя навигация — UIGlassEffect(.regular). Это нативный материал под Flutter-контролами; нативная интерактивная физика UIButton/UITabBar не заявлена. В pen.dev материал представлен статично. Дополнительные роли материала и новые действия восстановления требуют реализации и проверки в приложении. Карточки и поля остаются непрозрачными.

Экранные значения и данные подписки — исторические или иллюстративные, не актуальная проверка сервиса. Исходные экраны сохранены; таблица связывает их с новыми копиями. Ручной импорт использует последние варианты v2 вместо устаревших дубликатов v1.

## 89 исходных состояний

| Исходный ID | Новый ID | Макет v3 |
|---|---|---|
| XyysW | Ra7XH | Blizzard v3 · R02 · Подключение |
| IBc77 | WDnDd | Blizzard v3 · R02 · Нет активного профиля |
| nbM3s | DbUIw | Blizzard v3 · R02 · Требуется переподключение |
| a5Jv0 | TTn6g | Blizzard v3 · R02 · Отключение |
| V52aH | mvj0V | Blizzard v3 · R02 · Подписка истекла |
| y3qZU | Tsk3J | Blizzard v3 · R02 · Квота исчерпана |
| zIBCg | rtAyp | Blizzard v3 · R02 · Загрузка состояния |
| bbZEZ | qN1LZ | Blizzard v3 · R02 · Подключено · WARP |
| bX1KS | e0UefV | Blizzard v3 · R02 · Длинное имя профиля |
| RNqPB | tFll0 | Blizzard v3 · R01 · Готово |
| YYW7C | X9ZVk | Blizzard v3 · R01 · Начать · выполняется |
| DDxJW | hbCXn | Blizzard v3 · R04 · Удалённый профиль |
| ve332 | TRcrc | Blizzard v3 · R04 · Локальный профиль |
| k0t9O | AtqXd | Blizzard v3 · R04 · Изменения · сохранить доступно |
| FgLOj | K2ErT | Blizzard v3 · R04 · Сохранение |
| a7AZX | IQQSK | Blizzard v3 · R04 · Текстовый конфиг |
| Ylg9D | h2vhvD | Blizzard v3 · R04 · Загрузка |
| L6LPo | hdiMW | Blizzard v3 · R04 · Ошибка |
| yZMlH | V7siZ | Blizzard v3 · R04 · Автообновление отключено |
| tcqFl | a9oDu | Blizzard v3 · R07 · Основной экран |
| neo9R | zoqwf | Blizzard v3 · R08 · Основной экран |
| lf4uW | SlyhU | Blizzard v3 · R08 · Fake DNS включён |
| sYmDL | dJWgi | Blizzard v3 · R09 · Основной экран |
| iOqGe | ZnLf8 | Blizzard v3 · R09 · LAN sharing включён |
| X2QQ2D | f1SZI | Blizzard v3 · R10 · Основной экран |
| N1c2DJ | BIb1k | Blizzard v3 · R10 · Фрагментация включена · padding выключен |
| R5BroF | C50V3 | Blizzard v3 · R10 · Фрагментация и padding включены |
| ASzFv | eE7Jd | Blizzard v3 · R11 · Основной экран |
| t3wGdy | m7ZVF5 | Blizzard v3 · R11 · Генерация конфигурации WARP |
| c4jg42 | n6Q3UN | Blizzard v3 · R11 · WARP включён · конфигурация создана |
| YuH7m | pjOuP | Blizzard v3 · R11 · WARP включён · конфигурация отсутствует |
| ctkwc | Skg8L | Blizzard v3 · R12 · Поток журналов |
| w76lAj | u9IQ6f | Blizzard v3 · R12 · Пауза |
| mQ0hC | O232Y | Blizzard v3 · R12 · Фильтр |
| vfT7D | oTvGg | Blizzard v3 · R12 · Нет записей |
| G0DeuG | gnFhf | Blizzard v3 · R12 · Загрузка |
| gL15K | OGuUq | Blizzard v3 · R12 · Ошибка |
| EgWE2 | NOB6z | Blizzard v3 · R13 · Основной экран |
| rLEGl | e9EKp | Blizzard v3 · R13 · Проверка обновлений |
| nDACa | ImH31 | Blizzard v3 · D02 · Основное состояние |
| Fxdab | oJxBI | Blizzard v3 · D01 · Основное состояние |
| Y6dFea | b6xB9 | Blizzard v3 · D03 · Основное состояние |
| YNxBG | nsnXO | Blizzard v3 · D04 · Основное состояние |
| Rr2BS | zgf7h | Blizzard v3 · S01 · Основное состояние |
| oZEtl | LFmUO | Blizzard v3 · S01 · import-loading |
| el0kJ | zqAyO | Blizzard v3 · S02 · Основное состояние |
| Sg8QN | DNnfr | Blizzard v3 · S03 · Основное состояние |
| LSxGn | BvZ74 | Blizzard v3 · D07 · Основное состояние |
| zVKn4 | n4vjpy | Blizzard v3 · D08 · Основное состояние |
| b05e4 | JODmt | Blizzard v3 · D09 · Основное состояние |
| ALgVl | t86NpS | Blizzard v3 · D10 · Основное состояние |
| BrhPl | iVqci | Blizzard v3 · D11 · Основное состояние |
| a6ZYc1 | I43AiS | Blizzard v3 · D12 · Основное состояние |
| VszH0 | KqSRe | Blizzard v3 · D13 · Основное состояние |
| vLXZB | e8rAla | Blizzard v3 · S01 · free-loading |
| FIVn4 | b0DvnB | Blizzard v3 · S01 · free-data |
| DsDfF | x7hHM | Blizzard v3 · S01 · free-empty |
| WSpJH | DWZMI | Blizzard v3 · S01 · free-error |
| Q7YToY | J8Ve8 | Blizzard v3 · S02 · loading |
| HerHJ | iX0jC | Blizzard v3 · S02 · error |
| l89Vle | Hkv50 | Blizzard v3 · S03 · warp-on |
| T5wExH | c8a4rb | Blizzard v3 · D05 · camera-ready |
| F99Nlq | Llx1J | Blizzard v3 · D05 · loading |
| lndEq | B3r5js | Blizzard v3 · D05 · permission-denied |
| bTD0y | yTKH9 | Blizzard v3 · D06 · profile-url |
| z2rADA | MX8gu | Blizzard v3 · D06 · lan-share |
| PQnAc | FbRud | Blizzard v3 · R05-D01 · Значение из исходников |
| lHR7B | FloG5 | Blizzard v3 · R06-D01 · Значение из исходников |
| JTcEA | vVHlQ | Blizzard v3 · R06-D02 · Значение из исходников |
| aTSw1 | B8qq19 | Blizzard v3 · R06-D03 · Значение из исходников |
| UDwa9 | bQCCe | Blizzard v3 · R06-D04 · Значение из исходников |
| rXNLD | BArl3 | Blizzard v3 · R06-D05 · Значение из исходников |
| tey2x | caPE2 | Blizzard v3 · R06-D06 · Значение из исходников |
| yEamZ | u3BUv | Blizzard v3 · Главная · Отключено · Native Liquid Glass |
| rdRF8 | QjgLs | Blizzard v3 · Главная · Подключено · Native Liquid Glass |
| K4sH6r | zWUUX | Blizzard v3 · R02 · Подключено · Задержка неизвестна |
| QMiCy | lmdw3 | Blizzard v3 · R02 · Ошибка · Повторить |
| t3YQoV | b0gIl | Blizzard v3 · R03 · Серверы · Все 10 серверов |
| vTFHp | X8cuDi | Blizzard v3 · R03 · Серверы · iPhone viewport |
| bp4Hu | eYoR0 | Blizzard v3 · R03 · Загрузка |
| xaRAu | VONtZ | Blizzard v3 · R03 · Пустой список |
| Iaxw1 | Lujub | Blizzard v3 · R03 · Ошибка |
| V0uKUs | MVld7 | Blizzard v3 · R03 · Тест задержки |
| FsRTu | scqgc | Blizzard v3 · R03 · Тайм-аут задержки |
| ijHmu | cIxE0 | Blizzard v3 · R05 · Настройки |
| tcl2A | iOJWe | Blizzard v3 · R06 · Общие · Полное содержимое |
| GPlKu | rDOAr | Blizzard v3 · R06 · Общие · Пользовательские значения |
| HtzYc | V0zPO | Blizzard v3 · S01 · Импорт · Ошибка URL |
| pYfcv | pItXu | Blizzard v3 · S01 · Импорт · Готово к добавлению |

## 12 состояний кабинета

| Исходный ID | Новый ID | Макет v3 |
|---|---|---|
| er8r9 | AbWsO | Blizzard v3 · Кабинет · Вход · Пустое поле · Native Liquid Glass |
| BvKom | Q7IMPI | Blizzard v3 · Кабинет · Вход · Телефон · Native Liquid Glass |
| aoVcZ | Pllba | Blizzard v3 · Кабинет · Вход · Поиск по логину · Native Liquid Glass |
| TzIU7 | aoZxt | Blizzard v3 · Кабинет · Подписка · Активна · Native Liquid Glass |
| iBog7 | lfokQ | Blizzard v3 · Кабинет · Подписка · Безлимит · Native Liquid Glass |
| zvueD | kwhVa | Blizzard v3 · Кабинет · Подписка · Срок истёк · Native Liquid Glass |
| u6ub8 | vj2LR | Blizzard v3 · Кабинет · Подписка · Лимиты исчерпаны · Native Liquid Glass |
| ISFsk | IlAu2 | Blizzard v3 · Кабинет · Подписка · Сохранённые данные · Native Liquid Glass |
| dyOhK | RaNpU | Blizzard v3 · Кабинет · Подписка · Нет данных устройств · Native Liquid Glass |
| c7batd | f77Mk | Blizzard v3 · Кабинет · Вход · Подписка не найдена · Native Liquid Glass |
| xDWHe | mb7nO | Blizzard v3 · Кабинет · Вход · Ошибка сети · Native Liquid Glass |
| n8R3u | X2EW7 | Blizzard v3 · Кабинет · Подписка · Ошибка без сохранённых данных · Native Liquid Glass |

## Дополнительные варианты

| ID | Макет |
|---|---|
| VVoOF | Blizzard v3 · R06 · Общие · iPhone viewport |
| n4QSDH | Blizzard v3 · QA · Compact 320×568 |
| jX1gF | Blizzard v3 · QA · Large 430×932 |
| lCeuH | Blizzard v3 · QA · Reduce Transparency |

## Проверка результата

- Сопоставление: 89 из 89 исходных состояний; пропусков и неизвестных source ID нет.
- 12 из 12 состояний кабинета перенесены.
- Все 105 самостоятельных макетов: frame, clip=true, placeholder=false.
- Пересечений корневых экранов с другими объектами canvas нет.
- 96 макетов не имеют флагов обрезки. На 9 остаётся только ожидаемая обрезка прокручиваемого содержимого: X8cuDi, MVld7, scqgc, VVoOF и подложки под диалогами vVHlQ, B8qq19, bQCCe, BArl3, caPE2. Активные диалоги/контролы не обрезаны; длинное содержимое показано отдельно.
- Визуальное ревью проверяло согласованность, контраст и регрессии в представительных семействах. Исправлены скрытый логин в кабинете, старое имя приложения в About, несогласованные заголовки, обрезки WARP/длинного профиля, редактора и slider thumb.
- Это проверка статичных макетов. Она не подтверждает runtime Liquid Glass, VoiceOver, Dynamic Type, жесты, производительность или фактическую работу VPN.


