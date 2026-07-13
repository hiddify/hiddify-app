// RitualHero — the connect ritual: cold drifting glyphs (the matrix you're leaving)
// → rabbit dash + glitch → red awakening with a decrypted greeting.
// Red stays sacred (awake/protected); the "distraction" glyphs are cold grey-blue.
const { Icon:RHIcon } = window.C;
const GLYPHS = "アイウエオカキサソタネハヲ01<>[]#$%&*+=";
const rnd = () => GLYPHS[Math.floor(Math.random() * GLYPHS.length)];
const GPOS = [
  { top:"9%",  left:"8%",  fs:22, dur:"6.5s", del:"0s" },
  { top:"40%", left:"6%",  fs:18, dur:"8s",   del:"1.2s" },
  { top:"74%", left:"16%", fs:20, dur:"7.2s", del:".6s" },
  { top:"14%", left:"82%", fs:19, dur:"7.6s", del:".9s" },
  { top:"46%", left:"86%", fs:24, dur:"6.8s", del:".3s" },
  { top:"72%", left:"80%", fs:17, dur:"8.4s", del:"1.6s" }
];

const RitualHero = ({ status, children }) => {
  const on = status === "on";
  const connecting = status === "connecting";
  const rm = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const [glyphs, setGlyphs] = React.useState(() => GPOS.map(() => rnd()));
  const [welcome, setWelcome] = React.useState("");

  // drift: swap a random glyph while OFF (skipped under reduced-motion)
  React.useEffect(() => {
    if (status !== "off" || rm) return;
    const id = setInterval(() => {
      setGlyphs((g) => { const n = [...g]; n[Math.floor(Math.random() * n.length)] = rnd(); return n; });
    }, 900);
    return () => clearInterval(id);
  }, [status]);

  // decrypt greeting on awakening
  React.useEffect(() => {
    if (!on) { setWelcome(""); return; }
    if (rm) { setWelcome("С ВОЗВРАЩЕНИЕМ"); return; }   // resolved greeting, no scramble
    const target = "С ВОЗВРАЩЕНИЕМ", start = performance.now(); let raf;
    const frame = (t) => {
      const p = Math.min(1, (t - start) / 900), rev = Math.floor(p * target.length);
      let out = "";
      for (let i = 0; i < target.length; i++) out += target[i] === " " ? " " : (i < rev ? target[i] : rnd());
      setWelcome(out);
      if (p < 1) raf = requestAnimationFrame(frame); else setWelcome(target);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [on]);

  return (
    <div style={{ position:"relative", height:340, display:"grid", placeItems:"center", overflow:"hidden" }}
      className={connecting && !rm ? "nova-shake" : ""}>
      <RadarField active={on} height={340} hideCenter={true}/>

      {/* cold drifting glyphs — the sterile matrix */}
      <div style={{ position:"absolute", inset:0, pointerEvents:"none", zIndex:1 }}>
        {GPOS.map((g, i) => (
          <span key={i} className="nova-glyph" style={{
            position:"absolute", top:g.top, left:g.left, fontFamily:"var(--font-mono)", fontWeight:600,
            fontSize:g.fs, color: on ? "#2b343b" : "#3c4a53",
            textShadow: on ? "none" : "0 0 10px rgba(70,90,102,0.45)",
            opacity: on ? 0.35 : 0.8,
            animation: rm ? "none" : "nova-floaty " + g.dur + " var(--ease-inout) infinite",
            animationDelay: g.del, animationPlayState: on ? "paused" : "running",
            transition:"color 1s var(--ease-out), opacity 1s var(--ease-out)"
          }}>{glyphs[i]}</span>
        ))}
      </div>

      {/* white rabbit dashes across during the switch */}
      {connecting && (
        <div className="nova-rabbit" style={{ position:"absolute", top:"54%", left:0, width:40, height:40, zIndex:3,
          filter:"drop-shadow(0 0 10px rgba(255,255,255,0.85))" }}>
          <svg viewBox="0 0 64 64" style={{ width:"100%", height:"100%", fill:"#f4f7f8" }}>
            <path d="M24 60c-8 0-13-5-13-13 0-6 3-10 7-13-2-3-3-7-3-13 0-4 1-8 3-8 3 0 5 5 6 12 1-.2 2-.3 3-.3s2 .1 3 .3c1-7 3-12 6-12 2 0 3 4 3 8 0 6-1 10-3 13 4 3 7 7 7 13 0 8-5 13-13 13z"/>
          </svg>
        </div>
      )}

      {/* glitch scanlines during the switch */}
      {connecting && <div className="nova-scan" style={{ position:"absolute", inset:0, zIndex:2, pointerEvents:"none",
        mixBlendMode:"screen",
        background:"repeating-linear-gradient(0deg,rgba(255,45,62,0.06) 0 1px,transparent 1px 4px)" }}/>}

      {/* decrypted greeting on awakening */}
      <div style={{ position:"absolute", top:12, width:"100%", textAlign:"center", zIndex:4,
        fontFamily:"var(--font-mono)", letterSpacing:"0.22em", fontSize:13, fontWeight:600,
        color:"var(--red-400)", opacity: on ? 1 : 0, transition:"opacity .4s var(--ease-out)",
        textShadow:"0 0 12px var(--red-glow-soft)", minHeight:16, pointerEvents:"none" }}>{welcome}</div>

      <div style={{ position:"relative", zIndex:5, marginTop:34, display:"flex", flexDirection:"column", alignItems:"center", gap:18 }}>
        {children}
      </div>
    </div>
  );
};
window.RitualHero = RitualHero;