# Initial Research Plan — apep_0514

## Research Question

Does the severing of local–national political connections reduce local public investment? France's 2017 organic law banning the cumul of a parliamentary mandate with a local executive office (primarily the mayorship) provides a sharp natural experiment. Before 2017, 82% of French deputies simultaneously served as mayors or other local executives, creating a direct channel for local communes to access national resources. The ban forced these "cumulard" politicians to choose one mandate, breaking the local–national nexus. We estimate the causal effect of this severance on commune-level fiscal outcomes—particularly capital investment, state grants, and property values—to quantify the pork-barrel cost of dual mandates.

## Identification Strategy

**Design:** Two-period Difference-in-Differences (DiD)

- **Treatment group:** Communes in legislative constituencies whose député held a local executive mandate (primarily mayorship) during the XIV legislature (2012–2017). ~476 treated constituencies containing ~25,000 communes.
- **Control group:** Communes in constituencies whose député held NO local executive mandate. ~101 control constituencies.
- **Treatment timing:** June 2017 legislative elections (first election under the ban).
- **Panel:** 2008–2023 annual commune budgets. Primary specification: 2008–2019 (avoids COVID confounds).

**Key assumption:** Parallel trends in fiscal outcomes between cumulard and non-cumulard constituencies in the 2008–2016 pre-period.

**Threats and mitigation:**
1. *Selection into cumul:* Cumulard constituencies may differ systematically. Address with covariate matching on pre-reform characteristics (population, urbanization, income, political composition).
2. *COVID confounds:* Primary specification uses 2008–2019 only. Robustness with full 2008–2023 panel.
3. *Other concurrent reforms:* Region mergers (2016), NOTRe law (2015). Control for region FE and département FE.
4. *Anticipation:* Law passed Feb 2014 but binding only at June 2017 election. Test for anticipation effects in 2014–2016.

## Expected Effects and Mechanisms

**Primary hypothesis:** Communes that lost their cumulard connection experienced a decline in state investment grants and capital spending relative to controls.

**Channel decomposition:**
1. **State grants channel:** DETR/DSIL investment grants are discretionary and allocated by préfets. Cumulard MPs could lobby for their commune. Loss of dual mandate → reduced grant allocation.
2. **Capital spending channel:** Total capital expenditure (investment budgets) may decline as grant funding falls.
3. **Property value channel:** If local public investment affects amenity value, DVF property prices should respond.
4. **Political competition channel:** The ban may increase electoral competition in subsequent municipal elections (2020) as the incumbency advantage of cumulard mayors weakens.

**Sign ambiguity (scientific value):** The effect could be positive (cumulards diverted attention from Parliamentary duties, and focused mayors may invest more efficiently) or negative (loss of national advocacy channel reduces resources). This ambiguity makes the finding interesting regardless of direction.

## Primary Specification

$$Y_{ct} = \alpha + \beta \cdot \text{Cumulard}_c \times \text{Post}_t + \gamma_c + \delta_t + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: Fiscal outcome for constituency $c$ in year $t$
- $\text{Cumulard}_c$: Indicator for constituency having a cumulard MP in the XIV legislature
- $\text{Post}_t$: Indicator for $t \geq 2017$
- $\gamma_c$: Constituency fixed effects
- $\delta_t$: Year fixed effects
- Clustering: At the constituency level (577 clusters)

**Event-study specification:**
$$Y_{ct} = \alpha + \sum_{k \neq -1} \beta_k \cdot \text{Cumulard}_c \times \mathbf{1}(t = k) + \gamma_c + \delta_t + \varepsilon_{ct}$$

## Exposure Alignment (DiD Requirements)

- **Who is treated:** Communes whose legislative representative held a local executive mandate
- **Primary estimand population:** ~25,000 communes in ~476 treated constituencies
- **Placebo/control population:** ~8,000 communes in ~101 non-cumulard constituencies; additional placebo: private-sector outcomes
- **Design:** Standard 2×2 DiD (not staggered — single treatment date June 2017)

## Power Assessment

- **Pre-treatment periods:** 9 (2008–2016)
- **Treated clusters:** ~476 constituencies
- **Control clusters:** ~101 constituencies
- **Post-treatment periods:** 3 clean (2017–2019), up to 7 total (2017–2023)
- **MDE:** With 577 clusters, 9 pre-periods, and constituency-level outcomes, standard power calculations suggest ability to detect effects of 0.05 SD or larger. This is sufficient for economically meaningful effects on commune investment (~5% change).

## Planned Robustness Checks

1. Event-study pre-trend validation with HonestDiD sensitivity
2. Propensity-score matched sample (matching on pre-reform covariates)
3. Placebo outcome: private-sector employment (should not respond to dual mandate ban)
4. Placebo timing: "fake ban" at 2012 election using 2008–2016 data only
5. Drop COVID years (2020–2021) robustness
6. Triple-difference: Cumulard × Post × Rural (rural communes more dependent on state grants)
7. Dose-response: Intensity defined by type of local mandate (mayor vs. councillor) and commune population
8. Wild cluster bootstrap inference (robustness to clustering assumptions)

## Data Sources

| Source | Content | Access | Format |
|--------|---------|--------|--------|
| DGFiP Comptes individuels des communes | Annual commune budgets (revenue, expenditure, debt) | data.gouv.fr bulk download | CSV |
| Assemblée nationale open data | Deputies of XIV and XV legislatures with mandates | data.assemblee-nationale.fr | JSON/XML |
| NosDéputés.fr | Deputy profiles with local mandates | API/bulk | JSON |
| Commune-constituency crosswalk | Links communes to legislative constituencies | data.gouv.fr | CSV |
| DVF | Universe of property transactions | data.gouv.fr bulk download | CSV |
| Elections législatives | 2012, 2017, 2022 results by constituency/commune | data.gouv.fr | CSV |
| Elections municipales | 2008, 2014, 2020 results | data.gouv.fr | CSV |
| INSEE COG | Code officiel géographique (commune identifiers) | INSEE | CSV |
