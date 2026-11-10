import plistlib, subprocess, tempfile, unittest
from pathlib import Path

RUNNER = Path('/tmp/kamui-depthfix-runner')

class DepthFixTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.version = Path(self.tmp.name)/'versions'/'1'
        self.bundle = self.version/'contents'/'wall.wallpaper'
        self.bundle.mkdir(parents=True)
        self.path = self.bundle/'Wallpaper.plist'
        self.config = self.version/'com.apple.posterkit.provider.instance.renderingConfiguration.plist'

    def fixture(self, kind='LayeredAnimation', floating='floating.ca'):
        d={'family':'WWDC22','assets':{'lockAndHome':{'default':{'type':kind,'floatingAnimationFileNameKey':floating}}}}
        self.path.write_bytes(plistlib.dumps(d))
        if '/' not in floating and '\\' not in floating:
            (self.bundle/floating).mkdir(exist_ok=True)
            (self.bundle/floating/'main.caml').write_bytes(b'animation')

    def run_fix(self):
        return subprocess.run([str(RUNNER),self.tmp.name],capture_output=True,text=True)

    def test_fix_and_idempotence(self):
        self.fixture()
        self.assertEqual(self.run_fix().stdout.strip(),'1')
        self.assertEqual(self.run_fix().stdout.strip(),'1')
        d=plistlib.loads(self.path.read_bytes())
        self.assertEqual(d['family'],'Clownfish')
        self.assertEqual(d['assets']['lockAndHome']['default']['floatingAnimationFileNameKey'],'Clownfish_floating.ca')
        self.assertEqual((self.bundle/'Clownfish_floating.ca'/'main.caml').read_bytes(),b'animation')
        cfg=plistlib.loads(self.config.read_bytes())
        self.assertFalse(cfg['$objects'][1]['depthEffectDisabled'])

    def test_unrelated_type_unchanged(self):
        self.fixture(kind='ParameterizedCA')
        before=self.path.read_bytes()
        self.assertEqual(self.run_fix().stdout.strip(),'0')
        self.assertEqual(self.path.read_bytes(),before)
        self.assertFalse(self.config.exists())

    def test_existing_configuration_is_preserved(self):
        self.fixture(); self.config.write_bytes(b'existing')
        self.assertEqual(self.run_fix().returncode,0)
        self.assertEqual(self.config.read_bytes(),b'existing')

    def test_collision_aborts(self):
        self.fixture(); (self.bundle/'Clownfish_floating.ca').mkdir()
        before=self.path.read_bytes()
        self.assertNotEqual(self.run_fix().returncode,0)
        self.assertEqual(self.path.read_bytes(),before)

    def test_traversal_name_rejected(self):
        self.fixture(floating='../escape.ca')
        self.assertNotEqual(self.run_fix().returncode,0)

if __name__=='__main__': unittest.main()
