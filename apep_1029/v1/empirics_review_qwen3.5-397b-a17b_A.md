# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-26T23:37:02.191888

---

\begin{center}
    \textbf{\large Referee Report} \\
    \vspace{0.5em}
    \textit{Manuscript: The Compliance Slack: Why UK Firms Don't Bunch at Regulatory Size Thresholds} \\
    \textit{Journal: AER: Insights}
\end{center}

\vspace{1em}

\section*{1. Idea Fidelity}

The paper pursues the core research question outlined in the manifest: estimating compliance costs at UK company size thresholds using bunching estimation. However, there are significant deviations in data implementation and identification strategy. The manifest promised a panel of $\sim$1.3 million company-year observations from Companies House XBRL data (2008--2025) to exploit the April 2025 threshold reform as a dynamic migration experiment. The submitted paper instead relies on a cross-sectional snapshot of three days of filings (8,927 observations) for micro-analysis and aggregate binned data (NOMIS) for time series. Consequently, the proposed dynamic experiment using the 2025 reform is not executed, and the power to detect bunching at the 50- and 250-employee thresholds is severely compromised compared to the feasibility check. The core institutional insight (the two-of-three rule) remains consistent, but the empirical execution diverges substantially from the proposed design.

\section*{2. Summary}

This paper investigates whether UK private firms distort their reported size to avoid regulatory costs associated with Companies Act size thresholds. Using Companies House microdata and NOMIS aggregate records, the author finds no evidence of bunching at the 10, 50, or 250-employee thresholds. The null result is attributed to the "two-of-three rule," which allows firms to exceed one criterion (e.g., employees) without reclassification if financial thresholds are not also breached.

\section*{3. Essential Points}

The following issues must be addressed for the paper to support its causal claims:

\begin{enumerate}
    \item \textbf{Data Utilization and Power:} The manifest confirmed feasibility of an 18-year panel ($\sim$1.3M observations), yet the micro-analysis uses only three days of filings. This drastically reduces power, rendering the 50-employee threshold estimate uninformative (SE $= 0.31$). Given the manifest's confirmation that the full data is accessible, the authors must justify why the full panel was not utilized. Relying on aggregate NOMIS data for the 50/250 thresholds is problematic because the size bands (e.g., 20--49, 50--99) mask within-bin bunching. You cannot detect bunching at 50 if the data bins all firms from 50 to 99 together.
    \item \textbf{Identification of the Mechanism:} The central contribution is the "two-of-three rule" explanation. However, the current evidence is indirect. To claim this mechanism drives the null, you must show that firms near the employee threshold are \textit{not} near the turnover/balance sheet thresholds. Without joint microdata on employees and turnover for the marginal firms, you cannot confirm they are utilizing the slack rather than simply ignoring the regulation.
    \item \textbf{Counterfactual Sensitivity:} The bunching estimates are highly sensitive to polynomial degree and bandwidth (e.g., Degree 9 yields $\hat{b}=27.4$). While robustness checks are provided, the instability suggests the underlying density may not be smooth enough for standard polynomial counterfactuals, or the sample is too sparse. A more robust non-parametric approach or justification for the specific polynomial choice is needed to rule out specification error driving the null.
\end{enumerate}

\section*{4. Suggestions}

The following recommendations are intended to strengthen the empirical strategy and clarify the contribution. While not strictly essential for publication, addressing them would significantly improve the paper's credibility and policy relevance.

\begin{itemize}
    \item \textbf{Utilize the Full Panel Data:} The most critical improvement would be to process the full 18-year Companies House panel as originally planned in the manifest. Three days of filings introduce significant noise (e.g., filing timing effects) and limit the ability to study the 50-employee threshold where compliance costs (audit, IR35) are highest. With the full panel, you could construct a true density histogram with sufficient bins around 50 and 250 to match the precision of the 10-employee analysis. If parsing 1.3M XBRL files is computationally burdensome, consider using the BasicCompanyData CSV mentioned in the manifest, which may contain standardized employee counts without requiring full XBRL parsing.

    \item \textbf{Joint Distribution Analysis:} To substantiate the "compliance slack" mechanism, plot the joint distribution of employees and turnover for firms near the thresholds. For example, create a scatter plot or heat map of firms with 45--55 employees against their turnover relative to the £10.2M threshold. If the two-of-three rule is driving the result, you should observe a cluster of firms with $>50$ employees but turnover $<£10.2M$. This visual evidence would be far more convincing than the current indirect inference from aggregate density rates. If the microdata lacks joint reporting, explicitly discuss this limitation as a primary caveat rather than a secondary note.

    \item \textbf{Refine the Aggregate Data Strategy:} The NOMIS data bins (20--49, 50--99) preclude standard bunching estimation at the 50-employee threshold. Instead of comparing density decline rates across broad bands, consider using the aggregate data solely for the time-series analysis of the IR35 reform. For the cross-sectional bunching, rely exclusively on the microdata. If the microdata is too sparse for the 50-employee threshold, acknowledge that the paper primarily identifies the absence of bunching at the \textit{micro/small} boundary, and treat the medium/large boundaries as suggestive only. Overclaiming precision on the 50-employee threshold using binned aggregate data risks misleading readers about the identification power.

    \item \textbf{Heterogeneity in IR35 Exposure:} The IR35 event study compares aggregate density ratios before and after 2021. This is a weak test
