# Research Plan: apep_0532 v2

## Revision of "When the Monsoon Satisfies" (apep_0532 v1)

### Core Change
Replace Google Trends with World Values Survey (WVS) individual microdata as primary outcome. Google Trends demoted to supplementary "attention substitution" analysis.

### Empirical Design

**Primary specification:**
```
ClimateBelief_ist = b1*TempAnom_st + b2*TempAnom_st × AgShare_s + X_ist'g + alpha_s + delta_t + e_ist
```
- i = individual, s = state, t = wave/interview period
- WVS India: Wave 5 (2006), Wave 6 (2012), Wave 7 (2022) ≈ 9,500 respondents
- Key outcomes: V81 (environment vs growth), climate concern, willingness to pay
- Individual controls: age, gender, education, income, urban/rural
- State FE + wave FE, cluster at state level

**Supplementary analyses:**
1. Google Trends substitution: agricultural search terms during heat shocks
2. GDELT: state-month climate news coverage
3. Horse-race interactions: temp × education, temp × income, temp × urban

### Weather Data Upgrade
Replace Open-Meteo state capitals with NASA POWER gridded data, population-weighted state averages.

### What's Removed
- Bartik IV (weak F-stat, dubious exclusion restriction)
- Power calculations from main text
- Detailed WCB technical exposition (→ appendix)

### What's Promoted
- Seasonal monsoon/non-monsoon split → main results
- Individual-level horse-race interactions → main results
