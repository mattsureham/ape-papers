# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-04-02T18:45:55.572768

---

\section*{Referee Report}

\textbf{Manuscript:} The Digital Border Dividend: Estonia's e-Residency Program and Cross-Border Firm Formation \\
\textbf{Journal:} AER: Insights (Simulated) \\
\textbf{Date:} October 2023

\section{1. Idea Fidelity}

The paper largely adheres to the original research design outlined in the Idea Manifest, successfully executing the core identification strategy of comparing Estonia against Baltic neighbors and a broader European donor pool using Difference-in-Differences (DiD) and Augmented Synthetic Control Methods (ASCM). The primary outcome variable (World Bank business registration density) and the treatment timing (December 2014) match the proposal.

However, there is a notable deviation regarding data granularity. The Manifest explicitly confirmed access to "Statistics Estonia PxWeb API (ER028): enterprise stock by county (2017-2025)" to facilitate decomposition and spillover analysis. The submitted paper relies exclusively on country-level World Bank data and aggregate Dashboard statistics, acknowledging in the Limitations section that "Country-level analysis limits the ability to identify within-Estonia geographic spillovers." This represents a step down from the proposed feasibility check, weakening the empirical support for the "ecosystem spillover" mechanism which was a key component of the original idea's novelty. Additionally, while the Manifest proposed decomposing "domestic spillovers vs. displacement," the paper's decomposition is largely descriptive (Total minus e-Resident) rather than causally identified.

\section{2. Summary}

This paper estimates the causal effect of Estonia's 2014 e-Residency program on business formation, exploiting the policy shock relative to Latvia, Lithuania, and a synthetic control group. The authors find a large, statistically significant increase in business registration density (66--81 percent), driven partly by direct e-Resident firms but also by a rise in domestic registrations suggestive of ecosystem spillovers. However, the program shows no detectable effect on GDP per capita, leading the authors to conclude that while digital governance reduces administrative border costs for firm creation, the resulting activity is largely administrative ("hollow") rather than productive.

\section{3. Essential Points}

The following three issues must be addressed before the paper can be considered for publication. They concern the validity of the statistical inference, the causal attribution of the decomposition, and the fidelity of the data usage.

\begin{enumerate}
    \item \textbf{Inference with Few Clusters:} The DiD specifications cluster standard errors at the country level with only 3 countries (Baltic panel) or 9 countries (Full panel). Conventional cluster-robust standard errors are known to be severely biased downward in settings with fewer than 10--20 clusters, leading to over-rejection of the null. The reported $p$-values (e.g., $p < 0.001$ in Table 2) are likely unreliable. Given the ASCM conformal inference yields a $p$-value of 0.21 (Section 4.1), there is a stark inconsistency between the SCM and DiD significance levels. The authors must employ wild cluster bootstrap procedures (e.g., Cameron, Gelbach, \& Miller, 2008) or randomization inference to validate the DiD significance claims.
    
    \item \textbf{Causal Attribution of Spillovers:} The claim that domestic registrations rose due to "ecosystem spillovers" is currently correlational. The decomposition (Table 3) simply subtracts e-Resident firms from the total. Showing that domestic registrations exceeded pre-treatment averages does not establish causality; this could reflect mean reversion, concurrent domestic reforms, or global trends affecting small open economies. Without the proposed county-level variation or a specific shock to the service providers (e.g., entry of Wise/TransferWise), the spillover mechanism remains an assertion rather than an identified effect.
    
    \item \textbf{Data Granularity Deviation:} As noted in the Fidelity section, the paper abandons the proposed county-level data from Statistics Estonia. This omission is critical because the "ecosystem spillover" argument relies on geographic or sectoral clustering within Estonia that country-level data cannot capture. The authors must either justify why the county-level data was unusable despite the Manifest's "Feasibility Grade: READY" or acknowledge that the spillover conclusion is speculative without sub-national identification.
\end{enumerate}

\section{4. Suggestions}

The following recommendations are intended to strengthen the paper's empirical robustness and policy relevance. While not strictly mandatory for revision, addressing these would significantly elevate the contribution to the literature on digital governance and border effects.

\subsubsection*{Econometric Robustness and Inference}
Given the small number of clusters, the DiD results should be presented with much more caution. I recommend replacing the conventional clustered standard errors with wild cluster bootstrap $p$-values. If the significance disappears under bootstrap inference, the paper should pivot to emphasize the ASCM results, even if the confidence intervals are wider. The discrepancy between the DiD $p < 0.001$ and the ASCM $p = 0.21$ is troubling; it suggests the DiD may be picking up noise or idiosyncratic trends that the SCM weighting partially corrects. Please include a permutation test for the DiD estimator (assigning placebo treatment to control countries) to show the distribution of placebo effects relative to the true estimate. This would provide a more honest assessment of significance than the current $t$-statistics.

