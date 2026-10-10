# M1 — data formats

- Source: https://m1.material.io/patterns/data-formats.html
- Captured: 2026-08-13
- Older Material site; M3 has no equivalent page. Condensed in our own words, not a copy.

## Time
Inside the current day, show the time with an uppercase AM or PM and no periods: `2:00 PM`.
On a 24-hour clock, no AM/PM at all: `14:00`.

## Dates
Inside the current calendar year, leave the year off: `January 14`.
Otherwise include it: `14 January 2012`.

## Approximate vs absolute
Approximate time rounds down to the largest, most recent unit: `In 5 minutes`, `3 days ago`.
When that is not precise enough, give the real date or time: `Today, 10:00 AM`.

## Ranges
- En dash, no spaces: `8:00 AM–12:30 PM`. Add spaces when the month is spelled out: `6 Jan – 2 Feb`.
- Show the year on both ends unless both dates fall in the current year:
  `Dec 6, 2013–Jan 2, 2014`.
- One AM/PM at the end when both times share it: `8:00–10:30 AM`.

## Duration
Recordings use `H:MM:SS`, dropping the hours or the seconds when they do not apply: `0:30`,
`1:01:05`.

## Abbreviated numbers
Dropping the `:00` suits timestamps, graph labels and durations: `8 AM`, `2 hr 32 min ago`.
