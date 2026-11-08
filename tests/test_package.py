import hashlib,importlib.util,io,re,unittest,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('builder',ROOT/'tools/build.py');builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
class PackageTests(unittest.TestCase):
 def test_deterministic(self):self.assertEqual(builder.payload(ROOT/'src'),builder.payload(ROOT/'src'))
 def test_archive(self):
  with zipfile.ZipFile(io.BytesIO(builder.payload(ROOT/'src'))) as z:
   self.assertIsNone(z.testzip());self.assertEqual(set(z.namelist()),builder.EXPECTED)
   self.assertTrue(all(i.compress_type==zipfile.ZIP_STORED and i.create_system==3 and i.external_attr==(0o100644 << 16) for i in z.infolist()))
   self.assertTrue(all(z.read(n)==(ROOT/'src'/n).read_bytes() for n in z.namelist()))
 def test_trace_defaults_off(self):
  s=(ROOT/'src/rtv-mini-hud/Settings.gd').read_text()
  self.assertRegex(s,r'(?s)attribution_trace.*false')
 def test_pinned_scope(self):
  s=(ROOT/'src/rtv-mini-hud/CallbackContracts.gd').read_text()
  self.assertIn('VostokToolkit._on_ai_death@5.5.1',s);self.assertIn('MurdieLavaLamps._ai_died@1.1.2',s)
  self.assertNotIn('TotalKills',s)
 def test_native_boundary(self):
  s=(ROOT/'src/rtv-mini-hud/KillObserver.gd').read_text()
  body=s.split('func _death_native_after(',1)[1].split('func _death_after(',1)[0]
  self.assertIn('if not _step(target): return',body);self.assertNotIn('_step(target,',body)
  self.assertIn('death_pre_done',body)
if __name__=='__main__':unittest.main()
