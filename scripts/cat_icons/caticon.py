"""Cat head geometry shared by every app icon, in the same 100 x 100 box as
lib/core/widget/cat/cat_face.dart, and writers for SVG, Android vector
drawables and raster images (PIL, supersampled)."""

import math
from PIL import Image, ImageDraw

# ---------------------------------------------------------------- geometry

K = 0.5522847498  # cubic approximation of a quarter circle


def ellipse(cx, cy, rx, ry):
    """A closed ellipse as cubic segments, clockwise from the top."""
    return [
        ('M', (cx, cy - ry)),
        ('C', (cx + rx * K, cy - ry), (cx + rx, cy - ry * K), (cx + rx, cy)),
        ('C', (cx + rx, cy + ry * K), (cx + rx * K, cy + ry), (cx, cy + ry)),
        ('C', (cx - rx * K, cy + ry), (cx - rx, cy + ry * K), (cx - rx, cy)),
        ('C', (cx - rx, cy - ry * K), (cx - rx * K, cy - ry), (cx, cy - ry)),
        ('Z',),
    ]


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def ear(base, half, length, tilt, round_=.28, inner=False):
    left = (base[0] - half, base[1])
    right = (base[0] + half, base[1])
    tip = (base[0] + math.sin(tilt) * length, base[1] - math.cos(tilt) * length)
    if inner:
        g = ((left[0] + right[0] + tip[0]) / 3, (left[1] + right[1] + tip[1]) / 3)

        def shrink(p):
            return (g[0] + (p[0] - g[0]) * .56 + (tip[0] - g[0]) * .12,
                    g[1] + (p[1] - g[1]) * .56 + (tip[1] - g[1]) * .12)
        left, tip, right = shrink(left), shrink(tip), shrink(right)
        round_ *= 1.2
    before = lerp(left, tip, 1 - round_)
    after = lerp(tip, right, round_)
    return [('M', left), ('L', before), ('Q', tip, after), ('L', right), ('Z',)]


HEAD = [
    ('M', (50, 28)),
    ('C', (71, 28), (86, 42), (86, 62)),
    ('C', (86, 80), (70, 92), (50, 92)),
    ('C', (30, 92), (14, 80), (14, 62)),
    ('C', (14, 42), (29, 28), (50, 28)),
    ('Z',),
]

TUFTS = [
    ('M', (84.5, 60)), ('L', (91.5, 66.5)), ('L', (85.5, 69)), ('L', (90, 75)), ('L', (81, 77.5)), ('Z',),
    ('M', (15.5, 60)), ('L', (8.5, 66.5)), ('L', (14.5, 69)), ('L', (10, 75)), ('L', (19, 77.5)), ('Z',),
]

NOSE = [
    ('M', (46.2, 68.4)),
    ('Q', (50, 67.2), (53.8, 68.4)),
    ('Q', (54.9, 69.1), (53.8, 70.3)),
    ('L', (51, 72.5)),
    ('Q', (50, 73.3), (49, 72.5)),
    ('L', (46.2, 70.3)),
    ('Q', (45.1, 69.1), (46.2, 68.4)),
    ('Z',),
]

MOUTH = [
    ('M', (50, 72.8)), ('L', (50, 75)), ('Q', (48.2, 78.2), (45, 76.4)),
    ('M', (50, 75)), ('Q', (51.8, 78.2), (55, 76.4)),
]

STRIPES = [
    ('M', (50, 31)), ('L', (50, 38.5)),
    ('M', (43.5, 32.2)), ('L', (44.6, 38.6)),
    ('M', (56.5, 32.2)), ('L', (55.4, 38.6)),
    ('M', (16, 56)), ('L', (22.5, 57.5)),
    ('M', (15.5, 62)), ('L', (21.5, 62.5)),
    ('M', (84, 56)), ('L', (77.5, 57.5)),
    ('M', (84.5, 62)), ('L', (78.5, 62.5)),
]


def ears(tilt=.24, length=35):
    return [ear((50 + s * 18, 45), 12.5, length, s * tilt) for s in (-1, 1)]


