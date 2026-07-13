const {
  NavBar:SNav, IconButton:SIcon, SearchField:SSearch, SectionLabel:SLabel, ServerRow:SRow, Icon:SGlyph
} = window.C;
const Servers = ({ sel, onSelect, onBack, q, setQ }) => {
  const D = window.NOVA_DATA;
  const match = (x) => !q || x.name.toLowerCase().includes(q.toLowerCase());
  const best = D.best.filter(match), other = D.other.filter(match);
  const searching = !!q;
  const noMatches = searching && best.length === 0 && other.length === 0;
  return (
    <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column" }}>
      <SNav title="Выбор локации" onBack={onBack} right={<SIcon icon="refresh-cw" variant="plain" size={36}/>}/>
      <div style={{ padding:"4px var(--gutter) 12px" }}><SSearch value={q} onChange={setQ} placeholder="Поиск локации"/></div>
      <div style={{ flex:1, minHeight:0, overflowY:"auto", padding:"4px var(--gutter) 24px" }}>
        {noMatches ? (
          <div style={{ textAlign:"center", padding:"56px 20px" }}>
            <div style={{ display:"grid", placeItems:"center", marginBottom:12 }}>
              <SGlyph name="search-x" size={28} color="var(--text-3)"/>
            </div>
            <div style={{ font:"var(--text-title)", color:"var(--text-1)" }}>Ничего не найдено</div>
            <div style={{ font:"var(--text-foot)", color:"var(--text-2)", marginTop:6 }}>По запросу «{q}» локаций нет — проверьте написание.</div>
          </div>
        ) : (
          <React.Fragment>
            {best.length > 0 && (
              <React.Fragment>
                <SLabel>Лучшее соединение</SLabel>
                <div style={{ marginBottom:20 }}>
                  {best.map(s=>(
                    <SRow key={s.code} flagCode={s.code} name={s.name} sub={s.city} ms={s.ms}
                      selected={sel.code===s.code} onClick={()=>onSelect(s)}/>
                  ))}
                </div>
              </React.Fragment>
            )}
            {other.length > 0 && (
              <React.Fragment>
                <SLabel>Другие соединения</SLabel>
                <div style={{ marginBottom:20 }}>
                  {other.map(s=>(
                    <SRow key={s.code+s.city} flagCode={s.code} name={s.name} sub={s.city} ms={s.ms}
                      selected={sel.code===s.code&&sel.city===s.city} onClick={()=>onSelect(s)}/>
                  ))}
                </div>
              </React.Fragment>
            )}
            {!searching && (
              <React.Fragment>
                <SLabel>Свои узлы</SLabel>
                <div>
                  {D.nodes.map((n,i)=>(
                    <SRow key={i} tag={n.tag} name={n.name} sub={n.sub} ms={n.ms} select="none"/>
                  ))}
                </div>
                <div style={{ textAlign:"center", padding:"28px 0 8px", color:"var(--text-2)" }}>
                  <div style={{ font:"var(--text-foot)" }}>Новые локации открываются по мере доверия.</div>
                </div>
              </React.Fragment>
            )}
          </React.Fragment>
        )}
      </div>
    </div>
  );
};
window.Servers = Servers;
