const {
  NavBar:GNav, ListRow:GRow, SectionLabel:GLabel, Switch:GSwitch, Select:GSelect, Radio:GRadio } = window.C;
const grp = { background:"var(--surface-1)", border:"1px solid var(--line)", borderRadius:"var(--r-lg)", overflow:"hidden", marginBottom:20 };
const sep = <div style={{height:1,background:"var(--line)"}}/>;
const Settings = ({ onBack }) => {
  const [nov,setNov]=React.useState(false);
  const [dns,setDns]=React.useState(true);
  return (
    <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column" }}>
      <GNav title="Настройки" onBack={onBack}/>
      <div style={{ flex:1, minHeight:0, overflowY:"auto", padding:"4px var(--gutter) 24px" }}>
        <div style={grp}>
          <GRow icon="graduation-cap" title="Режим новичка" subtitle="Скрыть расширенные настройки" trailing={<GSwitch checked={nov} onChange={setNov}/>}/>
        </div>
        <GLabel>Основное</GLabel>
        <div style={grp}>
          <GRow icon="download" title="Получить трафик" onClick={()=>{}}/>{sep}
          <GRow icon="book-open" title="Обучение" onClick={()=>{}}/>{sep}
          <GRow icon="circle-help" title="Вопросы и ответы" onClick={()=>{}}/>{sep}
          <GRow icon="list-checks" title="Частые наборы правил" onClick={()=>{}}/>
        </div>
        <GLabel>Сеть</GLabel>
        <div style={grp}>
          <GRow icon="shield-check" title="Проверка утечек DNS" trailing={<GSwitch checked={dns} onChange={setDns}/>}/>{sep}
          <GRow icon="gauge" title="URL проверки скорости" value="speed.cloudflare.com" onClick={()=>{}}/>{sep}
          <GRow icon="activity" title="URL проверки задержки" value="gstatic.com/204" onClick={()=>{}}/>
        </div>
        <GLabel>Профили</GLabel>
        <div style={grp}>
          <GRow icon="plus" title="Добавить профиль" onClick={()=>{}}/>{sep}
          <GRow icon="layers" title="Мои профили" value="xnv" onClick={()=>{}}/>
        </div>
        <GLabel>Интервал обновления</GLabel>
        <div style={{ marginBottom:20 }}><GSelect value="Каждые 12 часов"/></div>
        <div style={{ textAlign:"center", color:"var(--text-2)", font:"var(--text-mono)", padding:"8px 0 4px" }}>Woman in Red · v2.4.0 · сборка 1102</div>
      </div>
    </div>
  );
};
window.Settings = Settings;