def inner_ears(tilt=.24, length=35):
    return [ear((50 + s * 18, 45), 12.5, length, s * tilt, inner=True) for s in (-1, 1)]


def whiskers():
    out = []
    for side in (-1, 1):
        root = (50 + side * 10.5, 74)
        for angle, length in ((-.22, 27.0), (0.0, 29.0), (.22, 27.0)):
            d = (side * math.cos(angle), math.sin(angle))
            start = (root[0] + d[0] * 3, root[1] + d[1] * 3)
            end = (root[0] + d[0] * length, root[1] + d[1] * length)
            mid = lerp(start, end, .5)
            out += [('M', start), ('Q', (mid[0], mid[1] - 1.6), end)]
    return out


def closed_eye(cx, cy, style, half=7.7, thickness=2.4):
    """A shut eye as a filled crescent: style -1 sleepy (◡), 1 happy (∩)."""
    y = cy + 1.5
    bend = -4.2 * style
    t = thickness / 2
    return [
        ('M', (cx - half, y - t)),
        ('Q', (cx, y + bend - t), (cx + half, y - t)),
        ('Q', (cx + half + t, y), (cx + half, y + t)),
        ('Q', (cx, y + bend + t), (cx - half, y + t)),
        ('Q', (cx - half - t, y), (cx - half, y - t)),
        ('Z',),
    ]


def half_eye(cx, cy, rx=8.6, ry=9.6, open_=.5):
    """The lower part of an eye under a straight lid."""
    lid = cy - ry + (1 - open_) * ry * 2.05
    # where the lid line meets the ellipse
    dy = (lid - cy) / ry
    dx = rx * math.sqrt(max(0, 1 - dy * dy))
    # lower arc from the right meeting point to the left one, through the bottom
    pts = []
    a0 = math.atan2(dy, dx / rx)
    a1 = math.pi - a0
    for i in range(17):
        a = a0 + (a1 - a0) * i / 16
        pts.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    cmds = [('M', pts[0])] + [('L', p) for p in pts[1:]] + [('Z',)]
    return cmds


# ---------------------------------------------------------------- colors

GINGER = dict(
    fur='#F5A35C', fur_shade='#DB7633', muzzle='#FFF4E6', inner_ear='#F9B4C2', nose='#EF7D95',
    iris='#8BC34A', pupil='#2B2118', shine='#FFFFFF', whisker='#9C7A63', blush='#FFB3C0',
    line='#4A2E1C', outline='#C2662B',
)


def color_layers(c=GINGER, detail=True):
    """The colored cat, back to front: (commands, fill, stroke, stroke width)."""
    L = []
    for e in ears():
        L.append((e, c['fur'], c['outline'], 1.4))
    for e in inner_ears():
        L.append((e, c['inner_ear'], None, 0))
    L.append((TUFTS, c['fur'], c['outline'], 1.2))
    L.append((HEAD, c['fur'], c['outline'], 1.4))
    if detail:
        L.append((STRIPES, None, c['fur_shade'], 2.6))
    L.append((ellipse(44.6, 76, 8.2, 8.2), c['muzzle'], None, 0))
    L.append((ellipse(55.4, 76, 8.2, 8.2), c['muzzle'], None, 0))
    L.append((ellipse(24.5, 72, 5.5, 3), c['blush'], None, 0))
    L.append((ellipse(75.5, 72, 5.5, 3), c['blush'], None, 0))
    for side in (-1, 1):
        cx = 50 + side * 15
        L.append((ellipse(cx, 61, 8.6, 9.6), c['iris'], c['line'], 1.3))
        L.append((ellipse(cx, 61, 3.55, 7.7), c['pupil'], None, 0))
        L.append((ellipse(cx - 2.58, 61 - 3.07, 2.32, 2.32), c['shine'], None, 0))
        L.append((ellipse(cx + 2.06, 61 + 2.11, 1.03, 1.03), c['shine'], None, 0))
    L.append((MOUTH, None, c['line'], 1.5))
    L.append((NOSE, c['nose'], None, 0))
    if detail:
        L.append((whiskers(), None, c['whisker'], 1.2))
    return L


