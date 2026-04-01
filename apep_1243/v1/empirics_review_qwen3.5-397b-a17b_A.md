# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-04-01T13:12:57.525073

---

\section*{Referee Report}

\subsection*{1. Idea Fidelity}
The paper deviates significantly from the Original Idea Manifest in three critical dimensions. First, the sample size is drastically reduced: the manifest proposed 500+ mergers (2000--2020), while the paper analyzes only 47 mergers (2015--2020). Second, the data range is truncated from 1981--2024 to 2010--2024, eliminating valuable pre-treatment history and earlier cohorts. Third, the identification strategy diverges: the manifest specified using failed merger votes as controls and a triple-diff design (Foreign vs. Swiss), whereas the paper uses never-merged municipalities as controls and relies on separate outcome regressions. While the core research question (mergers and sorting) remains intact, the empirical execution represents a subset of the proposed design rather than the full project.

\subsection*{2. Summary}
This paper examines whether voluntary municipal consolidations in Switzerland altered the residential sorting of foreign residents between 2010 and 2024. Using a staggered difference-in-differences design with 47 treated municipalities, the author finds no statistically or economically significant effects on foreign population shares or growth. The results suggest that while mergers may impact political participation, they do not drive demographic reallocation in the medium run.

\subsection*{3. Essential Points}
\begin{enumerate}
    \item \textbf{Sample Selection and Power:} The restriction to mergers occurring after 2015 reduces the treated units from the proposed 500+ to just 47. This raises concerns about statistical power and external validity. A null result with only 47 treated units is difficult to interpret confidently without explicit power calculations. The author must justify why earlier mergers (2000--2014) were excluded beyond the "five clean pre-treatment years" constraint, as earlier cohorts could be incorporated with flexible pre-trends.
    \item \textbf{Control Group Validity:} The manifest proposed using failed merger votes as controls, which provides a much cleaner counterfactual (communes that wanted to merge but didn't) than never-merged communes. Never-merged communes may differ systematically in unobservables (e.g., political cohesion, fiscal health) that also drive sorting. The author should either incorporate failed votes as a placebo test or defend the exogeneity of the never-merged group more rigorously.
    \item \textbf{Mechanism Evidence:} The manifest highlighted tax competition and identity loss as mechanisms. The paper mentions these but provides no empirical evidence linking the null result to them. Did tax differentials actually converge? If tax harmonization was minimal, the null result is expected. Without showing variation in the \emph{intensity} of the treatment (e.g., tax rate changes), the economic interpretation remains speculative.
\end{enumerate}

\subsection*{4. Suggestions}
The following recommendations are intended to strengthen the paper's contribution and align it more closely with the robust design outlined in the research proposal. While the current draft is well-written and the null result is intriguing, addressing these points will significantly enhance the credibility of the empirical claims.

\subsubsection*{Expand the Sample and Pre-Period}
The most pressing issue is the limited number of treated units (N=47). The manifest identified 500+ mergers between 2000 and 2020. Excluding mergers prior to 2015 sacrifices substantial variation.
\begin{itemize}
    \item \textbf{Incorporate Earlier Cohorts:} Consider including mergers from 2000--2014. While this reduces the number of pre-period years for those cohorts, modern event-study estimators (like Sun-Abraham, which you already use) can handle varying pre-period lengths. You could require a minimum of 3 pre-years instead of 5, or use imputation methods to handle missing pre-data.
    \item \textbf{Power Analysis:} Given the small treated sample, include a minimum detectable effect (MDE) calculation. Show readers what magnitude of effect you \emph{could} have detected with 47 treated units. If the MDE is larger than the effects found in similar literature (e.g., Danish mergers), the null result is less informative.
    \item \textbf{Data Extension:} The manifest confirmed access to BFS data back to 1981. Utilizing this longer series would allow for longer pre-trend testing (e.g., t-10 to t+10), strengthening the parallel trends assumption.
\end{itemize}

\subsubsection*{Refine the Identification Strategy}
The choice of control group is central to causal inference in voluntary reform settings.
\begin{itemize}
    \item \textbf{Failed Merger Votes:} The manifest explicitly proposed using failed merger votes as controls. This is a superior design to using never-merged communes because failed votes capture the \emph{intent} to merge without the \emph{execution}. If data on failed votes is available (often recorded in cantonal archives or BFS political data), please incorporate this as a placebo test. If mergers cause sorting, failed mergers should not. If both show effects, selection bias is likely driving the result.
    \item \textbf{Matching:} If failed votes are unavailable, consider propensity score matching to select never-merged controls that resemble treated communes on pre-merger characteristics (population size, tax rate, foreign share). Table 1 shows treated communes have higher log foreign population (6.02 vs 5.17); ensuring controls are balanced on levels, not just trends, is crucial.
    \item \textbf{Triple-Diff Specification:} The manifest suggested a triple-diff (Merged $\times$ Post $\times$ Foreign). While Table 3 compares Swiss and Foreign growth separately, a formal triple-diff interaction would directly test whether foreigners responded \emph{differentially} relative to Swiss residents. This isolates the sorting mechanism from general population shocks.
\end{itemize}

\subsubsection*{Empirical Mechanisms}
To move beyond a "disciplined null," the paper should test why mergers didn't move people.
\begin{itemize}
    \item \textbf{Tax Harmonization:} Mergers are often motivated by tax equalization. Merge the ESTV tax multiplier data mentioned in the manifest. Interact the merger indicator with the pre-merger tax differential between merging partners. If sorting only happens where tax rates change significantly, this heterogeneity would be highly informative.
    \item \textbf{Identity Proxies:} If identity loss is a mechanism, it should be stronger in smaller communes or those with distinct linguistic identities. Interact the treatment with pre-merger population size or language region.
    \item \textbf{Housing Supply:} Residential sorting is constrained by housing supply. If mergers occur in supply-constrained areas, sorting may be muted regardless of demand. Controlling for local construction permits (mentioned in the manifest as available) would help rule out supply-side constraints.
\end{itemize}

\subsubsection*{Clarify Data Harmonization}
The paper relies on harmonizing historical communes to current boundaries using the SMMT package.
\begin{itemize}
    \item \textbf{Boundary Changes:} Please clarify in the Data section how population counts are aggregated when multiple communes merge. Do you sum the populations of predecessors to create the counterfactual path for the successor? This aggregation method can induce mechanical correlations if not handled carefully.
    \item \textbf{Missing Data:} With a 2010 start date, you lose the 2000--2009 mergers entirely. If you expand the sample as suggested, document how missing values for specific variables (e.g., citizenship breakdowns in early years) are handled.
\end{itemize}

\subsubsection*{Narrative and Contribution}
The "Voice vs. Exit" framing is compelling but needs stronger grounding.
\begin{itemize}
    \item \textbf{Link to Political Literature:} You cite Frey et al. (2023) regarding turnout. Explicitly quantify the turnout effect relative to your null sorting effect. If turnout drops by 5\% but sorting moves by 0.2\%, the contrast is stark. If turnout also moves little, the "Voice" claim is weaker.
    \item \textbf{Policy Implications:} Expand the conclusion to discuss whether this null result supports consolidation policies. If mergers save money (Zell et al. 2025) without disrupting demographic stability, this is a strong argument for reformers. Make this trade-off explicit.
\end{itemize}

\subsubsection*{Minor Technical Points}
\begin{itemize}
    \item \textbf{Standard Errors:} You cluster at the municipality level. Given the staggered adoption and potential serial correlation, consider whether block-bootstrapping or multi-way clustering (by canton) is necessary, especially if cantons encourage mergers simultaneously.
    \item \textbf{Table Formatting:} Table 2 (Event Study) lists coefficients but lacks a visual plot. For an AER: Insights paper, a coefficient plot with confidence intervals is standard and more intuitive for assessing pre-trends.
    \item \textbf{Variable Definitions:} Define "Foreign Population" precisely. Does it include naturalized citizens or only non-citizens? Swiss data often distinguishes between \emph{Ausländer} (non-citizens) and \emph{Migrationshintergrund}. Clarify which BFS variable is used.
\end{itemize}

In summary, this paper has the potential to be a valuable contribution to the literature on fiscal federalism and migration. However, to meet the standards of a top field journal, it needs to leverage the full variation available in the data (as originally proposed) and tighten the identification strategy using failed merger votes or matching. The current draft reads like a pilot study; expanding it to the full scope outlined in the manifest will make the null result much more persuasive.
