# iOS connection status rendering

On WIR Baseline 0.0.1 (11), the device's safe report showed
`data / connected / connected`, with an iOS theme and no reconnect request,
while the user still saw Connecting after returning from diagnostics to Home.
The report's `tickers_enabled=false` was recorded while Settings was open;
it does not prove that tickers were muted while Home was visible.

The existing AnimatedSwitcher retains an outgoing label when ticker callbacks
are muted. A widget test reproduces Connecting remaining alongside Connected
under TickerMode(false). Normal route activation and lifecycle tests catch up;
the cause of the persistent device freeze has not been reproduced locally.

On iOS only, render the selected connection label directly as Text using the
same titleMedium style. This removes animation progress from status rendering.
State selection, accessibility label, actions, latency, and tunnel behavior
remain unchanged. Other platforms keep AnimatedText.

Behavior checks inspect actual RichText contents after one frame without
animation ticks, including Connected, Disconnected and Disconnecting. An
Android control preserves its outgoing and incoming animated labels. The
existing button and presentation contracts cover label priority and actions.

Physical acceptance remains required on the exact released build: connect,
lock for 60 seconds, unlock without pressing VPN, and confirm the visible Home
label agrees with iOS VPN state immediately and after 30 seconds.
