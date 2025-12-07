# AtomicNoize Protocol - WireGuard Obfuscation

## 🔒 What is AtomicNoize?

AtomicNoize is an advanced WireGuard obfuscation protocol that makes your VPN traffic look like regular internet traffic, helping bypass Deep Packet Inspection (DPI) and network censorship. It's specifically designed to work with Cloudflare WARP endpoints.

---

## ✨ Key Features

### 🎭 Protocol Imitation
- **IKEv2/IPsec Mimicry**: Wraps packets in special headers to disguise WireGuard traffic as IPsec/IKEv2 VPN traffic
- **Signature Packets (I1-I5)**: Sends configurable signature packets that mimic legitimate VPN handshakes

### 🌊 Traffic Obfuscation
- **Junk Packets**: Sends random noise packets to confuse DPI systems
- **Flexible Timing**: Control when junk packets are sent (before/after handshake, after signature packets)
- **Variable Packet Sizes**: Randomize junk packet sizes between configurable min/max values

### 🔌 Same-Port Architecture
- Ensures NAT/firewall compatibility
- Prevents source port fingerprinting

---

## 📋 Configuration Options

### Basic Setup

```json
{
  "atomicnoize-enable": true,
  "endpoint": "162.159.192.1:500",
  "atomicnoize-i1": "<b 0xc200...>"
}
```

### Complete Configuration Reference

#### 🔧 Core Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `atomicnoize-enable` | boolean | `false` | Enable/disable AtomicNoize obfuscation |

#### 📝 Signature Packets

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `atomicnoize-i1` | string | `""` | Main noise signature packet (CPS format). **Required!** |
| `atomicnoize-i2` | string | `"1"` | Second signature packet (simple number or CPS format) |
| `atomicnoize-i3` | string | `"2"` | Third signature packet |
| `atomicnoize-i4` | string | `"3"` | Fourth signature packet |
| `atomicnoize-i5` | string | `"4"` | Fifth signature packet |

#### 🎲 Junk Packets

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `atomicnoize-jc` | integer | `4` | **Total** number of junk packets (0-128) |
| `atomicnoize-jmin` | integer | `40` | Minimum junk packet size in bytes |
| `atomicnoize-jmax` | integer | `70` | Maximum junk packet size in bytes |

#### ⏱️ Timing Control

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `atomicnoize-jc-after-i1` | integer | `0` | Junk packets sent **immediately after** I1 signature |
| `atomicnoize-jc-before-hs` | integer | `0` | Junk packets sent **before** WireGuard handshake |
| `atomicnoize-junk-interval` | duration | `10ms` | Delay between junk packets (e.g., `10ms`, `50ms`, `100ms`) |
| `atomicnoize-handshake-delay` | duration | `0ms` | Delay before WireGuard handshake starts (e.g., `50ms`, `100ms`) |

#### 🚫 Advanced Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `atomicnoize-allow-zero-size` | boolean | `false` | Allow 0-byte junk packets (experimental, may not work everywhere) |
| `atomicnoize-s1` | integer | `0` | ⚠️ **Disabled** - Init packet prefix (breaks WARP compatibility) |
| `atomicnoize-s2` | integer | `0` | ⚠️ **Disabled** - Response packet prefix (breaks WARP compatibility) |

---

## 🎯 Usage Examples

### Example 1: Basic Obfuscation
**Simple setup with 10 junk packets**

```json
{
  "bind": "127.0.0.1:8086",
  "endpoint": "162.159.192.1:500",
  "atomicnoize-enable": true,
  "atomicnoize-i1": "<your-i1-packet>",
  "atomicnoize-jc": 10,
  "atomicnoize-jmin": 20,
  "atomicnoize-jmax": 100
}
```

**Packet Flow:**
```
1. I1 packet
2. I2-I5 packets
3. 10 junk packets (random 20-100 bytes each)
4. WireGuard handshake
```

---

### Example 2: Split Junk Packets
**Send junk packets at different stages**

```json
{
  "atomicnoize-enable": true,
  "atomicnoize-i1": "<your-i1-packet>",
  "atomicnoize-jc": 20,
  "atomicnoize-jc-after-i1": 5,
  "atomicnoize-jc-before-hs": 8,
  "atomicnoize-jmin": 10,
  "atomicnoize-jmax": 50
}
```

