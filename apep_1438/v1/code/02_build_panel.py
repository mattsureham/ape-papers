#!/usr/bin/env python3
"""Build muni-year panel linking donor capture to ICFES outcomes."""
import sys, json, unicodedata
from pathlib import Path
import pandas as pd
import requests

DATA = Path(__file__).resolve().parent.parent / "data"

def norm(s):
    if not isinstance(s, str): return ""
    s = unicodedata.normalize("NFKD", s).encode("ascii","ignore").decode("ascii")
    return s.upper().strip()

# --- DIVIPOLA codes ---
print("Fetching DIVIPOLA...", file=sys.stderr)
r = requests.get("https://www.datos.gov.co/resource/gdxc-w37w.json", params={"$limit":2000})
r.raise_for_status()
divi = pd.DataFrame(r.json())
divi['dpto_n'] = divi['dpto'].map(norm)
divi['mun_n'] = divi['nom_mpio'].map(norm)
divi = divi[['cod_mpio','cod_dpto','dpto_n','mun_n']].rename(columns={'cod_mpio':'muni'})

# --- Load datasets ---
cc = pd.read_parquet(DATA/'cuentas_claras_2019.parquet')
mayors = pd.read_parquet(DATA/'mayors_2019.parquet')
secop = pd.read_parquet(DATA/'secop_2020_2022.parquet')
icfes = pd.read_parquet(DATA/'icfes_muni_period.parquet')

# Numeric coercion
cc['ing_valor'] = pd.to_numeric(cc['ing_valor'], errors='coerce').fillna(0)
secop['valor_del_contrato'] = pd.to_numeric(secop['valor_del_contrato'], errors='coerce').fillna(0)
for c in ['mean_global','mean_math','mean_lectura','n_students']:
    icfes[c] = pd.to_numeric(icfes[c], errors='coerce')

# --- Normalize names + attach DANE muni code ---
cc['dpto_n'] = cc['dep_nombre'].map(norm)
cc['mun_n'] = cc['mun_nombre'].map(norm)
cc['cand_n'] = cc['nombre_candidato'].map(norm)
cc = cc.merge(divi[['muni','dpto_n','mun_n']], on=['dpto_n','mun_n'], how='left')

mayors['dpto_n'] = mayors['departamento'].map(norm)
mayors['mun_n'] = mayors['municipio'].map(norm)
mayors['win_n'] = mayors['nombre_del_elegido'].map(norm)
mayors = mayors.merge(divi[['muni','dpto_n','mun_n']], on=['dpto_n','mun_n'], how='left')

print(f"CC linked to DANE: {cc['muni'].notna().sum():,} / {len(cc):,}", file=sys.stderr)
print(f"Mayors linked to DANE: {mayors['muni'].notna().sum():,} / {len(mayors):,}", file=sys.stderr)

# --- Identify the WINNING candidate's donor cedulas per muni ---
# Match within muni: best Jaccard token overlap between cand_n and win_n
def token_jaccard(a, b):
    A = set(a.split()); B = set(b.split())
    if not A or not B: return 0
    return len(A & B) / len(A | B)

# For each muni, get distinct candidates from cc and pick the one matching the winner
mayors_lookup = mayors.dropna(subset=['muni']).set_index('muni')['win_n'].to_dict()

cc_cand = cc.dropna(subset=['muni'])[['muni','cand_n']].drop_duplicates()
cc_cand['win_n'] = cc_cand['muni'].map(mayors_lookup)
cc_cand = cc_cand.dropna(subset=['win_n'])
cc_cand['j'] = cc_cand.apply(lambda r: token_jaccard(r['cand_n'], r['win_n']), axis=1)

# Best-match candidate per muni (must have at least 0.4 token overlap)
best = cc_cand.sort_values(['muni','j'], ascending=[True,False]).drop_duplicates('muni')
best_winners = best[best['j'] >= 0.4][['muni','cand_n']].rename(columns={'cand_n':'winner_cand_n'})
print(f"Munis with matched winning candidate in CC: {len(best_winners):,}", file=sys.stderr)

# Get donor cedulas of the winning candidate (per muni)
winner_donors = (cc.merge(best_winners.assign(_w=1), left_on=['muni','cand_n'],
                          right_on=['muni','winner_cand_n'])
                   [['muni','ing_identificacion','ing_valor']])
# Drop rows with empty donor cedula
winner_donors = winner_donors[winner_donors['ing_identificacion'].astype(str).str.len() >= 5]
print(f"Winner-donor records: {len(winner_donors):,}", file=sys.stderr)

# --- Treatment: donors of winning candidate who later became SECOP contractors ANYWHERE ---
# Identification: candidates whose donor base includes the "contractor class" — this is
# itself a marker of clientelist political finance.
secop['donor'] = secop['documento_proveedor'].astype(str)
contractor_set = set(secop['donor'].unique())
wd = winner_donors.copy()
wd['is_contractor'] = wd['ing_identificacion'].astype(str).isin(contractor_set)
wd['ing_valor'] = pd.to_numeric(wd['ing_valor'], errors='coerce').fillna(0)