def silhouette(mood='awake', inner_ear_holes=False):
    """A one-color cat head: the shape to fill, and the holes cut out of it."""
    shape = [ears()[0], ears()[1], TUFTS, HEAD]
    holes = []
    for side in (-1, 1):
        cx = 50 + side * 15
        if mood == 'awake':
            holes.append(ellipse(cx, 61, 8.6, 9.6))
        elif mood == 'half':
            holes.append(half_eye(cx, 61, open_=.5))
        else:
            holes.append(closed_eye(cx, 61, -1, half=8.2, thickness=3.6))
    holes.append(NOSE)
    if inner_ear_holes:
        holes += inner_ears()
    # slit pupils back inside the open eyes, so they read as a cat's
    pupils = [ellipse(50 + side * 15, 61.6, 2.7, 6.9) for side in (-1, 1)] if mood in ('awake', 'half') else []
    return shape, holes, pupils


# ---------------------------------------------------------------- flattening

def _flatten(cmds, steps=24):
    """Subpaths as point lists; returns (subpaths, closed flags)."""
    subs, closed, cur, start = [], [], None, None
    for c in cmds:
        op = c[0]
        if op == 'M':
            if cur:
                subs.append(cur)
                closed.append(False)
            cur = [c[1]]
            start = c[1]
        elif op == 'L':
            cur.append(c[1])
        elif op == 'Q':
            p0, p1, p2 = cur[-1], c[1], c[2]
            for i in range(1, steps + 1):
                t = i / steps
                cur.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
        elif op == 'C':
            p0, p1, p2, p3 = cur[-1], c[1], c[2], c[3]
            for i in range(1, steps + 1):
                t = i / steps
                u = 1 - t
                cur.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                            u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
        elif op == 'Z':
            subs.append(cur)
            closed.append(True)
            cur = None
    if cur:
        subs.append(cur)
        closed.append(False)
    return subs, closed


def _rgba(color, alpha=255):
    if isinstance(color, tuple):
        return color
    color = color.lstrip('#')
    return (int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16), alpha)


class Raster:
    """Draws unit-box commands onto a supersampled RGBA canvas."""

    def __init__(self, size, box, ss=8):
        # box: (x, y, scale) maps unit coords to final pixels: px = x + u * scale
        self.size, self.ss = size, ss
        self.x, self.y, self.s = box
        self.img = Image.new('RGBA', (size * ss, size * ss), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.img)

    def _pt(self, p):
        return ((self.x + p[0] * self.s) * self.ss, (self.y + p[1] * self.s) * self.ss)

    def fill(self, cmds, color, draw=None):
        draw = draw or self.draw
        subs, _ = _flatten(cmds)
        for sub in subs:
            if len(sub) >= 3:
                draw.polygon([self._pt(p) for p in sub], fill=color)

    def stroke(self, cmds, color, width, draw=None):
        draw = draw or self.draw
        w = width * self.s * self.ss
        subs, closed = _flatten(cmds)
        for sub, is_closed in zip(subs, closed):
            pts = [self._pt(p) for p in sub]
            if is_closed:
                pts.append(pts[0])
            draw.line(pts, fill=color, width=max(1, round(w)), joint='curve')
            for p in (pts[0], pts[-1]):
                draw.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=color)

    def rounded_rect(self, rect, radius, color):
        x0, y0, x1, y1 = [v * self.ss for v in rect]
        self.draw.rounded_rectangle([x0, y0, x1, y1], radius=radius * self.ss, fill=color)

    def circle(self, center, radius, color):
        cx, cy = center[0] * self.ss, center[1] * self.ss
        r = radius * self.ss
        self.draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

    def result(self):
        return self.img.resize((self.size, self.size), Image.LANCZOS)


def render_color(size, box, background=None, detail=True):
    r = Raster(size, box)
    if background:
        background(r)
    for cmds, fill, stroke, width in color_layers(detail=detail):
        if fill:
            r.fill(cmds, _rgba(fill))
        if stroke:
            r.stroke(cmds, _rgba(stroke), width)
    return r.result()