Additionally, the pre-trend discussion requires nuance. The paper notes that coefficients for 2006--2010 are "negative and occasionally significant," attributing this to convergence. However, in a DiD with only 3 treated/control units, any significant pre-trend undermines the parallel trends assumption. I suggest truncating the sample to start in 2010 if the early years show divergent trends, or explicitly modeling the convergence trend in the pre-period to show that the 2015 break is distinct from the prior convergence path.

\subsubsection*{Refining the Mechanism and Decomposition}
The "hollow core" finding (null GDP effect) is compelling but noisy. Country-level GDP is influenced by many factors unrelated to firm registration. Since the paper highlights that the state gained EUR 400 million in revenue, I suggest using \textbf{tax revenue data} as an intermediate outcome. The e-Residency Dashboard reports estimated state revenue. Correlating the timing of firm registrations with actual corporate tax receipts (available from Estonian public finance data) would provide a tighter test of "economic value" than aggregate GDP. If tax revenue rose but GDP did not, it strengthens the argument that these are profit-shifting or administrative entities rather than productive firms.

Regarding the spillover claim: if county-level data is truly unavailable, consider using sectoral data. Did sectors complementary to e-Residency (e.g., IT services, legal, consulting) grow faster in Estonia than in Latvia/Lithuania? The World Bank or Eurostat Structural Business Statistics (SBS) often provide sectoral breakdowns. Finding heterogeneous effects across sectors would lend credence to the "ecosystem" story without requiring geographic variation.

\subsubsection*{Clarifying "Domestic" vs. "Foreign" Ownership}
The decomposition in Table 3 labels non-e-Resident firms as "Domestic." This is potentially misleading. A firm registered in Estonia without e-Residency could still be owned by a foreign national who visited an embassy or used a traditional intermediary. The term "Domestic" should be reserved for firms owned by Estonian residents. If the data does not distinguish owner residency, the label should be "Non-e-Resident Registrations." Conflating "Non-e-Residency channel" with "Domestic entrepreneurs" risks overstating the spillover to local citizens. Please clarify the definition of "Domestic" in the data section and adjust the interpretation accordingly.

\subsubsection*{Policy Implications and Nuance}
The conclusion that the dividend is "illusory for output" is strong, but perhaps too dismissive of the fiscal benefits. For a small state, EUR 400 million in revenue is significant (approx. 1.5\% of annual state budget). I suggest reframing the conclusion to distinguish between \textit{productive} growth (GDP/jobs) and \textit{fiscal} growth (tax/fees). The policy lesson might not be that the program is "hollow," but that it serves a different function: revenue generation and soft power rather than industrial agglomeration. This nuance aligns better with the OECD literature on digital nomad visas, which often target revenue and talent attraction rather than immediate GDP spikes.

\subsubsection*{Presentation and Data Transparency}
\begin{itemize}
    \item \textbf{Table 1 (Summary Stats):} Include the number of observations explicitly. For the Baltic panel, $N=51$ is clear, but for the SCM, clarify the pre-treatment fit metrics (RMSPE) in the table or text.
    \item \textbf{Figure Availability:} The LaTeX source references event-study coefficients in the text but does not include the corresponding plot. A coefficient plot with confidence intervals for the event study is essential for visualizing the parallel trends assumption.
    \item \textbf{Data Appendix:} Please provide the exact code or query used to extract the World Bank data. The Manifest mentioned a "Smoke Test Log" confirming API access; including the replication script for the data extraction would enhance transparency, especially given the reliance on external APIs that may change over time.
    \item \textbf{LaTeX Formatting:} Ensure that the \texttt{timing\_data.tex} file is properly managed for submission. Currently, it references "APEP Autonomous Research." If this is for a standard journal submission, ensure author anonymity conventions are met if required, or clarify the autonomous nature in the cover letter.
\end{itemize}

\subsubsection*{Final Thought on Contribution}
The paper addresses a timely question with a unique natural experiment. The core finding—that digital borders can be eliminated for administration but not for production—is valuable. However, the strength of this claim rests entirely on the validity of the counterfactual. By tightening the inference methods and clarifying the mechanism (fiscal vs. productive), this paper could become a definitive reference for the economics of digital governance. I encourage the authors to prioritize the robustness checks on inference above all else.

\vspace{1em}
\noindent\textbf{Recommendation:} Revise and Resubmit (conditional on addressing Essential Points 1 and 2).
