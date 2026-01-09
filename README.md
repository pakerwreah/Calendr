# Calendr

[![install](https://img.shields.io/badge/How_to_install-gray?label=📥)](https://github.com/pakerwreah/Calendr/issues/217)
[![homebrew](https://img.shields.io/badge/Homebrew_cask-gray?logo=homebrew&logoColor=ffdd00)](https://github.com/pakerwreah/homebrew-calendr)
[![release](https://img.shields.io/github/v/release/pakerwreah/Calendr?label=Latest%20release)](https://github.com/pakerwreah/Calendr/releases/latest)
[![downloads-latest](https://img.shields.io/github/downloads/pakerwreah/Calendr/latest/Calendr.zip?displayAssetName=false&logo=github&label=Downloads)](https://github.com/pakerwreah/Calendr/releases/latest)
[![downloads-all](https://img.shields.io/github/downloads/pakerwreah/Calendr/Calendr.zip?displayAssetName=false&logo=github&label=All%20downloads)](https://github.com/pakerwreah/Calendr/releases/latest)

[![ci-github](https://github.com/pakerwreah/Calendr/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/pakerwreah/Calendr/actions)
[![ci-bitrise](https://img.shields.io/bitrise/9fa2e96dc9458fbb?label=Unit%20Tests&logo=bitrise&token=iAJgn0FMJzmMP4ALCi0KdQ)](https://app.bitrise.io/app/9fa2e96dc9458fbb)
[![sentry](https://img.shields.io/badge/Sentry-purple?logo=sentry&logoColor=white)](https://github.com/pakerwreah/Calendr/issues)
[![linkedin](https://img.shields.io/badge/LinkedIn-blue?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/carlosenumo)
[![buy-me-a-coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-ffdd00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/pakerwreah)
[![pix](https://img.shields.io/badge/Pix-white?logo=pix)](https://nubank.com.br/cobrar/3gkjs/691cc802-1bb3-4b2e-b269-9b5f8ecbc806)
[![reddit](https://img.shields.io/badge/Follow%20r%2FCalendr--black?style=social&logo=reddit)](https://www.reddit.com/r/Calendr)

### Menu bar calendar for macOS

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

<table>
<tr>
  <td>
    <a href="https://star-history.com/#pakerwreah/Calendr&Date">
     <picture>
       <source width=679 media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=pakerwreah/Calendr&type=Date&theme=dark" />
       <source width=679 media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=pakerwreah/Calendr&type=Date" />
       <img width=679 alt="Star History Chart" src="https://api.star-history.com/svg?repos=pakerwreah/Calendr&type=Date" />
     </picture>
    </a>
  </td>
</tr>
</table>
<br>

### Hidden features 🔍
## Open date with a URL scheme https://github.com/pakerwreah/Calendr/issues/314
date|encoded
--|--
`december`|`calendr://date/december` (defaults to current date and year)
`feb 10 2025`|`calendr://date/feb%2010%202025`
`2nd of September 2025`|`calendr://date/2nd%20of%20September%202025`

It has limited support to relative dates like: `today`, `yesterday`, `tomorrow` but will not work with `next week`, `last month`, etc.

That's how `NSDataDetector` works ¯\\_\(ツ\)\_/¯

## Regex to prevent showing the map/weather https://github.com/pakerwreah/Calendr/issues/377

Since **v1.19.0** the app has a built-in blacklist editor in settings that uses plain text.

To filter more complex locations, like office room codes, you can add a regex via terminal.

`defaults write br.paker.Calendr "show_map_blacklist_regex" -string "([A-Z0-9]+\-){5}.+"`

