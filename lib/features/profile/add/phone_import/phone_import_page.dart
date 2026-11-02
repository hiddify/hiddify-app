import 'dart:convert';

/// One step of the page's guide.
typedef PhoneImportStep = ({String title, String body});

/// The texts of the page the phone opens, in the TV's language.
typedef PhoneImportPageText = ({
  String lang,
  bool rtl,
  String title,
  String intro,
  PhoneImportStep network,
  PhoneImportStep copy,
  PhoneImportStep paste,
  PhoneImportStep confirm,
  String label,
  String hint,
  String send,
  String sentTitle,
  String sent,
  String empty,
  String footer,
});

/// The page a phone opens: the Hiddify mark, then a guide of four steps, the third holding the
/// form that posts to [action]. Once a text was [sent], the first three are checked and the last,
/// confirming on the TV, stands out. One self-contained document: no script, nothing loaded.
String phoneImportPage(
  PhoneImportPageText t, {
  required String action,
  required int maxText,
  required bool sent,
  String? error,
}) {
  final e = const HtmlEscape().convert;
  String step(int n, PhoneImportStep s, String icon, {bool done = false, bool active = false, String extra = ''}) => [
    '<li class="step${done ? ' done' : ''}${active ? ' active' : ''}">',
    '<span class="num">${done ? _icons['check'] : '$n'}</span>',
    '<div class="body"><div class="head">$icon<h2>${e(s.title)}</h2></div><p>${e(s.body)}</p>$extra</div></li>',
  ].join();
  final notice = switch ((sent, error)) {
    (_, final error?) => '<div class="notice bad" role="alert">${_icons['error']}<div>${e(error)}</div></div>',
    (true, _) => [
      '<div class="notice ok" role="status">${_icons['check']}',
      '<div><strong>${e(t.sentTitle)}</strong>${e(t.sent)}</div></div>',
    ].join(),
    _ => '',
  };
  final form = [
    '<form method="post" action="${e(action)}" accept-charset="utf-8">',
    '<label for="link">${e(t.label)}</label>',
    '<textarea id="link" name="link" required maxlength="$maxText" placeholder="${e(t.hint)}" ',
    'autocapitalize="off" autocomplete="off" autocorrect="off" spellcheck="false" dir="ltr"></textarea>',
    '<button type="submit">${_icons['send']}<span>${e(t.send)}</span></button></form>',
  ].join();
  return [
    '<!doctype html><html lang="${e(t.lang)}" dir="${t.rtl ? 'rtl' : 'ltr'}"><head>',
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">',
    '<meta name="color-scheme" content="light dark">',
    '<meta name="theme-color" content="#455FE9">',
    '<meta name="referrer" content="no-referrer">',
    '<title>${e(t.title)}</title><style>$_css</style></head><body><main class="wrap">',
    '<header class="brand"><span class="logo">$_logo</span><span class="word">Hiddify</span></header>',
    '<h1>${e(t.title)}</h1><p class="intro">${e(t.intro)}</p>',
    notice,
    '<ol class="steps">',
    step(1, t.network, _icons['wifi']!, done: sent),
    step(2, t.copy, _icons['link']!, done: sent),
    step(3, t.paste, _icons['paste']!, done: sent, active: !sent, extra: form),
    step(4, t.confirm, _icons['tv']!, active: sent),
    '</ol>',
    '<p class="foot">${_icons['lock']}<span>${e(t.footer)}</span></p>',
    '</main></body></html>',
  ].join();
}

