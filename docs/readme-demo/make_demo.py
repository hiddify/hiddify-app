#!/usr/bin/env python3
"""Build the animated README demo (a MacBook and an iPhone running Hiddify) from two screen recordings.

usage (from the repository root):
    python3 docs/readme-demo/make_demo.py            # every language that has inputs in screens/
    python3 docs/readme-demo/make_demo.py --lang fa  # one language

Inputs (docs/readme-demo/screens/), a still image or an animation (animated WebP/GIF/PNG):
    desktop-<lang>.*   the desktop app window content, no title bar, about 1288x803
    phone-<lang>.*     the app in phone layout, 390x763 (an iPhone 6.1" screen without status bar
                       and home-indicator areas, which are drawn here)
Output: docs/demo-<lang>.webp (animated when an input is animated)

Needs Python 3 with Pillow (pip install pillow) and Google Chrome or Chromium
(set CHROME=/path/to/chrome if it is not found). Right-to-left languages get a mirrored layout.
"""
import argparse, glob, json, os, re, shutil, subprocess, sys, tempfile

try:
    from PIL import Image, ImageDraw, ImageSequence
except ImportError:
    sys.exit("Pillow is needed: pip install pillow")

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
RTL = {"fa", "ar", "ps", "ur", "he"}
W, H, SCALE = 2400, 1500, 2          # canvas in CSS px, rendered at 2x
OUT_W = 1600                         # width of the final image
HOLD_FIRST, HOLD_LAST = 900, 600    # ms the first and last frames stay on screen


def chrome():
    for c in (os.environ.get("CHROME"), "google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome",
              "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"):
        if c and (shutil.which(c) or os.path.exists(c)):
            return shutil.which(c) or c
    sys.exit("Chrome/Chromium not found: set CHROME=/path/to/chrome")


def find(lang, kind):
    for p in sorted(glob.glob(os.path.join(HERE, "screens", f"{kind}-{lang}.*"))):
        if p.rsplit(".", 1)[-1].lower() in ("png", "webp", "gif", "jpg", "jpeg"):
            return p
    return None


TICK = 83  # ms, the timeline step (12 frames per second)


def frames(path):
    """The input as one entry per TICK: a still image is one entry, an animation repeats each frame for its duration."""
    im = Image.open(path)
    out = []
    for i in range(getattr(im, "n_frames", 1)):
        im.seek(i)
        im.load()
        f = im.convert("RGB")
        out += [f] * max(1, round((im.info.get("duration") or TICK) / TICK))
    return out


def hexc(rgb):
    return "#%02x%02x%02x" % rgb[:3]


