"""Check active Android branding paths, and optionally the packaged APK."""
import hashlib
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
import traceback


def report_error(kind, error, trace):
    line = traceback.extract_tb(trace)[-1].lineno
    message = f"{kind.__name__}: {error} (line {line})"
    message = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=Mit branding::{message}", file=sys.stderr)
    sys.__excepthook__(kind, error, trace)


sys.excepthook = report_error

root = Path(__file__).resolve().parents[2]
res = root / 'android/app/src/main/res'
android = '{http://schemas.android.com/apk/res/android}'
manifest = ET.parse(root / 'android/app/src/main/AndroidManifest.xml').getroot()
assert any(p.get(android + 'name') == 'android.permission.ACCESS_NETWORK_STATE'
           for p in manifest.findall('uses-permission')), 'Network state permission required by recovery'
app = manifest.find('application')
assert app.get(android + 'label') == 'Mit’s VPN'
assert app.get(android + 'icon') == '@mipmap/mit_launcher'
assert app.get(android + 'roundIcon') == '@mipmap/mit_launcher'
for path in res.glob('values*/styles.xml'):
    text = path.read_text()
    assert '@drawable/android12splash' not in text, path
    for item in ET.fromstring(text).iter('item'):
        if item.get('name') == 'android:windowSplashScreenAnimatedIcon':
            assert item.text == '@drawable/mit_splash', path
for path in [res / 'drawable/launch_background.xml', res / 'drawable-v21/launch_background.xml']:
    text = path.read_text()
    assert '@drawable/mit_icon_art' in text and '@drawable/splash' not in text, path
icon = (root / 'assets/images/mit_vpn_icon.png').read_bytes()
assert icon[:8] == b'\x89PNG\r\n\x1a\n'
width, height = struct.unpack('>II', icon[16:24])
assert width == height and width >= 512
assert hashlib.sha256(icon).digest() == hashlib.sha256((res / 'drawable-nodpi/mit_icon_art.png').read_bytes()).digest()
assert (root / 'LICENSE.md').read_text() in (root / 'assets/legal/NOTICE.txt').read_text()
print(f'Android identity, launch resources, square {width}px icon and preserved license: PASS')

if len(sys.argv) > 1:
    apk = Path(sys.argv[1])
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        assert 'assets/flutter_assets/assets/images/mit_vpn_icon.png' in names
        assert 'assets/flutter_assets/assets/legal/NOTICE.txt' in names
        assert any(name.endswith('/mit_icon_art.png') for name in names)
    sdk = os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT']
    aapt = Path(sdk) / 'build-tools/36.0.0/aapt'
    badging = subprocess.run([str(aapt), 'dump', 'badging', str(apk)], check=True, capture_output=True, text=True).stdout
    labels = re.findall(r"application-label:'([^']+)'", badging)
    assert labels == ['Mit’s VPN'], labels
    alpha = (root / 'lib/features/one_tap/mit_release.dart').read_text()
    build_name = re.search(r"buildName = '([^']+)'", alpha).group(1)
    build_number = re.search(r'buildNumber = ([0-9]+)', alpha).group(1)
    assert f"versionName='{build_name}'" in badging, 'Android alpha version name mismatch'
    assert f"versionCode='{build_number}'" in badging, 'Android alpha version code mismatch'
    assert "uses-permission: name='android.permission.ACCESS_NETWORK_STATE'" in badging, 'Recovery permission missing from APK'
    assert any('mit_launcher' in line or 'mit_icon_art' in line for line in badging.splitlines() if line.startswith('application-icon-'))
    print('Packaged APK application label, launcher identity, artwork and legal asset: PASS')
