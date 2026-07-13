const { Button:WBtn } = window.C;
const Welcome = ({ onEnter }) => (
  <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column" }}>
    <RadarField active={true}/>
    <div style={{ position:"relative", zIndex:2, flex:1, display:"flex", flexDirection:"column",
      justifyContent:"flex-end", padding:"0 var(--gutter) 64px" }}>
      <div style={{ font:"var(--w-medium) var(--fs-cap)/1 var(--font-mono)", letterSpacing:"var(--ls-label)",
        textTransform:"uppercase", color:"var(--red-400)", marginBottom:14 }}>52.3702°N · 4.8952°E</div>
      <div style={{ font:"var(--w-bold) 40px/1.02 var(--font-sans)", letterSpacing:"-0.03em", color:"var(--text-1)" }}>
        Woman in <span style={{ color:"var(--red-500)" }}>Red</span></div>
      <div style={{ font:"var(--text-body)", color:"var(--text-2)", marginTop:14, maxWidth:290 }}>
        Личная дверь в открытый интернет. Войдите — за вами никто не последует.</div>
      <div style={{ marginTop:36 }}>
        <WBtn variant="outline" size="lg" block glow iconLeft="power" onClick={onEnter}>Войти</WBtn>
      </div>
      <div style={{ font:"var(--text-foot)", color:"var(--text-2)", textAlign:"center", marginTop:16 }}>
        Входя, вы принимаете <span style={{ color:"var(--text-1)", textDecoration:"underline", textUnderlineOffset:2, cursor:"pointer" }}>условия перехода</span>.</div>
    </div>
  </div>
);
window.Welcome = Welcome;