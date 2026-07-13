const {
  NavBar:RNav, IconButton:RIcon, ListRow:RRow, SectionLabel:RLabel, Switch:RSwitch,
  SegmentedControl:RSeg, Badge:RBadge } = window.C;
const Rules = ({ mode, setMode }) => {
  const D = window.NOVA_DATA;
  const [a,setA]=React.useState(true), [b,setB]=React.useState(true), [c,setC]=React.useState(false);
  return (
    <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column" }}>
      <RNav title="Правила маршрутизации" right={<RIcon icon="pencil" variant="plain" size={36}/>}/>
      <div style={{ flex:1, minHeight:0, overflowY:"auto", padding:"4px var(--gutter) 24px" }}>
        <div style={{ display:"flex", justifyContent:"center", marginBottom:18 }}>
          <RSeg options={[{label:"Правило",value:"Rule"},{label:"Глобально",value:"Global"}]} value={mode} onChange={setMode}/>
        </div>
        <div style={{ background:"var(--surface-1)", border:"1px solid var(--line)", borderRadius:"var(--r-lg)", overflow:"hidden", marginBottom:20 }}>
          <RRow icon="eye-off" title="Скрывать неиспользуемые группы" trailing={<RSwitch checked={a} onChange={setA}/>}/>
          <div style={{height:1,background:"var(--line)"}}/>
          <RRow icon="house-wifi" title="Локальная сеть напрямую" trailing={<RSwitch checked={b} onChange={setB}/>}/>
          <div style={{height:1,background:"var(--line)"}}/>
          <RRow icon="building-2" title="Отключить правила провайдера" trailing={<RSwitch checked={c} onChange={setC}/>}/>
        </div>
        <RLabel trailing={<RBadge tone="neutral">{D.rules.length} групп</RBadge>}>Свои группы маршрутизации</RLabel>
        <div style={{ background:"var(--surface-1)", border:"1px solid var(--line)", borderRadius:"var(--r-lg)", overflow:"hidden" }}>
          {D.rules.map((r,i)=>(<React.Fragment key={r.name}>
            {i>0 && <div style={{height:1,background:"var(--line)"}}/>}
            <RRow icon={r.icon} title={r.name} value={r.value} onClick={()=>{}}/>
          </React.Fragment>))}
        </div>
      </div>
    </div>
  );
};
window.Rules = Rules;