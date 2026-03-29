# Research Plan: The Dosage Shift

## Research Question
Did Florida's pill mill crackdown (HB 7095, October 2010) change the *dosage-strength composition* of oxycodone shipments — not just total volume — revealing the demand structure of diverted opioids?

## Identification Strategy
**Event study DiD** around Florida's pill mill law (HB 7095, effective October 2010, regulations phased through July 2011).

- **Treated units:** 67 Florida counties
- **Control units:** Georgia and Alabama counties (geographic neighbors without concurrent pill mill legislation in this period)
- **Treatment date:** October 2010 (law passage) / July 2011 (full enforcement). Use July 2011 as primary treatment date.
- **Pre-period:** January 2006 – June 2011 (5.5 years, ~66 months)
- **Post-period:** July 2011 – December 2012 (1.5 years, ~18 months)

Florida is an ideal setting: 98 of the top 100 oxycodone-dispensing physicians were in FL, no PDMP until 2011, high-dose share *doubled* from 26% to 54% (2006–2010) then crashed to 31%.

Standard TWFE event study is appropriate since all Florida counties are treated simultaneously. Will use `fixest::feols()` with county and year-month fixed effects, clustered at the state level (conservative — only 3 states, so will supplement with wild cluster bootstrap).

## Expected Effects and Mechanisms
**Primary prediction:** The high-dose oxycodone share should drop sharply in Florida post-crackdown, while Georgia/Alabama show no comparable shift.

**Mechanism:** Pill mills served two market segments:
1. **Legitimate patients** — typically prescribed lower-dose oxycodone (5–15mg)
2. **Diversion networks** — preferred high-dose (≥30mg) for crushing/snorting, easier transport per unit value

Crackdowns disproportionately shut down the diversion channel, so the *composition* shifts toward lower-dose prescriptions even as total volume also falls. The composition shift is a cleaner signal of diversion suppression than total volume.

## Primary Specification
$$\text{HighDoseShare}_{ct} = \alpha_c + \gamma_t + \sum_{k \neq -1} \beta_k \cdot \mathbb{1}[\text{FL}_c] \cdot \mathbb{1}[t - \text{July2011} = k] + \varepsilon_{ct}$$

Where:
- $\text{HighDoseShare}_{ct}$ = share of oxycodone pills with dosage ≥30mg in county $c$, month $t$
- $\alpha_c$ = county FE, $\gamma_t$ = year-month FE
- Clustered at state level + wild cluster bootstrap (3 clusters)

## Outcomes
1. **Primary:** High-dose share (oxycodone ≥30mg as % of total oxycodone pills)
2. **Secondary:** Average mg per oxycodone pill
3. **Secondary:** Oxycodone-to-hydrocodone ratio (composition across drug types)

## Data Source and Fetch Strategy
**DEA ARCOS transaction-level data** on Azure: `raw/arcos/arcos_transactions.parquet`
- 178.6M transactions, 2006–2012
- Key columns: `dos_str`, `DRUG_NAME`, `BUYER_STATE`, `BUYER_COUNTY`, `DOSAGE_UNIT`, `TRANSACTION_DATE`
- Aggregate to county-month level for analysis

**Processing pipeline:**
1. Filter to oxycodone transactions in FL, GA, AL
2. Parse `dos_str` to numeric milligrams
3. Classify pills as high-dose (≥30mg) vs. low-dose (<30mg)
4. Aggregate to county-month: total pills, high-dose pills, high-dose share, average mg
5. Also compute oxycodone vs. hydrocodone split for the ratio outcome

## Exposure Alignment
The treatment (HB 7095 enforcement) directly affects all oxycodone dispensing in Florida counties — the ARCOS data capture the universe of pill shipments to pharmacies and practitioners in each county. The outcome (high-dose share) is measured at the county-month level using the same ARCOS records, so the treated population (all Florida counties' oxycodone supply chain) is perfectly aligned with the outcome measurement. The composition shift reflects changes in what pills are shipped to Florida counties, which directly captures the supply-side effects of shutting down pill mills. Counties with no pill mills experience no composition change (confirmed by the null unweighted result), while high-volume counties with pill mills experience large shifts (confirmed by pill-weighted results).

## Robustness
- Placebo test: Apply same event study to GA/AL border counties (should show no effect)
- Alternative high-dose thresholds (≥20mg, ≥40mg)
- Donut hole around treatment date (exclude Oct 2010 – June 2011 transition period)
- Permutation inference (randomize treatment across states)
- Leave-one-out county jackknife
