# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-04-03T20:18:47.303562

---

**1. Idea Fidelity**  
The paper follows the manifest closely. It uses the ARC ARCOS transaction file, constructs county‑level “potency” measures (MME per pill and share of ≥20 mg tablets), and exploits Mallinckrodt’s 2008 high‑dose generic oxycodone launch as a shift‑share (Bartik) instrument. The identification strategy – pre‑2006 Mallinckrodt market share as the “share” and the 2008 product‑line expansion as the “shift” – is exactly as described. All key elements (the supply‑chain‑based share, the timing of the product expansion, the focus on potency rather than volume, and the hydrocodone placebo) appear in the paper. No major deviation from the original idea is evident.

**2. Summary**  
The paper documents a previously unexamined supply‑side channel of the U.S. opioid crisis: generic manufacturers’ expansion into higher‑dose oxycodone formulations. Using a shift‑share IV based on Mallinckrodt’s 2008 launch of 20‑, 40‑, and 80‑mg tablets, the author shows that counties with larger pre‑2006 Mallinckrodt exposure experienced a statistically and substantively larger increase in average oxycodone potency. The analysis suggests that product‑variety competition, rather than price competition, contributed to geographic heterogeneity in opioid strength.

**3. Essential Points**  

1. **Potential Violation of the Exclusion Restriction** – The instrument relies on the assumption that pre‑2006 Mallinckrodt share is unrelated to any other concurrent county‑level changes that could affect potency (e.g., differential adoption of prescribing guidelines, varying state‑level policy shocks, or unobserved demand shocks). The paper’s balance test shows a strong negative correlation between Mallinckrodt share and baseline potency, which raises concern that the share may be picking up unobserved county characteristics that also influence post‑2008 trends. Although the event‑study shows no pre‑trend after 2006, the negative pre‑trend in 2006 itself (Table 5) warrants a more thorough robustness exercise (e.g., adding county‑specific linear trends, instrumenting with lagged shares, or using a doubly‑robust approach).

2. **Limited Outcome Scope – No Health Outcome Analysis** – Demonstrating that potency rose is valuable, but the paper stops short of linking this increase to overdose or addiction outcomes, which is the ultimate policy relevance. While the author explicitly states that health outcomes are “outside the scope,” the AER‑Insights format expects a clear statement of why the documented channel matters for welfare. Providing at least a reduced‑form correlation (e.g., county‑level overdose deaths from CDC WONDER) would strengthen the claim that the potency arm‑race had substantive public‑health consequences.

3. **Treatment Definition and Heterogeneity** – The shift‑share reduces to a single continuous variable (2006 Mallinckrodt share). Yet the paper treats the “treatment” as both the share and the product‑line expansion. This can be confusing for readers and complicates interpretation of the 2SLS coefficient. Moreover, the effect appears to be driven almost entirely by the 20‑mg tablets (Table 6, column 5). The author should more clearly delineate (i) the effect of *any* Mallinckrodt exposure versus (ii) the marginal effect of the *new* high‑dose products, perhaps by constructing a “dose‑weighted” share that isolates the incremental high‑dose volume.

**4. Suggestions**  

*Methodological Enhancements*  
- **Instrument Validity Checks**: Augment the placebo strategy with additional falsification tests. For instance, use a similar shift‑share for a manufacturer that did **not** expand its product line (e.g., a generic ibuprofen firm) to confirm that the coefficient is specific to Mallinckrodt’s oxycodone expansion. Alternatively, construct a “reverse” instrument using post‑2008 Mallinckrodt share interacted with a pre‑2006 dummy to verify that any predictive power vanishes when the timing is mis‑aligned.  
- **County‑Specific Trends**: Include county‑level linear (or quadratic) time trends in the event‑study specification to address the observed negative pre‑trend in 2006. If the coefficient on Mallinckrodt share remains robust, the exclusion restriction will appear more credible.  
- **Alternative Share Measures**: Test robustness to alternative definitions of the share variable: (a) replace raw pill counts with dollar value of shipments (to control for price variations), (b) use the share of *high‑dose* Mallinckrodt pills in 2006 (though small, it could serve as a “pure” pre‑trend control), and (c) construct a “log‑share” to lessen the influence of extreme values. Report how the first‑stage and second‑stage coefficients vary.  

*Data and Measurement*  
- **Prescription vs. Shipment Data**: ARCOS records shipments to pharmacies, not actual dispensed prescriptions. Discuss potential discrepancies (e.g., inventory stockpiling, return policies) and, if possible, link ARCOS shipments to state Prescription Drug Monitoring Program (PDMP) data for a subsample to verify that shipment trends map onto prescribing trends.  
- **MME Conversion Consistency**: The paper assumes a constant conversion factor of 1.5 for oxycodone. While standard, consider checking whether the conversion factor varies across dosage forms (immediate‑release vs. extended‑release) or over time due to evolving clinical guidelines. A sensitivity analysis using alternative conversion factors (e.g., 1.0, 1.8) would reassure readers that results are not driven by a single conversion choice.  

*Presentation and Interpretation*  
- **Clarify the Two‑Stage Model**: Explicitly write out the second‑stage regression (potency outcome on predicted Mallinckrodt‑induced potency increase) and report the 2SLS estimate of the causal effect of *potency* on any downstream outcome (even if only the reduced‑form). This will help readers distinguish between the reduced‑form first‑stage (Mallinckrodt share → potency) and the structural effect of interest.  
- **Heterogeneity Analyses**: The paper already notes larger effects in “high‑volume” counties. Extend this by interacting the instrument with (i) baseline overdose death rates, (ii) state‑level policy variables (e.g., PDMP implementation dates), and (iii) demographic characteristics (age distribution, poverty). Such heterogeneity checks can reveal whether the potency arm‑race mattered more in vulnerable populations.  
- **Policy Discussion**: The conclusion mentions FDA oversight but could be more concrete. For example, discuss how the FDA’s “generic drug–abuse‑deterrent” guidance (issued after 2012) might mitigate similar future expansions, or propose criteria for pre‑approval assessment of high‑dose generic formulations.  

*Additional Analyses*  
- **Link to Overdose Mortality**: Even a simple reduced‑form regression of county‑year overdose deaths on the predicted potency increase (using the IV) would be valuable. If the coefficient is positive and significant, it would directly demonstrate the public‑health relevance of the potency channel.  
- **Supply‑Chain Mapping**: A brief network diagram showing how distributor‑manufacturer ties vary across counties (e.g., a map of dominant distributors) would make the “share” construction more intuitive and highlight the geographical heterogeneity that fuels the instrument.  

*Minor Corrections*  
- **Table 4 (Event Study) Labels**: Use “Pre‑2007” instead of “2006” to avoid confusion with the baseline year.  
- **Standard Errors**: Throughout the paper, SEs are clustered at the state level (55 clusters). Consider performing wild‑cluster bootstrap inference to guard against few‑cluster bias, especially for the long‑difference specification.  
- **Typographical**: In the abstract, “the 20–30 mg dose range” should read “the 20–80 mg dose range” (or clarify that the effect is driven by the 20 mg formulation).  

*Overall Assessment*  
The manuscript presents a compelling and novel supply‑side mechanism for the opioid crisis, backed by a rich transaction dataset and a plausible shift‑share design. With the additional robustness checks and a modest extension to health outcomes suggested above, the paper would meet the high standards of the AER‑Insights format and make a genuine contribution to both the opioid‑policy and industrial‑organization literatures. I recommend **major revision** to address the points listed.
