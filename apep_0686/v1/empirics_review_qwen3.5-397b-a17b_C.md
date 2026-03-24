# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-14T19:22:51.425536

---

\section*{Review of "The Presumption Paradox: Does Overriding Local Planning Discretion Increase Housing Supply in England?"}

\section{1. Idea Fidelity}
The paper adheres closely to the Original Idea Manifest. It successfully implements the proposed Regression Discontinuity Design (RDD) at the 75\% Housing Delivery Test (HDT) threshold using the specified data sources (DLUHC HDT measurement files and PS2 planning statistics). There are two minor deviations worth noting. First, the manifest proposed using six annual rounds (2018--2023), whereas the paper restricts analysis to four rounds (2020--2023). This is methodologically sound given the phasing of the 75\% threshold, but it reduces the sample size from the projected ~1,866 observations to 1,184. Second, the manifest listed "housing starts" as a key outcome, but the paper focuses exclusively on planning \emph{approval rates}. While approvals are a necessary precursor to starts, the manifest's promise of delivery outcomes is not fully met. Overall, the core identification strategy and data infrastructure match the proposal.

\section{2. Summary}
This paper provides the first causal estimate of England's "presumption in favour of sustainable development" policy using a sharp RDD at the 75\% HDT threshold. The authors find that Local Authorities subject to the presumption approve approximately 8--10 percentage points more major dwelling applications than those just above the threshold. While the parametric specification yields statistical significance ($p=0.03$), the preferred bias-corrected non-parametric estimate is marginally insignificant ($p=0.16$), though point estimates remain stable across robustness checks.

\section{3. Essential Points}
The paper is promising but requires addressing three critical econometric issues before publication.

\begin{enumerate}
    \item \textbf{Inference Priority:} The abstract and discussion emphasize the parametric result ($p=0.03$) over the non-parametric RDD estimate ($p=0.16$). In modern RDD practice, the local linear bias-corrected estimator is the gold standard; parametric global polynomials are prone to bias away from the cutoff. The paper must reframe the findings to reflect the uncertainty in the primary specification. Claiming a "real effect" based on a parametric specification when the non-parametric confidence interval includes zero is misleading.
    \item \textbf{Interpretation of Effect Sizes:} Table 4 (Standardized Effect Sizes) classifies the major dwelling result as "Large negative" based solely on the point estimate, despite the $p$-value of 0.16. Labeling statistically insignificant coefficients as "Large" is econometrically unsound and risks overstating the evidence. The classification should reflect statistical uncertainty or be removed.
    \item \textbf{Power and Clustering:} The effective sample size near the cutoff is small ($N \approx 273$), and the number of treated units is limited (~63 LAs per round). While standard errors are clustered at the LA level, conventional asymptotic inference may be unreliable with few clusters near the discontinuity. The paper needs to demonstrate that the inference is robust to the limited number of effective observations.
\end{enumerate}

\section{4. Suggestions}
The following recommendations are intended to strengthen the empirical rigor and clarity of the paper. These suggestions constitute the primary path to improving the manuscript for an \textit{AER: Insights} audience.

\subsubsection*{Inference and Randomization}
Given the discrete nature of the running variable near the cutoff and the relatively small number of treated units, I strongly recommend supplementing the conventional standard errors with \textbf{randomization inference (permutation tests)}. In RDD contexts with few treated units, asymptotic approximations can over-reject. You can implement this by permuting the treatment status across observations within the bandwidth many times (e.g., 1,000 iterations) to generate an empirical distribution of the test statistic under the null. If the permutation $p$-value aligns with the conventional $p=0.16$, it reinforces the need for caution. If it is lower, it strengthens the claim. This is increasingly standard in high-quality RDD applications (e.g., \cite{cattaneo2020}) and would address concerns about the precision of your main estimate.

\subsubsection*{Running Variable Distribution and Bandwidth}
The summary statistics reveal a highly skewed running variable (Mean HDT = 144\%, SD = 141\%). The optimal bandwidth is 18.5 percentage points around the 75\% cutoff. While this seems reasonable, the density of control units far above the cutoff is much higher than treated units below.
\begin{itemize}
    \item \textbf{Visual Inspection:} Ensure the RDD plot (which is not included in the LaTeX source but implied) clearly shows the local linear fits and the raw binned data. Given the skew, a log-transformation of the running variable might worth exploring to ensure the linearity assumption holds locally, though levels are usually preferred for interpretation.
    \item \textbf{Density Checks:} You report the McCrary test ($p=0.46$), which is good. However, visually inspect the histogram near 75\%. With only ~63 treated LAs, even a small amount of sorting could bias results. Consider reporting the local polynomial density estimate plot in the appendix.
\end{itemize}

\subsubsection*{Outcome Timing and Dynamics}
The paper aggregates planning outcomes over the four quarters \emph{following} HDT publication. Major residential applications often exceed the statutory 13-week determination period, especially when controversial.
\begin{itemize}
    \item \textbf{Lag Structure:} Consider extending the outcome window to 8 quarters (2 years) to capture the full effect of the presumption on complex applications. If the effect grows over time (as suggested by the year-by-year estimates), a longer window might increase precision and magnitude.
    \item \textbf{Dynamic RDD:} If data permits, plot the coefficient estimates for quarters 1, 2, 3, and 4 separately. This would show whether the effect is immediate or delayed, adding nuance to the mechanism discussion.
\end{itemize}

\subsubsection*{Heterogeneity and Mechanism}
The discussion notes that the presumption does not apply to protected areas (Green Belt, AONB). This is a crucial heterogeneity.
\begin{itemize}
    \item \textbf{Green Belt Interaction:} Many LAs below the 75\% threshold are constrained by Green Belt boundaries, where the presumption is weaker. Splitting the sample by Green Belt share would clarify whether the effect is driven by non-constrained LAs. If the effect is zero in Green Belt LAs, it confirms the mechanism but limits the policy's aggregate impact.
    \item \textbf{Appeals Data:} The mechanism is that developers win more appeals or councils approve more to avoid appeals. If data on planning appeals (also available from DLUHC) is accessible, using appeal success rates as a secondary outcome would strongly bolster the causal story.
\end{itemize}

\subsubsection*{Presentation and Hygiene}
