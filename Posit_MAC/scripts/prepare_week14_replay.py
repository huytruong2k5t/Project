"""Deliberately corrupt one expected result in a separate negative-test executable."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];O=R/'results/week14/replay_test'
assert not O.exists();O.mkdir()
text=(R/'tb/week14_fused_harness.cpp').read_text()
text=text.replace('const auto exp=Model::add(p,ceff);','auto exp=Model::add(p,ceff);')
needle='++oracle_checks;'
assert text.count(needle)==1
text=text.replace(needle,needle+'\n        exp.bits^=1;failure_expected=exp.bits; // NEGATIVE TEST ONLY: do not use for acceptance.')
(O/'injected.cpp').write_text(text,encoding='utf-8',newline='\n')
