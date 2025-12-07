# MASQUE Noize Configuration Examples

This directory contains ready-to-use MASQUE noize configuration files for different scenarios.

## Available Configurations

### `basic-obfuscation.json`
- **Use case**: Most firewalls and basic DPI
- **Overhead**: Low (~20ms latency, ~5% bandwidth)
- **Features**: 2 junk packets, minimal delays, QUIC mimicry

### `moderate-obfuscation.json`  
- **Use case**: Corporate firewalls and moderate DPI
- **Overhead**: Medium (~50ms latency, ~15% bandwidth)
- **Features**: 3 junk packets, HTTPS mimicry, light padding

### `heavy-obfuscation.json`
- **Use case**: Strict censorship and advanced DPI
- **Overhead**: High (~150ms latency, ~30% bandwidth)  
- **Features**: 6 junk packets, fragmentation, heavy randomization, SNI fragmentation

## Usage

```bash
# Use a specific configuration
vwarp --masque --masque-noize --masque-noize-config docs/examples/basic-obfuscation.json

# Test different levels
vwarp --masque --masque-noize --masque-noize-config docs/examples/moderate-obfuscation.json
vwarp --masque --masque-noize --masque-noize-config docs/examples/heavy-obfuscation.json
```

## Customization

Copy any example file and modify parameters as needed:
- Increase `Jc` (junk packet count) for more obfuscation
- Adjust `HandshakeDelay` for timing changes  
- Change `MimicProtocol` to "dns", "stun", etc.
- Enable `FragmentInitial` for packet splitting
- Add `PaddingMin`/`PaddingMax` for size obfuscation

See the [MASQUE Noize Guide](../MASQUE_NOIZE_GUIDE.md) for detailed parameter explanations.