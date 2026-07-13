/* @ds-bundle: {"format":4,"namespace":"NovaVPNDesignSystem_e35630","components":[{"name":"Button","sourcePath":"components/actions/Button.jsx"},{"name":"ConnectButton","sourcePath":"components/actions/ConnectButton.jsx"},{"name":"IconButton","sourcePath":"components/actions/IconButton.jsx"},{"name":"ConnectStatus","sourcePath":"components/connection/ConnectStatus.jsx"},{"name":"MiniChart","sourcePath":"components/connection/MiniChart.jsx"},{"name":"SpeedGauge","sourcePath":"components/connection/SpeedGauge.jsx"},{"name":"Badge","sourcePath":"components/display/Badge.jsx"},{"name":"Card","sourcePath":"components/display/Card.jsx"},{"name":"Flag","sourcePath":"components/display/Flag.jsx"},{"name":"Icon","sourcePath":"components/display/Icon.jsx"},{"name":"InfoCard","sourcePath":"components/display/InfoCard.jsx"},{"name":"LatencyBadge","sourcePath":"components/display/LatencyBadge.jsx"},{"name":"SignalBars","sourcePath":"components/display/SignalBars.jsx"},{"name":"StatCard","sourcePath":"components/display/StatCard.jsx"},{"name":"Tag","sourcePath":"components/display/Tag.jsx"},{"name":"Radio","sourcePath":"components/forms/Radio.jsx"},{"name":"SearchField","sourcePath":"components/forms/SearchField.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"ListRow","sourcePath":"components/lists/ListRow.jsx"},{"name":"SectionLabel","sourcePath":"components/lists/SectionLabel.jsx"},{"name":"ServerRow","sourcePath":"components/lists/ServerRow.jsx"},{"name":"NavBar","sourcePath":"components/navigation/NavBar.jsx"},{"name":"TabBar","sourcePath":"components/navigation/TabBar.jsx"}],"sourceHashes":{"components/actions/Button.jsx":"6a2839b1f56f","components/actions/ConnectButton.jsx":"5d8c6a22eee6","components/actions/IconButton.jsx":"a2129ab92350","components/connection/ConnectStatus.jsx":"ece409c1a7bb","components/connection/MiniChart.jsx":"b9a4c815ff71","components/connection/SpeedGauge.jsx":"22e29fccb370","components/display/Badge.jsx":"6db862e6be98","components/display/Card.jsx":"e78aaa9eec89","components/display/Flag.jsx":"37909c8a1c62","components/display/Icon.jsx":"cba91e6afbdd","components/display/InfoCard.jsx":"ba7b202241ce","components/display/LatencyBadge.jsx":"f796cd346735","components/display/SignalBars.jsx":"6f106a9d21c4","components/display/StatCard.jsx":"665e07983fbc","components/display/Tag.jsx":"2f50dc5c30be","components/forms/Radio.jsx":"1f52796ebb24","components/forms/SearchField.jsx":"a766626b7b2f","components/forms/SegmentedControl.jsx":"b3789ff975f0","components/forms/Select.jsx":"852385e2976d","components/forms/Switch.jsx":"1b0a61e04dd1","components/lists/ListRow.jsx":"56cdb68ad6a6","components/lists/SectionLabel.jsx":"29425ad22a09","components/lists/ServerRow.jsx":"38631e48eb8b","components/navigation/NavBar.jsx":"d4bcb61e1f34","components/navigation/TabBar.jsx":"819677ddd964","ui_kits/nova-ios/App.jsx":"038612a62f1f","ui_kits/nova-ios/Home.jsx":"b022881c9c21","ui_kits/nova-ios/Phone.jsx":"f4a7c7b4ac92","ui_kits/nova-ios/RadarField.jsx":"85a0aa3ad10f","ui_kits/nova-ios/Rules.jsx":"3943b84c8f98","ui_kits/nova-ios/Servers.jsx":"76a73283f0b7","ui_kits/nova-ios/Settings.jsx":"b018810777ce","ui_kits/nova-ios/Welcome.jsx":"7afc832dce60","ui_kits/nova-ios/data.js":"2daa2e317782"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.NovaVPNDesignSystem_e35630 = window.NovaVPNDesignSystem_e35630 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/connection/MiniChart.jsx
try { (() => {
/**
 * MiniChart — filled area sparkline for up/down throughput cards.
 * data: number[]; auto-scales.
 */
function MiniChart({
  data = [],
  color = "var(--red-500)",
  width = 150,
  height = 56,
  style
}) {
  const w = width,
    h = height,
    n = data.length;
  if (n < 2) return /*#__PURE__*/React.createElement("svg", {
    width: w,
    height: h,
    style: style
  });
  const max = Math.max(...data, 1),
    min = Math.min(...data, 0);
  const span = max - min || 1;
  const x = i => i / (n - 1) * w;
  const y = v => h - 4 - (v - min) / span * (h - 10);
  let line = "M " + x(0) + " " + y(data[0]);
  for (let i = 1; i < n; i++) line += " L " + x(i) + " " + y(data[i]);
  const area = line + " L " + w + " " + h + " L 0 " + h + " Z";
  const id = "mc" + Math.random().toString(36).slice(2, 7);
  return /*#__PURE__*/React.createElement("svg", {
    width: w,
    height: h,
    viewBox: "0 0 " + w + " " + h,
    style: style,
    preserveAspectRatio: "none"
  }, /*#__PURE__*/React.createElement("defs", null, /*#__PURE__*/React.createElement("linearGradient", {
    id: id,
    x1: "0",
    y1: "0",
    x2: "0",
    y2: "1"
  }, /*#__PURE__*/React.createElement("stop", {
    offset: "0%",
    stopColor: color,
    stopOpacity: "0.35"
  }), /*#__PURE__*/React.createElement("stop", {
    offset: "100%",
    stopColor: color,
    stopOpacity: "0"
  }))), /*#__PURE__*/React.createElement("path", {
    d: area,
    fill: "url(#" + id + ")"
  }), /*#__PURE__*/React.createElement("path", {
    d: line,
    fill: "none",
    stroke: color,
    strokeWidth: "2",
    strokeLinejoin: "round",
    strokeLinecap: "round"
  }));
}
Object.assign(__ds_scope, { MiniChart });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/connection/MiniChart.jsx", error: String((e && e.message) || e) }); }

