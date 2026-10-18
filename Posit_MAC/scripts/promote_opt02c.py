"""Promote the audited source once; leave the release pending active build checks."""
from pathlib import Path
import hashlib
import json
import shutil

from audit_opt02c import R,O,collect,sha,header


def main():
    if (O/'promotion.json').exists():raise RuntimeError('Preserve existing promotion')
    result=collect(require_complete=True)
    assert result['ready_for_selection'] and 'release_structure' in result and 'f_release_sta' in result
    variant=result['selection']['variant']
    frozen=json.loads((O/'freeze.json').read_text())
    source=O/'source'/variant
    paths=frozen['production_f']
    assert (R/'rtl/production.f').read_text().splitlines()==paths
    for name in paths+['rtl/posit_mac.vh']:
        p=R/name
        assert sha(p)==frozen['variants']['production'][p.name],f'Concurrent production edit: {name}'
        if p.suffix=='.sv':assert header(p)==header(source/p.name),name
    extras=['rtl/mac_nf/posit_product_pack.sv','rtl/mac_nf/posit_magnitude_parse.sv']
    assert all(not (R/p).exists() for p in extras),'Do not overwrite unrelated modules'
    updates=[]
    for name in paths+extras:
        target=R/name
        previous=sha(target) if target.exists() else None
        if previous!=sha(source/target.name):
            shutil.copyfile(source/target.name,target)
            updates.append(dict(path=name,previous_sha256=previous,new_sha256=sha(target)))
    all_paths=paths+extras
    (R/'rtl/production.f').write_text('\n'.join(all_paths)+'\n',newline='\n')
    maps=json.loads((R/'scripts/rtl_paths.json').read_text())
    for path in extras:maps['rtl/'+Path(path).name]=path
    (R/'scripts/rtl_paths.json').write_text(json.dumps(maps,indent=2)+'\n',newline='\n')
    (R/'scripts/rtl_paths.tsv').write_text(''.join(k+'\t'+v+'\n' for k,v in sorted(maps.items())),newline='\n')
    (O/'promotion.json').write_text(json.dumps({'status':'PROMOTED_PENDING_ACTIVE_CHECKS',
        'selected_variant':variant,'updated_modules':updates,'module_count':len(all_paths),
        'backup':'source/production plus reference_production.f in this study',
        'authorization':'user requested optimize and lock RTL before W14'},indent=2)+'\n')
    print('Promoted '+variant+': '+str(len(updates))+' module files changed, '+str(len(all_paths))+' modules total; lock pending active checks')


if __name__=='__main__':main()
