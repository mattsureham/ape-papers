# Initial Research Plan — apep_0571

## Research Question

Does the shift from compulsory to voluntary voting erode public safety provision in communities that lose the most voters? Chile's 2012 reform (Law 20.568) replaced compulsory voting with voluntary voting, causing turnout to collapse from 87% to 43% — with sharply differential declines across comunas by socioeconomic composition. This paper tests whether the resulting shift in the electorate toward wealthier, more educated voters led to deterioration of public safety in poorer comunas that lost the most democratic voice.

## Identification Strategy

**Bartik-style continuous-treatment DiD.** The reform was national (single timing: October 2012), but treatment intensity varies by comuna. Pre-reform (2002 Census) demographic composition — poverty rate, share with incomplete secondary education, share over 60, rurality — strongly predicts the magnitude of turnout decline (documented by Cox & González 2022).

**Estimating equation:**
$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (Z_i \times Post_t) + X_{it}'\delta + \varepsilon_{it}$$

where:
- $Y_{it}$: crime rate per 100K population in comuna $i$, year $t$
- $Z_i$: predicted turnout loss (from first-stage regression of actual turnout decline on pre-reform demographics)
- $Post_t$: indicator for $t \geq 2013$
- $\alpha_i$, $\gamma_t$: comuna and year fixed effects

**Event study specification:**
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k \neq 2011} \beta_k \cdot (Z_i \times \mathbb{1}[t = k]) + \varepsilon_{it}$$

with 2011 as the base year.

**Alternative: IV specification.** Instrument actual 2008→2012 turnout change with predicted change from pre-reform demographics. The first stage is strong (Cox & González 2022 document this).

## Built-in Placebo (Key Identification Feature)

**Police-discretionary vs. non-discretionary crimes.** If the mechanism is reduced policing effort/budget in high-turnout-loss comunas, effects should concentrate in:
- **Treatment group:** Robbery, drug offenses, vehicle theft — crimes sensitive to police patrol intensity
- **Placebo group:** Homicide, domestic violence — crimes of passion unrelated to police resource allocation

This built-in placebo mirrors the winning designs in the tournament (e.g., behavioral health placebo in Medicaid papers, owner-occupier placebo in EPC papers).

## Expected Effects and Mechanisms

**Theory (Fujiwara 2015, Econometrica):** When poor voters exit, politicians reallocate resources away from services benefiting the poor. Public safety in poorer neighborhoods should deteriorate.

**Primary prediction:** $\beta > 0$ — comunas with larger predicted turnout loss experience higher crime rates after 2012.

**Mechanism tests:**
1. Effects concentrated in police-discretionary crimes (robbery, drugs) vs. null for non-discretionary (homicide, DV)
2. Effects larger in comunas where LOW-income voters disproportionately dropped out
3. Municipal budget composition: public safety spending declines in high-loss comunas (SINIM data)
4. Timing: effects emerge after municipal elections (when politicians respond to new electorate), not immediately

## Primary Specification

TWFE with continuous treatment (valid because single treatment timing — no staggered adoption heterogeneity concerns). Cluster SEs at the comuna level (~345 clusters).

## Data Sources

| Source | Coverage | Confirmed |
|--------|----------|-----------|
| datos.gob.cl DMCS xlsx | 2010-2012, comuna-monthly | Yes (smoke test) |
| GitHub CEAD parquet | 2018-2025, comuna-monthly | Yes (smoke test) |
| CEAD historical (scraper) | 2005-2017, comuna-annual | Attempted |
| SERVEL (Harvard Dataverse) | Turnout by comuna, 2008-2012 | Yes (smoke test) |
| 2002 Census demographics | Comuna-level | To fetch |
| SINIM municipal budgets | Annual, comuna-level | To fetch |

## Planned Robustness

1. Event-study pre-trends (visual + joint F-test)
2. Placebo reform using 2004→2008 election (both compulsory — should show no differential effect)
3. Randomization inference (permute predicted turnout loss across comunas)
4. Wild cluster bootstrap (for inference)
5. Leave-one-out region stability
6. Controls for time-varying confounders: regional GDP, unemployment, police-to-population ratios
7. HonestDiD/Rambachan-Roth sensitivity analysis for pre-trend violations
8. Alternative treatment definitions (actual vs. predicted turnout loss)

## Exposure Alignment (DiD Required)

- **Who is treated:** All comunas (continuous treatment intensity)
- **Primary estimand:** Effect of a 1pp increase in predicted turnout loss on crime rates
- **Placebo population:** Crimes of passion (homicide, domestic violence) — non-discretionary
- **Design:** Continuous-treatment DiD (single timing)

## Power Assessment

- Pre-treatment periods: 2+ years (2010-2011), up to 7 if historical data obtained
- Treatment timing: October 2012 (single national reform)
- Units: ~345 comunas
- Post-treatment periods: 7+ years (2018-2025 confirmed)
- Treatment variation: predicted turnout loss ranges from ~10pp to ~60pp across comunas
- Outcome variation: property crime rates per 100K range from <100 to >3,000
