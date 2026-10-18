"""Remove the directed prefix from paired win confidence inference as well."""
from fractions import Fraction
from pathlib import Path
import json
from audit_week14 import R,O,sha,load
from check_week14_accuracy import decode
from audit_week14_accuracy_final import wilson


def main():
    parent=load(O/'accuracy_final/main_check.json');assert parent['status']=='PASS'
    rows=[];inputs={}
    for d in parent['rows']:
        n=d['n'];p=O/f'accuracy_final/main/n{n}.jsonl';inputs[p.relative_to(R).as_posix()]=sha(p)
        trace=[json.loads(line) for line in p.read_text().splitlines()]
        directed=[0,0,0]
        for row in trace[:128]:
            a,b,c=[decode(row[k]) for k in ('a','b','c')]
            if None in (a,b,c):continue
            ideal=a*b+c
            if not ideal:continue
            en=abs(decode(row['nf'])-ideal);ef=abs(decode(row['f'])-ideal)
            directed[0 if ef<en else 1 if ef>en else 2]+=1
        random=[v-k for v,k in zip(d['f_win_lose_tie'],directed)];assert min(random)>=0
        assert sum(random)==d['random_nf']['finite_nonzero']==d['random_f']['finite_nonzero']
        rows.append(dict(n=n,all_paired_finite=d['f_win_lose_tie'],directed_paired_finite=directed,
            random_paired_finite=random,random_f_win_among_decisive_wilson95_percent=wilson(random[0],random[0]+random[1]),
            random_correct_rate_wilson95_percent={k:d['random_'+k]['correct_rate_wilson95_percent'] for k in ('nf','f')}))
    report=dict(status='PASS',parent_accuracy_sha256=sha(O/'accuracy_final/main_check.json'),
        producer_sha256=sha(Path(__file__)),input_sha256=inputs,rows=rows,
        policy='Only IID random finite/nonzero rows enter inferential Wilson95. Directed prefix128 removed by exact Fraction errors. Original all-paired counts remain descriptive.',
        clarification='The original main_check f_win_among_decisive_wilson95 field included the directed prefix and is descriptive only. Its inferential replacement is this report random_f_win_among_decisive_wilson95_percent. Correct-rate Wilson95 was random-only already and is unchanged.')
    (O/'accuracy_inference.json').write_text(json.dumps(report,indent=2)+'\n')
    print('ACCURACY INFERENCE PASS 9 points; directed128 excluded from paired win confidence intervals')


if __name__=='__main__':main()
