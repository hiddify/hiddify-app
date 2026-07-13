const { TabBar:ATab } = window.C;
const fmt = (s) => { const h=Math.floor(s/3600), m=Math.floor(s%3600/60), x=s%60;
  const p=(n)=>String(n).padStart(2,"0"); return p(h)+":"+p(m)+":"+p(x); };

const App = () => {
  const D = window.NOVA_DATA;
  const [entered,setEntered]=React.useState(false);
  const [tab,setTab]=React.useState("home");
  const [status,setStatus]=React.useState("off");
  const [sel,setSel]=React.useState(D.best[0]);
  const [mode,setMode]=React.useState("Rule");
  const [q,setQ]=React.useState("");
  const [elapsed,setElapsed]=React.useState(0);
  const [down,setDown]=React.useState(0);
  const [up,setUp]=React.useState(0);
  const [series,setSeries]=React.useState({up:[2,3,3,4,3,5,4,6],down:[4,6,5,8,7,9,8,11]});
  const tRef=React.useRef(null), cRef=React.useRef(null), attemptRef=React.useRef(0);

  const stopTick=()=>{ clearInterval(tRef.current); clearInterval(cRef.current); };
  React.useEffect(()=>()=>stopTick(),[]);

  const toggle=()=>{
    if(status==="off" || status==="error"){
      setStatus("connecting");
      attemptRef.current++;
      const willFail = attemptRef.current % 3 === 0; // demo: surface the error state every 3rd attempt
      setTimeout(()=>{
        if(willFail){ setStatus("error"); return; }
        setStatus("on"); setElapsed(0); setDown(48); setUp(28);
        tRef.current=setInterval(()=>setElapsed(e=>e+1),1000);
        cRef.current=setInterval(()=>{
          setDown(d=>Math.max(30,Math.min(96,d+(Math.random()*16-8))));
          setUp(u=>Math.max(12,Math.min(60,u+(Math.random()*10-5))));
          setSeries(s=>({ up:[...s.up.slice(1), 3+Math.random()*8], down:[...s.down.slice(1), 5+Math.random()*10] }));
        },1200);
      },1500);
    } else { setStatus("off"); stopTick(); setElapsed(0); setDown(0); setUp(0); }
  };

  const selectServer=(s)=>{ setSel(s); setTab("home"); };

  if(!entered) return <Phone><Welcome onEnter={()=>setEntered(true)}/></Phone>;

  const screens = {
    home: <Home status={status} onToggle={toggle} sel={sel} timer={fmt(elapsed)} down={down} up={up} series={series}
            onOpenServers={()=>setTab("servers")} onSettings={()=>setTab("settings")}/>,
    servers: <Servers sel={sel} onSelect={selectServer} onBack={()=>setTab("home")} q={q} setQ={setQ}/>,
    rules: <Rules mode={mode} setMode={setMode}/>,
    settings: <Settings onBack={()=>setTab("home")}/>
  };

  return (
    <Phone>
      <div style={{ flex:1, minHeight:0, position:"relative" }}>{screens[tab]}</div>
      <ATab value={tab} onChange={setTab} items={[
        {id:"home",icon:"house"},{id:"servers",icon:"globe"},{id:"rules",icon:"shield"},{id:"settings",icon:"settings"}
      ]}/>
    </Phone>
  );
};
ReactDOM.createRoot(document.getElementById("root")).render(<App/>);