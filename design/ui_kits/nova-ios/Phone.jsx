const StatusBar = ({ dark }) => (
  <div style={{ height:"var(--safe-top)", display:"flex", alignItems:"flex-end",
    justifyContent:"space-between", padding:"0 26px 8px", flexShrink:0, position:"relative", zIndex:5 }}>
    <span style={{ font:"var(--w-semibold) 15px/1 var(--font-sans)", color:"var(--text-1)" }}>9:41</span>
    <div style={{ display:"flex", alignItems:"center", gap:7, color:"var(--text-1)" }}>
      <Icon name="signal" size={17}/><Icon name="wifi" size={17}/><Icon name="battery-full" size={22}/>
    </div>
  </div>
);
const Phone = ({ children }) => (
  <div style={{ width:"var(--screen-w)", height:"var(--screen-h)", position:"relative",
    background:"var(--void)", borderRadius:44, overflow:"hidden",
    border:"1px solid var(--line-2)", boxShadow:"var(--shadow-lg)", display:"flex", flexDirection:"column" }}>
    <StatusBar/>
    <div style={{ flex:1, minHeight:0, position:"relative", display:"flex", flexDirection:"column" }}>{children}</div>
    <div style={{ position:"absolute", bottom:8, left:"50%", transform:"translateX(-50%)",
      width:134, height:5, borderRadius:3, background:"var(--text-1)", opacity:0.9, zIndex:20 }}/>
  </div>
);
window.Phone = Phone;
window.StatusBar = StatusBar;