"""Derive isolated NF ModelSim and one-run A35T drivers; preserve old studies."""
from pathlib import Path
import shutil

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02b_20261017'
for name in ['fixtures','protocol_fixtures']:
    assert not (O/name).exists()
    shutil.copytree(R/'results/opt03_20261017'/name,O/name)
s=(R/'scripts/verify_opt03_modelsim.ps1').read_text().replace('opt03_20261017','opt02b_20261017')
(R/'scripts/verify_opt02b_modelsim.ps1').write_text(s)
s=(R/'scripts/single_a35_packer_sta.tcl').read_text()
a=s.index('# Requested scope is the product packer.')
b=s.index('close $csv',a)
s=s[:a]+'''report_group add_align [get_cells -hier -filter {IS_SEQUENTIAL && NAME =~ *u_add/a1_q_reg*}]
'''+s[b:]
s=s.replace('SINGLE_A35_PACKER_STA_COMPLETE','OPT02B_A35_PPA_COMPLETE')
(R/'scripts/opt02b_a35_ppa.tcl').write_text(s)
print('OPT02B_DRIVERS_PREPARED')
