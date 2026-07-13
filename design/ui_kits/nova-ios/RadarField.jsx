const RadarField = ({ active = false, height = 300, hideCenter = false }) => {
  const c = 200;
  const rm = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const rings = [60, 110, 160, 190];
  const allNodes = [
    { x: 120, y: 130, r: 2.4, on:false },
    { x: 268, y: 96, r: 2, on:false },
    { x: 300, y: 220, r: 2.6, on:false },
    { x: 96, y: 250, r: 2, on:false },
    { x: 200, y: 200, r: 4, on:true }
  ];
  const nodes = hideCenter ? allNodes.filter(n => !n.on) : allNodes;
  return (
    <div style={{ position:"absolute", inset:0, overflow:"hidden" }}>
      <div style={{ position:"absolute", inset:0,
        background:"radial-gradient(120% 90% at 50% 42%, rgba(255,45,62,0.10), transparent 60%)",
        opacity: active ? 1 : 0.35, transition:"opacity 600ms var(--ease-out)" }} />
      <svg viewBox="0 0 400 400" preserveAspectRatio="xMidYMid slice"
        style={{ position:"absolute", left:"50%", top:"46%", width:"140%", transform:"translate(-50%,-50%)", opacity:0.9 }}>
        <defs>
          <radialGradient id="rf-fade" cx="50%" cy="46%" r="55%">
            <stop offset="0%" stopColor="#fff" stopOpacity="1"/><stop offset="100%" stopColor="#fff" stopOpacity="0"/>
          </radialGradient>
          <linearGradient id="rf-sweep" x1="50%" y1="50%" x2="100%" y2="50%">
            <stop offset="0%" stopColor="var(--red-500)" stopOpacity="0.34"/>
            <stop offset="100%" stopColor="var(--red-500)" stopOpacity="0"/>
          </linearGradient>
          <mask id="rf-mask"><rect width="400" height="400" fill="url(#rf-fade)"/></mask>
        </defs>
        <g mask="url(#rf-mask)" stroke="var(--line-2)" strokeWidth="1" fill="none">
          {rings.map((r,i)=>(<circle key={i} cx={c} cy={c} r={r}/>))}
          <line x1={c} y1="0" x2={c} y2="400"/><line x1="0" y1={c} x2="400" y2={c}/>
          <line x1="46" y1="46" x2="354" y2="354"/><line x1="354" y1="46" x2="46" y2="354"/>
        </g>
        {active && !rm && (
          <g mask="url(#rf-mask)" style={{ transformOrigin:"200px 200px", animation:"nova-sweep 6s linear infinite" }}>
            <path d="M200 200 L390 200 A190 190 0 0 1 340 330 Z" fill="url(#rf-sweep)"/>
          </g>
        )}
        <g mask="url(#rf-mask)">
          {nodes.map((n,i)=>{
            const col = n.on && active ? "var(--red-500)" : "var(--text-4)";
            return (<g key={i}>
              <circle cx={n.x} cy={n.y} r={n.r} fill={col}
                style={{ filter: n.on&&active?"drop-shadow(0 0 6px var(--red-glow))":"none" }}/>
              {n.on && active && !rm && <circle cx={n.x} cy={n.y} r="10" fill="none" stroke="var(--red-500)" strokeWidth="1"
                style={{ transformOrigin:n.x+"px "+n.y+"px", animation:"nova-ring 2.6s var(--ease-out) infinite" }}/>}
            </g>);
          })}
        </g>
      </svg>
    </div>
  );
};
window.RadarField = RadarField;