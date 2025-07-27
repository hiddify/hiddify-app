# Changelog

## [0.16.0.dev] - 2024-2-18

### New Features and Improvements

- **Stabilized Experimental Features**: The following features have been moved from experimental to stable status:
  - TLS Tricks (TLS Fragment, TLS Mixed SNI Case, TLS Padding)
  - Mux (Multiplexing)
  - Cloudflare WARP
  - Bypass LAN
  - Allow Connection from LAN
  - Block Ads
  - These features are now fully supported and no longer require experimental feature warnings

- Changed App name to **Hiddify**
- Changed App icon
- **Stabilized Experimental Features**: Mux, Cloudflare WARP, TLS Tricks, Bypass LAN, Connection from LAN, and VPN Service modes are now stable and no longer marked as experimental
- Added Mux
- Added Cloudflare WARP
- Added connection info
  - when connected, name of the active node, speed and IP address are shown on home page
  - delay indicator below connection button shows active node's ping
- Added VPN Service (Windows & Linux)
  - VPN Service circumvents need for administrator permission while using TUN
- Changed in-app icons (using [Fluent UI System Icons](https://github.com/microsoft/fluentui-system-icons))
- Redesigned navigation flow, separating config options
- Added haptic feedback
- Added detailed subscription info in profile edit page
- Added Chinese Taiwan language. [PR#410](https://github.com/hiddify/hiddify-next/pull/410) by [junlin03](https://github.com/junlin03) and [PR#491](https://github.com/hiddify/hiddify-next/pull/491) by [kouhe3](https://github.com/kouhe3)
- Added Japanese Readme. [PR#371](https://github.com/hiddify/hiddify-next/pull/371) by [Ikko Eltociear Ashimine](https://github.com/eltociear)

### Bug Fixes

- Fixed TLS Tricks bugs
- Fixed logs on iOS. [PR#414](https://github.com/hiddify/hiddify-next/pull/414) by [Amir Mohammadi](https://github.com/amirsaam) and [PR#416](https://github.com/hiddify/hiddify-next/pull/416) by [Ebrahim Tahernejad](https://github.com/EbrahimTahernejad)
- Fixed Android service mode
- Fixed UI inconsistencies
- Fixed Readme download URL. [PR#482](https://github.com/hiddify/hiddify-next/pull/482) by [Ali Afsharzadeh](https://github.com/guoard)

## [0.14.1.dev] - 2024-1-19

### New Features and Improvements

- Redesigned profile options on mobile
- Improved configuration parser
- Added export config json in iOS
- Added iOS URL scheme. [PR#343](https://github.com/hiddify/hiddify-next/pull/343) by [Amir Mohammadi](https://github.com/amirsaam)
- Added option to reset VPN profile on iOS

### Bug Fixes

- Fixed TLS Tricks causing app crash
- Fixed connection status on iOS app relaunch
- Fixed iOS connection stats
- Fixed infinite subscription traffic
- Fixed infinite subscription expiry. [PR#334](https://github.com/hiddify/hiddify-next/pull/334) by [Pavel Volkov](https://github.com/pvolkov)

## [0.14.0.dev] - 2024-1-14

### New Features and Improvements

- Published initial iOS beta version on TestFlight
  - Thanks to contributions from [GFWFighter](https://github.com/GFWFighter) and [Amir Mohammadi](https://github.com/amirsaam)
  - iOS version is still in heavy development phase and there are known bugs
- Added Spanish language. [PR#314](https://github.com/hiddify/hiddify-next/pull/314) by [AvatarStark](https://github.com/AvatarStark)
- Changed Routing Assets page layout, separating assets by type
- Improved descriptions for some of the options in settings page

### Bug Fixes

- Fixed Deep links on Windows
- Fixed minor UI bugs
- Fixed subscription profiles with infinite traffic

## [0.13.6] - 2024-1-7

- First stable 0.13.x release. check changes from 0.13.0.dev to 0.13.5.dev for more details.

## [0.13.5.dev] - 2024-1-6

### New Features and Improvements

- Updated sing-box to version 1.7.8
- Improved TLS Fragmentation. [PR#12](https://github.com/hiddify/hiddify-sing-box/pull/12) by [Kyōchikutō | キョウチクトウ](https://github.com/kyochikuto)
- Improved v2ray config parser
- Added cancel button on new profile modal
- Changed default Connection Test URL

### Bug Fixes

- Fixed Android service mode
- Fixed QR code scanner not scanning deep links

## [0.13.4.dev] - 2024-1-4

### New Features and Improvements

- Added update all subscriptions
  - Force update all subscription profiles regardless of their interval
- Added basic authorization support
- Changed app http client, improving experience when fetching profiles, geo assets etc.

### Bug Fixes

- Fixed profile auto update service
- Fixed localization mistakes in Chinese. [PR#288](https://github.com/hiddify/hiddify-next/pull/288) by [wldjdjsks](https://github.com/huajizhige)

## [0.13.3.dev] - 2024-1-2

### New Features and Improvements

- Added Bypass LAN option
- Added Connection from LAN option
- Added DNS Routing option
- Changed outbound options section to TLS Tricks

### Bug Fixes

- Fixed profile edit bug where you were unable to change existing profile's URL
- Fixed localization mistakes in Chinese. [PR#287](https://github.com/hiddify/hiddify-next/pull/287) by [Wu Jiahao](https://github.com/wujiahao15)

## [0.13.2.dev] - 2023-12-31

### Bug Fixes

- Fixed db migration bug

## [0.13.1.dev] - 2023-12-31

### New Features and Improvements

- Removed experimental feature flag and notice dialog (features are now stable)

### Bug Fixes

- Fixed multiple instance launch on windows
- Removed auto connect on desktop which caused bugs on auto launch etc.
- Fixed inlang localization setup

## [0.13.0.dev] - 2023-12-29

### New Features and Improvements

- Added desktop shortcuts
  - Add profile from clipboard by pressing `CTRL+V` (`CMD+V` on macOS)
  - Close App window by pressing `CTRL+W` (`CMD+W` on macOS)
  - Quit App by pressing `CTRL+Q` (`CMD+Q` on macOS)
  - Open settings page by pressing `CMD+,` on macOS
- Added Android high refresh rate screen support

### Bug Fixes

- Fixed silent start bug where screen would blink
- Refactored Window management and system tray, fixing minor bugs
- Fixed windows portable release again!

## [0.12.3] - 2023-12-28

### New Features and Improvements

- Added version number in window title on desktop
- Added Afghanistan (af) region with default bypass rules

### Bug Fixes

- Fixed modal bug where config options were unmodifiable. [PR#267](https://github.com/hiddify/hiddify-next/pull/267) by [在7楼](https://github.com/RayWangQvQ)
- Fixed windows portable release

## [0.12.2] - 2023-12-23

### New Features and Improvements

- Updated Sing-box to Version 1.7.6

### Bug Fixes

- Fixed app log file not including stacktrace
- Fixed initialization process failing for non-essential dependencies
- Fixed analytics preferences requiring app restart

## [0.12.1] - 2023-12-21

### Bug Fixes

- Fixed Android service mode
- Fixed [preferences initialization error on Windows and Linux](https://github.com/flutter/flutter/issues/89211)
- Fixed incorrect privacy policy URL
- Bumped Android compile and target SDK version (34)

## [0.12.0] - 2023-12-20

### New Features and Improvements

- Added TLS Tricks
  - Including TLS fragments and Mixed SNI case. This feature might effect performance and battery life
- Added dynamic notification on Android
  - Active profile name and transfer speed are now shown in notification
- Added basic D-pad support for Android TV
- Added soffchen to recommended geo assets
- Added option to reset Config Options
- Improved text input field's accessibility and traversal

### Bug Fixes

- Refactored significant portions of the app
- Fixed incorrect profile parsing when missing headers
- Fixed geo assets bug where assets were deactivated
- Changed default memory limit option on desktop, fixing out of memory bug on macOS
- Fixed macOS icon
- Fixed system tray behavior
- Fixed incorrect casing of locale names
- Updated sing-box to version 1.7.0
- Fixed Chinese typography bug (thanks to [betaxab](https://github.com/betaxab))
- Fixed localization mistakes in Russian. [PR#189](https://github.com/hiddify/hiddify-next/pull/189) by [jomertix](https://github.com/jomertix)

## [0.11.1] - 2023-11-19

### Bug Fixes

- Fixed Android manifest bug.

## [0.11.0] - 2023-11-19

### New Features and Improvements

- Changed Responsive UI Behavior
  - Now app is responsive on all platforms with appropriate routing setup.
- Added Simplified Service Modes
  - Choose between VPN(Tun), System Proxy and Proxy only modes. (System Proxy available on desktop)
- Added Share Functionality
  - Share configuration as json(export to clipboard) or share subscription link as QR code.
- Redesigned System Tray on Desktop
  - Options have been simplified and a new mode selector and navigation options are added.
- Added Privilege Checks for VPN(TUN) on Desktop
- Added Auto Connect on Start
  - On desktop, app will try to connect to the last used profile on startup. (if last session was not explicitly disconnected by the user)
- Added AppCast Update Checker
  - Checking for new versions of the app will use a more reliable approach on all platforms.
- Added Geo Asset Settings
  - Update geo assets and use recommended providers
- Added **winget** Release
  - Now you're able to install and update Hiddify on Windows using [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/).
- Added Turkish Translations. [PR#173](https://github.com/hiddify/hiddify-next/pull/173) by [Hasan Karlı](https://github.com/hasankarli)
- Changed in-app Toasts
- Updated Core Sing-box Version to 1.7.0
- Improved Network Reliability While Adding/Updating Subscriptions
- Improved QR Code Scanner

### Bug Fixes

- Removed **execute config as is** option which caused crashes and confusion for users.
- Fixed android service revoke and restart.
- Fixed github release update checker.
- Fixed translator script. [PR#108](https://github.com/hiddify/hiddify-next/pull/108) by [Hirad Rasoolinejad](https://github.com/Hiiirad)
- Fixed localization mistakes in Chinese. [PR#113](https://github.com/hiddify/hiddify-next/pull/113) and [PR#123](https://github.com/hiddify/hiddify-next/pull/123) by [Nyar233](https://github.com/Nyar233)
- Fixed localization mistakes in Chinese Readme. [PR#137](https://github.com/hiddify/hiddify-next/pull/137) by [wldjdjsks](https://github.com/huajizhige)
- Fixed localization mistakes in Chinese. [PR#138](https://github.com/hiddify/hiddify-next/pull/138) and [PR#165](https://github.com/hiddify/hiddify-next/pull/165) by [wldjdjsks](https://github.com/huajizhige)
- Fixed localization mistakes in Russian. [PR#155](https://github.com/hiddify/hiddify-next/pull/155), [PR#162](https://github.com/hiddify/hiddify-next/pull/162) and [PR#169](https://github.com/hiddify/hiddify-next/pull/169) by [solokot](https://github.com/solokot)
- Fixed linux build libs command. [PR#161](https://github.com/hiddify/hiddify-next/pull/161) by [Aloxaf](https://github.com/Aloxaf)
- Fixed localization mistakes in Russian. [PR#164](https://github.com/hiddify/hiddify-next/pull/164) and [PR#168](https://github.com/hiddify/hiddify-next/pull/168) by [jomertix](https://github.com/jomertix)
- Fixed localization mistakes in Chinese. [PR#179](https://github.com/hiddify/hiddify-next/pull/179) by [betaxab](https://github.com/betaxab)
- Fixed localization mistakes in Chinese Readme. [PR#172](https://github.com/hiddify/hiddify-next/pull/172) by [Locas](https://github.com/Locas56227)

## [0.10.0] - 2023-10-27

### New Features and Improvements

- Added Basic region-based routing rules
  - Based on your selected region (Iran, China or Russia), local ip and domains are bypassed.
- Redesigned Logs page
  - Now you're able to pause stream and clear logs. Also logs are delivered more consistently, with less resource consumption.
- Added tag of selected outbound of selectors to proxies page
  - Selected outbound tag of selectors like URLTests are now shown in other selectors as well.
- Added color to delay number in proxies page
- Memory limit option
  - Limit sing-box core memory usage.
- Revamped theme preferences settings
- Added initial iOS implementation. [PR#98](https://github.com/hiddify/hiddify-next/pull/98) by [GFWFighter](https://github.com/GFWFighter)
- Added Russian region
- Added Terms and Conditions and Privacy policy to about page

### Bug Fixes

- Removed reconnection on auto profile updates
- Fixed filtering logs by level
- Fixed localization mistakes in Russian. [PR#95](https://github.com/hiddify/hiddify-next/pull/95) by [solokot](https://github.com/solokot)
- Fixed localization mistakes in Russian. [PR#74](https://github.com/hiddify/hiddify-next/pull/74) by [Elshad Guseynov](https://github.com/lifeindarkside)

[0.16.0.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.16.0.dev
[0.14.1.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.14.1.dev
[0.14.0.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.14.0.dev
[0.13.6]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.6
[0.13.5.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.5.dev
[0.13.4.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.4.dev
[0.13.3.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.3.dev
[0.13.2.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.2.dev
[0.13.1.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.1.dev
[0.13.0.dev]: https://github.com/hiddify/hiddify-next/releases/tag/v0.13.0.dev
[0.12.3]: https://github.com/hiddify/hiddify-next/releases/tag/v0.12.3
[0.12.2]: https://github.com/hiddify/hiddify-next/releases/tag/v0.12.2
[0.12.1]: https://github.com/hiddify/hiddify-next/releases/tag/v0.12.1
[0.12.0]: https://github.com/hiddify/hiddify-next/releases/tag/v0.12.0
[0.11.1]: https://github.com/hiddify/hiddify-next/releases/tag/v0.11.1
[0.11.0]: https://github.com/hiddify/hiddify-next/releases/tag/v0.11.0
[0.10.0]: https://github.com/hiddify/hiddify-next/releases/tag/v0.10.0
