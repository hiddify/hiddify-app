"""Writes every app icon of the cat theme into the repository.

    pip install pillow
    python3 scripts/cat_icons/make_icons.py . [preview-dir]

The second argument, if given, also gets a few preview sheets.
"""

import os
import sys
import tempfile

from PIL import Image

import caticon as c

REPO = sys.argv[1]
PREVIEW = sys.argv[2] if len(sys.argv) > 2 else tempfile.mkdtemp(prefix='cat-icons-')
os.makedirs(PREVIEW, exist_ok=True)

CREAM = '#FFF4E6'
GINGER = '#E8833A'


def out(rel):
    path = os.path.join(REPO, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def box(size, width_units=83, center=(50, 51), cx=None, cy=None, fraction=.94):
    """Maps the cat's unit box into a square of `size` px, the cat `fraction` wide."""
    s = size * fraction / width_units
    cx = size / 2 if cx is None else cx
    cy = size / 2 if cy is None else cy
    return (cx - center[0] * s, cy - center[1] * s, s)


# ------------------------------------------------------------- Android launcher

def adaptive(p):
    # 2048 viewport, the cat about 900 wide around the middle, inside the 66 dp safe zone
    return (474 + p[0] * 11, 463 + p[1] * 11)


foreground = c.android_vector(adaptive, stroke_scale=11, comment='the cat theme\'s head, drawn by scripts/cat_icons/make_icons.py')
open(out('android/app/src/main/res/drawable/ic_launcher_foreground.xml'), 'w').write(foreground)
open(out('android/app/src/main/res/drawable/android12splash.xml'), 'w').write(foreground)

open(out('android/app/src/main/res/values/ic_launcher_background.xml'), 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFF4E6</color>\n</resources>'
)
open(out('android/app/src/main/res/drawable/ic_launcher_background.xml'), 'w').write(
    '''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="2048dp"
    android:height="2048dp"
    android:viewportWidth="2048"
    android:viewportHeight="2048">
  <group>
    <!-- Filled rectangle -->
    <path
        android:pathData="M0,0 L2048,0 L2048,2048 L0,2048 Z"
        android:fillColor="#FFFFF4E6" />
  </group>
</vector>
'''
)


def legacy(size, round_):
    def background(r):
        m = size * .0625
        if round_:
            r.circle((size / 2, size / 2), size / 2 - m, c._rgba(CREAM))
        else:
            r.rounded_rect((m, m, size - m, size - m), size * .16, c._rgba(CREAM))

    return c.render_color(size, box(size, fraction=.66, cy=size * .53), background=background, detail=size >= 96)


for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    legacy(size, False).save(out(f'android/app/src/main/res/mipmap-{density}/ic_launcher.webp'), 'WEBP', lossless=True)
    legacy(size, True).save(out(f'android/app/src/main/res/mipmap-{density}/ic_launcher_round.webp'), 'WEBP', lossless=True)
legacy(512, False).save(os.path.join(PREVIEW, 'launcher_legacy.png'))
legacy(512, True).save(os.path.join(PREVIEW, 'launcher_round.png'))

# notification icon: white, Android only reads its alpha
for density, size in [('mdpi', 24), ('hdpi', 36)]:
    c.render_silhouette(size, box(size, fraction=.96), '#FFFFFF').save(
        out(f'android/app/src/main/res/drawable-{density}/ic_stat_logo.png')
    )
c.render_silhouette(2048, box(2048, fraction=.96), '#FFFFFF').save(out('assets/images/source/ic_notify.png'))

# splash: the colored cat on its own
c.render_color(324, box(324, fraction=.72)).save(out('android/app/src/main/res/drawable-xxxhdpi/splash.png'))
for name, size in [('LaunchImage.png', 256), ('LaunchImage@2x.png', 512), ('LaunchImage@3x.png', 768)]:
    c.render_color(size, box(size, fraction=.72)).save(out(f'ios/Runner/Assets.xcassets/LaunchImage.imageset/{name}'))

# ------------------------------------------------------------- tray

TRAY = {
    # idle: asleep, ginger; brighter for dark taskbars
    'tray_icon': ('#FF9A4D', 'sleepy'),
    'tray_icon_dark': ('#D9702A', 'sleepy'),
    # connected: awake, green
    'tray_icon_connected': ('#2FB344', 'awake'),
    # connecting or disconnecting: half awake, amber
    'tray_icon_disconnected': ('#E9A21B', 'half'),
}
for name, (color, mood) in TRAY.items():
    c.render_silhouette(128, box(128), color, mood).save(out(f'assets/images/{name}.png'))
    frames = [c.render_silhouette(s, box(s), color, mood) for s in (16, 32, 48, 64, 128, 256)]
    frames[-1].save(
        out(f'assets/images/{name}.ico'),
        format='ICO',
        sizes=[f.size for f in frames],
        append_images=frames[:-1],
    )
    if name != 'tray_icon_dark':
        c.render_silhouette(2048, box(2048), color, mood).save(out(f'assets/images/source/{name}.png'))

# ------------------------------------------------------------- desktop and stores

frames = [c.render_color(s, box(s, fraction=.96), detail=s >= 48) for s in (16, 24, 32, 48, 64, 128, 256)]
frames[-1].save(out('windows/runner/resources/app_icon.ico'), format='ICO', sizes=[f.size for f in frames], append_images=frames[:-1])
frames[-1].save(os.path.join(PREVIEW, 'windows_256.png'))

hiddify_ico = [c.render_color(s, box(s, fraction=.96), detail=s >= 48) for s in (16, 32, 48, 64, 128, 256)]
hiddify_ico[-1].save(out('assets/images/source/hiddify.ico'), format='ICO', sizes=[f.size for f in hiddify_ico], append_images=hiddify_ico[:-1])


def store_tile(size, rect_color='#FFFFFF', margin=.0, radius=.2, fraction=.7):
    def background(r):
        m = size * margin
        r.rounded_rect((m, m, size - m, size - m), size * radius, c._rgba(rect_color))

    return c.render_color(size, box(size, fraction=fraction, cy=size * .53), background=background)


store_tile(256).save(out('snap/gui/app_icon.png'))
store_tile(1024, rect_color='#FFF4E6', margin=.06, radius=.17, fraction=.62).save(out('assets/images/source/ic_launcher_border.png'))

# ------------------------------------------------------------- logo (iOS and macOS icons tint it)


def logo(p):
    return (p[0] * .72 - 4, p[1] * .72 - 3.2)


svg = c.svg_silhouette((64, 64), logo, GINGER, mood='awake', inner_ear_holes=True)
for rel in ['assets/images/logo.svg', 'ios/Runner/AppIcon.icon/Assets/logo.svg', 'macos/Runner/AppIcon.icon/Assets/logo.svg']:
    open(out(rel), 'w').write(svg)

# previews
c.render_silhouette(256, box(256), GINGER, 'awake', inner_ear_holes=True).save(os.path.join(PREVIEW, 'logo.png'))
sheet = Image.new('RGBA', (4 * 140, 2 * 140), (255, 255, 255, 255))
for i, (name, (color, mood)) in enumerate(TRAY.items()):
    sheet.paste(Image.open(out(f'assets/images/{name}.png')), (i * 140 + 6, 6), Image.open(out(f'assets/images/{name}.png')))
    small = c.render_silhouette(32, box(32), color, mood).resize((128, 128), Image.NEAREST)
    sheet.paste(small, (i * 140 + 6, 146), small)
sheet.save(os.path.join(PREVIEW, 'tray_sheet.png'))
print('done')