// components/connection/SpeedGauge.jsx
try { (() => {
/**
 * SpeedGauge — 270° arc gauge for throughput (Mbps).
 * Pure SVG; value 0..max drives the red fill + needle.
 */
function SpeedGauge({
  value = 0,
  max = 100,
  unit = "Mbps",
  size = 200,
  style
}) {
  const cx = size / 2,
    cy = size / 2,
    r = size / 2 - 16;
  const start = 135,
    sweep = 270;
  const pct = Math.max(0, Math.min(1, value / max));
  const polar = deg => {
    const a = (deg - 90) * Math.PI / 180;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
  };
  const arc = (fromDeg, toDeg) => {
    const [x1, y1] = polar(fromDeg),
      [x2, y2] = polar(toDeg);
    const large = toDeg - fromDeg > 180 ? 1 : 0;
    return "M " + x1 + " " + y1 + " A " + r + " " + r + " 0 " + large + " 1 " + x2 + " " + y2;
  };
  const needleDeg = start + sweep * pct;
  const [nx, ny] = polar(needleDeg);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      width: size,
      height: size,
      ...style
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: "0 0 " + size + " " + size
  }, /*#__PURE__*/React.createElement("path", {
    d: arc(start, start + sweep),
    fill: "none",
    stroke: "var(--surface-4)",
    strokeWidth: "10",
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("path", {
    d: arc(start, needleDeg),
    fill: "none",
    stroke: "var(--red-500)",
    strokeWidth: "10",
    strokeLinecap: "round",
    style: {
      filter: "drop-shadow(0 0 8px var(--red-glow))"
    }
  }), /*#__PURE__*/React.createElement("line", {
    x1: cx,
    y1: cy,
    x2: nx,
    y2: ny,
    stroke: "var(--text-1)",
    strokeWidth: "3",
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: cx,
    cy: cy,
    r: "6",
    fill: "var(--text-1)"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "grid",
      placeItems: "center",
      pointerEvents: "none"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: "center",
      marginTop: size * 0.18
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-bold) var(--fs-h1)/1 var(--font-mono)",
      letterSpacing: "var(--ls-mono)",
      color: "var(--text-1)"
    }
  }, value.toFixed(1)), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-semibold) var(--fs-cap)/1 var(--font-sans)",
      letterSpacing: "var(--ls-wide)",
      textTransform: "uppercase",
      color: "var(--text-3)",
      marginTop: 4
    }
  }, unit))));
}
Object.assign(__ds_scope, { SpeedGauge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/connection/SpeedGauge.jsx", error: String((e && e.message) || e) }); }

// components/display/Badge.jsx
try { (() => {
/** Badge — small status/label pill. tone: neutral | red | gold | success | outline */
function Badge({
  children,
  tone = "neutral",
  style
}) {
  const tones = {
    neutral: {
      background: "var(--surface-3)",
      color: "var(--text-2)",
      border: "1px solid var(--line-2)"
    },
    red: {
      background: "var(--red-tint)",
      color: "var(--red-400)",
      border: "1px solid var(--red-tint-2)"
    },
    gold: {
      background: "rgba(233,178,60,0.12)",
      color: "var(--warn)",
      border: "1px solid rgba(233,178,60,0.25)"
    },
    success: {
      background: "rgba(61,214,176,0.12)",
      color: "var(--sig-good)",
      border: "1px solid rgba(61,214,176,0.25)"
    },
    outline: {
      background: "transparent",
      color: "var(--text-2)",
      border: "1px solid var(--line-2)"
    }
  };
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 5,
      height: 22,
      padding: "0 9px",
      borderRadius: "var(--r-pill)",
      font: "var(--w-semibold) var(--fs-micro)/1 var(--font-sans)",
      letterSpacing: "var(--ls-wide)",
      textTransform: "uppercase",
      ...tones[tone],
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Badge.jsx", error: String((e && e.message) || e) }); }

// components/display/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Card — base surface container. tone: base | elevated | glass */
function Card({
  children,
  tone = "base",
  pad = 16,
  glow = false,
  style,
  ...rest
}) {
  const tones = {
    base: {
      background: "var(--surface-1)",
      border: "1px solid var(--line)"
    },
    elevated: {
      background: "var(--surface-2)",
      border: "1px solid var(--line-2)",
      boxShadow: "var(--shadow-card)"
    },
    glass: {
      background: "rgba(22,22,28,0.72)",
      border: "1px solid var(--line-2)",
      backdropFilter: "blur(var(--blur-chip))",
      WebkitBackdropFilter: "blur(var(--blur-chip))"
    }
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      borderRadius: "var(--r-lg)",
      padding: pad,
      ...tones[tone],
      boxShadow: glow ? "var(--glow-red-soft)" : tones[tone].boxShadow || "none",
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Card.jsx", error: String((e && e.message) || e) }); }

// components/display/Flag.jsx
try { (() => {
/** Flag — country flag via flagcdn (ISO-3166 alpha-2). Rounded, hairline ring.
 * TODO(privacy): self-host flags before ship — do not fetch per-render from flagcdn.
 * Spec: design/SELF_HOST_ASSETS.md §2 (local SVG set; alt = country name). */
function Flag({
  code = "un",
  size = 26,
  style
}) {
  const cc = String(code).toLowerCase();
  return /*#__PURE__*/React.createElement("img", {
    src: "https://flagcdn.com/w80/" + cc + ".png",
    srcSet: "https://flagcdn.com/w160/" + cc + ".png 2x",
    alt: cc.toUpperCase(),
    width: size,
    height: size,
    style: {
      width: size,
      height: size,
      borderRadius: "var(--r-full)",
      objectFit: "cover",
      border: "1px solid var(--line-2)",
      background: "var(--surface-3)",
      flexShrink: 0,
      ...style
    }
  });
}
Object.assign(__ds_scope, { Flag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Flag.jsx", error: String((e && e.message) || e) }); }

// components/display/Icon.jsx
try { (() => {
/**
 * Icon — thin wrapper over Lucide (loaded from CDN as window.lucide).
 * Consumers must include <script src="https://unpkg.com/lucide@latest"></script>.
 * name = Lucide kebab name, e.g. "power", "chevron-right", "shield".
 * TODO(privacy): bundle the used Lucide icons before ship — no runtime unpkg fetch.
 * Spec: design/SELF_HOST_ASSETS.md §3. */
function Icon({
  name,
  size = 20,
  stroke = 1.75,
  color,
  style,
  className
}) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    const host = ref.current;
    if (!host || !window.lucide) return;
    host.innerHTML = "";
    const i = document.createElement("i");
    i.setAttribute("data-lucide", name);
    host.appendChild(i);
    window.lucide.createIcons({
      nameAttr: "data-lucide",
      attrs: {
        width: size,
        height: size,
        "stroke-width": stroke,
        stroke: color || "currentColor"
      }
    });
  }, [name, size, stroke, color]);
  return /*#__PURE__*/React.createElement("span", {
    ref: ref,
    className: className,
    "aria-hidden": "true",
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      width: size,
      height: size,
      color: color || "currentColor",
      ...style
    }
  });
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Icon.jsx", error: String((e && e.message) || e) }); }

// components/actions/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — Nova's primary action. Pills by default.
 * variant: primary | secondary | ghost | outline | danger
 * size: sm | md | lg
 */
function Button({
  children,
  variant = "primary",
  size = "md",
  block = false,
  iconLeft,
  iconRight,
  disabled = false,
  glow = false,
  style,
  ...rest
}) {
  const sizes = {
    sm: {
      h: 36,
      px: 16,
      fs: "var(--fs-foot)",
      gap: 6,
      icon: 16
    },
    md: {
      h: 46,
      px: 22,
      fs: "var(--fs-sub)",
      gap: 8,
      icon: 18
    },
    lg: {
      h: 54,
      px: 28,
      fs: "var(--fs-callout)",
      gap: 10,
      icon: 20
    }
  };
  const s = sizes[size] || sizes.md;
  const variants = {
    primary: {
      background: "var(--red-600)",
      color: "var(--text-on-red)",
      border: "1px solid transparent"
    },
    danger: {
      background: "var(--red-600)",
      color: "var(--text-on-red)",
      border: "1px solid transparent"
    },
    secondary: {
      background: "var(--surface-3)",
      color: "var(--text-1)",
      border: "1px solid var(--line-2)"
    },
    ghost: {
      background: "transparent",
      color: "var(--text-2)",
      border: "1px solid transparent"
    },
    outline: {
      background: "transparent",
      color: "var(--red-400)",
      border: "1px solid var(--red-500)"
    }
  };
  const v = variants[variant] || variants.primary;
  return /*#__PURE__*/React.createElement("button", _extends({
    disabled: disabled,
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      gap: s.gap,
      height: s.h,
      padding: "0 " + s.px + "px",
      width: block ? "100%" : "auto",
      font: "var(--w-semibold) " + s.fs + "/1 var(--font-sans)",
      letterSpacing: "var(--ls-tight)",
      borderRadius: "var(--r-pill)",
      cursor: disabled ? "not-allowed" : "pointer",
      opacity: disabled ? 0.4 : 1,
      transition: "transform var(--dur-1) var(--ease-out), background var(--dur-2), box-shadow var(--dur-2)",
      boxShadow: glow ? "var(--glow-red-soft)" : "none",
      WebkitTapHighlightColor: "transparent",
      ...v,
      ...style
    },
    onMouseDown: e => {
      if (!disabled) e.currentTarget.style.transform = "scale(var(--press-scale))";
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = "scale(1)";
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = "scale(1)";
    }
  }, rest), iconLeft && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: iconLeft,
    size: s.icon
  }), children, iconRight && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: iconRight,
    size: s.icon
  }));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/Button.jsx", error: String((e && e.message) || e) }); }

// components/actions/ConnectButton.jsx
try { (() => {
/**
 * ConnectButton — the ritual. A circular power control with a red glow.
 * status: "off" | "connecting" | "on"
 * The glow and expanding signal rings only appear once you're through.
 */
function ConnectButton({
  status = "off",
  size = 156,
  onClick,
  label,
  style
}) {
  const on = status === "on";
  const connecting = status === "connecting";
  const rm = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const error = status === "error";
  const ring = on ? "var(--red-500)" : connecting ? "var(--red-400)" : error ? "var(--danger)" : "var(--line-strong)";
  const glow = on ? "0 0 0 1px var(--red-500), 0 0 36px var(--red-glow), 0 0 90px var(--red-glow-soft)" : connecting ? "0 0 0 1px var(--red-400), 0 0 24px var(--red-glow-soft)" : error ? "0 0 0 1px var(--danger), 0 0 22px var(--red-glow-soft)" : "inset 0 0 0 1px var(--line-2)";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      width: size,
      height: size,
      display: "grid",
      placeItems: "center",
      ...style
    }
  }, (on || connecting) && !rm && [0, 1].map(i => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      position: "absolute",
      inset: 0,
      borderRadius: "var(--r-full)",
      border: "1px solid var(--red-glow)",
      pointerEvents: "none",
      animation: "nova-ring 2.6s var(--ease-out) infinite",
      animationDelay: i * 1.3 + "s"
    }
  })), /*#__PURE__*/React.createElement("button", {
    onClick: connecting ? undefined : onClick,
    "aria-busy": connecting,
    disabled: connecting,
    style: {
      position: "relative",
      width: size,
      height: size,
      borderRadius: "var(--r-full)",
      background: on ? "radial-gradient(circle at 50% 40%, rgba(255,45,62,0.22), rgba(255,45,62,0.04) 70%)" : "var(--surface-1)",
      border: "1px solid " + ring,
      boxShadow: glow,
      cursor: connecting ? "default" : "pointer",
      display: "grid",
      placeItems: "center",
      color: on ? "var(--red-400)" : error ? "var(--danger)" : "var(--text-2)",
      transition: "box-shadow var(--dur-3) var(--ease-out), color var(--dur-3), border-color var(--dur-3)",
      WebkitTapHighlightColor: "transparent"
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = "scale(0.98)";
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = "scale(1)";
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = "scale(1)";
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      placeItems: "center",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: error ? "triangle-alert" : "power",
    size: Math.round(size * 0.3),
    stroke: 1.5,
    style: {
      animation: connecting && !rm ? "nova-pulse 1.2s var(--ease-inout) infinite" : "none"
    }
  }), label && /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-semibold) var(--fs-micro)/1 var(--font-mono)",
      letterSpacing: "var(--ls-label)",
      textTransform: "uppercase",
      color: on ? "var(--red-400)" : "var(--text-3)"
    }
  }, label))));
}
Object.assign(__ds_scope, { ConnectButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/ConnectButton.jsx", error: String((e && e.message) || e) }); }

// components/actions/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * IconButton — circular/rounded glyph button used in nav bars & toolbars.
 * variant: plain | surface | ghost
 */
function IconButton({
  icon,
  size = 40,
  iconSize,
  variant = "surface",
  active = false,
  style,
  ...rest
}) {
  const variants = {
    plain: {
      background: "transparent",
      border: "1px solid transparent"
    },
    surface: {
      background: "var(--surface-2)",
      border: "1px solid var(--line)"
    },
    ghost: {
      background: "transparent",
      border: "1px solid var(--line-2)"
    }
  };
  const v = variants[variant] || variants.surface;
  const hit = Math.max(size, 44); // >=44px tap target (touch-min); visual circle stays `size`
  return /*#__PURE__*/React.createElement("button", _extends({
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      width: hit,
      height: hit,
      padding: 0,
      border: "none",
      background: "transparent",
      color: active ? "var(--red-400)" : "var(--text-2)",
      cursor: "pointer",
      transition: "transform var(--dur-1) var(--ease-out), color var(--dur-2)",
      WebkitTapHighlightColor: "transparent",
      ...style
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = "scale(var(--press-scale))";
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = "scale(1)";
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = "scale(1)";
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      width: size,
      height: size,
      borderRadius: "var(--r-full)",
      transition: "background var(--dur-2)",
      ...v
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: iconSize || Math.round(size * 0.5)
  })));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/display/InfoCard.jsx
try { (() => {
/**
 * InfoCard — the translucent connection-info chip (IP / location) that floats
 * over the map. tone: red (connected) | neutral.
 */
function InfoCard({
  rows = [],
  tone = "red",
  style
}) {
  const accent = tone === "red" ? "var(--red-400)" : "var(--text-2)";
  const bg = tone === "red" ? "rgba(255,45,62,0.10)" : "rgba(22,22,28,0.72)";
  const border = tone === "red" ? "1px solid var(--red-tint-2)" : "1px solid var(--line-2)";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "inline-flex",
      flexDirection: "column",
      gap: 8,
      padding: "12px 16px",
      borderRadius: "var(--r-md)",
      background: bg,
      border: border,
      backdropFilter: "blur(var(--blur-chip))",
      WebkitBackdropFilter: "blur(var(--blur-chip))",
      boxShadow: tone === "red" ? "var(--glow-red-soft)" : "none",
      ...style
    }
  }, rows.map((r, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8
    }
  }, r.icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: r.icon,
    size: 15,
    color: accent
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-regular) var(--fs-foot)/1 var(--font-sans)",
      color: "var(--text-2)"
    }
  }, r.label), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-medium) var(--fs-foot)/1 var(--font-mono)",
      letterSpacing: "var(--ls-mono)",
      color: "var(--text-1)"
    }
  }, r.value))));
}
Object.assign(__ds_scope, { InfoCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/InfoCard.jsx", error: String((e && e.message) || e) }); }

// components/display/LatencyBadge.jsx
try { (() => {
/** LatencyBadge — mono ms readout with a quality dot. Auto-thresholds. */
function LatencyBadge({
  ms,
  showDot = true,
  style
}) {
  const color = ms == null ? "var(--text-3)" : ms < 80 ? "var(--sig-good)" : ms < 180 ? "var(--sig-mid)" : "var(--sig-slow)";
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      ...style
    }
  }, showDot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 7,
      height: 7,
      borderRadius: "var(--r-full)",
      background: color,
      boxShadow: "0 0 6px " + color
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-medium) var(--fs-foot)/1 var(--font-mono)",
      letterSpacing: "var(--ls-mono)",
      color
    }
  }, ms == null ? "—" : ms + "ms"));
}
Object.assign(__ds_scope, { LatencyBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/LatencyBadge.jsx", error: String((e && e.message) || e) }); }

// components/display/SignalBars.jsx
try { (() => {
/** SignalBars — 4-bar strength indicator, colored by latency quality. */
function SignalBars({
  level = 4,
  size = 16,
  style
}) {
  const color = level >= 3 ? "var(--sig-good)" : level === 2 ? "var(--sig-mid)" : "var(--sig-slow)";
  const bars = [0.4, 0.6, 0.8, 1];
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "flex-end",
      gap: 2,
      height: size,
      ...style
    }
  }, bars.map((h, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      width: Math.max(2, size * 0.16),
      height: size * h,
      borderRadius: 1,
      background: i < level ? color : "var(--line-2)",
      boxShadow: i < level ? "0 0 6px " + color.replace("var(", "").replace(")", "") : "none"
    }
  })));
}
Object.assign(__ds_scope, { SignalBars });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/SignalBars.jsx", error: String((e && e.message) || e) }); }

