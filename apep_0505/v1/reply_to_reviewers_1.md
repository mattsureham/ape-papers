# Reply to Reviewers - Round 1

## GPT-5.2 Referee (MAJOR REVISION)

### Must-Fix 1: Treatment is post-reform (2017/18) spending

**Concern:** The main treatment is 2017/18 expenditure used to identify 2013 reform effects. Post-treatment measurement undermines causal interpretation through reverse causality and caseload confounding.

**Response:** We agree this is the paper's most important identification concern. We have made four changes: (1) Substantially expanded the limitations section to lead with this issue, discussing the endogeneity of post-reform expenditure and the conflation of scheme generosity with caseload/take-up. (2) Elevated the alternative pre-reform JSA exposure measure (β=-0.018, p=0.01) throughout the paper—in the abstract, introduction, discussion, and conclusion—as independent corroboration that does not rely on post-reform data. (3) Softened causal language throughout: "isolates" → "is consistent with isolating"; "operates through" → "consistent with"; added explicit caveats on causal interpretation. (4) Noted that future work using direct scheme parameters (minimum payment rates, taper rates, capital limits) collected at/near 2013 would substantially strengthen identification. We cannot collect scheme-parameter panel data within this revision, but we are transparent about this limitation and the extent to which the alternative treatment addresses it.

### Must-Fix 2: Separate generosity from caseload/take-up

**Concern:** Spending per capita conflates policy generosity and claimant numbers.

**Response:** Acknowledged as a key limitation. Added explicit discussion that expenditure reflects both scheme rules and take-up behavior. The alternative treatment (pre-reform JSA) sidesteps this because it predates any scheme choices. We note that simulated entitlements for reference households would be the ideal treatment measure.

### Must-Fix 3: Re-establish identification for property prices

**Concern:** Current support for parallel trends is weak (p=0.09) and not tied to a valid treatment.

**Response:** The property price pre-trend test yields p=0.09, which we characterize as "marginally insignificant." Combined with the clean event study (Figure 3) showing no visually apparent pre-trends, and the alternative treatment corroboration (β=-0.018, p=0.01), we believe the price identification is suggestive though not ironclad. We have softened claims accordingly.

### Must-Fix 4: Resolve internal contradictions

**Concern:** The appendix claims "no significant effects" for the alternative treatment while the main text reports β=-0.018, p=0.01.

**Response:** Fixed. The appendix now reports the same pooled result (β=-0.018, p=0.01) and clarifies that individual event-study year coefficients are imprecisely estimated due to reduced power, while the overall effect is significant. Both sections are now fully consistent.

### High-Value 5: Horse-race multicollinearity

**Concern:** r=0.70 between WA and pensioner intensities; sign flips may be unstable.

**Response:** Added a new limitation paragraph discussing the multicollinearity concern and noting that the alternative treatment provides independent support. We acknowledge that VIF analysis and alternative normalizations would strengthen confidence.

### High-Value 6-8: Region×year FE, spatial spillovers, Land Registry matching

**Response:** Region×year FE and spatial lag models are beyond the current revision but noted as valuable extensions. The Land Registry matching (82.8%) is discussed in the data section with evidence that unmatched districts are evenly distributed across quartiles.

---

## Grok-4.1-Fast Referee (MAJOR REVISION)

### Must-Fix 1: Time-series CTS expenditure for dynamic treatment

**Concern:** 2017/18 snapshot assumes persistence; fiscal shocks could endogenize.

**Response:** We lack a full Revenue Outturn panel for CTS expenditure splits by working-age/pensioner for 2013-2016 (data available from 2017/18 onward). We address this through (1) the alternative pre-reform treatment, (2) explicit acknowledgment in limitations, and (3) citation to Adam (2017) survey evidence on scheme persistence.

### Must-Fix 2: Bound/test horse-race endogeneity

**Concern:** Both WA/Pen are post-reform expenditures; correlated (r=0.70).

**Response:** Added multicollinearity limitation. The pre-reform JSA treatment serves as the closest available "instrument" in the sense of providing an independent pre-determined measure. Formal IV estimation would require stronger exclusion restrictions than we can justify.

### Must-Fix 3: Explicit scheme-parameter treatment

**Concern:** Expenditure conflates generosity/take-up.

**Response:** Acknowledged as key limitation. NPI/Adam surveys document scheme parameters but not in a panel format suitable for econometric analysis. We note this as the highest-priority data improvement for future work.

### High-Value: Spatial robustness, micro-transactions, citations

**Response:** Spillover limitation paragraph added. Micro-transaction analysis noted as an important extension. Citation suggestions noted for future revision.

---

## Gemini-3-Flash Referee (MINOR REVISION)

### Must-Fix 1: Correlation with other austerity measures (RSG cuts)

**Concern:** If CTS cuts correlate with Revenue Support Grant cuts, estimates may capture omnibus austerity.

**Response:** The horse-race decomposition partially addresses this: if general austerity drove both CTS and other cuts, pensioner intensity should capture this (since pensioner services were also cut). The sign reversal suggests the working-age coefficient reflects something specific to the CTS reform channel. We acknowledge this concern in the broader austerity context discussion (Section 2.4). A correlation table with RSG cuts would strengthen the analysis but is beyond the current data.

### High-Value 1: Property price tiers

**Response:** The Land Registry data do not include valuation band information at the transaction level, precluding band-specific analysis. We note this as a limitation and potential extension.

### High-Value 2: Explicit SUTVA discussion

**Response:** Added a dedicated spillover limitation paragraph discussing border-hopping demand and SUTVA concerns.

---

## GPT-5.2 Advisor (FAIL → addressed)

### Fatal Error 1: Alternative treatment contradiction (main text vs appendix)

**Fixed:** Appendix now reports the same pooled result (β=-0.018, p=0.01) and clarifies that individual year coefficients are imprecise while the overall effect is significant.

### Fatal Error 2: JSA denominator inconsistency

**Fixed:** Main text (Section 4.2) now correctly states "total population" as the denominator, consistent with Table 1 notes and the Data Appendix. The code uses NOMIS NM_31_1 with age=0 (total population).

### Fatal Error 3: Table 4 Year FE row blank in column 4

**Fixed:** Table 4 note now explicitly states that column 4 "replaces year FE with LA-specific linear time trends (LA FE × year)." The blank Year FE cell is correct given the specification (fixest `la_code[year]` absorbs LA-specific trends but not separate year dummies).

---

## Internal Review (Claude Code)

**Concerns addressed:** JSA pre-trends (explicitly labeled non-causal throughout), treatment timing (limitation substantially expanded), price pre-trend p=0.09 (noted in text as borderline).
