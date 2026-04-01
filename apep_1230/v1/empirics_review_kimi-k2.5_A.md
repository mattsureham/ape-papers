# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-04-01T09:45:13.326600

---

\begin{center}
\textsc{Referee Report for ``Gatekeepers of the Good Death''}
\end{center}

\vspace{0.5em}
\noindent\textit{Manuscript Type:} AER: Insights\\
\textit{Recommendation:} Revise and Resubmit

\section{Idea Fidelity}

The paper successfully executes the core empirical strategy outlined in the manifest: a difference-in-differences analysis of the 2023 PPEO rollout using new hospice certifications from PECOS, with robustness checks for California's prior moratorium and decomposition by ownership type. The few-cluster inference procedures (randomization inference and wild bootstrap) are implemented as proposed.

However, the manuscript departs from the manifest in two notable ways. First, the manifest explicitly identified Wave 2 (Georgia and Ohio, December 2025) as providing ``out-of-sample validation,'' yet the paper only mentions this wave in passing without incorporating it into the empirical analysis. Given the manuscript's data extend through 2025, these states could serve as a placebo test or secondary treatment. Second, the manifest listed ``per-beneficiary spending'' as a primary outcome alongside new certifications, but the paper relegates spending to summary statistics (Table 1) without causal analysis. The shift to focusing exclusively on entry intensive margins is reasonable given data constraints, but the spending analysis should either be incorporated or explicitly justified as outside the manuscript's scope.

\section{Summary}

This paper provides the first causal evidence on how enhanced entry regulation shapes the hospice market. Exploiting the 2023 activation of CMS's Provisional Period of Enhanced Oversight (PPEO) in four states, the author finds that prepayment review and enhanced scrutiny reduced new for-profit hospice entry by approximately 80 percent (14 enrollments per state-quarter) while leaving nonprofit entry precisely unchanged. The identification strategy leverages sharp timing and ownership-type heterogeneity to argue that PPEO selectively screened out organizational forms vulnerable to regulatory enforcement rather than indiscriminately restricting supply.

\section{Essential Points}

The following issues must be addressed for the paper to be publishable:

\begin{enumerate}
\item \textbf{Control group validity and parallel trends.} The treated states are extreme outliers: 17.6 new enrollments per quarter versus 0.7 in control states (a 25-fold difference). While the event study shows no pre-trends in levels, the economic interpretation requires that these ``hotbed'' markets would have evolved similarly to markets with near-zero entry absent the intervention. This is a strong assumption. The authors must provide additional evidence supporting the comparability of these markets—such as parallel trends in other healthcare sectors (e.g., home health agencies, skilled nursing facilities) or synthetic control estimates that weight donor states to better match the treated units' pre-treatment levels and trends.

\item \textbf{Spillovers and geographic displacement.} The identification strategy assumes no spillovers onto the control group, yet the deterred for-profit providers (many operating national chains) likely relocated to untreated states. If PPEO merely redistributed fraudulent entry geographically rather than reducing it, the welfare conclusions change substantially. The authors must test for spillovers by examining whether entry increased in neighboring states, states with high baseline for-profit shares, or the Wave 2 states (GA/OH) prior to their official treatment date.

\item \textbf{Interpretation of the mechanism.} The paper interprets the for-profit/nonprofit decomposition as evidence that PPEO screened out ``fraudulent'' or ``low-quality'' entry, but the empirical results only demonstrate differential effects by ownership form. Without linking deterred entrants to observable quality predictors (e.g., chain affiliation, prior Medicare sanctions, or eventual claim denial rates among the marginal entrants), the conclusion that regulation improved welfare by deterring fraud is premature. The cross-sectional quality gaps (Table 1, Panel B) reflect historical accumulation, not PPEO's causal effect on provider quality. The authors should clarify the interpretation or provide direct evidence on the quality characteristics of deterred entrants.
\end{enumerate}

\section{Suggestions}

The following recommendations would strengthen the paper but are not essential for publication:

\begin{itemize}
\item \textit{Synthetic control robustness.} Given the extreme baseline heterogeneity, augment the two-way fixed effects estimates with a synthetic control approach using as donors the subset of states with non-zero but moderate entry rates (e.g., FL, IL, PA). This would provide a more credible counterfactual for what would have happened in AZ, CA, NV, and TX absent PPEO.

\item \textit{California decomposition.} California imposed a state-level moratorium in January 2022, 18 months before federal PPEO. Present separate event-study figures for California versus the other three treated states to demonstrate whether the enrollment decline exhibits a sharp break in early 2022 (suggesting the state moratorium mattered) or mid-2023 (supporting the federal identification). This would clarify how much of the aggregate effect is driven by California versus the true PPEO experiment in AZ, NV, and TX.

\item \textit{Incumbent responses.} Analyze whether incumbent providers in treated states expanded capacity (e.g., increased patient counts or visits) to fill the gap left by deterred entry. If PPEO improved market quality by blocking low-quality entrants but simultaneously induced incumbents to admit sicker patients or reduce visit intensity, the net welfare effect is ambiguous.

\item \textit{Chain heterogeneity.} Examine heterogeneity by chain affiliation. If the decline in for-profit entry concentrates among multi-state chains (which can more easily relocate) versus independent for-profits, this would support the geographic displacement interpretation and help characterize the deterred margin.

\item \textit{Alternative estimators for count data.} The outcome (new enrollments) is a count variable with many zeros in the control group. Show robustness to Poisson or negative binomial two-way fixed effects models rather than OLS, which may produce biased estimates with rare count outcomes.

\item \textit{Wave 2 placebo analysis.} Even with limited post-treatment data for Georgia and Ohio (treated December 2025), test whether these states exhibited anticipation effects in Q3-Q4 2025 or whether entry declined immediately upon announcement. This would serve as a falsification test for the main results and address the manifest's original intention to use Wave 2 for validation.

\item \textit{Cost-benefit framing.} The paper notes CMS denied 40 percent of reviewed claims and revoked 181 certifications. Quantify the administrative costs of PPEO review against the estimated reduction in Medicare spending from deterred entry (using the cross-sectional spending differences in Table 1) to provide policymakers with a preliminary cost-effectiveness benchmark.

\item \textit{Sensitivity to treatment timing.} Test robustness to excluding the transition quarter (Q3 2023) or coding the treatment beginning in Q4 2023, given that providers with applications in progress during July 2023 may have been grandfathered in, creating a noisy treatment quarter.
\end{itemize}

\noindent\textit{Overall Assessment:} This paper addresses an important and timely policy question with a clean research design and compelling descriptive evidence. Resolving the concerns regarding control group validity, spillovers, and mechanism interpretation will be essential to establishing a credible causal claim suitable for \textit{AER: Insights}.
