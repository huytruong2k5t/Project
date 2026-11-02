#!/usr/bin/env python3
"""Same-source module-point union, retaining raw rates and explicit exclusions."""
import hashlib
import json
from pathlib import Path
from collections import defaultdict

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/quire_20261103'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    points={}
    for label in ('coverage_final','units_final'):
        report=json.loads((OUT/(label+'.json')).read_text())
        manifest=json.loads((OUT/report['build_manifest']).read_text())
        assert report['status']=='PASS' and report['mismatches']==0
        for path,expected in manifest['source_sha256'].items():assert sha(ROOT/path)==expected,path
        for line in (OUT/(label+'.json.dat')).read_text().splitlines():
            if not line.startswith('C '):continue
            fields=dict(t.split('\x02',1) for t in line.split("'",2)[1].split('\x01') if '\x02' in t)
            if '/rtl/' not in fields.get('f',''):continue
            fields['f']=fields['f'][fields['f'].index('rtl/'):]
            key=tuple(sorted((k,v) for k,v in fields.items() if k!='h'))
            points[key]=points.get(key,0)+int(line.rsplit(' ',1)[1])
    exclusions=[]
    def exclude(path,text,reason):
        lines=(ROOT/path).read_text().splitlines()
        matches=[i+1 for i,line in enumerate(lines) if text in line]
        assert len(matches)==1,(path,matches)
        point=[key for key,n in points.items() if dict(key)['f']==path and dict(key)['l']==str(matches[0])
               and dict(key)['page'].startswith('v_line/') and n==0]
        assert len(point)==1,(path,point)
        exclusions.append({'point':dict(point[0]),'source_sha256':sha(ROOT/path),'reason':reason})
    parser=(ROOT/'rtl/parser/posit_parser.sv').read_text()
    assert "assign detector_in = {terminator_bits, 1'b1};" in parser
    exclude('rtl/common/lod_lzd_core_fixed2.sv','default:',
            'Quire hierarchy uses this module only in posit_parser: detector_in LSB is a hardwired1 sentinel. Therefore input can never be all zero and this default arm is unreachable, independently of raw A/B.')
    exclude('rtl/mac_quire/quire_read.sv','default: state_q',
            'State is2 bits and all four binary values0/1/2/3 have explicit case arms. This default is only a four-state X/Z recovery arm, unreachable in two-state Verilator. ModelSim startup/reset/stall checked separately.')
    exclude('rtl/mac_quire/mac_quire_wrapper.sv','end else if (meta_sync2)',
            'Empty implicit else of assertion-only guard: binary meta_sync2=0 takes if(!meta_sync2);1 takes else-if(meta_sync2). Only X/Z can take the implicit else. Not synthesized datapath;4-state reset checked in ModelSim.')
    thresholds={'v_line':95,'v_branch':90,'v_toggle':85}
    def metrics(filtered):
        counters=defaultdict(lambda:[0,0])
        for key,count in filtered.items():
            category=dict(key)['page'].split('/')[0]
            counters[category][0]+=count>0;counters[category][1]+=1
        return {k:{'hit':v[0],'total':v[1],'percent':100*v[0]/v[1],
                   'threshold':thresholds[k],'met':100*v[0]/v[1]>=thresholds[k]} for k,v in counters.items()}
    excluded={tuple(sorted(row['point'].items())) for row in exclusions}
    adjusted={key:n for key,n in points.items() if key not in excluded}
    report={'status':'PASS' if all(v['met'] for v in metrics(adjusted).values()) else 'OPEN',
            'scope':'Module-source-point union of100k mixed integration and exhaustive-domain/sampled unit tests, same RTL SHA. Not per-instance or formal coverage.',
            'raw':metrics(points),'adjusted':metrics(adjusted),'exclusions':exclusions,
            'unhit_retained':[dict(key) for key,n in adjusted.items() if not n],
            'inputs':{label+'.json.dat':sha(OUT/(label+'.json.dat')) for label in ('coverage_final','units_final')},
            'limits':'Thresholds unchanged. Only three source-explained line points excluded under SPEC6.6; no toggle/branch exclusions. No borrowed NF/F coverage.'}
    (OUT/'coverage_review.json').write_text(json.dumps(report,indent=2)+'\n')
    print('QUIRE_COVERAGE',report['status'],'raw', {k:round(v['percent'],3) for k,v in report['raw'].items()},
          'adjusted',{k:round(v['percent'],3) for k,v in report['adjusted'].items()})


if __name__=='__main__':main()
