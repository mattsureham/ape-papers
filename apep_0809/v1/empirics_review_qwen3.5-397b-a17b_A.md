# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-23T12:52:29.954825

---

# Referee Report

**Manuscript:** Trading Non-Tradable Votes: EU Posted Workers and Far-Right Support in French Departements
**Journal:** AER: Insights
**Date:** October 26, 2023

## 1. Idea Fidelity

The paper largely adheres to the Original Idea Manifest regarding the core research question, data sources, and empirical setting. The authors successfully utilize the DARES posted worker data, French presidential election results, and EU enlargement dates as specified. However, there is a notable deviation in the **identification strategy**. The Manifest proposed a "Bartik design" as the primary causal engine, asserting feasibility as "READY." The paper, however, reveals that the Bartik instrument loses significance once department and year fixed effects are included (Table 2, Column 2). Consequently, the authors pivot to a standard Difference-in-Differences (Exposure $\times$ Post) specification as their preferred model. Additionally, while the Manifest anticipated a clean causal break, the paper honestly reports significant pre-trends (1995 coefficient) that were not flagged in the initial feasibility check. This shift from a confident IV strategy to a DiD with acknowledged validity threats represents a material change from the proposed plan, though it reflects rigorous empirical honesty.

## 2. Summary

This paper investigates whether labor market competition from EU posted workers drove increased support for the Far-Right (Front National/Rassemblement National) in France between 1995 and 2022. Using EU enlargement shocks and pre-enlargement sectoral employment shares, the authors find that departments more exposed to construction and agriculture postings experienced significantly larger gains in far-right voting. While the manufacturing placebo and China trade controls support a non-tradable labor channel, significant pre-existing trends in high-exposure areas complicate the causal interpretation.

## 3. Essential Points

The authors must address the following three critical issues before this paper can be considered for publication. These issues strike at the validity of the causal claim.

1.  **Violation of Parallel Trends:** The event study (Table 3) shows a massive, statistically significant coefficient for 1995 (-22.6), indicating that high-exposure departments were already on a divergent trajectory regarding far-right support well before the 2004 enlargement. The authors argue that the *acceleration* of the trend post-2007 justifies the causal claim. This is econometrically insufficient. A violated parallel trends assumption invalidates the standard DiD estimator. The authors must either demonstrate that the *growth rate* of FN support was parallel (rather than levels) or employ a method robust to linear pre-trends (e.g., including department-specific time trends).
2.  **Instrument Weakness and Identification Source:** The Manifest promised a Bartik shift-share identification. The paper shows the Bartik instrument is collinear with year fixed effects and insignificant in the FE specification. This implies the identification relies almost entirely on cross-sectional variation in sectoral shares rather than the temporal shock of enlargement. This makes the estimate highly vulnerable to omitted variable bias (e.g., unobserved cultural or economic factors correlated with construction dependence). The authors need to clarify why the temporal shock does not identify the effect and whether the cross-sectional variation can truly be considered exogenous.
3.  **Measurement Error in Exposure:** The paper maps NUTS2 regional employment shares to Department-level exposure. NUTS2 regions (e.g., PACA) contain multiple departments (e.g., Alpes-Maritimes, Var). Assuming uniform sectoral composition across a region introduces classical measurement error, which attenuates coefficients, but may also introduce bias if the mapping correlates with political outcomes. Given the precision claimed in the results, the authors must validate the sectoral share variation at the department level (using INSEE data rather than Eurostat) to ensure the exposure measure is not noisy.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's contribution and robustness. While not strictly fatal if addressed partially, implementing them would significantly elevate the quality of the analysis for an *Insights* format.

** Econometric Remedies for Pre-Trends**
The acknowledgment of pre-trends is commendable, but the current handling is too defensive. I suggest three specific econometric enhancements:
*   **Department-Specific Time Trends:** Include linear department-specific time trends in the main specification. If the effect persists, it suggests the enlargement shock added to the trend rather than simply following it.
*   **Matching Estimator:** Construct a control group of low-exposure departments that match high-exposure departments on pre-2004 FN vote growth rates and economic characteristics (unemployment, income). A matched DiD would mitigate the concern that high-exposure areas are fundamentally different.
*   **De-meaned Outcome:** Instead of levels, use the change in FN vote share as the outcome variable over specific intervals (e.g., 2002–2007, 2007–2012). This focuses the identification strictly on the acceleration, though standard errors must be adjusted accordingly.