**Packet Flow:**
```
1. I1 packet
2. 5 junk packets (after I1)
3. 8 junk packets (before handshake)
4. I2-I5 packets
5. WireGuard handshake
6. 7 junk packets (20 total - 5 - 8 = 7 remaining, sent after handshake)
```

---

### Example 3: Stealthy Configuration
**Slow, randomized traffic pattern**

```json
{
  "atomicnoize-enable": true,
  "atomicnoize-i1": "<your-i1-packet>",
  "atomicnoize-jc": 15,
  "atomicnoize-jc-before-hs": 10,
  "atomicnoize-jmin": 50,
  "atomicnoize-jmax": 150,
  "atomicnoize-junk-interval": "100ms",
  "atomicnoize-handshake-delay": "200ms"
}
```

**What it does:**
- Sends 10 junk packets **before** handshake with 100ms delay between each
- Waits 200ms before starting WireGuard handshake
- Sends 5 remaining junk packets **after** handshake
- All junk packets are between 50-150 bytes

**Best for:** Evading timing-based DPI detection

---

### Example 4: Zero-byte Junk (Experimental)
**Minimal packet sizes**

```json
{
  "atomicnoize-enable": true,
  "atomicnoize-i1": "<your-i1-packet>",
  "atomicnoize-jc": 12,
  "atomicnoize-jmin": 0,
  "atomicnoize-jmax": 0,
  "atomicnoize-allow-zero-size": true
}
```

**Note:** May not work with all UDP implementations. If connection fails, set `atomicnoize-allow-zero-size: false` (will send 1-byte minimum).

---

## 🔄 Packet Flow Explained

### Standard Flow (with AtomicNoize enabled)

```
┌─────────────────────────────────────────────────────┐
│ 1. I1 Signature Packet (IKEv2 wrapped)             │
│    └─> 52-byte IKEv2 header + payload              │
├─────────────────────────────────────────────────────┤
│ 2. Junk Packets (if jc-after-i1 > 0)              │
│    └─> Random noise, configurable size             │
├─────────────────────────────────────────────────────┤
│ 3. Junk Packets (if jc-before-hs > 0)             │
│    └─> More random noise                            │
├─────────────────────────────────────────────────────┤
│ 4. I2, I3, I4, I5 Signature Packets                │
│    └─> Additional protocol imitation                │
├─────────────────────────────────────────────────────┤
│ 5. Delay (if handshake-delay > 0)                  │
│    └─> Pause before handshake                       │
├─────────────────────────────────────────────────────┤
│ 6. WireGuard Handshake Initiation                  │
│    └─> Standard WireGuard protocol (type 1)        │
├─────────────────────────────────────────────────────┤
│ 7. Remaining Junk Packets (auto-calculated)        │
│    └─> (jc - jc-after-i1 - jc-before-hs)          │
└─────────────────────────────────────────────────────┘
```

### Junk Packet Distribution Formula

```
Total Junk (jc) = jc-after-i1 + jc-before-hs + (sent after handshake)

Example:
jc = 20
jc-after-i1 = 3
jc-before-hs = 5

After handshake: 20 - 3 - 5 = 12 packets
```

---

## 🚀 Command Line Usage

### Run with Config File
```bash
./Vwarp --config config.json
```

### Run with Command Line Flags
```bash
./Vwarp \
  --atomicnoize-enable \
  --atomicnoize-i1 "<b 0xc200...>" \
  --atomicnoize-jc 15 \
  --atomicnoize-jmin 30 \
  --atomicnoize-jmax 100 \
  --atomicnoize-jc-before-hs 10 \
  --atomicnoize-junk-interval 20ms \
  --endpoint 162.159.192.5:500
```

### Enable Verbose Logging
```bash
./Vwarp --config config.json --verbose
```

**Tip:** Use verbose mode to see detailed packet flow in logs

---

## 🔍 How It Works

### 1. IKEv2 Header Wrapping
AtomicNoize wraps the I1 packet in a 52-byte IKEv2 header structure:

