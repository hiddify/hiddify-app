# vwarp

vwarp is an open-source implementation of Cloudflare's Warp, enhanced with Psiphon integration for circumventing censorship. This project aims to provide a robust and cross-platform VPN solution that can use psiphon on top of warp and warp-in-warp for changing the user virtual nat location.
<div align="center">

<img src="https://github.com/voidr3aper-anon/Vwarp/blob/master/logo/logo.png" width="350" alt="Vwarp Logo" />


**Maintainer**: [voidreaper](https://github.com/voidr3aper-anon)

**Check out the telegram channel**: 📱 [@VoidVerge](https://t.me/VoidVerge)

</div>
## 🚀 Quick Start

```bash
# Basic WARP connection
vwarp --bind 127.0.0.1:8086

# MASQUE mode with noize obfuscation (bypass DPI/censorship)
vwarp --masque --masque-noize --masque-noize-preset light

# With AtomicNoize obfuscation (WireGuard anti-censorship)
vwarp --atomicnoize-enable --bind 127.0.0.1:8086

# Through SOCKS5 proxy (double-VPN)
vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086

# Maximum privacy (MASQUE + noize + SOCKS5 proxy)
vwarp --masque --masque-noize --masque-noize-preset heavy --proxy socks5://127.0.0.1:1080
```

📖 **Need help?** Check out the [MASQUE Noize Guide](docs/MASQUE_NOIZE_GUIDE.md), [SOCKS5 Proxy Guide](SOCKS_PROXY_GUIDE.md) and [AtomicNoize Guide](cmd/docs/ATOMICNOIZE_README.md)

## Features

- **Warp Integration**: Leverages Cloudflare's Warp to provide a fast and secure VPN service.
- **MASQUE Tunneling**: Connect to Warp via MASQUE proxy protocol for enhanced censorship resistance.
- **MASQUE Noize Obfuscation**: Advanced packet obfuscation system to bypass Deep Packet Inspection (DPI). [Learn more](docs/MASQUE_NOIZE_GUIDE.md)
- **Psiphon Chaining**: Integrates with Psiphon for censorship circumvention, allowing seamless access to the internet in restrictive environments.
- **Warp in Warp Chaining**: Chaining two instances of warp together to bypass location restrictions.
- **AtomicNoize Protocol**: Advanced obfuscation protocol for enhanced privacy and censorship resistance. [Learn more](cmd/docs/ATOMICNOIZE_README.md)
- **SOCKS5 Proxy Chaining**: Route WireGuard traffic through SOCKS5 proxies for double-VPN setups. [Learn more](SOCKS_PROXY_GUIDE.md)
- **SOCKS5 Proxy Server**: Includes a SOCKS5 proxy server for secure and private browsing.

## Getting Started

### Prerequisites

- [Download the latest version from the releases page](https://github.com/bepass-org/vwarp/releases)
- Basic understanding of VPN and proxy configurations

### Usage

```
NAME
  vwarp

FLAGS
  -v, --verbose                                enable verbose logging
  -4                                           only use IPv4 for random warp endpoint
  -6                                           only use IPv6 for random warp endpoint
  -b, --bind STRING                            socks bind address (default: 127.0.0.1:8086)
  -e, --endpoint STRING                        warp endpoint
  -k, --key STRING                             warp key
      --dns STRING                             DNS address (default: 1.1.1.1)
      --gool                                   enable gool mode (warp in warp)
      --cfon                                   enable psiphon mode (must provide country as well)
      --country STRING                         psiphon country code (default: AT)
      --scan                                   enable warp scanning
      --rtt DURATION                            (default: 1s)
      --cache-dir STRING
      --fwmark UINT32                           (default: 0)
      --reserved STRING
      --wgconf STRING
      --test-url STRING                         (default: http://connectivity.cloudflareclient.com/cdn-cgi/trace)
  -c, --config STRING
      --atomicnoize-enable
      --atomicnoize-i1 STRING                  AtomicNoize I1 signature packet in CPS format (e.g., '<b 0xc200...>'). Required for obfuscation.
      --atomicnoize-i2 STRING                  AtomicNoize I2 signature packet (CPS format or simple number) (default: 1)
      --atomicnoize-i3 STRING                  AtomicNoize I3 signature packet (CPS format or simple number) (default: 2)
      --atomicnoize-i4 STRING                  AtomicNoize I4 signature packet (CPS format or simple number) (default: 3)
      --atomicnoize-i5 STRING                  AtomicNoize I5 signature packet (CPS format or simple number) (default: 4)
      --atomicnoize-s1 INT                     AtomicNoize S1 random prefix for Init packets (0-64 bytes) - disabled for WARP compatibility (default: 0)
      --atomicnoize-s2 INT                     AtomicNoize S2 random prefix for Response packets (0-64 bytes) - disabled for WARP compatibility (default: 0)
      --atomicnoize-jc INT                     Total number of junk packets to send (0-128) (default: 4)
      --atomicnoize-jmin INT                   Minimum junk packet size in bytes (default: 40)
      --atomicnoize-jmax INT                   Maximum junk packet size in bytes (default: 70)
      --atomicnoize-jc-after-i1 INT            Number of junk packets to send immediately after I1 packet (default: 0)
      --atomicnoize-jc-before-hs INT           Number of junk packets to send before handshake initiation (default: 0)
      --atomicnoize-jc-after-hs INT            Number of junk packets to send after handshake (auto-calculated as Jc - JcBeforeHS - JcAfterI1) (default: 0)
      --atomicnoize-junk-interval DURATION     Time interval between sending junk packets (e.g., 10ms, 50ms) (default: 10ms)
      --atomicnoize-allow-zero-size            Allow zero-size junk packets (may not work with all UDP implementations)
      --atomicnoize-handshake-delay DURATION   Delay before actual WireGuard handshake after I-sequence (e.g., 50ms, 100ms) (default: 0s)
      --masque                                 enable MASQUE mode (connect to warp via MASQUE proxy)
      --masque-auto-fallback                   automatically fallback to WireGuard if MASQUE fails
      --masque-preferred                       prefer MASQUE over WireGuard (with automatic fallback)
      --masque-noize                           enable MASQUE QUIC obfuscation (helps bypass DPI/censorship)
      --masque-noize-preset STRING             MASQUE noize preset: light, medium, heavy, stealth, gfw, firewall (default: medium)
      --masque-noize-config STRING             path to custom MASQUE noize configuration JSON file (overrides preset)
      --proxy STRING                           SOCKS5 proxy address to route WireGuard traffic through (e.g., socks5://127.0.0.1:1080)
```

### Basic Examples

#### Standard WARP Connection
```bash
vwarp --bind 127.0.0.1:8086
```

#### MASQUE Mode with Noize Obfuscation
```bash
# Light obfuscation (recommended for most users)
vwarp --masque --masque-noize --masque-noize-preset light

# Heavy obfuscation for strict censorship
vwarp --masque --masque-noize --masque-noize-preset heavy

# Custom configuration from JSON file
vwarp --masque --masque-noize --masque-noize-config docs/examples/basic-obfuscation.json
```

#### With AtomicNoize Obfuscation (WireGuard)
```bash
vwarp --atomicnoize-enable --atomicnoize-packet-size 1280 --bind 127.0.0.1:8086
```

#### Through SOCKS5 Proxy (Double VPN)
```bash
# First, start your SOCKS5 proxy (e.g., SSH tunnel, VPN, etc.)
# Then route WARP through it:
vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086
```

#### With Psiphon for Censorship Circumvention
```bash
vwarp --cfon --country US --bind 127.0.0.1:8086
```

#### Warp-in-Warp (Change Location)
```bash
vwarp --gool --bind 127.0.0.1:8086
```

#### Maximum Privacy Setup
```bash
vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --atomicnoize-packet-size 1280 \
  --atomicnoize-junk-size 50 \
  --verbose
```

#### Scan for Best Endpoint
```bash
vwarp --scan --rtt 800ms
```

For more detailed examples and configurations, see:
- [SOCKS5 Proxy Chaining Guide](SOCKS_PROXY_GUIDE.md)
- [AtomicNoize Protocol Guide](cmd/docs/ATOMICNOIZE_README.md)

### Country Codes for Psiphon

- Austria (AT)
- Australia (AU)
- Belgium (BE)
- Bulgaria (BG)
- Canada (CA)
- Switzerland (CH)
- Czech Republic (CZ)
- Germany (DE)
- Denmark (DK)
- Estonia (EE)
- Spain (ES)
- Finland (FI)
- France (FR)
- United Kingdom (GB)
- Croatia (HR)
- Hungary (HU)
- Ireland (IE)
- India (IN)
- Italy (IT)
- Japan (JP)
- Latvia (LV)
- Netherlands (NL)
- Norway (NO)
- Poland (PL)
- Portugal (PT)
- Romania (RO)
- Serbia (RS)
- Sweden (SE)
- Singapore (SG)
- Slovakia (SK)
- United States (US)
![0](https://raw.githubusercontent.com/Ptechgithub/configs/main/media/line.gif)
### Termux

```
bash <(curl -fsSL https://raw.githubusercontent.com/bepass-org/vwarp/master/termux.sh)
```
![1](https://github.com/Ptechgithub/configs/blob/main/media/18.jpg?raw=true)

- اگه حس کردی کانکت نمیشه یا خطا میده دستور `rm -rf .cache/vwarp` رو بزن و مجدد warp رو وارد کن.
- بعد از نصب برای اجرای مجدد فقط کافیه که `warp` یا `usef` یا `./warp` یا `vwarp`را وارد کنید. همش یکیه هیچ فرقی ندارد.
- اگر با 1 نصب نشد و خطا گرفتید ابتدا یک بار 3 را بزنید تا `Uninstall` شود سپس عدد 2 رو انتخاب کنید یعنی Arm.
- برای نمایش راهنما ` warp -h` را وارد کنید. 
- ای پی و پورت `127.0.0.1:8086`پروتکل socks
- در روش تبدیل اکانت  warp به warp plus (گزینه 6) مقدار ID را وارد میکنید. پس از اجرای warp دو اکانت برای شما ساخته شده که پس از انتخاب گزینه 6 خودش مقدار ID هر دو اکانت را پیدا میکند و شما باید هر بار یکی را انتخاب کنید و یا میتوانید با انتخاب manual مقدار ID دیگری را وارد کنید (مثلا برای خود برنامه ی 1.1.1.1 یا جای دیگر) با این کار هر 20 ثانیه 1 GB به اکانت شما اضافه میشود. و اکانت شما از حالت رایگان به پلاس تبدیل میشود. 
- برای تغییر  لوکیشن با استفاده از سایفون از طریق منو یا به صورت دستی (برای مثال به USA  از دستور  زیر استفاده کنید) 
- `warp --cfon --country US`
- برای اسکن ای پی سالم وارپ از دستور `warp --scan` استفاده کنید. 
- برای ترکیب (chain) دو کانفیگ برای تغییر لوکیشن از دستور `warp --gool` استفاده کنید. 

## Documentation

- **[SOCKS5 Proxy Chaining Guide](docs/SOCKS_PROXY_GUIDE.md)** - Complete guide for double-VPN setups
- **[AtomicNoize Protocol](docs/ATOMICNOIZE_README.md)** - Advanced obfuscation protocol documentation
- **[Configuration Examples](example_config.json)** - Sample configuration files(will place later)

## Acknowledgements

- **Maintainer**: [voidreaper](https://github.com/voidr3aper-anon)
- Cloudflare Warp
- Psiphon
- WireGuard Protocol
- Original Bepass-org team
- All contributors and supporters of this project

## License

This repository is a fork of [vwarp] (MIT licensed).
Original files are © their respective authors and remain under the MIT License.
All additional changes and new files in this fork are © voidreaper and licensed under [LICENSE-GPL-3.0], see LICENSE-GPL-3.0. all new feature tricks and ideas are not allowed to copy or pull from this  repo to the main repo or other similar project unless the maintainers have granted permission.


## Moto 
 Beside Licensing , we honor the main developer of the code yousef Ghobadi ,and We coutinue the way of actively help the people access internet of freedom. We are legion. 