def page(rtl, top_color, bottom_color, logo):
    sl, sr = ("right", "left") if rtl else ("left", "right")
    return f'''<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}} html,body{{margin:0;width:{W}px;height:{H}px;background:#fff;overflow:hidden}}
.floor{{position:absolute;left:160px;right:160px;top:1300px;height:80px;border-radius:50%;
  background:radial-gradient(ellipse at center,rgba(20,20,40,.22),rgba(20,20,40,0) 70%);filter:blur(6px)}}
.lap{{position:absolute;{sl}:110px;top:110px;width:1760px}}
.lid{{position:relative;margin:0 70px;background:#0b0b0d;border-radius:44px 44px 14px 14px;padding:26px 26px 34px;
  box-shadow:inset 0 0 0 3px #2a2a2e,0 2px 0 #9a9aa0}}
.cam{{position:absolute;left:50%;top:9px;width:10px;height:10px;margin-left:-5px;border-radius:50%;background:#1d2733}}
.scr{{position:relative;height:1018px;border-radius:12px;overflow:hidden;background:#1a1446}}
.wall{{position:absolute;inset:0}}
.menu{{position:absolute;left:0;right:0;top:0;height:34px;background:rgba(255,255,255,.28);direction:ltr;
  display:flex;align-items:center;gap:26px;padding:0 22px;font:600 17px -apple-system,Inter,"Segoe UI",DejaVu Sans,sans-serif;color:#fff}}
.menu .r{{margin-left:auto;font-weight:500;display:flex;gap:22px;align-items:center}} .menu svg{{width:20px;height:20px}}
.win{{position:absolute;{sl}:150px;top:78px;width:1180px;border-radius:14px;overflow:hidden;
  box-shadow:0 0 0 1px rgba(0,0,0,.25),0 40px 90px rgba(0,0,0,.5)}}
.tb{{height:38px;background:#e9e9ef;display:flex;align-items:center;gap:9px;padding:0 16px;direction:ltr}}
.tb i{{width:14px;height:14px;border-radius:50%;display:block}}
#dsk{{width:1180px;height:735px;background:#f0f}}
.dock{{position:absolute;left:50%;bottom:14px;transform:translateX(-50%);height:76px;padding:9px 12px;display:flex;gap:12px;
  border-radius:24px;background:rgba(255,255,255,.3);box-shadow:inset 0 0 0 1px rgba(255,255,255,.35)}}
.dock b{{width:58px;height:58px;border-radius:15px;display:block}}
.dock .h{{background:#fff;display:flex;align-items:center;justify-content:center}} .dock .h svg{{width:40px;height:40px}}
.base{{position:relative;height:44px;border-radius:4px 4px 40px 40px;
  background:linear-gradient(#e9e9ed 0%,#cfcfd4 45%,#a9a9b0 100%);box-shadow:0 22px 40px rgba(0,0,0,.18)}}
.base:before{{content:"";position:absolute;left:50%;top:0;width:260px;height:16px;margin-left:-130px;border-radius:0 0 16px 16px;
  background:linear-gradient(#bdbdc3,#d6d6db)}}
/* iPhone 6.1": a 390x844 pt screen, drawn at 510 px wide */
.ip{{position:absolute;{sr}:140px;top:250px;width:560px;padding:12px;border-radius:92px;
  background:linear-gradient(140deg,#8d8a86,#4a4845 18%,#2c2b2a 50%,#55524e 82%,#9a9792);
  box-shadow:inset 0 0 0 2px rgba(255,255,255,.18),0 50px 90px rgba(0,0,0,.35)}}
.ip .k{{position:absolute;width:6px;border-radius:3px;background:#3d3b39}}
.bez{{border-radius:80px;background:#000;padding:13px}}
.screen{{position:relative;width:510px;border-radius:68px;overflow:hidden;background:{top_color}}}
.sb{{position:relative;height:61.5px;background:{top_color};display:flex;align-items:center;justify-content:space-between;
  padding:4px 38px 0 52px;font:600 22px -apple-system,"SF Pro Text",Inter,"Segoe UI",DejaVu Sans,sans-serif;color:#000;direction:ltr}}
.island{{position:absolute;left:50%;top:14px;width:164px;height:48px;margin-left:-82px;border-radius:24px;background:#000}}
.sb .ic{{display:flex;gap:8px;align-items:center}}
#app{{width:510px;height:997.8px;background:#f0f}}
.hb{{height:44.5px;background:{bottom_color};display:flex;align-items:flex-end;justify-content:center;padding-bottom:11px}}
.hb i{{width:176px;height:7px;border-radius:4px;background:#111;display:block}}
</style></head><body>
<div class="floor"></div>
<div class="lap"><div class="lid"><span class="cam"></span><div class="scr">
<svg class="wall" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice"><defs>
<linearGradient id="a" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1e1b6b"/><stop offset=".55" stop-color="#5b2bd6"/><stop offset="1" stop-color="#0ea5e9"/></linearGradient>
<linearGradient id="b" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8b5cf6" stop-opacity=".9"/><stop offset="1" stop-color="#22d3ee" stop-opacity=".7"/></linearGradient>
<linearGradient id="c" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#f472b6" stop-opacity=".55"/><stop offset="1" stop-color="#6366f1" stop-opacity=".2"/></linearGradient></defs>
<rect width="1600" height="1000" fill="url(#a)"/>
<path d="M0 640 C300 520 520 760 860 640 S1400 420 1600 520 V1000 H0Z" fill="url(#b)"/>
<path d="M0 820 C380 700 700 940 1060 800 S1480 700 1600 760 V1000 H0Z" fill="url(#c)"/>
<path d="M0 300 C260 220 520 380 820 300 S1300 160 1600 240 V0 H0Z" fill="#ffffff" fill-opacity=".06"/></svg>
<div class="menu">{logo}<span>Hiddify</span><span style="font-weight:500">File</span><span style="font-weight:500">Edit</span><span style="font-weight:500">Window</span><span style="font-weight:500">Help</span>
<span class="r">{logo}<span>9:41</span></span></div>
<div class="win"><div class="tb"><i style="background:#ff5f57"></i><i style="background:#febc2e"></i><i style="background:#28c840"></i></div><div id="dsk"></div></div>
<div class="dock"><b style="background:linear-gradient(#5ac8fa,#007aff)"></b><b style="background:linear-gradient(#ffd60a,#ff9f0a)"></b><b style="background:linear-gradient(#34c759,#248a3d)"></b><b class="h">{logo}</b><b style="background:linear-gradient(#ff6482,#ff2d55)"></b><b style="background:linear-gradient(#bf5af2,#5e5ce6)"></b></div>
</div></div><div class="base"></div></div>
<div class="ip"><span class="k" style="{sl}:-5px;top:210px;height:44px"></span><span class="k" style="{sl}:-5px;top:290px;height:86px"></span>
<span class="k" style="{sl}:-5px;top:392px;height:86px"></span><span class="k" style="{sr}:-5px;top:320px;height:130px"></span>
<div class="bez"><div class="screen"><div class="sb"><span>9:41</span><span class="island"></span>
<span class="ic"><svg width="27" height="17" viewBox="0 0 27 17"><rect x="0" y="11" width="5" height="6" rx="1.5"/><rect x="7" y="8" width="5" height="9" rx="1.5"/><rect x="14" y="4.5" width="5" height="12.5" rx="1.5"/><rect x="21" y="1" width="5" height="16" rx="1.5"/></svg>
<svg width="24" height="17" viewBox="0 0 24 17"><path d="M12 3.2c3.4 0 6.5 1.3 8.8 3.5l1.7-1.8C19.7 2.2 16 .7 12 .7S4.3 2.2 1.5 4.9l1.7 1.8C5.5 4.5 8.6 3.2 12 3.2zm0 5c2 0 3.9.8 5.3 2.1l1.7-1.8C17.2 6.8 14.7 5.7 12 5.7S6.8 6.8 5 8.5l1.7 1.8C8.1 9 10 8.2 12 8.2zm0 5c.7 0 1.3.3 1.8.7L12 15.8l-1.8-1.9c.5-.4 1.1-.7 1.8-.7z"/></svg>
<svg width="37" height="17" viewBox="0 0 37 17"><rect x=".7" y=".7" width="31" height="15.6" rx="4.5" fill="none" stroke="#000" stroke-opacity=".4" stroke-width="1.4"/><rect x="3" y="3" width="26.4" height="11" rx="2.6"/><path d="M33.6 5.7v5.6c1.2-.4 2-1.6 2-2.8s-.8-2.4-2-2.8z" fill-opacity=".45"/></svg></span></div>
<div id="app"></div><div class="hb"><i></i></div></div></div></div>
<script>const r=e=>{{const b=document.getElementById(e).getBoundingClientRect();return [b.left,b.top,b.width,b.height]}};
document.body.setAttribute("data-rects",JSON.stringify({{dsk:r("dsk"),app:r("app")}}));</script>
</body></html>'''


