# README demo image

`make_demo.py` builds the animated picture at the top of the README (`docs/demo-<lang>.webp`): a MacBook and an iPhone (6.1") running Hiddify, both going from "Tap to connect" to "Connected". It takes two recordings of the app, so it can be refreshed for every release in a few minutes.

## Update for a new version

1. Record the app connecting, on Linux desktop (X11), in light theme, one recording per language:
   - **Desktop:** app window content at **1288×803**
   - **Phone:** the same app with its window at **390×763** (the app switches to its phone layout; the iPhone status bar and home indicator are drawn by the script)

   For example, with the window's content at `X,Y` on screen:

   ```bash
   ffmpeg -f x11grab -draw_mouse 0 -framerate 12 -video_size 1288x803 -i :0.0+X,Y -t 16 frames/%03d.png
   ```

   Click the connect button about one second after the recording starts. About five seconds later, once connected, start a download through the app (for example `curl -x socks5h://127.0.0.1:12334 -o /dev/null https://ash-speed.hetzner.com/100MB.bin`) so the connect button shows its live-traffic glow until the end. Make a still image instead of a recording if you prefer: the script accepts both.
2. Pack the frames as an animated WebP and save it as `screens/desktop-<lang>.webp` / `screens/phone-<lang>.webp`, e.g. with Pillow:

   ```python
   from PIL import Image; import glob
   f = [Image.open(p).convert("RGB") for p in sorted(glob.glob("frames/*.png"))]
   f[0].save("screens/desktop-en.webp", save_all=True, append_images=f[1:], duration=83, loop=0, quality=90)
   ```

   Hide anything private (server IPs, profile names) first. Release builds have no "dev" label next to the version (the current inputs had a dev build, so the version label was removed).
3. Run, from the repository root:

   ```bash
   python3 docs/readme-demo/make_demo.py            # all languages in screens/
   python3 docs/readme-demo/make_demo.py --lang fa  # one language
   ```

4. Commit the new `docs/demo-<lang>.webp` and the inputs in `screens/`.

## Requirements

- Python 3 with Pillow: `pip install pillow`
- Google Chrome or Chromium (set `CHROME=/path/to/chrome` if it is not found)

Right-to-left languages (`fa`, `ar`, `ps`, `ur`, `he`) get a mirrored layout (iPhone on the left). The script follows the real timing of each recording on a 12 fps timeline; the first frame stays at least 0.9 s. The README files use `demo-fa.webp` for Persian and `demo-en.webp` for the other languages.
