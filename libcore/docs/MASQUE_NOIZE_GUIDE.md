# MASQUE Noize Obfuscation Guide

## Overview

MASQUE Noize is a sophisticated packet obfuscation system designed to bypass Deep Packet Inspection (DPI) and censorship mechanisms. It works by disguising QUIC traffic patterns, making encrypted tunnels appear as legitimate web traffic to network monitoring systems.

## How It Works

### Core Concepts

**Noize** operates at the UDP packet level, transforming QUIC handshake patterns through several techniques:

1. **Junk Packet Injection**: Sends decoy packets before, during, and after the real handshake
2. **Protocol Mimicry**: Makes traffic appear as HTTP/HTTPS, DNS, or STUN protocols
3. **Timing Obfuscation**: Introduces controlled delays to break fingerprinting patterns
4. **Packet Fragmentation**: Splits initial packets to avoid signature detection
5. **Padding**: Adds random data to alter packet size patterns

### Technical Implementation

```
Original QUIC Flow:
Client ──[Initial]──> Server
Client <──[Response]── Server
Client ──[1-RTT]────> Server

Noize-Obfuscated Flow:
Client ──[Junk1]────> Server (ignored)
Client ──[Junk2]────> Server (ignored) 
Client ──[Initial*]──> Server (fragmented/padded)
Client <──[Response]── Server
Client ──[Junk3]────> Server (ignored)
Client ──[1-RTT]────> Server
```

## Configuration

### Quick Start

**Using Presets** (Recommended):
```bash
# Light obfuscation (fastest, works with most firewalls)
vwarp --masque --masque-noize --masque-noize-preset light

# Heavy obfuscation (slower, bypasses strict DPI)
vwarp --masque --masque-noize --masque-noize-preset heavy

# GFW bypass (optimized for China's Great Firewall)
vwarp --masque --masque-noize --masque-noize-preset gfw
```

**Available Presets**:
- `light` - Minimal overhead, basic DPI evasion
- `medium` - Balanced performance and obfuscation  
- `heavy` - Maximum obfuscation for strict censorship
- `stealth` - Advanced evasion with protocol mimicry
- `gfw` - Optimized for Great Firewall bypass
- `firewall` - Corporate firewall circumvention

### Custom Configuration

For advanced users requiring fine-tuned parameters:

```bash
vwarp --masque --masque-noize --masque-noize-config custom-config.json
```

#### Sample Configuration

```json
{
  "Jc": 3,
  "Jmin": 40,
  "Jmax": 80,
  "JcBeforeHS": 2,
  "JcDuringHS": 1,
  "JcAfterHS": 0,
  "JunkInterval": "15ms",
  "HandshakeDelay": "25ms",
  "MimicProtocol": "https",
  "FragmentInitial": false,
  "FragmentSize": 0,
  "PaddingMin": 0,
  "PaddingMax": 0,
  "RandomDelay": false
}
```

#### Parameter Reference

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `Jc` | Total junk packets to send | 2 | 0-20 |
| `JcBeforeHS` | Junk packets before handshake | 2 | 0-Jc |
| `JcDuringHS` | Junk packets during handshake | 0 | 0-Jc |
| `JcAfterHS` | Junk packets after handshake | 0 | 0-Jc |
| `Jmin`/`Jmax` | Junk packet size range (bytes) | 20/50 | 1-1400 |
| `JunkInterval` | Delay between junk packets | "10ms" | "1ms"-"1s" |
| `HandshakeDelay` | Delay before real handshake | "10ms" | "0s"-"1s" |
| `MimicProtocol` | Protocol to imitate | "quic" | quic, https, dns, stun |
| `FragmentInitial` | Split initial packets | false | true/false |
| `FragmentSize` | Fragment size in bytes | 0 | 0-1200 |
| `PaddingMin`/`PaddingMax` | Padding range (bytes) | 0/0 | 0-256 |
| `RandomDelay` | Randomize packet timing | false | true/false |

### Example Configurations

Ready-to-use configuration files are available in `docs/examples/`:

- **`basic-obfuscation.json`** - Simple, low-overhead configuration
- **`moderate-obfuscation.json`** - Balanced performance and effectiveness  
- **`heavy-obfuscation.json`** - Maximum obfuscation for strict censorship

```bash
# Use example configuration
vwarp --masque --masque-noize --masque-noize-config docs/examples/basic-obfuscation.json
```

## Performance Impact

| Preset | Latency Overhead | Bandwidth Overhead | Success Rate |
|--------|------------------|-------------------|--------------|
| `light` | +20-50ms | +5-10% | 85% |
| `medium` | +50-100ms | +10-20% | 90% |
| `heavy` | +100-200ms | +20-40% | 95% |
| `stealth` | +200-300ms | +30-50% | 98% |

## Troubleshooting

### Common Issues

**Connection Timeouts**:
- Try reducing `HandshakeDelay` and `JunkInterval`
- Decrease total junk packet count (`Jc`)
- Switch to lighter preset

**Still Blocked**:
- Increase obfuscation level (try `heavy` or `stealth`)
- Enable packet fragmentation (`FragmentInitial: true`)
- Add padding (`PaddingMin`/`PaddingMax`)
- Change protocol mimicry (`MimicProtocol: "https"`)

**High Latency**:
- Use `light` preset
- Reduce `HandshakeDelay`
- Disable `RandomDelay`
- Minimize junk packet count

### Debugging

Enable verbose logging to analyze obfuscation behavior:

```bash
vwarp --masque --masque-noize --masque-noize-preset medium --verbose
```

Look for these log messages:
- `"Loading custom MASQUE noize configuration"` - Custom config loaded
- `"Using MASQUE noize preset configuration"` - Preset selected
- `"Using noize obfuscation for MASQUE connection"` - Obfuscation active

## Security Considerations

### Threat Model

Noize defends against:
- ✅ Statistical traffic analysis
- ✅ Protocol fingerprinting
- ✅ Timing correlation attacks
- ✅ Packet size analysis
- ✅ Handshake pattern detection

Noize does NOT protect against:
- ❌ Content inspection (traffic is still encrypted)
- ❌ Endpoint correlation (IP addresses visible)
- ❌ Flow correlation over long periods
- ❌ Advanced ML-based detection (future threat)

### Best Practices

1. **Rotate configurations**: Change noize parameters periodically
2. **Monitor effectiveness**: Test connection success rates
3. **Layer defenses**: Combine with VPN/proxy chains
4. **Update regularly**: Keep vwarp updated for latest evasion techniques

## Development Notes

### Algorithm Details

The noize system implements a multi-stage obfuscation pipeline:

1. **Pre-handshake Phase**: Injects configurable junk packets
2. **Handshake Interception**: Modifies timing and packet structure
3. **Post-handshake Phase**: Continues obfuscation as needed
4. **Protocol Shaping**: Applies specific protocol mimicry patterns

### Extensibility

New obfuscation techniques can be added by:
- Extending the `NoizeConfig` struct
- Implementing handlers in `ObfuscateWrite()`
- Adding protocol patterns in `applyProtocolMimicry()`

## Contributing

When contributing to noize functionality:
1. Test against multiple DPI systems
2. Benchmark performance impact
3. Document new parameters thoroughly
4. Consider backward compatibility

---

**Note**: This obfuscation adds latency and bandwidth overhead. Use the lightest effective configuration for your environment.