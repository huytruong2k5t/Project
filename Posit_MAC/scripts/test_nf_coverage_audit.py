import importlib.util
import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('nf_audit',root/'scripts/audit_nf_coverage.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
original_read=module.read
original_sha=module.sha
original_sources=module.source_paths
results={}

def reject(name, action):
    try:
        action()
    except AssertionError as error:
        results[name]={'rejected':True,'reason':str(error)}
    else:
        raise RuntimeError('Audit incorrectly accepted '+name)
    finally:
        module.read=original_read
        module.sha=original_sha
        module.source_paths=original_sources

module.read=lambda p: 'RUNNING' if p.name=='pilot_status.txt' else original_read(p)
reject('unfinished_suite',lambda: module.audit('preflight'))

def altered_source():
    sources=original_sources()
    sources['tb/nf_coverage_corpus.hpp']='0'*64
    return sources
module.source_paths=altered_source
reject('source_changed_after_pilot',lambda: module.audit('preflight'))

module.sha=lambda p: '0'*64 if p.name=='mac_32_3.txt' else original_sha(p)
reject('fixture_changed',lambda: module.audit('preflight'))

def changed_count(path):
    if path.name=='pilot_summary.json' and path.parent.name=='32_3':
        data=json.loads(original_read(path))
        data['near_delta_standalone_acc']=[1]*10
        return json.dumps(data)
    return original_read(path)
module.read=changed_count
reject('near_below_30_percent',lambda: module.check_report(module.RUN/'32_3','pilot'))

(module.RUN/'audit_guard_tests.json').write_text(json.dumps(results,indent=2)+'\n')
print('AUDIT GUARDS PASS: 4 invalid states rejected; live data unchanged')
