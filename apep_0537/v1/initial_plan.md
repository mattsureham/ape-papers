# Initial Research Plan: apep_0537

## Research Question

Does generative AI adoption constitute seniority-biased technological change? Specifically, did industries with higher GenAI adoption intensity experience disproportionate declines in entry-level/junior employment relative to senior employment after 2023, and does this pattern hold across independent public data sources?

## Motivation

Hosseini Maasoum and Lichtinger (2025) documented that firms posting GenAI integrator roles experienced sharp declines in junior hiring while senior employment continued rising, using proprietary résumé data. This paper tests whether the same pattern appears in entirely independent public data: SEC EDGAR filings for the treatment and BLS employment surveys for the outcomes. Confirming (or refuting) the seniority-bias hypothesis with different data and identification strategies is a first-order scientific contribution.

## Identification Strategy

**Design:** Continuous-treatment difference-in-differences at the industry level.

**Treatment:** Industry-level GenAI adoption intensity, measured as the share of publicly traded firms in each 3-digit NAICS industry that disclose generative AI in their annual 10-K filings with the SEC. This captures revealed adoption (firms report to investors what they are actually implementing), not just theoretical exposure.

**Outcome:** Employment by seniority level within industries, from three independent sources:
1. **QCEW** (primary): Quarterly employment counts by industry × county. High-frequency event study.
2. **OEWS**: Annual occupation × industry employment. Combined with O*NET Job Zones to classify occupations as entry-level (Zones 1-2) vs. senior (Zones 4-5).
3. **CPS**: Monthly microdata with worker age, education, tenure, and industry.

**Triple-difference:** Industry GenAI adoption intensity × Occupation seniority (Job Zone) × Post-2023.

**Pre-period:** 2015-2022 (8 years, 32 quarters).
**Post-period:** 2023-2024 (2 years, 8 quarters).

## Expected Effects and Mechanisms

**Primary hypothesis:** GenAI is seniority-biased — it substitutes for tasks disproportionately performed by junior workers (data entry, basic analysis, drafting, scheduling) while complementing senior workers' judgment and strategic roles.

**Expected signs:**
- Entry-level employment share declines in high-GenAI industries (negative)
- Senior employment share stable or increasing (zero or positive)
- Effect concentrated in high-AI-exposure occupations (AIOE interaction)
- Stronger in information, professional services, finance; weaker in healthcare, manufacturing

**Mechanism:** Primarily through reduced hiring (fewer entry-level positions posted) rather than increased separations. GenAI tools reduce the need for junior labor input per unit of senior output, raising the effective seniority ratio.

## Primary Specification

### Specification 1: Industry-level QCEW event study

$$\ln(Emp_{i,c,t}) = \alpha_i + \gamma_t + \sum_{k} \beta_k \cdot GenAI_i \cdot \mathbb{1}[t=k] + X_{i,c,t}\delta + \varepsilon_{i,c,t}$$

Where $i$ indexes 3-digit NAICS industry, $c$ county, $t$ quarter, and $GenAI_i$ is the share of firms in industry $i$ disclosing GenAI in 10-K filings by end-2024.

### Specification 2: Triple-difference with occupation seniority

$$\Delta \text{Share}_{o,i,t} = \alpha_{oi} + \gamma_t + \beta \cdot Junior_o \times GenAI_i \times Post_t + \mu_{oi,t}$$

Where $o$ indexes occupation (via 6-digit SOC), $Junior_o$ is an indicator for O*NET Job Zones 1-2, and $\Delta \text{Share}$ is the change in occupation $o$'s employment share within industry $i$.

### Specification 3: CPS worker-level

$$Emp_{j,t} = \alpha_{ind(j)} + \gamma_t + \beta \cdot Young_j \times GenAI_{ind(j)} \times Post_t + X_j\delta + \varepsilon_{j,t}$$

Where $j$ indexes individual workers in CPS, $Young_j$ indicates age < 30.

## Planned Robustness Checks

1. Alternative GenAI treatment: Felten-Raj-Seamans AIOE scores (occupation-level, no firm data needed)
2. Excluding NAICS 51 and 54 (tech/professional services — tech recession confounder)
3. Pre-ChatGPT placebo (fake treatment at 2020Q1)
4. Healthcare placebo (high AI discussion, no entry-level displacement expected)
5. Senior-occupation placebo (Job Zones 4-5 within high-GenAI industries)
6. Manual/physical occupation placebo (low AI exposure within same industries)
7. Controlling for industry-level equity returns and VC funding
8. Binary vs. continuous treatment measures
9. Callaway-Sant'Anna staggered estimator for industries with different adoption timing

## Data Sources

| Source | Unit | Frequency | Years | Access |
|--------|------|-----------|-------|--------|
| SEC EDGAR EFTS | Firm × Filing | Filing date | 2015-2025 | Public API |
| BLS QCEW | County × Industry | Quarterly | 2015-2024 | Public CSV |
| BLS OEWS | Occupation × Industry × State | Annual (May) | 2015-2024 | Public XLSX |
| O*NET | Occupation | Static snapshot | Current | Public download |
| AIOE (Felten et al.) | Occupation | Static | Published | GitHub |
| CPS Basic Monthly | Individual | Monthly | 2015-2025 | Census API |
| FRED | Series | Various | Various | API (key available) |