/// The Hiddify mark (assets/images/logo.svg), in white for its tile.
final _logo = [
  '<svg viewBox="0 0 64 64" aria-hidden="true"><g fill="#fff">',
  '<path d="M47.1582 14.4283C47.1582 13.8368 47.4684 13.2886 47.9757 12.9842L61.4494 4.89891C62.5721 4.22529 64.0003 5.03389 64.0003 6.34306V20.2103C64.0003 21.1405 63.2461 21.8945 62.3161 21.8945H48.8424C47.9124 21.8945 47.1582 21.1405 47.1582 20.2103V14.4283Z"/>',
  '<path fill-rule="evenodd" d="M24.3966 26.4593C23.8893 26.7637 23.5789 27.3118 23.5789 27.9034V43.7921L23.5789 45.4751L23.5789 45.4763L23.5789 48.0001C23.5789 48.9301 22.8249 49.6001 21.8947 49.6001H18.5263C17.5962 49.6001 16.8421 48.9301 16.8421 48.0001V45.4751V34.976C16.8421 33.6669 15.4139 32.8583 14.2913 33.5319L0.817607 41.6171C0.310362 41.9216 0 42.4696 0 43.0615V60.6342C0 61.5642 0.754048 62.3184 1.68421 62.3184H15.1579C16.0881 62.3184 16.8421 61.5642 16.8421 60.6342V58.9488V56.8314C16.8421 55.9011 17.5962 55.3376 18.5263 55.3376H21.8947C22.8249 55.3376 23.5789 55.9011 23.5789 56.8314V58.9488L23.5789 60.6342C23.5789 61.5642 24.333 62.3184 25.2632 62.3184H38.7368C39.6669 62.3184 40.4211 61.5642 40.4211 60.6342V45.4763V43.7921V19.8182C40.4211 18.509 38.9928 17.7004 37.8701 18.374L24.3966 26.4593Z"/>',
  '<path d="M47.1592 28.7999V60.7999C47.1592 61.6836 47.9132 62.3999 48.8434 62.3999H62.3171C63.2472 62.3999 64.0013 61.6836 64.0013 60.7999V28.7999C64.0013 27.9162 63.2472 27.1999 62.3171 27.1999H48.8434C47.9132 27.1999 47.1592 27.9162 47.1592 28.7999Z"/>',
  '</g></svg>',
].join();

/// Material icons, filled by the page's styles.
const _icons = {
  'wifi':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.08 2.93 1 9zm8 8l3 3 3-3c-1.65-1.66-4.34-1.66-6 0zm-4-4l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.14 9.14 8.87 9.14 5 13z"/></svg>',
  'link':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/></svg>',
  'paste':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M19 2h-4.18C14.4.84 13.3 0 12 0S9.6.84 9.18 2H5c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 0c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm7 18H5V4h2v3h10V4h2v16z"/></svg>',
  'tv':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M21 3H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h5v2h8v-2h5c1.1 0 1.99-.9 1.99-2L23 5c0-1.1-.9-2-2-2zm0 14H3V5h18v12z"/></svg>',
  'send': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2.01 21 23 12 2.01 3 2 10l15 2-15 2z"/></svg>',
  'check': '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>',
  'lock':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>',
  'error':
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>',
};

