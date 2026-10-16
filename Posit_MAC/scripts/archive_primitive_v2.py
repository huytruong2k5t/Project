"""Package or restore immutable small evidence; never archive tool databases."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'
ARCHIVE=OUT/'routed_evidence.zip'
SKIP={'obj_dir','obj_fast','work','db','incremental_db','xsim.dir','.Xil','tmp','appdata','localappdata','__pycache__'}
EXT={'.v','.sv','.vh','.cpp','.hpp','.h','.dat','.rpt','.log','.txt','.csv','.json','.tsv','.sha256','.do','.options','.in','.gz'}

def digest(data):return hashlib.sha256(data).hexdigest()

def safe(name):
 p=Path(name)
 if p.is_absolute() or '..' in p.parts or ':' in name or '\\' in name:
  raise RuntimeError('Unsafe evidence member: '+name)
 target=(OUT/p).resolve()
 if not target.is_relative_to(OUT.resolve()):raise RuntimeError('Outside study root')
 return target

def main():
 parser=argparse.ArgumentParser();parser.add_argument('mode',choices=('pack','restore','check'));args=parser.parse_args()
 metadata=OUT/'evidence_archive.json'
 if args.mode=='pack':
  # Freeze only after final collector and all tools are finished.
  summary=json.loads((OUT/'summary.json').read_text())
  if summary['status'] not in ('MEASURED_COMPLETE_REVIEW_REQUIRED','COMPLETE') or summary['missing']:
   raise RuntimeError('Incomplete evidence cannot be packaged as final')
  if ARCHIVE.exists():raise RuntimeError('Archive exists; do not overwrite immutable evidence')
  entries={};size=0
  with ZipFile(ARCHIVE,'x',compression=ZIP_DEFLATED,compresslevel=9) as z:
   for p in sorted(OUT.rglob('*')):
    if not p.is_file() or p.is_symlink():continue
    rel=p.relative_to(OUT)
    if any(x in SKIP for x in rel.parts) or p.name in ('evidence_archive.json','routed_evidence.zip','backup_paths.txt') or rel.as_posix()=='summary.json':continue
    if p.suffix not in EXT and p.name!='source_initial.zip':continue
    data=p.read_bytes()
    if len(data)>100*1024**2:raise RuntimeError('Unexpected large non-cache evidence: '+str(p))
    z.writestr(rel.as_posix(),data)
    entries[rel.as_posix()]=dict(bytes=len(data),sha256=digest(data));size+=len(data)
  meta=dict(status='PACKED',files=len(entries),uncompressed_bytes=size,archive_bytes=ARCHIVE.stat().st_size,
            archive_sha256=digest(ARCHIVE.read_bytes()),entries=entries,
            policy='Raw reports/logs/source/checkers/tool versions; excludes databases, binaries, waves, DCP, runtime and temporary directories. Summary remains outside archive to avoid self-reference.')
  metadata.write_text(json.dumps(meta,indent=2)+'\n')
 else:
  meta=json.loads(metadata.read_text())
  if digest(ARCHIVE.read_bytes())!=meta['archive_sha256']:raise RuntimeError('Archive hash mismatch')
  with ZipFile(ARCHIVE) as z:
   if set(z.namelist())!=set(meta['entries']):raise RuntimeError('Archive member list differs')
   for name,expected in meta['entries'].items():
    target=safe(name);data=z.read(name)
    if digest(data)!=expected['sha256']:raise RuntimeError('Member hash mismatch: '+name)
    if args.mode=='restore':
     if target.exists() and target.read_bytes()!=data:raise RuntimeError('Refusing to overwrite different data: '+name)
     target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
  print(args.mode.upper()+'_PASS files='+str(meta['files']))
 if args.mode=='pack':print('PACKED files='+str(meta['files'])+' bytes='+str(meta['archive_bytes']))

if __name__=='__main__':main()
