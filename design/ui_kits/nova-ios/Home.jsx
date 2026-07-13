const {
  NavBar:HNav, IconButton:HIcon, ConnectButton:HConn, ConnectStatus:HStatus,
  Card:HCard, StatCard:HStat, SpeedGauge:HGauge, MiniChart:HChart, ServerRow:HRow,
  Flag:HFlag, Icon:HGlyph, Badge:HBadge, Button:HBtn } = window.C;

const Home = ({ status, onToggle, sel, onOpenServers, onSettings, timer, down, up, series }) => {
  const on = status === "on";
  const err = status === "error";
  const sub = on ? "Ты вне матрицы"
    : status === "connecting" ? "Агент Смит ищет тебя"
    : err ? "Не удалось подключиться · проверьте сеть"
    : "Ты на виду · нажми кнопку";
  return (
    <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column" }}>
      <HNav brand={<span style={{font:"var(--w-bold) 17px/1 var(--font-sans)",letterSpacing:"-0.01em"}}>Woman in <span style={{color:"var(--red-500)"}}>Red</span></span>}
        left={<HIcon icon="grip" variant="plain" size={36}/>}
        right={<HIcon icon="settings" variant="plain" size={36} onClick={onSettings}/>}/>
      <div style={{ flex:1, minHeight:0, overflowY:"auto", position:"relative" }}>
        <RitualHero status={status}>
          <HConn status={status} size={168} onClick={onToggle}/>
          <HStatus variant="pill" status={status} onClick={onToggle}/>
          <div style={{ fontFamily:"var(--font-mono)", fontSize:11, letterSpacing:"0.06em", color: err ? "var(--danger)" : "var(--text-3)", textAlign:"center", maxWidth:260 }}>{sub}</div>
          {err && <HBtn variant="outline" size="sm" iconLeft="refresh-cw" onClick={onToggle}>Повторить</HBtn>}
        </RitualHero>

        <div style={{ padding:"4px var(--gutter) 24px", display:"flex", flexDirection:"column", gap:16 }}>
          <HCard tone="elevated" pad={0}>
            <div onClick={onOpenServers} style={{ display:"flex", alignItems:"center", gap:12, padding:"14px 16px", cursor:"pointer" }}>
              <HFlag code={sel.code} size={38}/>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ font:"var(--text-title)", color:"var(--text-1)" }}>{sel.name}</div>
                <div style={{ font:"var(--text-mono)", color:"var(--text-3)", marginTop:2 }}>{on ? "IP 185.42."+sel.ms+".7" : sel.city}</div>
              </div>
              <HGlyph name="chevron-right" size={20} color="var(--text-4)"/>
            </div>
          </HCard>

          {/* subscription / traffic — always visible; values are placeholders until Remnawave wiring */}
          <HCard tone="base" pad={0}>
            <div style={{ padding:"12px 16px", display:"flex", flexDirection:"column", gap:9 }}>
              <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                  <HGlyph name="gauge" size={15} color="var(--text-3)"/>
                  <span style={{ font:"var(--w-medium) var(--fs-cap)/1 var(--font-sans)", letterSpacing:"var(--ls-label)", textTransform:"uppercase", color:"var(--text-3)" }}>Трафик</span>
                </div>
                <span style={{ font:"var(--text-mono)", color:"var(--text-2)" }}>до 12 авг</span>
              </div>
              <div style={{ display:"flex", alignItems:"baseline", justifyContent:"space-between" }}>
                <span style={{ font:"var(--w-semibold) var(--fs-title)/1 var(--font-mono)", color:"var(--text-1)" }}>42 ГБ</span>
                <span style={{ font:"var(--text-foot)", color:"var(--text-3)" }}>из 100 ГБ</span>
              </div>
              <div style={{ height:6, borderRadius:"var(--r-pill)", background:"var(--surface-3)", overflow:"hidden" }}>
                <div style={{ width:"42%", height:"100%", borderRadius:"var(--r-pill)", background:"var(--red-500)", boxShadow:"var(--glow-red-soft)" }}/>
              </div>
            </div>
          </HCard>

          {on ? (
            <React.Fragment>
              <HCard tone="elevated" pad={16}>
                <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", rowGap:16, columnGap:12 }}>
                  {[
                    {l:"Приём", v:down.toFixed(0)+" ↓", c:"var(--red-400)"},
                    {l:"Отдача", v:up.toFixed(0)+" ↑", c:"var(--sig-good)"},
                    {l:"Задержка", v:sel.ms+" ms"},
                    {l:"Время", v:timer}
                  ].map((s)=>(
                    <div key={s.l} style={{ textAlign:"center", minWidth:0 }}>
                      <div style={{ font:"var(--w-medium) var(--fs-micro)/1 var(--font-sans)", letterSpacing:"var(--ls-label)", textTransform:"uppercase", color:"var(--text-3)" }}>{s.l}</div>
                      <div style={{ font:"var(--w-semibold) var(--fs-callout)/1 var(--font-mono)", color:s.c||"var(--text-1)", marginTop:6, whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" }}>{s.v}</div>
                    </div>
                  ))}
                </div>
              </HCard>
              {/* literal protection signal alongside the theme — placeholder strings until wiring */}
              <div style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:8 }}>
                <HGlyph name="lock" size={13} color="var(--sig-good)"/>
                <span style={{ font:"var(--w-medium) var(--fs-cap)/1 var(--font-mono)", letterSpacing:"0.04em", color:"var(--text-2)" }}>WireGuard · AES-256 · kill-switch on</span>
              </div>
            </React.Fragment>
          ) : (
            <div>
              <div style={{ font:"var(--w-medium) var(--fs-cap)/1 var(--font-sans)", letterSpacing:"var(--ls-label)", textTransform:"uppercase", color:"var(--text-3)", textAlign:"center", marginBottom:14 }}>Оптимальные локации</div>
              <div style={{ display:"flex", justifyContent:"center", gap:18 }}>
                {["fr","nl","de"].map(c=>(<HFlag key={c} code={c} size={48}/>))}
              </div>
              <div style={{ display:"flex", justifyContent:"center", marginTop:16 }}>
                <HBadge tone="red">Авто · мин. задержка</HBadge>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
window.Home = Home;