/// Mobile first, light and dark, left to right and right to left (logical properties throughout).
const _css = '''
:root{--brand:#455fe9;--brand2:#7b5cff;--bg:#f3f5fb;--card:#fff;--field:#f7f8fc;--text:#14161f;--muted:#5d6275;--line:#e2e5f0;--ok:#15803d;--okbg:#e7f6ec;--bad:#c62828;--badbg:#fdecec}
@media (prefers-color-scheme:dark){:root{--bg:#0d0e13;--card:#171922;--field:#10121a;--text:#eceef6;--muted:#9aa0b4;--line:#272b38;--ok:#4ade80;--okbg:#10291b;--bad:#f87171;--badbg:#2e1515}}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;min-height:100vh;font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,Vazirmatn,Tahoma,sans-serif;color:var(--text);background:radial-gradient(900px 420px at 50% -160px,rgba(69,95,233,.30),transparent 72%),var(--bg)}
.wrap{max-width:560px;margin:0 auto;padding:28px 18px calc(32px + env(safe-area-inset-bottom))}
.brand{display:flex;align-items:center;justify-content:center;gap:10px;margin:4px 0 22px}
.logo{width:46px;height:46px;border-radius:14px;display:grid;place-items:center;background:linear-gradient(135deg,var(--brand),var(--brand2));box-shadow:0 10px 26px rgba(69,95,233,.38)}
.logo svg{width:26px;height:26px}
.word{font-size:22px;font-weight:700;letter-spacing:.2px}
h1{margin:0 0 8px;font-size:clamp(22px,6vw,28px);line-height:1.25;text-align:center}
.intro{max-width:430px;margin:0 auto 24px;color:var(--muted);text-align:center}
.notice{display:flex;align-items:flex-start;gap:12px;margin:0 0 20px;padding:14px 16px;border-radius:18px;font-size:15px}
.notice svg{flex:none;width:24px;height:24px;fill:currentColor}
.notice strong{display:block;margin-bottom:2px;font-size:17px;color:var(--text)}
.ok{background:var(--okbg);color:var(--ok)}
.bad{background:var(--badbg);color:var(--bad)}
.steps{margin:0;padding:0;list-style:none}
.step{position:relative;display:flex;gap:14px;padding-bottom:16px}
.step:not(:last-child)::before{content:"";position:absolute;inset-inline-start:17px;top:42px;bottom:6px;width:2px;border-radius:2px;background:var(--line)}
.num{flex:none;display:grid;place-items:center;width:36px;height:36px;border-radius:50%;font-weight:700;color:#fff;background:linear-gradient(135deg,var(--brand),var(--brand2));box-shadow:0 6px 14px rgba(69,95,233,.32)}
.num svg{width:20px;height:20px;fill:#fff}
.done .num{background:var(--ok);box-shadow:none}
.done .head,.done .body>p{opacity:.7}
.body{flex:1;min-width:0;padding:14px 16px;border:1px solid var(--line);border-radius:18px;background:var(--card)}
.active .body{border-color:var(--brand);box-shadow:0 0 0 4px rgba(69,95,233,.14)}
.head{display:flex;align-items:center;gap:8px}
.head svg{flex:none;width:20px;height:20px;fill:var(--brand)}
h2{margin:0;font-size:17px;line-height:1.3}
.body p{margin:4px 0 0;font-size:15px;color:var(--muted)}
label{display:block;margin:14px 0 6px;font-size:14px;font-weight:600}
textarea{display:block;width:100%;min-height:118px;padding:12px 14px;font:15px/1.45 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:var(--text);text-align:left;background:var(--field);border:1.5px solid var(--line);border-radius:14px;resize:vertical}
textarea:focus{outline:none;border-color:var(--brand);box-shadow:0 0 0 4px rgba(69,95,233,.18)}
textarea::placeholder{font-family:system-ui,-apple-system,"Segoe UI",Roboto,Vazirmatn,Tahoma,sans-serif;color:var(--muted);opacity:.8}
[dir=rtl] textarea:placeholder-shown{direction:rtl;text-align:right}
button{display:flex;align-items:center;justify-content:center;gap:10px;width:100%;min-height:54px;margin-top:12px;font-family:inherit;font-size:17px;font-weight:600;color:#fff;border:0;border-radius:14px;background:linear-gradient(135deg,var(--brand),var(--brand2));box-shadow:0 12px 26px rgba(69,95,233,.36);cursor:pointer;-webkit-tap-highlight-color:transparent}
button:active{transform:translateY(1px);box-shadow:0 6px 16px rgba(69,95,233,.3)}
button svg{width:20px;height:20px;fill:#fff}
[dir=rtl] button svg{transform:scaleX(-1)}
.foot{display:flex;align-items:flex-start;justify-content:center;gap:8px;margin:10px auto 0;max-width:430px;font-size:13px;color:var(--muted);text-align:center}
.foot svg{flex:none;width:16px;height:16px;margin-top:2px;fill:currentColor}
@media (min-width:600px){.wrap{padding-top:52px}}
''';
