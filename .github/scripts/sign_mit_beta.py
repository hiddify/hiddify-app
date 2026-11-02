"""Sign a tested APK; secrets only live in a private temporary directory."""
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


def run(args):
    return subprocess.run([str(a) for a in args], check=True, capture_output=True, text=True).stdout


def main():
    names = ['ANDROID_SIGNING_KEY', 'ANDROID_SIGNING_STORE_PASSWORD',
             'ANDROID_SIGNING_KEY_PASSWORD', 'ANDROID_SIGNING_KEY_ALIAS']
    if any(not os.environ.get(name) for name in names):
        raise RuntimeError('Configure the four ANDROID_SIGNING_* repository secrets before publishing.')
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT']) / 'build-tools/36.0.0'
    target = Path('signed')
    target.mkdir(exist_ok=True)
    apk = target / 'mits-vpn.apk'
    with tempfile.TemporaryDirectory(prefix='mit-signing-') as temporary:
        private = Path(temporary)
        os.chmod(private, 0o700)
        store, storepass, keypass = [private / name for name in ['key.jks', 'storepass', 'keypass']]
        store.write_bytes(base64.b64decode(os.environ['ANDROID_SIGNING_KEY'], validate=True))
        storepass.write_text(os.environ['ANDROID_SIGNING_STORE_PASSWORD'])
        keypass.write_text(os.environ['ANDROID_SIGNING_KEY_PASSWORD'])
        for file in [store, storepass, keypass]:
            os.chmod(file, 0o600)
        run([sdk / 'apksigner', 'sign', '--ks', store, '--ks-key-alias', os.environ['ANDROID_SIGNING_KEY_ALIAS'],
             '--ks-pass', f'file:{storepass}', '--key-pass', f'file:{keypass}', '--out', apk,
             'unsigned/mits-vpn-unsigned.apk'])
    verified = run([sdk / 'apksigner', 'verify', '--verbose', '--print-certs', apk])
    certs = re.findall(r'Signer #[0-9]+ certificate SHA-256 digest: ([a-fA-F0-9]+)', verified)
    expected = Path('android/mit-signing-cert.sha256').read_text().strip().lower()
    if [cert.lower() for cert in certs] != [expected]:
        raise RuntimeError('APK signing certificate differs from the permanent certificate pin.')
    badging = run([sdk / 'aapt', 'dump', 'badging', apk])
    release = Path('lib/features/one_tap/mit_release.dart').read_text()
    version = re.search(r"buildName = '([^']+)'", release).group(1)
    build = int(re.search(r'buildNumber = ([0-9]+)', release).group(1))
    if ("package: name='app.hiddify.com'" not in badging or f"versionCode='{build}'" not in badging
            or f"versionName='{version}'" not in badging or 'application-debuggable' in badging):
        raise RuntimeError('APK package, version or release mode mismatch.')
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    metadata = {'schema': 1, 'application_id': 'app.hiddify.com', 'version': version,
                'build_number': build, 'apk_size': apk.stat().st_size, 'apk_sha256': digest}
    (target / 'mits-vpn-update.json').write_text(json.dumps(metadata, indent=2) + '\n')
    (target / 'SHA256SUMS').write_text(f'{digest}  mits-vpn.apk\n')
    print(f'Permanent signature, release package and version verified: {version} ({build})')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Do not print subprocess arguments/output, which may contain credential material.
        print(f'::error::Signing failed: {error if isinstance(error, RuntimeError) else type(error).__name__}')
        raise SystemExit(1)
