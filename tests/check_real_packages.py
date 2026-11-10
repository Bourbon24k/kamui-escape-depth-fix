import pathlib, plistlib, subprocess, sys, tempfile, zipfile

runner=pathlib.Path(sys.argv[1])
archives=[pathlib.Path(x) for x in sys.argv[2:]]
count=0

def variants(v):
    if isinstance(v,dict):
        if v.get('type') == 'LayeredAnimation' and isinstance(v.get('floatingAnimationFileNameKey'),str): yield v
        for x in v.values(): yield from variants(x)
    elif isinstance(v,list):
        for x in v: yield from variants(x)

for package in archives:
    with tempfile.TemporaryDirectory() as temp:
        base=pathlib.Path(temp)
        with zipfile.ZipFile(package) as z:
            original={x.filename:z.read(x) for x in z.infolist() if not x.is_dir() and not x.filename.startswith('__MACOSX/') and '.DS_Store' not in x.filename}
            for name,data in original.items():
                path=base/name; path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(data)
        desc=base/'descriptors'
        if not desc.exists(): continue
        folders=[p for p in desc.iterdir() if p.is_dir() and (p/'com.apple.posterkit.provider.descriptor.identifier').exists()]
        for folder in folders:
            mappings={}
            for name,data in original.items():
                if not name.endswith('/Wallpaper.plist'): continue
                root=name.rsplit('/',1)[0]+'/'
                for v in variants(plistlib.loads(data).get('assets',{})):
                    old=v['floatingAnimationFileNameKey']
                    if old.endswith('.ca'):
                        new=old if 'Clownfish' in old else 'Clownfish_'+old
                        mappings[root+old+'/']=root+new+'/'
            p=subprocess.run([str(runner),str(folder)],check=True,text=True,capture_output=True)
            first=int(p.stdout.strip())
            if first==0: continue
            def check():
                for name,data in original.items():
                    if name.endswith('/Wallpaper.plist'):
                        d=plistlib.loads((base/name).read_bytes())
                        assert d['family']=='Clownfish',(package,name)
                        continue
                    newname=name
                    for before,after in mappings.items():
                        if name.startswith(before): newname=after+name[len(before):]; break
                    assert (base/newname).read_bytes()==data,(package,name)
            check()
            assert int(subprocess.run([str(runner),str(folder)],check=True,text=True,capture_output=True).stdout.strip())==first
            check(); count+=1
print('real descriptor checks:',count)