# Per muni: count and value of donors who became contractors
muni_treat = wd.groupby('muni').agg(
    n_donors=('ing_identificacion','nunique'),
    n_donor_contractors=('is_contractor', lambda s: s.sum()),
    val_donations=('ing_valor','sum'),
    val_from_contractors=('ing_valor', lambda s: wd.loc[s.index].loc[wd.loc[s.index,'is_contractor'],'ing_valor'].sum())
).reset_index()
muni_treat['contractor_donor_share'] = muni_treat['n_donor_contractors'] / muni_treat['n_donors'].replace(0,pd.NA)
muni_treat['contractor_donor_share'] = muni_treat['contractor_donor_share'].fillna(0)
muni_treat['contractor_value_share'] = muni_treat['val_from_contractors'] / muni_treat['val_donations'].replace(0,pd.NA)
muni_treat['contractor_value_share'] = muni_treat['contractor_value_share'].fillna(0)
muni_treat['has_contractor_donor'] = (muni_treat['n_donor_contractors'] > 0).astype(int)
cap = muni_treat.copy()
cap['donor_share'] = cap['contractor_value_share']  # primary intensity measure
cap['contract_total'] = cap['val_donations']
cap['contract_to_donors'] = cap['val_from_contractors']
print(f"Munis with treatment data: {len(cap):,}", file=sys.stderr)
print(f"  with contractor-donor: {cap['has_contractor_donor'].sum():,}", file=sys.stderr)
print(f"  mean contractor_donor_share: {cap['contractor_donor_share'].mean():.4f}", file=sys.stderr)
print(f"  mean contractor_value_share: {cap['contractor_value_share'].mean():.4f}", file=sys.stderr)

# --- ICFES periods → year (use only fall periods 'Y4' to be consistent annual) ---
icfes['year'] = icfes['periodo'].astype(str).str[:4].astype(int)
icfes['sem'] = icfes['periodo'].astype(str).str[-1]
# Aggregate to year-level (weighted average across semesters)
icfes['mw_g'] = icfes['mean_global'] * icfes['n_students']
icfes['mw_m'] = icfes['mean_math'] * icfes['n_students']
icfes['mw_l'] = icfes['mean_lectura'] * icfes['n_students']
yearly = icfes.groupby(['muni','year']).agg(
    mw_g=('mw_g','sum'), mw_m=('mw_m','sum'), mw_l=('mw_l','sum'),
    n=('n_students','sum')
).reset_index()
yearly['mean_global'] = yearly['mw_g'] / yearly['n']
yearly['mean_math'] = yearly['mw_m'] / yearly['n']
yearly['mean_lectura'] = yearly['mw_l'] / yearly['n']
yearly = yearly[['muni','year','mean_global','mean_math','mean_lectura','n']]
yearly = yearly[yearly['year'].between(2013,2022)]

# --- Final panel ---
panel = yearly.merge(cap[['muni','contract_total','contract_to_donors','donor_share',
                          'contractor_donor_share','contractor_value_share','has_contractor_donor',
                          'n_donors','n_donor_contractors']],
                     on='muni', how='inner')
panel = panel.merge(mayors[['muni','departamento','municipio']].dropna(subset=['muni']).drop_duplicates('muni'),
                    on='muni', how='left')
panel['post'] = (panel['year'] >= 2020).astype(int)
panel['treated_high'] = (panel['contractor_value_share'] > panel.loc[panel['contractor_value_share']>0,'contractor_value_share'].median()).astype(int)
panel['log_donations'] = (panel['contract_total']+1).map(lambda x: __import__('math').log(x))

panel.to_parquet(DATA/'panel.parquet', index=False)
panel.to_csv(DATA/'panel.csv', index=False)

# Diagnostics
n_treated_units = panel.loc[panel['has_contractor_donor']==1,'muni'].nunique()
n_pre = panel.loc[panel['year']<2020,'year'].nunique()
diag = {
  'n_obs': int(len(panel)),
  'n_munis': int(panel['muni'].nunique()),
  'n_treated': int(n_treated_units),
  'n_pre': int(n_pre),
  'n_post': int(panel.loc[panel['year']>=2020,'year'].nunique()),
  'mean_donor_share_overall': float(panel['donor_share'].mean()),
  'mean_donor_share_positive': float(panel.loc[panel['donor_share']>0,'donor_share'].mean()) if n_treated_units>0 else 0.0,
  'years_in_panel': sorted(panel['year'].unique().tolist()),
}
with open(DATA/'diagnostics.json','w') as f:
    json.dump(diag, f, indent=2)
print(json.dumps(diag, indent=2))