// components/connection/ConnectStatus.jsx
try { (() => {
/**
 * ConnectStatus — connection state readout.
 * variant "pill": the floating capsule ("Connected") over the map.
 * variant "card": full status row with flag, state, timer, signal.
 * status: "on" | "off" | "connecting"
 */
function ConnectStatus({
  variant = "pill",
  status = "on",
  flagCode,
  location,
  timer,
  signal = 4,
  onClick,
  style
}) {
  const on = status === "on";
  const rm = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const stateText = on ? "Подключено" : status === "connecting" ? "Соединение…" : status === "error" ? "Ошибка подключения" : "Не подключено";
  const accent = on ? "var(--red-400)" : status === "connecting" ? "var(--red-300)" : status === "error" ? "var(--danger)" : "var(--text-3)";
  if (variant === "pill") {
    return /*#__PURE__*/React.createElement("button", {
      onClick: onClick,
      style: {
        display: "inline-flex",
        alignItems: "center",
        gap: 9,
        height: 40,
        padding: "0 16px",
        borderRadius: "var(--r-pill)",
        cursor: onClick ? "pointer" : "default",
        background: on ? "var(--red-tint)" : "var(--surface-2)",
        border: "1px solid " + (on ? "var(--red-tint-2)" : status === "error" ? "var(--danger)" : "var(--line-2)"),
        boxShadow: on ? "var(--glow-red-soft)" : "none",
        backdropFilter: "blur(var(--blur-chip))",
        WebkitBackdropFilter: "blur(var(--blur-chip))",
        WebkitTapHighlightColor: "transparent",
        ...style
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: on ? "shield-check" : status === "error" ? "triangle-alert" : "shield-off",
      size: 17,
      color: accent,
      style: {
        animation: status === "connecting" && !rm ? "nova-pulse 1.2s var(--ease-inout) infinite" : "none"
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        font: "var(--w-semibold) var(--fs-foot)/1 var(--font-sans)",
        color: accent
      }
    }, stateText));
  }
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      padding: "12px 16px",
      borderRadius: "var(--r-md)",
      background: "var(--surface-1)",
      border: "1px solid " + (on ? "var(--red-tint-2)" : "var(--line)"),
      cursor: onClick ? "pointer" : "default",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, flagCode && /*#__PURE__*/React.createElement(__ds_scope.Flag, {
    code: flagCode,
    size: 34
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-title)",
      color: "var(--text-1)"
    }
  }, location), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8,
      marginTop: 3
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-semibold) var(--fs-cap)/1 var(--font-sans)",
      letterSpacing: "var(--ls-wide)",
      textTransform: "uppercase",
      color: accent
    }
  }, stateText), timer && /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-mono)",
      color: "var(--text-3)"
    }
  }, timer))), /*#__PURE__*/React.createElement(__ds_scope.SignalBars, {
    level: signal,
    size: 18
  }));
}
Object.assign(__ds_scope, { ConnectStatus });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/connection/ConnectStatus.jsx", error: String((e && e.message) || e) }); }