** Data Refinement and Validation**
The data section relies heavily on Eurostat NUTS2 data mapped to departments. This is a potential weak link.
*   **INSEE Microdata:** France's INSEE provides employment data at the *zone d'emploi* or department level (CLAP data). Using this would eliminate the measurement error inherent in downscaling NUTS2 regional averages. Even a validation table showing the correlation between NUTS2 shares and actual department shares would bolster confidence.
*   **Posted Worker Density:** Currently, exposure is based on *sectoral shares* interacted with national inflows. If DARES data allows, construct a department-level predicted stock of posted workers (using the shift-share) and instrument for it. This makes the "first stage" more transparent.
*   **Unemployment Controls:** The paper controls for unemployment at the NUTS2 level. Since the mechanism is labor competition, department-level unemployment rates are preferable. If unavailable, discuss how regional aggregation might bias the control variable.

** Mechanism and Heterogeneity Analysis**
The paper posits a "non-tradable labor competition" mechanism but does not directly test it.
*   **Wage Pressure:** If posted workers depress wages in construction, this should be visible in department-level wage data (e.g., DADS files). Even a null result on wages would be informative (suggesting the mechanism is cultural/salience rather than economic displacement).
*   **Urban vs. Rural:** Posted workers in agriculture are likely in rural areas; construction workers may be in peri-urban zones. Splitting the sample by urbanization level could reveal whether the political reaction is driven by rural isolation or peri-urban competition.
*   **Salience Test:** If the mechanism is visibility, the effect should be stronger in areas where construction sites are highly visible (e.g., residential zones vs. industrial zones). While data may be limited, discussing this heterogeneity would strengthen the "non-tradable" argument.

** Clarifying the Identification Narrative**
The paper currently sends mixed signals about its identification strategy.
*   **Reframe the Bartik:** If the Bartik instrument fails with FE, do not present it as a primary identification strategy. Instead, frame the paper as a cross-sectional analysis of differential exposure to a national shock. This lowers the causal claim slightly but increases credibility.
*   **China Shock Specification:** The China import shock control is crucial. Ensure the specification matches *Autor, Dorn, and Hanson (2013)* closely (using initial employment shares to predict import exposure). The current description is brief; a footnote detailing the exact construction of this variable is necessary for replicability.
*   **Standardized Effects:** The appendix reports a Standardized Effect Size (SDE) of 0.28. This is very large for political economy. Compare this explicitly to *Dustmann et al. (2019)* or *Halla et al. (2017)*. If the effect is an order of magnitude larger, discuss why (e.g., is posted worker competition more salient than permanent immigration?).

** Writing and Positioning**
*   **Title Nuance:** The title "Trading Non-Tradable Votes" is catchy but slightly opaque. Consider "Labor Market Competition in Non-Tradable Sectors and Far-Right Voting."
*   **Policy Context:** The conclusion mentions EU debates on the Posted Workers Directive. Expand this slightly. Did the 2018 revision of the Directive (equal pay principle) mitigate these effects? A brief comment on post-2018 trends (if data allows) would make the paper timely.
*   **Literature Connection:** The paper cites *Muñoz (2024)* regarding labor market effects. It should also engage more deeply with *Colantone and Stanig (2018)* on trade shocks and *Steinmayr (2021)* on refugee exposure. Positioning the "posted worker" channel as distinct from both "trade" and "permanent migration" is the paper's unique selling point; this distinction needs to be sharper in the introduction.

** Final Recommendation**
This is a promising paper with a novel data application and a politically relevant question. However, the identification strategy currently rests on shaky grounds due to pre-trends and instrument weakness. I encourage the authors to treat this as a **Major Revision**. If they can robustly address the pre-trend issue (perhaps by conceding a correlational finding with strong quasi-experimental support rather than a clean causal break) and refine the exposure measurement, this will be a valuable contribution to the *AER: Insights* portfolio. The transparency regarding the Bartik failure is a strength; building the narrative around that honesty rather than obscuring it will serve the paper well.
