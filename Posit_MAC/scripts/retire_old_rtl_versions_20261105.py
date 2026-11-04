"""User-authorized retirement of old RTL snapshots, preserving report payloads.

Only deletes classified files under results/experiments and named old locks.
Never follows links, never touches live RTL modules, golden models, or new locks.
Mixed evidence ZIPs retain report/vector entries byte-for-byte.
"""
from pathlib import Path
import hashlib
import json
import os
import zipfile

ROOT=Path(__file__).resolve().parents[1]
WORKSPACE=ROOT.parent
PUBLISH=WORKSPACE/'.github-publish-Project/Posit_MAC'
REPORT=ROOT/'docs/retired_versions_20261105.json'
CODE={'.sv','.v','.vh','.svh','.vhd','.vhdl','.cpp','.cc','.c','.h','.hpp','.f'}
OLD_LOCKS=['rtl/production.f','rtl/production_freeze.json','rtl/feedforward_checkpoint.json',
    'rtl/shared_multiplier_checkpoint.json','rtl/quire_checkpoint.json','rtl/quire_opt_checkpoint.json',
    'syn/fixed32_3_release.json','syn/opt12_120mhz_release.json']


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def safe(p,root):
    p=Path(os.path.abspath(p));p.relative_to(root)
    for ancestor in [p,*p.parents]:
        if ancestor==root.parent:break
        assert not ancestor.is_symlink(),ancestor
    return p


def old_lock(name):
    n=Path(name).name.lower()
    return ('freeze' in n or 'checkpoint' in n or n=='frozen_sources.sha256') and n.endswith(('.json','.sha256'))


def classify(root):
    retired={}
    for rel in OLD_LOCKS:
        p=root/rel
        if p.is_file():retired[p]='superseded lock metadata'
    for p in (root/'experiments').rglob('*'):
        if p.is_file():retired[p]='retired isolated candidate source'
    for p in (root/'results').rglob('*'):
        if not p.is_file():continue
        rel=p.relative_to(root/'results')
        if rel.parts[0]=='nf_f_lock_20261105':continue
        if p.suffix.lower() in CODE:retired[p]='historical RTL/verification source snapshot'
        elif old_lock(p.name):retired[p]='historical source-lock metadata'
    return retired


def process_zip(path):
    with zipfile.ZipFile(path) as archive:
        members=[i for i in archive.infolist() if not i.is_dir()]
        removed=[i for i in members if Path(i.filename.replace('\\','/')).suffix.lower() in CODE or old_lock(i.filename)]
        if not removed:return None
        pure_source=any(token in path.name.lower() for token in ['source','bundle','before_literal','reference_split'])
        if pure_source:return {'action':'remove_source_archive','sha256':sha(path),'members':len(members)}
        keep=[i for i in members if i not in removed]
        records={i.filename:hashlib.sha256(archive.read(i)).hexdigest() for i in keep}
        scratch=path.with_name(path.name+'.without_sources')
        assert not scratch.exists()
        with zipfile.ZipFile(scratch,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as new:
            for entry in keep:new.writestr(entry,archive.read(entry))
            new.writestr('RTL_RETIREMENT_20261105.json',json.dumps({
                'date':'2026-11-05','removed_source_entries':[i.filename for i in removed],
                'reports_vectors_preserved_sha256':records,
                'note':'Historical source removed by user request. Any original source index describes the earlier archive.'},indent=2))
    with zipfile.ZipFile(scratch) as check:
        assert check.testzip() is None
        for name,h in records.items():assert hashlib.sha256(check.read(name)).hexdigest()==h,name
    original=sha(path);os.replace(scratch,path)
    return {'action':'strip_source_keep_evidence','original_sha256':original,
            'new_sha256':sha(path),'removed_source_entries':len(removed),
            'preserved_entries':len(records),'preserved_member_sha256':records}


def main():
    assert not REPORT.exists(),'Retirement is one-shot; inspect the receipt'
    assert (ROOT/'releases/current.json').is_file(),'Freeze current versions first'
    results={'date':'2026-11-05','status':'RUNNING','roots':{},'zip_changes':[],
        'user_scope':'Remove old source snapshots/locks; retain reports/logs/vectors; keep current NF/F locks and working quire RTL.'}
    protected={}
    for root in [ROOT,PUBLISH]:
        assert root.resolve().is_relative_to(WORKSPACE)
        planned=classify(root)
        # All other plain evidence files remain unchanged; ZIP evidence is checked per member.
        for p in (root/'results').rglob('*'):
            if p.is_file() and p not in planned and p.suffix.lower()!='.zip':protected[p]=sha(p)
        receipt=[]
        for p,reason in sorted(planned.items()):
            safe(p,root);receipt.append({'path':p.relative_to(root).as_posix(),
                'bytes':p.stat().st_size,'sha256':sha(p),'reason':reason})
        results['roots'][str(root)]={'removed_files':receipt}
        for p in (root/'results').rglob('*.zip'):
            safe(p,root);change=process_zip(p)
            if change:
                change['path']=p.relative_to(root).as_posix();change['root']=str(root)
                results['zip_changes'].append(change)
                if change['action']=='remove_source_archive':p.unlink()
        for p in planned:p.unlink()
        # Empty directories only, including empty snapshot trees.
        for base in [root/'results',root/'experiments']:
            for p in sorted((p for p in base.rglob('*') if p.is_dir()),key=lambda x:len(x.parts),reverse=True):
                safe(p,root)
                try:p.rmdir()
                except OSError:pass
    for p,h in protected.items():assert p.is_file() and sha(p)==h,p
    assert not any(p for p in (ROOT/'results').rglob('*.sv')
                   if p.relative_to(ROOT/'results').parts[0]!='nf_f_lock_20261105')
    results['status']='COMPLETE';results['preserved_plain_evidence_files']=len(protected)
    results['preserved_plain_evidence_unchanged']=True
    REPORT.write_text(json.dumps(results,indent=2)+'\n')
    print('OLD_RTL_RETIRED',sum(len(r['removed_files']) for r in results['roots'].values()),
          'files; protected',len(protected),'plain reports/vectors; ZIP payloads checked')


if __name__=='__main__':main()
