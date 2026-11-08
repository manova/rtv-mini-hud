from pathlib import Path, PurePosixPath
import argparse,hashlib,io,re,zipfile
ROOT=Path(__file__).resolve().parents[1]
EXPECTED={"mod.txt","CHANGELOG.txt","LICENSE","THIRD-PARTY-NOTICES.txt",*("rtv-mini-hud/"+n for n in ["AttributionTrace.gd","CallbackContracts.gd","ClockReader.gd","KillObserver.gd","KillReader.gd","Main.gd","Model.gd","NativeAIContract.gd","Panel.gd","RefreshGate.gd","Settings.gd","TimerReader.gd","WatchReader.gd"]),*("rtv-mini-hud/assets/"+n for n in ["clock.svg","moon.svg","pause.svg","question.svg","skull.svg","sun.svg","user.svg","PHOSPHOR-LICENSE.txt"])}
def payload(source):
 files={}
 for p in source.rglob('*'):
  if p.is_symlink():raise ValueError('Source symlinks are forbidden')
  if p.is_file():files[p.relative_to(source).as_posix()]=p.read_bytes()
 if set(files)!=EXPECTED:raise ValueError('Unexpected package entry set')
 if len({n.casefold() for n in files})!=len(files):raise ValueError('Case-insensitive collision')
 out=io.BytesIO()
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
  for name,data in sorted(files.items()):
   path=PurePosixPath(name)
   if path.is_absolute() or '..' in path.parts or '\\' in name:raise ValueError('Unsafe package path')
   info=zipfile.ZipInfo(name,(2026,11,8,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,data)
 return out.getvalue()
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path)
 args=parser.parse_args();source=ROOT/'src'
 version=re.search(r'^version="([^"]+)"',(source/'mod.txt').read_text(),re.M).group(1)
 result=payload(source)
 target=args.output or ROOT/'dist'/('rtv_mini_hud-'+version+'.vmz')
 target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(result)
 print(hashlib.sha256(result).hexdigest(),target)
if __name__=='__main__':main()
