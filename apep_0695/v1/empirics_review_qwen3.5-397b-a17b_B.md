# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-15T16:06:21.298661

---

\section*{1. Idea Fidelity}

The paper deviates significantly from the Original Idea Manifest. The manifest proposed a **Continuous-Treatment Difference-in-Differences** design exploiting province-level variation in Haitian-descent population shares using ENI microdata (2012/2017) and ENCFT labor force data. The submitted paper instead employs an **Interrupted Time Series (ITS)** design on **national-level aggregate data** from ILO and World Bank APIs. While the topic (TC/0168) and background context remain consistent, the core identification strategy has shifted from a geographic quasi-experiment to a macroeconomic time-series analysis. The manifest explicitly rated the province-level variation as "confirmed" and "READY," yet the paper relegates province-level data to descriptive tables (Table 5) without using them in the regression analysis. This pivot changes the paper from a causal estimation of labor market segregation to a documentation of aggregate statistical power limitations.

\section*{2. Summary}

This paper investigates the labor market effects of the Dominican Republic's 2013 TC/0168 ruling, which retroactively stripped citizenship from approximately 210,000 Haitian-descent individuals. Using national-level interrupted time series data from 2005--2023, the author finds no detectable break in vulnerable employment, unemployment, or school enrollment following the ruling. The central contribution is the argument of "statistical invisibility": the affected population constitutes only 2\% of the workforce, rendering the human cost of denationalization invisible in aggregate macroeconomic indicators despite potentially severe individual consequences.

\section*{3. Essential Points}

\begin{enumerate}
    \item \textbf{Identification Strategy and Causal Claims:} The shift from the proposed province-level DiD to a national ITS substantially weakens the causal identification. A national time series cannot easily disentangle the TC/0168 shock from concurrent economic events, such as the opening of the Pueblo Viejo gold mine (2013), tourism expansion, or post-2008 recovery trends. The paper claims these are "aggregate nulls," but without a control group (low-exposure provinces), it is difficult to rule out that national growth simply masked the shock. The authors must either justify why ITS is sufficient for a causal claim in this context or incorporate the proposed geographic variation to strengthen identification.
    \item \textbf{Underutilization of Available Microdata:} The manuscript acknowledges the existence of ENI 2012/2017 microdata (which was central to the original manifest) but states it is not used for estimation ("The present paper establishes the aggregate null as a baseline"). Given that the feasibility check confirmed access to these surveys, omitting them limits the paper's contribution. Even if the main result is the aggregate null, providing bounds using the microdata (e.g., comparing high-exposure vs. low-exposure provinces in the ENI) would validate the "invisibility" mechanism rather than just asserting it.
    \item \textbf{Power Analysis and Effect Bounds:} The power calculation in the Appendix is helpful but relies on assumptions about the pre-existing formal employment rate of the affected population (assumed 20\%). This parameter is critical yet unverified. If the affected population was predominantly informal \textit{before} the ruling, the expected aggregate shock would be even smaller. The authors need to provide empirical evidence or citations supporting the baseline formality rate of Haitian-descent Dominicans to make the power argument convincing.
\end{enumerate}

\section*{4. Suggestions}

The paper presents a compelling narrative about the limitations of aggregate data in capturing marginalized populations, but to meet the standards of \textit{AER: Insights}, it needs to tighten the empirical link between the policy and the null result. Below are concrete recommendations to strengthen the analysis, largely focusing on recovering the geographic variation proposed in the original idea and refining the interpretation of the null.

\subsection*{Recovering Geographic Variation}
The strongest asset of this research design is the heterogeneity in exposure across the Dominican Republic's 32 provinces. The manifest correctly identified that border provinces (e.g., Dajabón, Monte Cristi) have Haitian-born shares of 5--9\%, while central provinces have shares near 1\%. The current paper treats this variation as descriptive (Table 5) rather than analytic. I strongly encourage the authors to estimate the proposed Continuous-Treatment DiD specification:
\begin{equation}
Y_{pt} = \alpha + \beta \cdot (HaitianShare_p \times Post_t) + \gamma_p + \delta_t + \epsilon_{pt}
\end{equation}
Even if the outcome $Y_{pt}$ must be drawn from aggregate provincial labor force surveys (if available via ONE) or constructed from Census waves (2002 vs. 2010 vs. 2022), this would provide a much stronger test than the national ITS. If province-level labor data is unavailable, the authors could use the ENI microdata to estimate a triple-difference model: $\text{Outcome}_{ipt} = \beta (\text{HaitianDescent}_i \times \text{HighExp}_p \times \text{Post}_t)$. This would directly test whether individuals in high-exposure provinces suffered worse outcomes than those in low-exposure provinces, isolating the policy effect from national trends.