```
┌──────────────────────────────────────┐
│ IKEv2 Header (28 bytes)              │
│  - Initiator SPI: 8 bytes            │
│  - Responder SPI: 8 bytes            │
│  - Version: 0x20 (IKEv2)             │
│  - Exchange Type: 0x22 (IKE_SA_INIT) │
│  - Flags: 0x08 (Initiator)           │
│  - Message ID: 0                      │
│  - Length: calculated                 │
├──────────────────────────────────────┤
│ SA Payload Header (24 bytes)         │
│  - Next Payload: 0                    │
│  - Flags: 0                           │
│  - Length: calculated                 │
│  - DOI, Situation, etc.               │
├──────────────────────────────────────┤
│ Original I1 Packet Data               │
│  (your configured payload)            │
└──────────────────────────────────────┘
```

This makes WireGuard traffic appear as IPsec/IKEv2 VPN negotiation to DPI systems.

.
---

## ⚠️ Important Notes

### S1/S2 Prefixes (Disabled)
- `atomicnoize-s1` and `atomicnoize-s2` are **disabled** by design
- These would add random prefixes to WireGuard packets themselves
- ❌ This breaks Cloudflare WARP compatibility
- ✅ AtomicNoize uses surrounding junk packets instead

### Port Selection
- Use port `500` for IKEv2 mimicry (default IPsec port)
- Example: `"endpoint": "162.159.192.5:500"`

### I1 Packet Requirement
- The `atomicnoize-i1` packet is **required** for obfuscation to work
- Must be in CPS format: `<b 0xhexdata>`
- Get this from a working Amnezia configuration

---

## 🐛 Troubleshooting

### Connection Fails
**Problem:** VPN doesn't connect with AtomicNoize enabled

**Solutions:**
1. Set `atomicnoize-allow-zero-size: false` if using zero-byte junk
2. Reduce junk packet count: `"atomicnoize-jc": 5`
3. Check I1 packet is valid CPS format
4. Try without handshake delay: `"atomicnoize-handshake-delay": "0ms"`

### Slow Connection
**Problem:** Connection works but is very slow

**Solutions:**
1. Reduce junk interval: `"atomicnoize-junk-interval": "1ms"`
2. Reduce total junk packets: `"atomicnoize-jc": 4`
3. Remove handshake delay: `"atomicnoize-handshake-delay": "0ms"`

### Still Blocked
**Problem:** Traffic is still being detected/blocked

**Solutions:**
1. Increase junk packets: `"atomicnoize-jc": 20`
2. Add delays: `"atomicnoize-handshake-delay": "100ms"`
3. Use split junk timing: Configure `jc-after-i1` and `jc-before-hs`
4. Increase packet size variation: Set larger gap between `jmin` and `jmax`

---

## 📊 Performance Impact

| Configuration | Handshake Overhead | Throughput Impact | Detection Resistance |
|---------------|-------------------|-------------------|---------------------|
| Minimal (jc=4, no delays) | ~50ms | Negligible | Low |
| Moderate (jc=10, 10ms intervals) | ~200ms | <5% | Medium |
| Aggressive (jc=20, 50ms intervals) | ~1500ms | <10% | High |
| Maximum (jc=50, 100ms intervals) | ~5000ms | ~15% | Very High |

**Recommendation:** Start with moderate settings and adjust based on blocking severity.

---

## 🎓 Advanced Tips

### 1. Dynamic Configuration
Adjust settings based on network conditions:
- **High censorship:** Increase junk packets and delays
- **Low censorship:** Minimize overhead for better performance

### 2. Packet Size Strategy
```json
{
  "atomicnoize-jmin": 40,
  "atomicnoize-jmax": 1400
}
```
Large variation makes traffic harder to profile.

### 3. Multi-Stage Junk
```json
{
  "atomicnoize-jc": 30,
  "atomicnoize-jc-after-i1": 10,
  "atomicnoize-jc-before-hs": 10
}
```
Distributes junk across connection lifecycle (10 after I1, 10 before HS, 10 after HS).

### 4. Timing Randomization
While not directly configurable, the implementation adds small random variations to timing automatically.

---

## 📚 Technical Specifications

- **IKEv2 Header Size:** 28 bytes
removed for security considerations
---

## 🤝 Contributing

Found a bug or have a suggestion? Please open an issue!

---

## 📄 License

See LICENSE file for details.

---

## 🙏 Credits

AtomicNoize protocol inspired by Amnezia WireGuard obfuscation techniques, adapted specifically for Cloudflare WARP compatibility By voidreaper-anon.

---

**Happy secure browsing! may the anonymous be with you🚀🔒**
