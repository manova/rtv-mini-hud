from pathlib import Path
import os,json,subprocess,time,zipfile,hashlib,shutil,sys,re
import argparse
from pck import pack
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description="Run isolated native tests with separately obtained licensed local inputs")
parser.add_argument('--inputs',type=Path,required=True)
parser.add_argument('--stacks',nargs='+',choices=['minimal','aial','toolkit','lava','combined','aial-combined'],default=['minimal','aial','toolkit','lava','combined','aial-combined'])
args=parser.parse_args()
inputs=json.loads(args.inputs.read_text())
def file_sha(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
required=['engine','game_pack','loader','class_cache','mcm','toolkit','lava','aial','captured_minimal','captured_broad']
paths={k:Path(inputs[k]).resolve() for k in required}
for name,path in paths.items():
 if not path.is_file():raise SystemExit('Missing input: '+name)
approved=json.loads((ROOT/'tools/accepted-input-sha256.json').read_text())
for name,path in paths.items():
 if file_sha(path)!=approved[name]:raise SystemExit('Input identity mismatch: '+name)
D=ROOT/'.local'
if D.resolve().parent!=ROOT.resolve() or D.is_symlink() or getattr(D,'is_junction',lambda:False)():raise SystemExit('Unsafe local test root')
D.mkdir(exist_ok=True)
for name in ['runtime','tests','runs','candidate']:
 folder=D/name
 if folder.resolve().parent!=D.resolve() or folder.is_symlink() or getattr(folder,'is_junction',lambda:False)():raise SystemExit('Unsafe test folder: '+name)
 folder.mkdir(exist_ok=True)
for p in (ROOT/'tests/native').iterdir():shutil.copy2(p,D/'tests'/p.name)
for key,name in [('engine','CompatProbe.exe'),('game_pack','RTV.pck'),('loader','modloader.gd'),('class_cache','global_script_class_cache.cfg')]:
 dst=D/'runtime'/name
 if not dst.exists():shutil.copy2(paths[key],dst)
 elif dst.stat().st_size!=paths[key].stat().st_size or file_sha(dst)!=file_sha(paths[key]):raise SystemExit('Unexpected existing runtime copy: '+name)
for key,name in [('captured_minimal','captured-minimal.gd.txt'),('captured_broad','captured-broad.gd.txt')]:shutil.copy2(paths[key],D/'tests'/name)
VERSION=re.search(r'^version="([^"]+)"',(ROOT/'src/mod.txt').read_text(),re.M).group(1)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=ROOT/'src'
(D/'candidate').mkdir(exist_ok=True)
(D/'runs').mkdir(exist_ok=True)
# Use the release builder so the tested archive is byte-identical.
from build import payload
archive=D/'candidate'/('rtv_mini_hud-'+VERSION+'.vmz')
archive.write_bytes(payload(source))
run=D/'runs'/str(time.time_ns());run.mkdir()
for p in (D/'tests').iterdir():shutil.copy2(p,run/p.name)
rt=D/'runtime';rows=[]
for stack in args.stacks:
 for dev in [False,True]:
  case=stack+('-dev' if dev else '-off');profile=run/'profiles'/case;profile.mkdir(parents=True)
  case_rt=rt;mods=rt/'mods';mods.mkdir(exist_ok=True)
  if mods.resolve().parent!=rt.resolve() or mods.is_symlink() or getattr(mods,'is_junction',lambda:False)():raise SystemExit('Unsafe disposable mods folder')
  for old in mods.iterdir():
   assert old.is_file() and not old.is_symlink() and old.resolve().parent==mods.resolve() and mods.resolve().parent==rt.resolve()
   old.unlink()
  desired={'00ModConfigurationMenu.vmz':paths['mcm'],archive.name:archive}
  keys={'doinkoink-mcm@2.9.3':-100,'rtv_mini_hud@'+VERSION:100}
  toolkit='toolkit' in stack or 'combined' in stack;lava='lava' in stack or 'combined' in stack;aial=stack.startswith('aial')
  if toolkit:
   desired['VostokToolkit-5.5.1.vmz']=paths['toolkit'];keys['vostok-toolkit@5.5.1']=0
  if lava:
   desired['MurdieLavaLamps-1.1.2.vmz']=paths['lava'];keys['MurdieLavaLamps@1.1.2']=0
  if aial:
   desired['AIActuallyLoots.vmz']=paths['aial'];keys['ai_actually_loots@1.2.0']=0
  for n,p in desired.items():shutil.copy2(p,mods/n)
  config={'registry':lava,'aial':aial,'count':len(keys),'toolkit':toolkit,'lava':lava,'userdata':str(profile.resolve())}
  (profile/'case.json').write_text(json.dumps(config))
  (profile/'mod_config.cfg').write_text('[settings]\ndeveloper_mode='+str(dev).lower()+'\nactive_profile="Default"\n[profile.Default.enabled]\n'+''.join(k+'=true\n' for k in keys)+'[profile.Default.priority]\n'+''.join(k+'='+str(v)+'\n' for k,v in keys.items()))
  (profile/'inventory.json').write_text(json.dumps({n:sha(p) for n,p in desired.items()},indent=2))
  project='[application]\nconfig/name="Mini HUD isolated compatibility tests"\nrun/main_scene="res://Probe.tscn"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+case+'"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[autoload]\nLoader="*res://Host.gd"\nDatabase="*res://Host.gd"\nSimulation="*res://Host.gd"\n'
  scene='[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://FixProbe.gd" id="1"]\n[node name="Probe" type="Node"]\nscript=ExtResource("1")\n'
  files={'project.godot':project.encode(),'Probe.tscn':scene.encode(),'Host.gd':b'extends Node\nvar day=1\nvar simulate=false\nvar nomadsRemaining=100\nvar nomadsDiscovered=[]\nvar scenePath=""\n','.godot/global_script_class_cache.cfg':(rt/'global_script_class_cache.cfg').read_bytes(),'modloader.gd':(rt/'modloader.gd').read_bytes()}
  for p in (D/'tests').iterdir():files[p.name]=p.read_bytes()
  pack(files,case_rt/'CompatProbe.pck')
  for phase in ['generate','activate']:
   env=os.environ.copy()
   for key,folder in [('APPDATA','profiles'),('LOCALAPPDATA','local'),('TEMP','temp'),('TMP','temp')]:
    (run/folder).mkdir(exist_ok=True);env[key]=str(run/folder)
   log=run/(case+'-'+phase+'.log');start=time.time_ns()
   with log.open('w',encoding='utf-8') as f:
    renderer=['--headless'] if phase=='generate' else ['--display-driver','windows','--rendering-method','gl_compatibility','--windowed','--resolution','320x180','--position','-32000,-32000','--disable-vsync']
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
    result=subprocess.run([str(case_rt/'CompatProbe.exe'),*renderer,'--quit-after','1200','--log-file',str(log.with_suffix('.engine.log')),'--',phase,case],cwd=case_rt,env=env,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=si,timeout=180)
   text=log.read_text(errors='replace');errors=[l for l in text.splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:','FATAL:')) and l!='ERROR: Failed to read the root certificate store.']
   file=profile/(phase+'-results.json');fresh=file.exists() and file.stat().st_mtime_ns>=start
   data=json.loads(file.read_text()) if fresh else {'passed':False,'checks':[]}
   markers=[json.loads(l.split(' ',1)[1]) for l in text.splitlines() if l.startswith('FIX_PROBE ')]
   row={'case':case,'phase':phase,'passed':result.returncode==0 and fresh and not errors and markers==[data] and data['passed'] and 'HOST_CLEANUP_DONE' in text,'exit':result.returncode,'freshResult':fresh,'checks':len(data['checks']),'failedChecks':[c for c in data['checks'] if not c['passed']],'errors':errors,'log':str(log),'firstDeath':[json.loads(l.split(' ',1)[1]) for l in text.splitlines() if l.startswith('FIRST_DEATH ')]}
   rows.append(row);summary={'passed':all(r['passed'] for r in rows),'checks':sum(r['checks'] for r in rows),'rows':rows,'gameplayLaunched':False,'archiveSHA256':sha(archive),'damageBodies':'modeled; actual production boot and source contracts checked independently','hostCleanupVerified':True,'renderer':'Windows gl_compatibility hidden offscreen activation; headless generation'}
   (run/'results.json').write_text(json.dumps(summary,indent=2));(D/'latest-results.json').write_text(json.dumps({'path':str(run/'results.json'),'passed':summary['passed']},indent=2));print(json.dumps({k:v for k,v in row.items() if k!='firstDeath'}),flush=True)
   if not row['passed']:raise SystemExit(1)
print('ALL PASS',summary['checks'],str(run/'results.json'))
