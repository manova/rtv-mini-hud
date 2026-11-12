"""Run production Settings/Panel in an isolated Godot project, without game saves."""
from pathlib import Path
import argparse, json, os, shutil, subprocess, time, hashlib
from pck import pack
ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--engine', type=Path, required=True)
args = parser.parse_args()
run = ROOT / '.local' / 'ui' / str(time.time_ns())
run.mkdir(parents=True)
for name in ['Model.gd', 'Settings.gd', 'Panel.gd']:
    target = run / 'rtv-mini-hud' / name
    target.parent.mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'src/rtv-mini-hud' / name, target)
shutil.copytree(ROOT / 'src/rtv-mini-hud/assets', run / 'rtv-mini-hud/assets')
shutil.copy2(ROOT / 'tests/ui/DisplayTests.gd', run / 'DisplayTests.gd')
(run/'project.godot').write_text('[application]\nconfig/name="Mini HUD isolated display checks"\nrun/main_scene="res://DisplayTests.tscn"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="MiniHUDDisplayChecks"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
env = os.environ.copy()
for name in ['APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP']:
    folder = run / name.lower(); folder.mkdir(exist_ok=True); env[name] = str(folder)
env['MINIHUD_UI_OUTPUT'] = str(run)
(run/'DisplayTests.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://DisplayTests.gd" id="1"]\n[node name="DisplayTests" type="Node"]\nscript=ExtResource("1")\n', encoding='utf-8')
(run/'.godot').mkdir()
(run/'.godot/global_script_class_cache.cfg').write_text('list=[]\n', encoding='utf-8')
shutil.copy2(args.engine, run/'UIProbe.exe')
files = {p.relative_to(run).as_posix():p.read_bytes() for p in run.rglob('*') if p.is_file() and p.suffix != '.exe'}
pack(files, run/'UIProbe.pck')
log = run / 'engine.log'
with log.open('w', encoding='utf-8') as output:
    result = subprocess.run([str(run/'UIProbe.exe'), '--headless', '--quit-after', '1800'], cwd=run, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=180)
text = log.read_text(errors='replace')
print(text)
errors = [line for line in text.splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'FATAL:')) and line != 'ERROR: Failed to read the root certificate store.']
result_path = run / 'ui-results.json'
data = json.loads(result_path.read_text()) if result_path.exists() else {'passed':False}
summary = {'passed':result.returncode == 0 and data['passed'] and not errors, 'assertions':data.get('assertions',0), 'exit':result.returncode, 'errors':errors, 'result':str(result_path), 'log':str(log), 'sourceSHA256':{name:hashlib.sha256((ROOT/'src/rtv-mini-hud'/name).read_bytes()).hexdigest() for name in ['Model.gd','Settings.gd','Panel.gd']}, 'gameplay':False}
(ROOT/'.local/ui/latest.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary, indent=2))
raise SystemExit(0 if summary['passed'] else 1)