\subsection*{Strengthening the Interrupted Time Series}
If the authors wish to retain the national ITS as the primary specification, they must address the confounding trends more rigorously. The year 2013 was economically significant for the Dominican Republic beyond TC/0168.
\begin{itemize}
    \item \textbf{Control Group Construction:} Consider constructing a synthetic control group using a weighted average of comparable Caribbean economies (e.g., Jamaica, Costa Rica, Panama) that did not experience denationalization. This would allow the authors to show that the Dominican Republic's labor market trajectory did not diverge from its peers post-2013, strengthening the "null" claim.
    \item \textbf{Event Study Visualization:} Replace the single \textit{Post} coefficient with an event study plot showing coefficients for each year relative to 2013. This would visually demonstrate whether there was any anticipatory effect (pre-trend violation) or delayed effect, which is crucial for validating the parallel trends assumption in an ITS context.
    \item \textbf{Sector-Specific Analysis:} The shock was likely concentrated in agriculture and construction. Aggregating across all sectors dilutes the signal. If the World Bank or ILO data allows, run the ITS specifically on agricultural employment or construction employment shares. A null result in the specific sectors where Haitian-descent workers are concentrated would be far more informative than a null in the aggregate economy.
\end{itemize}

\subsection*{Refining the Power Argument}
The "statistical invisibility" argument is the paper's novel contribution, but it currently rests on a back-of-the-envelope calculation. To make this robust:
\begin{itemize}
    \item \textbf{Baseline Formality Rates:} The Appendix assumes 20\% of the affected population was formally employed. This seems high given the literature on Haitian-descent labor market integration. If the baseline formal employment rate was closer to 5\%, the aggregate shock would be negligible regardless of sample size. The authors should cite specific studies (e.g., \citet{amuedo2017dominican} or ENI reports) that document the baseline formality of this group to justify the counterfactual effect size.
    \item \textbf{Minimum Detectable Effect (MDE) Curve:} Instead of a single MDE calculation, present a figure showing the MDE across different sample sizes or effect magnitudes. This helps readers understand the precision of the null result across a range of plausible scenarios.
    \item \textbf{Welfare Implications:} The paper focuses on labor market \textit{shares} (e.g., vulnerable employment rate). However, the welfare cost might appear in \textit{wages} rather than employment status. If denationalized workers stayed employed but saw wage compression, aggregate employment shares would not move. If wage data is available (even at a national average), testing for wage stagnation in low-skill sectors would complement the employment analysis.
\end{itemize}

\subsection*{Positioning and Framing}
Finally, the paper should clarify its contribution relative to the existing literature. The Introduction cites \citet{amuedo2017dominican} as using a "simple pre/post comparison." If the current paper's ITS is also essentially a pre/post with a trend, the methodological advancement is modest. The authors should frame the contribution more sharply around the \textit{aggregation bias} literature. Explicitly connect the findings to recent work on how aggregate statistics mask inequality (e.g., \citet{alsan2024fear} or similar development economics literature). The title could also be adjusted to reflect the aggregate focus (e.g., "\dots and the \textit{Aggregate} Labor Market") to manage reader expectations about causal identification on the treated individuals.

\subsection*{Minor Corrections}
\begin{itemize}
    \item \textbf{Table Formatting:} Table 2 uses \texttt{talltblr} which may not render correctly in all journal templates. Ensure compatibility with \textit{AER} style files (standard \texttt{tabular} or \texttt{threeparttable} is safer).
    \item \textbf{Standard Errors:} The paper uses Newey-West standard errors for annual data with $T=19$. With such a small time dimension, HAC estimators can be unstable. Consider reporting results with clustered bootstrap standard errors or simply robust standard errors as a sensitivity check.
    \item \textbf{Data Availability:} The paper states ENI microdata is held by ONE and "would enable" future work. If possible, the authors should clarify if they attempted to access it and were denied, or if they chose not to apply. Transparency about data access barriers is valuable for replication.
\end{itemize}

By incorporating province-level variation or strengthening the time-series robustness checks, this paper can move from a descriptive note on data limitations to a rigorous demonstration of how citizenship policies interact with labor market measurement. The core insight—that macroeconomic stability can coexist with microeconomic devastation—is powerful and deserves the strongest possible empirical foundation.
