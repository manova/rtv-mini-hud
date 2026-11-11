"""Build the private VTK 5.6.4 fixture from separately obtained official source.

This reproduces upstream pack.ps1's selected entries/comment stripping, with
fixed ZIP_STORED metadata. It is not the hash of a published VTK release asset.
"""
from pathlib import Path
import argparse,hashlib,io,json,zipfile
ROOT=Path(__file__).resolve().parents[1]
SOURCE_COMMIT='59a544adc57accd841e9e38ffd55e6e3ac202892'

def payload(source):
 out=io.BytesIO()
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_STORED) as z:
  for p in sorted(source.rglob('*')):
   if p.is_symlink():raise ValueError('Source symlinks are forbidden')
   if not p.is_file():continue
   rel=p.relative_to(source).as_posix()
   if rel.split('/')[0] in ('assets','tests'):continue
   if p.name not in ('mod.txt','version.txt') and p.suffix not in ('.gd','.tres','.tscn','.gdshader','.webp','.png'):continue
   b=p.read_bytes()
   if p.suffix=='.gd':b=('\n'.join(l.rstrip() for l in b.decode('utf-8-sig').splitlines() if l.strip() and not l.strip().startswith('#'))+'\n').encode()
   if rel=='mods/VTK/version.txt':b=b'5.6.4\n'
   info=zipfile.ZipInfo(rel,(2026,11,10,0,0,0));info.create_system=3;info.external_attr=0o100644<<16;z.writestr(info,b)
 return out.getvalue()

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--source',type=Path,required=True,help='mods/vostok-toolkit from official source commit '+SOURCE_COMMIT)
 parser.add_argument('--output',type=Path,required=True)
 args=parser.parse_args();data=payload(args.source);digest=hashlib.sha256(data).hexdigest()
 approved=json.loads((ROOT/'tools/accepted-input-sha256.json').read_text())['toolkit'][1]
 if digest!=approved:raise SystemExit('Source fixture mismatch; no output written: '+digest)
 args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(data)
 print(digest,args.output)
if __name__=='__main__':main()