def render_silhouette(size, box, color, mood='awake', inner_ear_holes=False):
    r = Raster(size, box)
    mask = Image.new('L', r.img.size, 0)
    md = ImageDraw.Draw(mask)
    shape, holes, pupils = silhouette(mood, inner_ear_holes)
    for cmds in shape:
        r.fill(cmds, 255, draw=md)
    for cmds in holes:
        r.fill(cmds, 0, draw=md)
    for cmds in pupils:
        r.fill(cmds, 255, draw=md)
    solid = Image.new('RGBA', r.img.size, _rgba(color))
    out = Image.new('RGBA', r.img.size, (0, 0, 0, 0))
    out.paste(solid, (0, 0), mask)
    return out.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- vector writers

def _fmt(v):
    s = f'{v:.2f}'.rstrip('0').rstrip('.')
    return '0' if s == '-0' else s


def path_data(cmds, transform=lambda p: p):
    out = []
    for c in cmds:
        op = c[0]
        if op == 'Z':
            out.append('Z')
        else:
            pts = ' '.join(f'{_fmt(transform(p)[0])},{_fmt(transform(p)[1])}' for p in c[1:])
            out.append(f'{op}{pts}')
    return ' '.join(out)


def _area(cmds):
    subs, _ = _flatten(cmds)
    a = 0
    for sub in subs:
        for (x0, y0), (x1, y1) in zip(sub, sub[1:] + sub[:1]):
            a += x0 * y1 - x1 * y0
    return a / 2  # positive: clockwise on screen (y down)


def reverse(cmds):
    """The same closed subpath, run the other way round."""
    segs, cur = [], None
    for c in cmds:
        if c[0] == 'M':
            cur = c[1]
        elif c[0] == 'Z':
            continue
        else:
            segs.append((cur, c[0], c[1:-1], c[-1]))
            cur = c[-1]
    out = [('M', segs[-1][3])]
    for start, op, ctrl, end in reversed(segs):
        out.append((op, *reversed(ctrl), start))
    out.append(('Z',))
    return out


def clockwise(cmds, want=True):
    return cmds if (_area(cmds) > 0) == want else reverse(cmds)


def svg_silhouette(viewbox, transform, color, mood='awake', inner_ear_holes=True):
    """One path, nonzero fill: the parts all run clockwise, so overlaps stay
    filled, and the holes run the other way, so they cut through."""
    shape, holes, pupils = silhouette(mood, inner_ear_holes)
    parts = []
    for c in shape + pupils:
        for sub in _split(c):
            parts.append(path_data(clockwise(sub, True), transform))
    for c in holes:
        for sub in _split(c):
            parts.append(path_data(clockwise(sub, False), transform))
    w, h = viewbox
    d = ' '.join(parts)
    return f'''<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="{d}" fill="{color}"/>
</svg>
'''


def _split(cmds):
    """Commands split into closed subpaths."""
    out, cur = [], []
    for c in cmds:
        if c[0] == 'M' and cur:
            out.append(cur)
            cur = []
        cur.append(c)
        if c[0] == 'Z':
            out.append(cur)
            cur = []
    if cur:
        out.append(cur)
    return out


def android_vector(transform, width_dp=108, viewport=2048, stroke_scale=1.0, comment=''):
    lines = [
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"',
        f'    android:width="{width_dp}dp"',
        f'    android:height="{width_dp}dp"',
        f'    android:viewportWidth="{viewport}"',
        f'    android:viewportHeight="{viewport}">',
    ]
    if comment:
        lines.append(f'  <!-- {comment} -->')
    for cmds, fill, stroke, width in color_layers():
        attrs = [f'android:pathData="{path_data(cmds, transform)}"']
        if fill:
            attrs.append(f'android:fillColor="{fill}"')
        if stroke:
            attrs += [
                f'android:strokeColor="{stroke}"',
                f'android:strokeWidth="{_fmt(width * stroke_scale)}"',
                'android:strokeLineCap="round"',
                'android:strokeLineJoin="round"',
            ]
        lines.append('  <path\n      ' + '\n      '.join(attrs) + '/>')
    lines.append('</vector>')
    return '\n'.join(lines) + '\n'