def run_chrome(args):
    return subprocess.run([chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars"] + args,
                          check=True, capture_output=True, text=True).stdout


def build(lang):
    d, p = find(lang, "desktop"), find(lang, "phone")
    if not d or not p:
        print(f"{lang}: skipped (needs screens/desktop-{lang}.* and screens/phone-{lang}.*)")
        return
    dfr, pfr = frames(d), frames(p)
    top, bottom = pfr[0].getpixel((4, 4)), pfr[0].getpixel((4, pfr[0].height - 4))
    logo = open(os.path.join(REPO, "assets", "images", "logo.svg"), encoding="utf-8").read()
    html = page(lang in RTL, hexc(top), hexc(bottom), logo)
    with tempfile.TemporaryDirectory() as tmp:
        hp, png = os.path.join(tmp, "base.html"), os.path.join(tmp, "base.png")
        open(hp, "w", encoding="utf-8").write(html)
        dom = run_chrome([f"--window-size={W},{H}", "--dump-dom", "file://" + hp])
        rects = json.loads(re.search(r'data-rects="([^"]+)"', dom).group(1).replace("&quot;", '"'))
        run_chrome([f"--force-device-scale-factor={SCALE}", f"--window-size={W},{H}", f"--screenshot={png}", "file://" + hp])
        base = Image.open(png).convert("RGB")
    box = {k: [round(v * SCALE) for v in r] for k, r in rects.items()}
    dx, dy, dw, dh = box["dsk"]
    dmask = Image.new("L", (dw, dh), 0)  # the desktop window has round bottom corners
    ImageDraw.Draw(dmask).rounded_rectangle((0, -40, dw - 1, dh - 1), radius=14 * SCALE, fill=255)
    ax, ay, aw, ah = box["app"]
    n = max(len(dfr), len(pfr))
    out_h = round(H * OUT_W / W)
    imgs, durs, last = [], [], None
    for i in range(n):
        df, pf = dfr[min(i, len(dfr) - 1)], pfr[min(i, len(pfr) - 1)]
        if last == (id(df), id(pf)):  # nothing changed on either screen: show the last picture longer
            durs[-1] += TICK
            continue
        last = (id(df), id(pf))
        im = base.copy()
        im.paste(df.resize((dw, dh), Image.LANCZOS), (dx, dy), dmask)
        im.paste(pf.resize((aw, ah), Image.LANCZOS), (ax, ay))
        imgs.append(im.resize((OUT_W, out_h), Image.LANCZOS))
        durs.append(TICK)
    durs[0] = max(durs[0], HOLD_FIRST)
    durs[-1] = max(durs[-1], HOLD_LAST)
    n = len(imgs)
    out = os.path.join(REPO, "docs", f"demo-{lang}.webp")
    if n == 1:
        imgs[0].save(out, quality=88, method=6)
    else:
        imgs[0].save(out, save_all=True, append_images=imgs[1:], duration=durs, loop=0, quality=82, method=4,
                     minimize_size=True)
    print(f"{lang}: {out} ({n} frame{'s' if n > 1 else ''}, {os.path.getsize(out) // 1024} KB)")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lang", help="one language code (default: all with inputs)")
    a = ap.parse_args()
    langs = [a.lang] if a.lang else sorted({os.path.basename(f).split("-", 1)[1].rsplit(".", 1)[0]
                                            for f in glob.glob(os.path.join(HERE, "screens", "desktop-*"))})
    for lang in langs:
        build(lang)


if __name__ == "__main__":
    main()
