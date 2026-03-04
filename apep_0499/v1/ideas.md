# Research Ideas — apep_0499 (France)

## Idea 1: Does Public Investment Revitalize Declining City Centers? Evidence from France's Action Cœur de Ville

**Policy:** Action Cœur de Ville (ACV) — €5 billion place-based revitalization program targeting 222 medium-sized French cities. Announced March 26, 2018. Five axes: housing rehabilitation, commercial development, mobility, heritage, and public space. Convention signing staggered across 2018-2024, but all 222 cities designated simultaneously.

**Outcome:** (1) Property transaction prices and volumes from DVF (Demandes de Valeurs Foncières — universe of property transactions since 2014). (2) Firm creation, destruction, and sectoral composition from INSEE Sirene. (3) Commercial vacancy indicators.

**Identification:** Triple-difference (DDD): (i) ACV vs. non-ACV comparable cities × (ii) Pre vs. Post 2018 × (iii) City-center vs. peripheral properties within communes. The DDD solves the known COVID confound (medium-sized cities became more attractive during lockdowns regardless of ACV). DVF is geocoded to parcel level, enabling within-commune center/periphery classification. Callaway-Sant'Anna for event-study dynamics; matching on pre-treatment city characteristics for the control group.

**Why it's novel:** The Cour des Comptes (2022) explicitly stated that existing ACV evaluations "do not allow separating the specific role of the program from societal trends." No rigorous causal evaluation exists. This fills a major policy gap for France's largest urban revitalization program while contributing to the global place-based policy literature (Neumark & Simpson 2015; Gaubert, Hanson & Neumark 2024).

**Feasibility check:**
- ✅ 244 treated communes with INSEE codes (data.gouv.fr, verified download)
- ✅ DVF bulk data: 518MB compressed CSV, 2014-2025 (4yr pre, 7yr post)
- ✅ DVF API confirmed working (7,802+ mutations per city)
- ✅ Sirene data accessible via bulk or API (credentials configured)
- ✅ No APEP or major academic causal evaluation exists
- ✅ DDD design with built-in COVID placebo
- ✅ Mechanism chain: investment → commercial activity → amenities → housing capitalization
- ✅ 244 treated clusters (well above 20 minimum)

---

## Idea 2: Anticipating the Ban — Energy Performance Labels and Property Values in France's "Passoire Thermique" Policy

**Policy:** Loi Climat et Résilience (August 2021): progressive ban on renting energy-inefficient homes. January 2023: rent freeze on F/G-rated homes. January 2025: G-rated homes banned from new rental contracts. January 2028: F-rated homes banned. January 2034: E-rated homes banned.

**Outcome:** Property transaction prices from DVF, conditional on DPE (Diagnostic de Performance Énergétique) rating from ADEME open data (all DPEs performed since July 2021).

**Identification:** DiD on treatment intensity: G-rated properties (facing imminent ban) vs. D-rated properties (unaffected until 2034+), before and after the August 2021 law passage and January 2023 rent freeze. Additional multi-cutoff analysis comparing each DPE boundary (comparable to the winning UK EPC paper). Owner-occupied properties serve as a built-in placebo (ban only applies to rentals).

**Why it's novel:** While the UK EPC paper (apep_0477, rated 21.7) studied information vs. regulation effects in England, the French case offers a unique anticipation channel: property owners know G-rated homes will become unlettable, creating a forward-looking capitalization shock. No causal evaluation of the French DPE reform exists.

**Feasibility check:**
- ✅ ADEME DPE data available on data.ademe.fr (post-July 2021)
- ✅ DVF includes geocoded transactions
- ⚠️ DPE ratings in DVF only systematically available post-2021 (limits pre-period)
- ⚠️ Must merge DVF × ADEME DPE at property level (address matching required)
- ⚠️ More naturally an RDD/multi-cutoff design than pure DiD
- ✅ Built-in owner-occupied placebo
- ✅ First-order stakes: 4.8M "passoire thermique" homes in France

---

## Idea 3: Tax Incentives in the French Countryside — The ZRR Redesign and Rural Firm Dynamics

**Policy:** Zones de Revitalisation Rurale (ZRR) — tax exemptions for firms in designated rural communes. Major redesign in 2015: new classification criteria based on population density and median income (Décret 2015-1788). Hundreds of communes gained or lost ZRR status. Further reformed to "Zones France Rurale" (ZFR) in 2024.

**Outcome:** Firm creation and destruction rates from Sirene (universe of French firms with SIREN/SIRET). Employment indicators from INSEE BDM. Property prices from DVF.

**Identification:** DiD exploiting the 2015 redesign: communes that newly gained ZRR status (treatment) vs. communes that lost status (reverse treatment) vs. communes with unchanged status (control). Staggered by effective date of status change. Event study on firm creation rates.

**Why it's novel:** While French enterprise zones (ZFU) have been studied (Mayer, Mayneris, Py 2017 JPUBE; Gobillon, Magnac, Selod 2012 JUE), the ZRR rural program has received less rigorous causal evaluation, especially the 2015 redesign which created a natural experiment.

**Feasibility check:**
- ✅ ZRR commune lists with effective dates available via Légifrance/ANCT
- ✅ Sirene data accessible (bulk + API, credentials configured)
- ✅ DVF data for property values
- ✅ Clear treatment/control variation from 2015 redesign
- ⚠️ Need to verify exact commune-level ZRR status transitions (Légifrance décret)
- ⚠️ Rural communes have fewer transactions in DVF (smaller samples)
- ✅ Speaks to place-based tax incentive literature (Busso, Gregory, Kline 2013; Gobillon et al. 2012)

---

## Idea 4: Vacant Homes and Housing Markets — France's Expanding Vacancy Tax

**Policy:** Taxe sur les Logements Vacants (TLV) — annual tax on vacant properties. Originally applied in 8 major agglomérations (1999). Extended to 28 agglomérations (1,151 communes) by Décret 2013-392. Massively expanded by Décret 2023-822 (August 2023) to 3,690 communes, effective January 2024.

**Outcome:** Housing vacancy rates, property transaction volumes and prices from DVF, rental market indicators from INSEE BDM.

**Identification:** DiD exploiting the 2023 expansion: newly designated TLV communes (treatment) vs. non-TLV comparable communes (control), before and after January 2024. The 2013 expansion provides a historical placebo/validation test (though DVF only starts in 2014).

**Why it's novel:** Housing vacancy taxes are understudied globally despite their growing popularity. The French 2023 expansion is one of the largest natural experiments in vacancy taxation, covering 3,690 communes.

**Feasibility check:**
- ✅ TLV commune lists available via Légifrance décret
- ✅ DVF data for transaction prices/volumes
- ⚠️ Very short post-period (Jan 2024-present = ~1.5 years) — likely underpowered
- ⚠️ Vacancy rates at commune level may not be available at annual frequency
- ✅ 3,690 treated communes (massive N)
- ⚠️ Tournament feedback explicitly penalizes "recent policies with short post-periods"
