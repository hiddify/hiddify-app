# MASQUE Noize Configuration

This guide explains how to use custom noize configurations for MASQUE QUIC obfuscation.

## Usage

To use a custom noize configuration, create a JSON file with your desired parameters and use the `--masque-noize-config` flag:

```bash
vwarp --masque --masque-noize --masque-noize-config my-config.json
```

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_pre_handshake` | boolean | true | Enable junk packets before handshake |
| `enable_post_handshake` | boolean | false | Enable junk packets after handshake |
| `pre_handshake_count` | integer | 2 | Number of junk packets before handshake |
| `post_handshake_count` | integer | 0 | Number of junk packets after handshake |
| `junk_packet_count` | integer | 2 | Total junk packets to send |
| `junk_min_size` | integer | 20 | Minimum junk packet size (bytes) |
| `junk_max_size` | integer | 50 | Maximum junk packet size (bytes) |
| `handshake_delay` | string | "10ms" | Delay before handshake |
| `junk_delay` | string | "5ms" | Delay between junk packets |
| `enable_padding` | boolean | false | Add padding to packets |
| `padding_min_size` | integer | 0 | Minimum padding size (bytes) |
| `padding_max_size` | integer | 0 | Maximum padding size (bytes) |
| `fragment_initial` | boolean | false | Fragment initial packets |
| `fragment_size` | integer | 0 | Fragment size for initial packets |
| `i1` to `i5` | integer | 32,64,128,256,512 | Signature parameters |
| `enable_debug_padding` | boolean | false | Enable debug output for padding |
| `protocols` | array | ["quic","udp"] | Supported protocols |
| `target_protocol` | string | "quic" | Target protocol to mimic |

## Example Configurations

### Light Obfuscation (Recommended for most firewalls)
```json
{
  "enable_pre_handshake": true,
  "enable_post_handshake": false,
  "pre_handshake_count": 2,
  "post_handshake_count": 0,
  "junk_packet_count": 2,
  "junk_min_size": 20,
  "junk_max_size": 50,
  "handshake_delay": "10ms",
  "junk_delay": "5ms",
  "enable_padding": false,
  "padding_min_size": 0,
  "padding_max_size": 0,
  "fragment_initial": false,
  "fragment_size": 0,
  "i1": 32,
  "i2": 64,
  "i3": 128,
  "i4": 256,
  "i5": 512,
  "enable_debug_padding": false,
  "protocols": ["quic", "udp"],
  "target_protocol": "quic"
}
```

### Heavy Obfuscation (For strict DPI)
```json
{
  "enable_pre_handshake": true,
  "enable_post_handshake": true,
  "pre_handshake_count": 4,
  "post_handshake_count": 3,
  "junk_packet_count": 7,
  "junk_min_size": 64,
  "junk_max_size": 256,
  "handshake_delay": "50ms",
  "junk_delay": "20ms",
  "enable_padding": true,
  "padding_min_size": 32,
  "padding_max_size": 128,
  "fragment_initial": true,
  "fragment_size": 512,
  "i1": 64,
  "i2": 128,
  "i3": 256,
  "i4": 512,
  "i5": 1024,
  "enable_debug_padding": false,
  "protocols": ["https", "h3", "stun"],
  "target_protocol": "https"
}
```

## Notes

- The custom config file overrides preset configurations
- If the config file fails to load, vwarp will fall back to the specified preset
- Duration values (delays) should be specified as Go duration strings (e.g., "10ms", "1s")
- Protocol mimicry helps packets look like other traffic types to bypass DPI
- Start with light obfuscation and increase complexity as needed