// components/display/StatCard.jsx
try { (() => {
/**
 * StatCard — dashboard metric tile (Karing home: Run Duration, Traffic, Speed).
 * value can be a string or a node (for up/down rows).
 */
function StatCard({
  icon,
  label,
  value,
  sub,
  align = "left",
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--surface-1)",
      border: "1px solid var(--line)",
      borderRadius: "var(--r-md)",
      padding: "14px 16px",
      display: "flex",
      flexDirection: "column",
      gap: 8,
      alignItems: align === "center" ? "center" : "flex-start",
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 7,
      color: "var(--text-3)"
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 15,
    color: "var(--text-3)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-medium) var(--fs-cap)/1 var(--font-sans)",
      letterSpacing: "var(--ls-wide)",
      textTransform: "uppercase"
    }
  }, label)), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-semibold) var(--fs-h3)/1.1 var(--font-mono)",
      letterSpacing: "var(--ls-mono)",
      color: "var(--text-1)"
    }
  }, value), sub && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-mono)",
      color: "var(--text-3)"
    }
  }, sub));
}
Object.assign(__ds_scope, { StatCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/StatCard.jsx", error: String((e && e.message) || e) }); }

// components/display/Tag.jsx
try { (() => {
/** Tag — technical/protocol chip in the mono register: [TUIC], hy2, QUIC. */
function Tag({
  children,
  tone = "mono",
  style
}) {
  const tones = {
    mono: {
      background: "var(--surface-3)",
      color: "var(--text-2)",
      border: "1px solid var(--line-2)"
    },
    red: {
      background: "var(--red-tint)",
      color: "var(--red-400)",
      border: "1px solid var(--red-tint-2)"
    }
  };
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      height: 20,
      padding: "0 7px",
      borderRadius: "var(--r-xs)",
      font: "var(--w-medium) 11px/1 var(--font-mono)",
      letterSpacing: "var(--ls-mono)",
      ...tones[tone],
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Tag.jsx", error: String((e && e.message) || e) }); }

// components/forms/Radio.jsx
try { (() => {
/** Radio — single-select dot. Filled red ring when selected. */
function Radio({
  checked = false,
  onChange,
  size = 22,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    role: "radio",
    "aria-checked": checked,
    disabled: disabled,
    onClick: () => !disabled && onChange && onChange(true),
    style: {
      width: size,
      height: size,
      borderRadius: "var(--r-full)",
      background: "transparent",
      border: "2px solid " + (checked ? "var(--red-500)" : "var(--line-strong)"),
      display: "grid",
      placeItems: "center",
      cursor: disabled ? "not-allowed" : "pointer",
      opacity: disabled ? 0.4 : 1,
      transition: "border-color var(--dur-2)",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: size * 0.5,
      height: size * 0.5,
      borderRadius: "var(--r-full)",
      background: "var(--red-500)",
      boxShadow: checked ? "0 0 8px var(--red-glow)" : "none",
      transform: checked ? "scale(1)" : "scale(0)",
      transition: "transform var(--dur-2) var(--ease-out)"
    }
  }));
}
Object.assign(__ds_scope, { Radio });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Radio.jsx", error: String((e && e.message) || e) }); }

// components/forms/SearchField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** SearchField — rounded search input used in Countries / Select Server. */
function SearchField({
  value,
  onChange,
  placeholder = "Search location",
  trailing,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10,
      height: 48,
      padding: "0 16px",
      borderRadius: "var(--r-md)",
      background: "var(--surface-2)",
      border: "1px solid var(--line)",
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "search",
    size: 18,
    color: "var(--text-3)"
  }), /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    onChange: e => onChange && onChange(e.target.value),
    placeholder: placeholder,
    style: {
      flex: 1,
      background: "transparent",
      border: "none",
      outline: "none",
      color: "var(--text-1)",
      font: "var(--text-sub)"
    }
  }, rest)), trailing);
}
Object.assign(__ds_scope, { SearchField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SearchField.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
/** SegmentedControl — Rule / Global style switch (from Karing). */
function SegmentedControl({
  options = [],
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "inline-flex",
      padding: 3,
      gap: 2,
      borderRadius: "var(--r-pill)",
      background: "var(--surface-3)",
      border: "1px solid var(--line)",
      ...style
    }
  }, options.map(o => {
    const val = typeof o === "string" ? o : o.value;
    const lbl = typeof o === "string" ? o : o.label;
    const active = val === value;
    return /*#__PURE__*/React.createElement("button", {
      key: val,
      onClick: () => onChange && onChange(val),
      style: {
        padding: "8px 18px",
        borderRadius: "var(--r-pill)",
        cursor: "pointer",
        font: "var(--w-medium) var(--fs-foot)/1 var(--font-sans)",
        color: active ? "var(--text-on-red)" : "var(--text-2)",
        background: active ? "var(--red-600)" : "transparent",
        boxShadow: active ? "var(--glow-red-soft)" : "none",
        transition: "background var(--dur-2), color var(--dur-2)",
        WebkitTapHighlightColor: "transparent"
      }
    }, lbl);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
/** Select — dropdown row (settings). Presentational; toggles a caret. */
function Select({
  value,
  placeholder = "Select",
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      gap: 10,
      width: "100%",
      height: 48,
      padding: "0 16px",
      borderRadius: "var(--r-md)",
      background: "var(--surface-3)",
      border: "1px solid var(--line-2)",
      cursor: "pointer",
      color: value ? "var(--text-1)" : "var(--text-3)",
      font: "var(--text-sub)",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", null, value || placeholder), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-down",
    size: 18,
    color: "var(--text-3)"
  }));
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
/** Switch — iOS-style toggle. Red when on. */
function Switch({
  checked = false,
  onChange,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    role: "switch",
    "aria-checked": checked,
    disabled: disabled,
    onClick: () => !disabled && onChange && onChange(!checked),
    style: {
      width: 52,
      height: 31,
      borderRadius: "var(--r-pill)",
      position: "relative",
      background: checked ? "var(--red-500)" : "var(--surface-4)",
      border: "1px solid " + (checked ? "transparent" : "var(--line-2)"),
      cursor: disabled ? "not-allowed" : "pointer",
      opacity: disabled ? 0.4 : 1,
      transition: "background var(--dur-2) var(--ease-out)",
      WebkitTapHighlightColor: "transparent",
      boxShadow: checked ? "var(--glow-red-soft)" : "none",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      top: 2,
      left: checked ? 23 : 2,
      width: 25,
      height: 25,
      borderRadius: "var(--r-full)",
      background: "#fff",
      boxShadow: "0 2px 5px rgba(0,0,0,0.4)",
      transition: "left var(--dur-2) var(--ease-out)"
    }
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/lists/ListRow.jsx
try { (() => {
/**
 * ListRow — settings / menu row. Leading icon, title, optional value, trailing.
 * trailing defaults to a chevron unless you pass one (Switch, value text, etc).
 */
function ListRow({
  icon,
  title,
  subtitle,
  value,
  trailing,
  chevron = true,
  onClick,
  danger = false,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      minHeight: "var(--row-h)",
      padding: "10px 16px",
      background: "var(--surface-1)",
      cursor: onClick ? "pointer" : "default",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement("span", {
    style: {
      display: "grid",
      placeItems: "center",
      width: 30,
      height: 30,
      color: danger ? "var(--red-400)" : "var(--text-2)"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 19
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-body)",
      color: danger ? "var(--red-400)" : "var(--text-1)"
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-3)",
      marginTop: 2
    }
  }, subtitle)), value != null && /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-sub)",
      color: "var(--text-3)",
      textAlign: "right",
      maxWidth: 160
    }
  }, value), trailing, trailing == null && chevron && onClick && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-right",
    size: 18,
    color: "var(--text-4)"
  }));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/lists/SectionLabel.jsx
try { (() => {
/** SectionLabel — quiet uppercase group header ("Best connection", "Main"). */
function SectionLabel({
  children,
  trailing,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      padding: "0 4px 8px",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--w-medium) var(--fs-cap)/1 var(--font-sans)",
      letterSpacing: "var(--ls-label)",
      textTransform: "uppercase",
      color: "var(--text-3)"
    }
  }, children), trailing);
}
Object.assign(__ds_scope, { SectionLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/SectionLabel.jsx", error: String((e && e.message) || e) }); }

// components/lists/ServerRow.jsx
try { (() => {
/**
 * ServerRow — the core selectable location/node row.
 * Leading: country flag (flagCode) OR a protocol tag (tag).
 * Trailing options: latency (ms), signal bars, and a select control
 * (radio dot or a quality status dot).
 */
function ServerRow({
  flagCode,
  tag,
  name,
  sub,
  ms,
  signal,
  selected = false,
  select = "radio",
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      minHeight: "var(--row-h-lg)",
      padding: "12px 16px",
      cursor: onClick ? "pointer" : "default",
      background: selected ? "var(--red-tint)" : "transparent",
      borderRadius: "var(--r-md)",
      transition: "background var(--dur-2)",
      WebkitTapHighlightColor: "transparent",
      ...style
    }
  }, flagCode && /*#__PURE__*/React.createElement(__ds_scope.Flag, {
    code: flagCode,
    size: 30
  }), tag && /*#__PURE__*/React.createElement(__ds_scope.Tag, null, tag), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-title)",
      color: "var(--text-1)",
      whiteSpace: "nowrap",
      overflow: "hidden",
      textOverflow: "ellipsis"
    }
  }, name), sub && /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-3)",
      marginTop: 2
    }
  }, sub)), ms != null && /*#__PURE__*/React.createElement(__ds_scope.LatencyBadge, {
    ms: ms,
    showDot: signal == null
  }), signal != null && /*#__PURE__*/React.createElement(__ds_scope.SignalBars, {
    level: signal,
    size: 16
  }), select === "radio" && /*#__PURE__*/React.createElement(__ds_scope.Radio, {
    checked: selected,
    onChange: onClick
  }), select === "dot" && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 9,
      height: 9,
      borderRadius: "var(--r-full)",
      background: selected ? "var(--red-500)" : "var(--sig-good)",
      boxShadow: "0 0 8px " + (selected ? "var(--red-glow)" : "var(--sig-good)")
    }
  }));
}
Object.assign(__ds_scope, { ServerRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/ServerRow.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavBar.jsx
try { (() => {
/**
 * NavBar — top bar. Centered title, optional back and trailing actions.
 * Pass a wordmark node as `brand` to use the logotype instead of a title.
 */
function NavBar({
  title,
  brand,
  onBack,
  backIcon = "chevron-left",
  left,
  right,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8,
      height: "var(--nav-h)",
      padding: "0 12px",
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8,
      minWidth: 44
    }
  }, onBack && /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: backIcon,
    variant: "plain",
    size: 36,
    onClick: onBack
  }), left), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: "center",
      overflow: "hidden"
    }
  }, brand || /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-title)",
      color: "var(--text-1)",
      whiteSpace: "nowrap"
    }
  }, title)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 4,
      minWidth: 44,
      justifyContent: "flex-end"
    }
  }, right));
}
Object.assign(__ds_scope, { NavBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/TabBar.jsx
try { (() => {
/**
 * TabBar — bottom navigation. Active tab tints red with a soft glow dot.
 * items: [{ id, icon, label? }]
 */
function TabBar({
  items = [],
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-around",
      height: 64,
      padding: "0 8px",
      background: "rgba(16,16,21,0.86)",
      borderTop: "1px solid var(--line)",
      backdropFilter: "blur(var(--blur-sheet))",
      WebkitBackdropFilter: "blur(var(--blur-sheet))",
      ...style
    }
  }, items.map(it => {
    const active = it.id === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.id,
      onClick: () => onChange && onChange(it.id),
      style: {
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 4,
        flex: 1,
        padding: "8px 0",
        cursor: "pointer",
        background: "none",
        color: active ? "var(--red-400)" : "var(--text-3)",
        transition: "color var(--dur-2)",
        WebkitTapHighlightColor: "transparent"
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: it.icon,
      size: 22,
      stroke: active ? 2 : 1.75,
      style: {
        filter: active ? "drop-shadow(0 0 8px var(--red-glow))" : "none"
      }
    }), it.label && /*#__PURE__*/React.createElement("span", {
      style: {
        font: "var(--w-medium) 10px/1 var(--font-sans)",
        letterSpacing: "var(--ls-wide)"
      }
    }, it.label));
  }));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/TabBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/App.jsx
try { (() => {
const {
  TabBar: ATab
} = window.C;
const fmt = s => {
  const h = Math.floor(s / 3600),
    m = Math.floor(s % 3600 / 60),
    x = s % 60;
  const p = n => String(n).padStart(2, "0");
  return p(h) + ":" + p(m) + ":" + p(x);
};
const App = () => {
  const D = window.NOVA_DATA;
  const [entered, setEntered] = React.useState(false);
  const [tab, setTab] = React.useState("home");
  const [status, setStatus] = React.useState("off");
  const [sel, setSel] = React.useState(D.best[0]);
  const [mode, setMode] = React.useState("Rule");
  const [q, setQ] = React.useState("");
  const [elapsed, setElapsed] = React.useState(0);
  const [down, setDown] = React.useState(0);
  const [up, setUp] = React.useState(0);
  const [series, setSeries] = React.useState({
    up: [2, 3, 3, 4, 3, 5, 4, 6],
    down: [4, 6, 5, 8, 7, 9, 8, 11]
  });
  const tRef = React.useRef(null),
    cRef = React.useRef(null);
  const stopTick = () => {
    clearInterval(tRef.current);
    clearInterval(cRef.current);
  };
  React.useEffect(() => () => stopTick(), []);
  const toggle = () => {
    if (status === "off") {
      setStatus("connecting");
      setTimeout(() => {
        setStatus("on");
        setElapsed(0);
        setDown(48);
        setUp(28);
        tRef.current = setInterval(() => setElapsed(e => e + 1), 1000);
        cRef.current = setInterval(() => {
          setDown(d => Math.max(30, Math.min(96, d + (Math.random() * 16 - 8))));
          setUp(u => Math.max(12, Math.min(60, u + (Math.random() * 10 - 5))));
          setSeries(s => ({
            up: [...s.up.slice(1), 3 + Math.random() * 8],
            down: [...s.down.slice(1), 5 + Math.random() * 10]
          }));
        }, 1200);
      }, 1500);
    } else {
      setStatus("off");
      stopTick();
      setElapsed(0);
      setDown(0);
      setUp(0);
    }
  };
  const selectServer = s => {
    setSel(s);
    setTab("home");
  };
  if (!entered) return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Welcome, {
    onEnter: () => setEntered(true)
  }));
  const screens = {
    home: /*#__PURE__*/React.createElement(Home, {
      status: status,
      onToggle: toggle,
      sel: sel,
      timer: fmt(elapsed),
      down: down,
      up: up,
      series: series,
      onOpenServers: () => setTab("servers"),
      onSettings: () => setTab("settings")
    }),
    servers: /*#__PURE__*/React.createElement(Servers, {
      sel: sel,
      onSelect: selectServer,
      onBack: () => setTab("home"),
      q: q,
      setQ: setQ
    }),
    rules: /*#__PURE__*/React.createElement(Rules, {
      mode: mode,
      setMode: setMode
    }),
    settings: /*#__PURE__*/React.createElement(Settings, {
      onBack: () => setTab("home")
    })
  };
  return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      position: "relative"
    }
  }, screens[tab]), /*#__PURE__*/React.createElement(ATab, {
    value: tab,
    onChange: setTab,
    items: [{
      id: "home",
      icon: "house"
    }, {
      id: "servers",
      icon: "globe"
    }, {
      id: "rules",
      icon: "shield"
    }, {
      id: "settings",
      icon: "settings"
    }]
  }));
};
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Home.jsx
try { (() => {
const {
  NavBar: HNav,
  IconButton: HIcon,
  ConnectButton: HConn,
  ConnectStatus: HStatus,
  Card: HCard,
  StatCard: HStat,
  SpeedGauge: HGauge,
  MiniChart: HChart,
  ServerRow: HRow,
  Flag: HFlag,
  Icon: HGlyph,
  Badge: HBadge
} = window.C;
const Home = ({
  status,
  onToggle,
  sel,
  onOpenServers,
  onSettings,
  timer,
  down,
  up,
  series
}) => {
  const on = status === "on";
  const label = on ? "Подключено" : status === "connecting" ? "Соединение…" : "Нажмите, чтобы подключиться";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement(HNav, {
    brand: /*#__PURE__*/React.createElement("span", {
      style: {
        font: "var(--w-bold) 17px/1 var(--font-sans)",
        letterSpacing: "-0.01em"
      }
    }, "Woman in ", /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--red-500)"
      }
    }, "Red")),
    left: /*#__PURE__*/React.createElement(HIcon, {
      icon: "grip",
      variant: "plain",
      size: 36
    }),
    right: /*#__PURE__*/React.createElement(HIcon, {
      icon: "settings",
      variant: "plain",
      size: 36,
      onClick: onSettings
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflowY: "auto",
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      height: 320,
      display: "grid",
      placeItems: "center"
    }
  }, /*#__PURE__*/React.createElement(RadarField, {
    active: on,
    height: 320
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      zIndex: 2,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 22
    }
  }, /*#__PURE__*/React.createElement(HConn, {
    status: status,
    size: 168,
    label: label,
    onClick: onToggle
  }), /*#__PURE__*/React.createElement(HStatus, {
    variant: "pill",
    status: status,
    onClick: onToggle
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "4px var(--gutter) 24px",
      display: "flex",
      flexDirection: "column",
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(HCard, {
    tone: "elevated",
    pad: 0
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onOpenServers,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      padding: "14px 16px",
      cursor: "pointer"
    }
  }, /*#__PURE__*/React.createElement(HFlag, {
    code: sel.code,
    size: 38
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-title)",
      color: "var(--text-1)"
    }
  }, sel.name), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-mono)",
      color: "var(--text-3)",
      marginTop: 2
    }
  }, on ? "IP 185.42." + sel.ms + ".7" : sel.city)), /*#__PURE__*/React.createElement(HGlyph, {
    name: "chevron-right",
    size: 20,
    color: "var(--text-4)"
  }))), on ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(HCard, {
    tone: "elevated",
    pad: 16,
    style: {
      display: "grid",
      placeItems: "center"
    }
  }, /*#__PURE__*/React.createElement(HGauge, {
    value: down,
    max: 100,
    unit: "\u041C\u0431\u0438\u0442/\u0441 \u2193",
    size: 190
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(HCard, {
    tone: "elevated",
    pad: 13,
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6,
      color: "var(--sig-good)",
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement(HGlyph, {
    name: "arrow-up",
    size: 14
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-2)"
    }
  }, "\u041E\u0442\u0434\u0430\u0447\u0430")), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-semibold) var(--fs-h3)/1 var(--font-mono)",
      color: "var(--text-1)"
    }
  }, up.toFixed(1), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-3)",
      marginLeft: 4
    }
  }, "\u041C\u0431\u0438\u0442/\u0441")), /*#__PURE__*/React.createElement(HChart, {
    data: series.up,
    color: "var(--sig-good)",
    width: 150,
    height: 44,
    style: {
      marginTop: 6,
      width: "100%"
    }
  })), /*#__PURE__*/React.createElement(HCard, {
    tone: "elevated",
    pad: 13,
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6,
      color: "var(--red-400)",
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement(HGlyph, {
    name: "arrow-down",
    size: 14
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-2)"
    }
  }, "\u041F\u0440\u0438\u0451\u043C")), /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-semibold) var(--fs-h3)/1 var(--font-mono)",
      color: "var(--text-1)"
    }
  }, down.toFixed(1), /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--text-foot)",
      color: "var(--text-3)",
      marginLeft: 4
    }
  }, "\u041C\u0431\u0438\u0442/\u0441")), /*#__PURE__*/React.createElement(HChart, {
    data: series.down,
    color: "var(--red-500)",
    width: 150,
    height: 44,
    style: {
      marginTop: 6,
      width: "100%"
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(HStat, {
    label: "\u0412\u0440\u0435\u043C\u044F",
    value: timer,
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(HStat, {
    label: "\u0417\u0430\u0434\u0435\u0440\u0436\u043A\u0430",
    value: sel.ms + "ms",
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(HStat, {
    label: "\u041F\u043E\u0442\u0435\u0440\u0438",
    value: "0.2%",
    style: {
      flex: 1
    }
  }))) : /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--w-medium) var(--fs-cap)/1 var(--font-sans)",
      letterSpacing: "var(--ls-label)",
      textTransform: "uppercase",
      color: "var(--text-3)",
      textAlign: "center",
      marginBottom: 14
    }
  }, "\u041E\u043F\u0442\u0438\u043C\u0430\u043B\u044C\u043D\u044B\u0435 \u043B\u043E\u043A\u0430\u0446\u0438\u0438"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "center",
      gap: 18
    }
  }, ["fr", "nl", "de"].map(c => /*#__PURE__*/React.createElement(HFlag, {
    key: c,
    code: c,
    size: 48
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "center",
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement(HBadge, {
    tone: "red"
  }, "\u0410\u0432\u0442\u043E \xB7 \u043C\u0438\u043D. \u0437\u0430\u0434\u0435\u0440\u0436\u043A\u0430"))))));
};
window.Home = Home;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Home.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Phone.jsx
try { (() => {
const StatusBar = ({
  dark
}) => /*#__PURE__*/React.createElement("div", {
  style: {
    height: "var(--safe-top)",
    display: "flex",
    alignItems: "flex-end",
    justifyContent: "space-between",
    padding: "0 26px 8px",
    flexShrink: 0,
    position: "relative",
    zIndex: 5
  }
}, /*#__PURE__*/React.createElement("span", {
  style: {
    font: "var(--w-semibold) 15px/1 var(--font-sans)",
    color: "var(--text-1)"
  }
}, "9:41"), /*#__PURE__*/React.createElement("div", {
  style: {
    display: "flex",
    alignItems: "center",
    gap: 7,
    color: "var(--text-1)"
  }
}, /*#__PURE__*/React.createElement(Icon, {
  name: "signal",
  size: 17
}), /*#__PURE__*/React.createElement(Icon, {
  name: "wifi",
  size: 17
}), /*#__PURE__*/React.createElement(Icon, {
  name: "battery-full",
  size: 22
})));
const Phone = ({
  children
}) => /*#__PURE__*/React.createElement("div", {
  style: {
    width: "var(--screen-w)",
    height: "var(--screen-h)",
    position: "relative",
    background: "var(--void)",
    borderRadius: 44,
    overflow: "hidden",
    border: "1px solid var(--line-2)",
    boxShadow: "var(--shadow-lg)",
    display: "flex",
    flexDirection: "column"
  }
}, /*#__PURE__*/React.createElement(StatusBar, null), /*#__PURE__*/React.createElement("div", {
  style: {
    flex: 1,
    minHeight: 0,
    position: "relative",
    display: "flex",
    flexDirection: "column"
  }
}, children), /*#__PURE__*/React.createElement("div", {
  style: {
    position: "absolute",
    bottom: 8,
    left: "50%",
    transform: "translateX(-50%)",
    width: 134,
    height: 5,
    borderRadius: 3,
    background: "var(--text-1)",
    opacity: 0.9,
    zIndex: 20
  }
}));
window.Phone = Phone;
window.StatusBar = StatusBar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Phone.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/RadarField.jsx
try { (() => {
const RadarField = ({
  active = false,
  height = 300
}) => {
  const c = 200;
  const rings = [60, 110, 160, 190];
  const nodes = [{
    x: 120,
    y: 130,
    r: 2.4,
    on: false
  }, {
    x: 268,
    y: 96,
    r: 2,
    on: false
  }, {
    x: 300,
    y: 220,
    r: 2.6,
    on: false
  }, {
    x: 96,
    y: 250,
    r: 2,
    on: false
  }, {
    x: 200,
    y: 200,
    r: 4,
    on: true
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      background: "radial-gradient(120% 90% at 50% 42%, rgba(255,45,62,0.10), transparent 60%)",
      opacity: active ? 1 : 0.35,
      transition: "opacity 600ms var(--ease-out)"
    }
  }), /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 400 400",
    preserveAspectRatio: "xMidYMid slice",
    style: {
      position: "absolute",
      left: "50%",
      top: "46%",
      width: "140%",
      transform: "translate(-50%,-50%)",
      opacity: 0.9
    }
  }, /*#__PURE__*/React.createElement("defs", null, /*#__PURE__*/React.createElement("radialGradient", {
    id: "rf-fade",
    cx: "50%",
    cy: "46%",
    r: "55%"
  }, /*#__PURE__*/React.createElement("stop", {
    offset: "0%",
    stopColor: "#fff",
    stopOpacity: "1"
  }), /*#__PURE__*/React.createElement("stop", {
    offset: "100%",
    stopColor: "#fff",
    stopOpacity: "0"
  })), /*#__PURE__*/React.createElement("linearGradient", {
    id: "rf-sweep",
    x1: "50%",
    y1: "50%",
    x2: "100%",
    y2: "50%"
  }, /*#__PURE__*/React.createElement("stop", {
    offset: "0%",
    stopColor: "var(--red-500)",
    stopOpacity: "0.34"
  }), /*#__PURE__*/React.createElement("stop", {
    offset: "100%",
    stopColor: "var(--red-500)",
    stopOpacity: "0"
  })), /*#__PURE__*/React.createElement("mask", {
    id: "rf-mask"
  }, /*#__PURE__*/React.createElement("rect", {
    width: "400",
    height: "400",
    fill: "url(#rf-fade)"
  }))), /*#__PURE__*/React.createElement("g", {
    mask: "url(#rf-mask)",
    stroke: "var(--line-2)",
    strokeWidth: "1",
    fill: "none"
  }, rings.map((r, i) => /*#__PURE__*/React.createElement("circle", {
    key: i,
    cx: c,
    cy: c,
    r: r
  })), /*#__PURE__*/React.createElement("line", {
    x1: c,
    y1: "0",
    x2: c,
    y2: "400"
  }), /*#__PURE__*/React.createElement("line", {
    x1: "0",
    y1: c,
    x2: "400",
    y2: c
  }), /*#__PURE__*/React.createElement("line", {
    x1: "46",
    y1: "46",
    x2: "354",
    y2: "354"
  }), /*#__PURE__*/React.createElement("line", {
    x1: "354",
    y1: "46",
    x2: "46",
    y2: "354"
  })), active && /*#__PURE__*/React.createElement("g", {
    mask: "url(#rf-mask)",
    style: {
      transformOrigin: "200px 200px",
      animation: "nova-sweep 6s linear infinite"
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M200 200 L390 200 A190 190 0 0 1 340 330 Z",
    fill: "url(#rf-sweep)"
  })), /*#__PURE__*/React.createElement("g", {
    mask: "url(#rf-mask)"
  }, nodes.map((n, i) => {
    const col = n.on && active ? "var(--red-500)" : "var(--text-4)";
    return /*#__PURE__*/React.createElement("g", {
      key: i
    }, /*#__PURE__*/React.createElement("circle", {
      cx: n.x,
      cy: n.y,
      r: n.r,
      fill: col,
      style: {
        filter: n.on && active ? "drop-shadow(0 0 6px var(--red-glow))" : "none"
      }
    }), n.on && active && /*#__PURE__*/React.createElement("circle", {
      cx: n.x,
      cy: n.y,
      r: "10",
      fill: "none",
      stroke: "var(--red-500)",
      strokeWidth: "1",
      style: {
        transformOrigin: n.x + "px " + n.y + "px",
        animation: "nova-ring 2.6s var(--ease-out) infinite"
      }
    }));
  }))));
};
window.RadarField = RadarField;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/RadarField.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Rules.jsx
try { (() => {
const {
  NavBar: RNav,
  IconButton: RIcon,
  ListRow: RRow,
  SectionLabel: RLabel,
  Switch: RSwitch,
  SegmentedControl: RSeg,
  Badge: RBadge
} = window.C;
const Rules = ({
  mode,
  setMode
}) => {
  const D = window.NOVA_DATA;
  const [a, setA] = React.useState(true),
    [b, setB] = React.useState(true),
    [c, setC] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement(RNav, {
    title: "\u041F\u0440\u0430\u0432\u0438\u043B\u0430 \u043C\u0430\u0440\u0448\u0440\u0443\u0442\u0438\u0437\u0430\u0446\u0438\u0438",
    right: /*#__PURE__*/React.createElement(RIcon, {
      icon: "pencil",
      variant: "plain",
      size: 36
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflowY: "auto",
      padding: "4px var(--gutter) 24px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "center",
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement(RSeg, {
    options: [{
      label: "Правило",
      value: "Rule"
    }, {
      label: "Глобально",
      value: "Global"
    }],
    value: mode,
    onChange: setMode
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--surface-1)",
      border: "1px solid var(--line)",
      borderRadius: "var(--r-lg)",
      overflow: "hidden",
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement(RRow, {
    icon: "eye-off",
    title: "\u0421\u043A\u0440\u044B\u0432\u0430\u0442\u044C \u043D\u0435\u0438\u0441\u043F\u043E\u043B\u044C\u0437\u0443\u0435\u043C\u044B\u0435 \u0433\u0440\u0443\u043F\u043F\u044B",
    trailing: /*#__PURE__*/React.createElement(RSwitch, {
      checked: a,
      onChange: setA
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 1,
      background: "var(--line)"
    }
  }), /*#__PURE__*/React.createElement(RRow, {
    icon: "house-wifi",
    title: "\u041B\u043E\u043A\u0430\u043B\u044C\u043D\u0430\u044F \u0441\u0435\u0442\u044C \u043D\u0430\u043F\u0440\u044F\u043C\u0443\u044E",
    trailing: /*#__PURE__*/React.createElement(RSwitch, {
      checked: b,
      onChange: setB
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 1,
      background: "var(--line)"
    }
  }), /*#__PURE__*/React.createElement(RRow, {
    icon: "building-2",
    title: "\u041E\u0442\u043A\u043B\u044E\u0447\u0438\u0442\u044C \u043F\u0440\u0430\u0432\u0438\u043B\u0430 \u043F\u0440\u043E\u0432\u0430\u0439\u0434\u0435\u0440\u0430",
    trailing: /*#__PURE__*/React.createElement(RSwitch, {
      checked: c,
      onChange: setC
    })
  })), /*#__PURE__*/React.createElement(RLabel, {
    trailing: /*#__PURE__*/React.createElement(RBadge, {
      tone: "neutral"
    }, D.rules.length, " \u0433\u0440\u0443\u043F\u043F")
  }, "\u0421\u0432\u043E\u0438 \u0433\u0440\u0443\u043F\u043F\u044B \u043C\u0430\u0440\u0448\u0440\u0443\u0442\u0438\u0437\u0430\u0446\u0438\u0438"), /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--surface-1)",
      border: "1px solid var(--line)",
      borderRadius: "var(--r-lg)",
      overflow: "hidden"
    }
  }, D.rules.map((r, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: r.name
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      height: 1,
      background: "var(--line)"
    }
  }), /*#__PURE__*/React.createElement(RRow, {
    icon: r.icon,
    title: r.name,
    value: r.value,
    onClick: () => {}
  }))))));
};
window.Rules = Rules;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Rules.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Servers.jsx
try { (() => {
const {
  NavBar: SNav,
  IconButton: SIcon,
  SearchField: SSearch,
  SectionLabel: SLabel,
  ServerRow: SRow
} = window.C;
const Servers = ({
  sel,
  onSelect,
  onBack,
  q,
  setQ
}) => {
  const D = window.NOVA_DATA;
  const match = x => !q || x.name.toLowerCase().includes(q.toLowerCase());
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement(SNav, {
    title: "\u0412\u044B\u0431\u043E\u0440 \u043B\u043E\u043A\u0430\u0446\u0438\u0438",
    onBack: onBack,
    right: /*#__PURE__*/React.createElement(SIcon, {
      icon: "refresh-cw",
      variant: "plain",
      size: 36
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "4px var(--gutter) 12px"
    }
  }, /*#__PURE__*/React.createElement(SSearch, {
    value: q,
    onChange: setQ,
    placeholder: "\u041F\u043E\u0438\u0441\u043A \u043B\u043E\u043A\u0430\u0446\u0438\u0438"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflowY: "auto",
      padding: "4px var(--gutter) 24px"
    }
  }, /*#__PURE__*/React.createElement(SLabel, null, "\u041B\u0443\u0447\u0448\u0435\u0435 \u0441\u043E\u0435\u0434\u0438\u043D\u0435\u043D\u0438\u0435"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 20
    }
  }, D.best.filter(match).map(s => /*#__PURE__*/React.createElement(SRow, {
    key: s.code,
    flagCode: s.code,
    name: s.name,
    sub: s.city,
    ms: s.ms,
    selected: sel.code === s.code,
    onClick: () => onSelect(s)
  }))), /*#__PURE__*/React.createElement(SLabel, null, "\u0414\u0440\u0443\u0433\u0438\u0435 \u0441\u043E\u0435\u0434\u0438\u043D\u0435\u043D\u0438\u044F"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 20
    }
  }, D.other.filter(match).map(s => /*#__PURE__*/React.createElement(SRow, {
    key: s.code + s.city,
    flagCode: s.code,
    name: s.name,
    sub: s.city,
    ms: s.ms,
    selected: sel.code === s.code && sel.city === s.city,
    onClick: () => onSelect(s)
  }))), /*#__PURE__*/React.createElement(SLabel, null, "\u0421\u0432\u043E\u0438 \u0443\u0437\u043B\u044B"), /*#__PURE__*/React.createElement("div", null, D.nodes.map((n, i) => /*#__PURE__*/React.createElement(SRow, {
    key: i,
    tag: n.tag,
    name: n.name,
    sub: n.sub,
    ms: n.ms,
    select: "none"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: "center",
      padding: "28px 0 8px",
      color: "var(--text-4)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: "var(--text-foot)"
    }
  }, "\u041D\u043E\u0432\u044B\u0435 \u043B\u043E\u043A\u0430\u0446\u0438\u0438 \u043E\u0442\u043A\u0440\u044B\u0432\u0430\u044E\u0442\u0441\u044F \u043F\u043E \u043C\u0435\u0440\u0435 \u0434\u043E\u0432\u0435\u0440\u0438\u044F."))));
};
window.Servers = Servers;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Servers.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Settings.jsx
try { (() => {
const {
  NavBar: GNav,
  ListRow: GRow,
  SectionLabel: GLabel,
  Switch: GSwitch,
  Select: GSelect,
  Radio: GRadio
} = window.C;
const grp = {
  background: "var(--surface-1)",
  border: "1px solid var(--line)",
  borderRadius: "var(--r-lg)",
  overflow: "hidden",
  marginBottom: 20
};
const sep = /*#__PURE__*/React.createElement("div", {
  style: {
    height: 1,
    background: "var(--line)"
  }
});
const Settings = ({
  onBack
}) => {
  const [nov, setNov] = React.useState(false);
  const [dns, setDns] = React.useState(true);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement(GNav, {
    title: "\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438",
    onBack: onBack
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minHeight: 0,
      overflowY: "auto",
      padding: "4px var(--gutter) 24px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: grp
  }, /*#__PURE__*/React.createElement(GRow, {
    icon: "graduation-cap",
    title: "\u0420\u0435\u0436\u0438\u043C \u043D\u043E\u0432\u0438\u0447\u043A\u0430",
    subtitle: "\u0421\u043A\u0440\u044B\u0442\u044C \u0440\u0430\u0441\u0448\u0438\u0440\u0435\u043D\u043D\u044B\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438",
    trailing: /*#__PURE__*/React.createElement(GSwitch, {
      checked: nov,
      onChange: setNov
    })
  })), /*#__PURE__*/React.createElement(GLabel, null, "\u041E\u0441\u043D\u043E\u0432\u043D\u043E\u0435"), /*#__PURE__*/React.createElement("div", {
    style: grp
  }, /*#__PURE__*/React.createElement(GRow, {
    icon: "download",
    title: "\u041F\u043E\u043B\u0443\u0447\u0438\u0442\u044C \u0442\u0440\u0430\u0444\u0438\u043A",
    onClick: () => {}
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "book-open",
    title: "\u041E\u0431\u0443\u0447\u0435\u043D\u0438\u0435",
    onClick: () => {}
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "circle-help",
    title: "\u0412\u043E\u043F\u0440\u043E\u0441\u044B \u0438 \u043E\u0442\u0432\u0435\u0442\u044B",
    onClick: () => {}
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "list-checks",
    title: "\u0427\u0430\u0441\u0442\u044B\u0435 \u043D\u0430\u0431\u043E\u0440\u044B \u043F\u0440\u0430\u0432\u0438\u043B",
    onClick: () => {}
  })), /*#__PURE__*/React.createElement(GLabel, null, "\u0421\u0435\u0442\u044C"), /*#__PURE__*/React.createElement("div", {
    style: grp
  }, /*#__PURE__*/React.createElement(GRow, {
    icon: "shield-check",
    title: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0443\u0442\u0435\u0447\u0435\u043A DNS",
    trailing: /*#__PURE__*/React.createElement(GSwitch, {
      checked: dns,
      onChange: setDns
    })
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "gauge",
    title: "URL \u043F\u0440\u043E\u0432\u0435\u0440\u043A\u0438 \u0441\u043A\u043E\u0440\u043E\u0441\u0442\u0438",
    value: "speed.cloudflare.com",
    onClick: () => {}
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "activity",
    title: "URL \u043F\u0440\u043E\u0432\u0435\u0440\u043A\u0438 \u0437\u0430\u0434\u0435\u0440\u0436\u043A\u0438",
    value: "gstatic.com/204",
    onClick: () => {}
  })), /*#__PURE__*/React.createElement(GLabel, null, "\u041F\u0440\u043E\u0444\u0438\u043B\u0438"), /*#__PURE__*/React.createElement("div", {
    style: grp
  }, /*#__PURE__*/React.createElement(GRow, {
    icon: "plus",
    title: "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u043F\u0440\u043E\u0444\u0438\u043B\u044C",
    onClick: () => {}
  }), sep, /*#__PURE__*/React.createElement(GRow, {
    icon: "layers",
    title: "\u041C\u043E\u0438 \u043F\u0440\u043E\u0444\u0438\u043B\u0438",
    value: "xnv",
    onClick: () => {}
  })), /*#__PURE__*/React.createElement(GLabel, null, "\u0418\u043D\u0442\u0435\u0440\u0432\u0430\u043B \u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u0438\u044F"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement(GSelect, {
    value: "\u041A\u0430\u0436\u0434\u044B\u0435 12 \u0447\u0430\u0441\u043E\u0432"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: "center",
      color: "var(--text-4)",
      font: "var(--text-mono)",
      padding: "8px 0 4px"
    }
  }, "Woman in Red \xB7 v2.4.0 \xB7 \u0441\u0431\u043E\u0440\u043A\u0430 1102")));
};
window.Settings = Settings;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Settings.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/Welcome.jsx
try { (() => {
const {
  Button: WBtn
} = window.C;
const Welcome = ({
  onEnter
}) => /*#__PURE__*/React.createElement("div", {
  style: {
    position: "absolute",
    inset: 0,
    display: "flex",
    flexDirection: "column"
  }
}, /*#__PURE__*/React.createElement(RadarField, {
  active: true
}), /*#__PURE__*/React.createElement("div", {
  style: {
    position: "relative",
    zIndex: 2,
    flex: 1,
    display: "flex",
    flexDirection: "column",
    justifyContent: "flex-end",
    padding: "0 var(--gutter) 64px"
  }
}, /*#__PURE__*/React.createElement("div", {
  style: {
    font: "var(--w-medium) var(--fs-cap)/1 var(--font-mono)",
    letterSpacing: "var(--ls-label)",
    textTransform: "uppercase",
    color: "var(--red-400)",
    marginBottom: 14
  }
}, "52.3702\xB0N \xB7 4.8952\xB0E"), /*#__PURE__*/React.createElement("div", {
  style: {
    font: "var(--w-bold) 40px/1.02 var(--font-sans)",
    letterSpacing: "-0.03em",
    color: "var(--text-1)"
  }
}, "Woman in ", /*#__PURE__*/React.createElement("span", {
  style: {
    color: "var(--red-500)"
  }
}, "Red")), /*#__PURE__*/React.createElement("div", {
  style: {
    font: "var(--text-body)",
    color: "var(--text-2)",
    marginTop: 14,
    maxWidth: 290
  }
}, "\u041B\u0438\u0447\u043D\u0430\u044F \u0434\u0432\u0435\u0440\u044C \u0432 \u043E\u0442\u043A\u0440\u044B\u0442\u044B\u0439 \u0438\u043D\u0442\u0435\u0440\u043D\u0435\u0442. \u0412\u043E\u0439\u0434\u0438\u0442\u0435 \u2014 \u0437\u0430 \u0432\u0430\u043C\u0438 \u043D\u0438\u043A\u0442\u043E \u043D\u0435 \u043F\u043E\u0441\u043B\u0435\u0434\u0443\u0435\u0442."), /*#__PURE__*/React.createElement("div", {
  style: {
    marginTop: 36
  }
}, /*#__PURE__*/React.createElement(WBtn, {
  variant: "outline",
  size: "lg",
  block: true,
  glow: true,
  iconLeft: "power",
  onClick: onEnter
}, "\u0412\u043E\u0439\u0442\u0438")), /*#__PURE__*/React.createElement("div", {
  style: {
    font: "var(--text-foot)",
    color: "var(--text-4)",
    textAlign: "center",
    marginTop: 16
  }
}, "\u0412\u0445\u043E\u0434\u044F, \u0432\u044B \u043F\u0440\u0438\u043D\u0438\u043C\u0430\u0435\u0442\u0435 \u0443\u0441\u043B\u043E\u0432\u0438\u044F \u043F\u0435\u0440\u0435\u0445\u043E\u0434\u0430.")));
window.Welcome = Welcome;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/Welcome.jsx", error: String((e && e.message) || e) }); }

// ui_kits/nova-ios/data.js
try { (() => {
window.NOVA_DATA = {
  best: [{
    code: "nl",
    name: "Нидерланды",
    city: "Амстердам",
    ms: 24,
    signal: 4
  }, {
    code: "de",
    name: "Германия",
    city: "Франкфурт",
    ms: 41,
    signal: 4
  }, {
    code: "fr",
    name: "Франция",
    city: "Париж",
    ms: 63,
    signal: 3
  }],
  other: [{
    code: "ca",
    name: "Канада",
    city: "Торонто",
    ms: 112,
    signal: 3
  }, {
    code: "us",
    name: "США",
    city: "Ашберн",
    ms: 138,
    signal: 3
  }, {
    code: "it",
    name: "Италия",
    city: "Милан",
    ms: 151,
    signal: 2
  }, {
    code: "ru",
    name: "Россия",
    city: "Москва",
    ms: 176,
    signal: 2
  }, {
    code: "jp",
    name: "Япония",
    city: "Токио",
    ms: 214,
    signal: 2
  }, {
    code: "nz",
    name: "Новая Зеландия",
    city: "Окленд",
    ms: 288,
    signal: 1
  }, {
    code: "in",
    name: "Индия",
    city: "Мумбаи",
    ms: 196,
    signal: 2
  }, {
    code: "fi",
    name: "Финляндия",
    city: "Хельсинки",
    ms: 88,
    signal: 3
  }],
  nodes: [{
    code: "kr",
    tag: "TUIC",
    name: "KR · BGP · D04",
    sub: "Авто-выбор",
    ms: 73
  }, {
    code: "kr",
    tag: "TUIC",
    name: "KR · BGP · D02",
    sub: "Авто-выбор",
    ms: 79
  }, {
    code: "us",
    tag: "hy2",
    name: "US · Сан-Хосе · 4 Гбит/с",
    sub: "Hysteria2",
    ms: 149
  }],
  rules: [{
    icon: "globe",
    name: "Google",
    value: "Текущий узел"
  }, {
    icon: "bird",
    name: "Telegram",
    value: "Текущий узел"
  }, {
    icon: "clapperboard",
    name: "Netflix",
    value: "Текущий узел"
  }, {
    icon: "apple",
    name: "Apple",
    value: "Напрямую"
  }, {
    icon: "shield-alert",
    name: "Вредоносное ПО",
    value: "Блок"
  }]
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/nova-ios/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.ConnectButton = __ds_scope.ConnectButton;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.ConnectStatus = __ds_scope.ConnectStatus;

__ds_ns.MiniChart = __ds_scope.MiniChart;

__ds_ns.SpeedGauge = __ds_scope.SpeedGauge;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Flag = __ds_scope.Flag;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.InfoCard = __ds_scope.InfoCard;

__ds_ns.LatencyBadge = __ds_scope.LatencyBadge;

__ds_ns.SignalBars = __ds_scope.SignalBars;

__ds_ns.StatCard = __ds_scope.StatCard;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.Radio = __ds_scope.Radio;

__ds_ns.SearchField = __ds_scope.SearchField;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.SectionLabel = __ds_scope.SectionLabel;

__ds_ns.ServerRow = __ds_scope.ServerRow;

__ds_ns.NavBar = __ds_scope.NavBar;

__ds_ns.TabBar = __ds_scope.TabBar;

})();
