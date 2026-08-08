# Calendr

[![install](https://img.shields.io/badge/How_to_install-gray?label=📥)](https://github.com/pakerwreah/Calendr/issues/217)
[![homebrew](https://img.shields.io/badge/Homebrew_cask-gray?logo=homebrew&logoColor=ffdd00)](https://github.com/pakerwreah/homebrew-calendr)
[![release](https://img.shields.io/github/v/release/pakerwreah/Calendr?label=Latest%20release)](https://github.com/pakerwreah/Calendr/releases/latest)
[![downloads-latest](https://img.shields.io/github/downloads/pakerwreah/Calendr/latest/Calendr.zip?displayAssetName=false&logo=github&label=Downloads)](https://github.com/pakerwreah/Calendr/releases/latest)
[![downloads-all](https://img.shields.io/github/downloads/pakerwreah/Calendr/Calendr.zip?displayAssetName=false&logo=github&label=All%20downloads)](https://github.com/pakerwreah/Calendr/releases/latest)

[![ci-github](https://github.com/pakerwreah/Calendr/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/pakerwreah/Calendr/actions)
[![ci-bitrise](https://img.shields.io/bitrise/9fa2e96dc9458fbb?label=Bitrise&logo=bitrise&token=iAJgn0FMJzmMP4ALCi0KdQ)](https://app.bitrise.io/app/9fa2e96dc9458fbb)
[![sentry](https://img.shields.io/badge/Sentry-purple?logo=sentry&logoColor=white)](https://github.com/pakerwreah/Calendr/issues)
[![linkedin](https://img.shields.io/badge/LinkedIn-blue?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/carlosenumo)
[![buy-me-a-coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-ffdd00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/pakerwreah)
[![reddit](https://img.shields.io/badge/Follow%20r%2FCalendr--black?style=social&logo=reddit)](https://www.reddit.com/r/Calendr)

## Menu bar calendar for macOS

<table>
<tr>
  <td>
    <img width=350 src="resources/screenshot.png" title="Calendr" />
    <img valign='top' width=170 src='https://github.com/pakerwreah/Calendr/assets/803954/8b3ebb0f-52ad-461c-91c3-7b4d2646712e' />
    <img valign='top' width=150 src='https://github.com/pakerwreah/Calendr/assets/803954/8e8d342d-9be5-4bad-b741-875cc407ec1a' />
  </td>
</tr>
</table>

Hey 🙋🏻‍♂️ if you like my app, please consider buying me a coffee to keep me motivated.<br>
<sub>(and maybe update the screenshot once in a while)</sub>

## Natural-language event entry

Create events faster by typing the title together with optional date, time, duration, all-day, and calendar instructions. Calendr highlights recognized instructions while you type, immediately updates the event fields, and removes the instructions from the saved event title.

For example:

`Pickleball with Tom next Friday from 10 to 12 /sport`

- Dates: `today`, `tomorrow`, `yesterday`, `in a week`, `in 3 days`, `on Friday`, `at Friday`, `next Friday`, or `August 12`
- Times: `at 14`, `at 2pm`, `at noon`, `tomorrow morning`, `from 10 to 12`, or `at 22 until 1`
- Relative starts and durations: `in 2 hours`, `for 30 minutes`, `for 2 hours`, or `for 4 days`
- All-day events: `all day` or `full day`
- Calendars: add `/` followed by part of a calendar name, such as `/sport`, to fuzzy-match and select it

Natural-language instructions are currently English-only. The feature can be enabled or disabled in Settings and defaults to enabled when Calendr's preferred localization is English. Numeric dates follow the date order configured by the active locale, and the first word is always preserved as event title text.

<table>
<tr>
  <td>
    <img width="500" src="resources/smart-event-entry.png" alt="Natural-language event entry with highlighted date, time, and calendar instructions" />
  </td>
</tr>
</table>

## Hidden features 🔍

### Display multiple timezones in the menu bar
- Format
`HH:mm | HH:mm@GMT+2 'LT' | HH:mm@GMT-3 'BR'`
- Result
`15:00 | 17:00 LT | 12:00 BR`

### Open date with a URL scheme https://github.com/pakerwreah/Calendr/issues/314
date|encoded
--|--
`december`|`calendr://date/december` (defaults to current date and year)
`feb 10 2025`|`calendr://date/feb%2010%202025`
`2nd of September 2025`|`calendr://date/2nd%20of%20September%202025`

It has limited support to relative dates like: `today`, `yesterday`, `tomorrow` but will not work with `next week`, `last month`, etc.

That's how `NSDataDetector` works ¯\\_\(ツ\)\_/¯
