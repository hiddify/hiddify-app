# SOCKS5 Proxy Chaining Guide

This guide explains how to use Vwarp with SOCKS5 proxy chaining to create double-VPN configurations for enhanced privacy and censorship circumvention.

## Quick Reference

| Use Case | Command |
|----------|---------|
| Basic proxy chaining | `Vwarp --proxy socks5://127.0.0.1:1080` |
| With AtomicNoize | `Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable` |
| Maximum privacy | `Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable --atomicnoize-junk-size 50` |
| Through SSH tunnel | `ssh -D 1080 -N user@server` then `Vwarp --proxy socks5://127.0.0.1:1080` |
| With Psiphon | `Vwarp --cfon --country US --proxy socks5://127.0.0.1:1080` |
| Scan through proxy | `Vwarp --proxy socks5://127.0.0.1:1080 --scan --rtt 800ms` |

## Table of Contents

- [Overview](#overview)
- [Use Cases](#use-cases)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Overview

SOCKS5 proxy chaining allows you to route your WireGuard/WARP traffic through another VPN or proxy server, creating a "double-VPN" configuration. This adds an extra layer of privacy and can help bypass advanced censorship systems.

### Traffic Flow

```
Your Application
       ↓
   WARP SOCKS5 Proxy (127.0.0.1:8086)
       ↓
   WireGuard (with AtomicNoize)
       ↓
   SOCKS5 Proxy (Your VPN/Proxy)
       ↓
   Internet
```

### Supported Features

- ✅ IPv4 and IPv6 support
- ✅ UDP ASSOCIATE for WireGuard protocol
- ✅ Compatible with any SOCKS5 proxy
- ✅ Works with AtomicNoize obfuscation
- ✅ No authentication required (no-auth method)
- ✅ Automatic relay address resolution

## Use Cases

### 1. Bypass Advanced Censorship

Chain WARP through a local VPN to hide WireGuard traffic patterns:

```bash
Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable --bind 127.0.0.1:8086
```

### 2. Change Exit Location

Use WARP for speed while routing through a specific geographic location:

```bash
# First VPN in Japan (SOCKS5 on port 1080)
# WARP exit in US
Vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086
```

### 3. Corporate Network Traversal

Route WARP through corporate proxy:

```bash
Vwarp --proxy socks5://proxy.company.com:1080 --bind 127.0.0.1:8086
```

### 4. Triple-VPN with Psiphon

Combine Psiphon, WARP, and external proxy:

```bash
Vwarp --cfon --country US --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086
```

## Quick Start

### Prerequisites

1. A running SOCKS5 proxy (VPN, SSH tunnel, or proxy service)
2. Vwarp installed
3. Basic understanding of proxy configuration

### Basic Setup

1. **Start your SOCKS5 proxy** (e.g., OpenVPN, SSH tunnel, or WireGuard)

2. **Run Vwarp with proxy flag**:
   ```bash
   Vwarp --proxy socks5://127.0.0.1:1080
   ```

3. **Configure your applications** to use WARP SOCKS5 proxy:
   ```
   SOCKS5: 127.0.0.1:8086
   ```

### Example: SSH Tunnel as Proxy

Create a SOCKS5 proxy using SSH:

```bash
# Create SSH tunnel (SOCKS5 proxy on port 1080)
ssh -D 1080 -N user@your-server.com

# Run Vwarp through the tunnel
Vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086 --verbose
```

### Example: OpenVPN + WARP

```bash
# Start OpenVPN (creates tun0 interface)
sudo openvpn --config vpn.ovpn

# Run SOCKS5 proxy on VPN interface
ssh -D 127.0.0.1:1080 -N user@localhost

# Chain WARP through the proxy
Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable
```

## Configuration

### Command Line

```bash
Vwarp --proxy socks5://HOST:PORT [other-options]
```

**Proxy Format Options:**
- `socks5://127.0.0.1:1080` - Full SOCKS5 URL
- `127.0.0.1:1080` - Host and port only
- `localhost:1080` - Hostname with port
- `proxy.example.com:1080` - Remote proxy

**Default port**: If no port specified, defaults to 1080

### Configuration File

Create a JSON configuration file:

```json
{
  "proxy": "socks5://127.0.0.1:1080",
  "bind": "127.0.0.1:8086",
  "verbose": true,
  "atomicnoize-enable": true,
  "atomicnoize-packet-size": 1280,
  "atomicnoize-offset": 8
}
```

Run with config:
```bash
Vwarp --config myconfig.json
```

### Combining with AtomicNoize

For maximum obfuscation, combine proxy chaining with AtomicNoize:

```bash
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --atomicnoize-packet-size 1280 \
  --atomicnoize-offset 8 \
  --atomicnoize-junk-size 50 \
  --verbose
```

This creates three layers:
1. **AtomicNoize**: Obfuscates WireGuard packets
2. **SOCKS5 Tunnel**: Routes through your VPN/proxy
3. **WARP**: Final encryption and exit point

## Advanced Usage

### Testing Proxy Connection

Enable verbose mode to see connection details:

```bash
Vwarp --proxy socks5://127.0.0.1:1080 --verbose
```

Look for these log messages:
```
[PROXY] Establishing UDP association to 127.0.0.1:1080
[PROXY] UDP association established, relay: 127.0.0.1:10808
UDP bind has been updated
```

### Custom Endpoints

Specify WARP endpoints with proxy:

```bash
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --endpoint 162.159.192.1:500 \
  --bind 127.0.0.1:8086
```

### Scan for Best Endpoint Through Proxy

```bash
Vwarp --proxy socks5://127.0.0.1:1080 --scan --rtt 800ms
```

### Multi-Instance Setup

Run multiple WARP instances through different proxies:

```bash
# Instance 1: Through SSH tunnel on US server
Vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086 --cache-dir ~/.cache/warp1

# Instance 2: Through SSH tunnel on EU server
Vwarp --proxy socks5://127.0.0.1:1081 --bind 127.0.0.1:8087 --cache-dir ~/.cache/warp2
```

### Warp-in-Warp with Proxy

Chain WARP instances with external proxy:

```bash
# First WARP instance through proxy
Vwarp --proxy socks5://127.0.0.1:1080 --bind 127.0.0.1:8086

# Second WARP instance through first WARP
Vwarp --gool --bind 127.0.0.1:8087
```

## Troubleshooting

### Connection Issues

**Problem**: `proxy not initialized` or `dial: connection refused`

**Solutions**:
1. Verify SOCKS5 proxy is running:
   ```bash
   netstat -an | grep 1080
   ```

2. Test proxy with curl:
   ```bash
   curl -x socks5://127.0.0.1:1080 https://ifconfig.me
   ```

3. Check proxy supports UDP ASSOCIATE:
   - Some proxies only support TCP CONNECT
   - WireGuard requires UDP support

### UDP Association Errors

**Problem**: `Failed to establish UDP association`

**Solutions**:
1. Ensure proxy supports SOCKS5 UDP ASSOCIATE (not all do)
2. Try different proxy software (e.g., SSH dynamic forwarding, Dante, Shadowsocks)
3. Check firewall rules allow UDP traffic

### Slow Performance

**Problem**: High latency or packet loss

**Solutions**:
1. Test proxy latency:
   ```bash
   Vwarp --proxy socks5://127.0.0.1:1080 --test-url http://connectivity.cloudflareclient.com/cdn-cgi/trace
   ```

2. Try different WARP endpoints:
   ```bash
   Vwarp --proxy socks5://127.0.0.1:1080 --scan --rtt 500ms
   ```

3. Optimize AtomicNoize settings:
   ```bash
   Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable --atomicnoize-packet-size 1400
   ```

### IPv6 Errors

**Problem**: `Failed to send data packets: IPv6 not supported` (older versions)

**Solution**: Update to latest version - IPv6 is fully supported in current builds.

### DNS Resolution Issues

**Problem**: DNS lookups fail or timeout

**Solutions**:
1. Specify custom DNS:
   ```bash
   Vwarp --proxy socks5://127.0.0.1:1080 --dns 8.8.8.8
   ```

2. Use proxy DNS resolution
3. Check DNS is not blocked in proxy chain

### Debugging

Enable verbose logging to diagnose issues:

```bash
Vwarp --proxy socks5://127.0.0.1:1080 --verbose 2>&1 | tee warp-debug.log
```

Check for:
- `[PROXY] Establishing UDP association` - Connection attempt
- `[PROXY] UDP association established` - Success
- `UDP bind has been updated` - WireGuard using proxy
- `Received handshake response` - WARP connected

## Security Considerations

### Privacy

**Double-VPN Advantages**:
- VPN provider cannot see your WARP traffic
- Cloudflare cannot see your real IP (only VPN IP)
- Extra layer of encryption
- More difficult to correlate traffic

**Privacy Tips**:
- Use no-log VPN providers for first hop
- Combine with AtomicNoize for packet obfuscation
- Rotate VPN servers regularly
- Use different VPN provider than WARP

### Trust Model

**Traffic Visibility**:
```
Your Device: See everything
     ↓
SOCKS5 Proxy: See obfuscated WireGuard packets (with AtomicNoize)
     ↓
Cloudflare: See decrypted traffic (like normal WARP)
     ↓
Destination: See traffic from Cloudflare IP
```

**Trust Requirements**:
- Trust your SOCKS5 proxy provider (they see packet metadata)
- Trust Cloudflare (they decrypt WARP traffic)
- AtomicNoize hides WireGuard patterns from proxy

### Performance Impact

**Latency**:
- Adds 10-50ms depending on proxy location
- Use local proxies or fast VPN servers
- Test with `--scan` to find optimal endpoints

**Bandwidth**:
- Minimal overhead (<5%)
- AtomicNoize adds small padding
- SOCKS5 header is only 10-22 bytes per packet

### Recommended Configurations

**Maximum Privacy**:
```bash
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --atomicnoize-packet-size 1280 \
  --atomicnoize-offset 8 \
  --atomicnoize-junk-size 50 \
  --verbose
```

**Best Performance**:
```bash
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --endpoint <scanned-optimal-endpoint> \
  --atomicnoize-enable \
  --atomicnoize-packet-size 1400
```

**Balanced**:
```bash
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --scan \
  --rtt 500ms
```

## Common Proxy Software Compatibility

### Supported (UDP ASSOCIATE)

✅ **SSH Dynamic Forwarding**
```bash
ssh -D 1080 -N user@server
```

✅ **Dante SOCKS Server**
```bash
sockd -D
```

✅ **Shadowsocks**
```bash
ss-local -c config.json
```

✅ **V2Ray/Xray**
```json
{
  "inbounds": [{
    "port": 1080,
    "protocol": "socks",
    "settings": {"udp": true}
  }]
}
```

### Limited Support

⚠️ **HTTP Proxies**: Not compatible (no UDP)

⚠️ **Some VPN clients**: May not expose SOCKS5 interface

⚠️ **TOR**: SOCKS5 available but UDP blocked by default

## Examples

### Example 1: SSH Tunnel + WARP + AtomicNoize

```bash
# Terminal 1: Create SSH tunnel
ssh -D 1080 -N -C user@remote-server.com

# Terminal 2: Run WARP through tunnel
Vwarp \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --bind 127.0.0.1:8086 \
  --verbose

# Configure browser: SOCKS5 127.0.0.1:8086
```

### Example 2: Shadowsocks + WARP

```bash
# Terminal 1: Start Shadowsocks client
ss-local -c ss-config.json -l 1080

# Terminal 2: WARP through Shadowsocks
Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable

# Result: Shadowsocks obfuscation + WARP speed
```

### Example 3: WireGuard VPN + WARP

```bash
# Terminal 1: Start WireGuard
sudo wg-quick up wg0

# Terminal 2: SOCKS proxy on WireGuard interface
ssh -D 127.0.0.1:1080 -N user@10.0.0.1

# Terminal 3: Chain WARP
Vwarp --proxy socks5://127.0.0.1:1080 --atomicnoize-enable
```

### Example 4: Psiphon + External Proxy + WARP

```bash
# Chain three layers for maximum censorship resistance
Vwarp \
  --cfon --country US \
  --proxy socks5://127.0.0.1:1080 \
  --atomicnoize-enable \
  --atomicnoize-junk-size 50 \
  --verbose

# Traffic flow: Device → Psiphon → SOCKS5 Proxy → WARP → Internet
```

## Additional Resources

- [AtomicNoize Protocol Guide](ATOMICNOIZE_GUIDE.md)
- [Main README](README.md)
- [WireGuard Documentation](https://www.wireguard.com/)
- [SOCKS5 RFC 1928](https://www.rfc-editor.org/rfc/rfc1928)

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Enable `--verbose` logging
3. Test proxy independently with curl/netcat
4. Verify UDP support in your proxy
5. Check firewall rules
6. Open an issue on GitHub with debug logs

---

**Maintainer**: [voidreaper](https://github.com/voidr3aper-anon)
