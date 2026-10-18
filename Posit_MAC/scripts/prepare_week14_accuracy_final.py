"""Derivative accuracy collector: preserve the calibrated historical pilot."""
from pathlib import Path
import json
from audit_week14 import R,O,sha


def main():
    out=O/'accuracy_final'
    assert not out.exists()
    out.mkdir()
    source=(R/'tb/week14_accuracy.cpp').read_text()
    source=source.replace('long double square=0,max_err=0,max_abs_zero=0;',
                          'long double square=0,sum_err=0,max_err=0,max_abs_zero=0;')
    source=source.replace('square+=rel*rel;', 'sum_err+=err;square+=rel*rel;')
    needle='<<",\\\"max_ulp\\\":"<<max_ulp'
    assert needle in source
    source=source.replace(needle,
        '<<",\\\"mean_err_percent\\\":"<<(finite?sum_err/finite:0)\n           '+needle)
    # No change to generator, reference, strict integer thresholds or paired comparison.
    (out/'collector.cpp').write_text(source,encoding='utf-8',newline='\n')
    plan=dict(status='PREPARED_BEFORE_PILOT',parent_matrix_sha256=sha(O/'matrix_freeze.json'),
        calibrated_pilot_sha256=sha(O/'accuracy/python_check.json'),
        original_source_sha256=sha(R/'tb/week14_accuracy.cpp'),source_sha256=sha(out/'collector.cpp'),
        seeds={str(n):2026101900+n for n in range(9)},pilot_count=100000,main_count=1000000,
        order=[2,4,8,0,1,3,5,6,7],
        corpus='Unchanged mt19937_64 raw uint32 triple; first128 directed reported separately',
        confidence='Wilson95 for strict correct-rate on IID random finite/nonzero stratum; normal mean-error95 descriptive, no accuracy guarantee',
        state_policy='Standalone shared C_port; feedback correctness is covered by RTL main. No feedback application-accuracy inference.')
    (out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')


if __name__=='__main__':main()
