# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-03-23T12:09:34.184044

---

 \documentclass[12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[margin=1in]{geometry}
\usepackage{setspace}
\onehalfspacing
\usepackage{parskip}
\setlength{\parskip}{0.5em}
\setlength{\parindent}{0pt}
\usepackage{titlesec}
\titleformat{\section}{\large\bfseries}{\thesection}{1em}{}
\titleformat{\subsection}{\normalsize\bfseries}{\thesubsection}{1em}{}

\begin{document}

\section*{Referee Report: ``Darkness by Decree: The Economic Cost of Internet Shutdowns in India''}

\subsection*{1. Idea Fidelity}

The paper pursues the core research question from the manifest—estimating the economic cost of India's internet shutdowns using nightlights and exam-triggered variation—but deviates critically from the proposed research design. Most importantly, the paper uses \emph{annual} VIIRS composites (district-year panel, $N=6{,}084$) rather than the promised \emph{monthly} data (district-month panel, $N \approx 105{,}000$). This aggregation fundamentally alters the feasibility of the identification strategy: the manifest emphasized leveraging high-frequency variation to detect transient economic disruptions, but annual averages smooth over the 1--2 day exam-triggered shutdowns that form the claimed ``plausibly exogenous'' subsample. 

The paper also omits several promised elements: the event-study design for long shutdowns (only static heterogeneity by duration is shown), neighboring-district placebo tests, mechanism tests (service type, sector composition, digital penetration interactions, market integration), and the analysis of mobile-only vs.\ full blackouts. While the paper retains the core TWFE structure and the exam-triggered concept, the shift to annual data represents a significant departure that undermines the paper's ability to detect the causal effects described in the manifest.

\subsection*{2. Summary}

This paper attempts to estimate the causal effect of India's district-level internet shutdowns on local economic activity using annual satellite nighttime lights (2014--2022). While basic two-way fixed effects suggest a 4.1\% reduction in luminosity associated with shutdowns, the inclusion of state-by-year fixed effects attenuates estimates to near-zero, suggesting state-level confounding. The authors find a monotonic dose-response relationship---districts with 50+ shutdown days show 3.4\% lower luminosity---and present placebo tests supporting the identifying assumptions, though the study appears underpowered to detect effects of brief shutdowns at annual frequency.

\subsection*{3. Essential Points}

\textbf{(1) Aggregation Bias from Annual Data Destroys Identification Power.} The manifest proposed monthly nightlights to capture transient disruptions from short shutdowns. By switching to annual composites, the paper averages over the very variation (days vs.\ weeks) needed to identify causal effects. The null result for exam-triggered shutdowns---central to the identification strategy---is mechanically unsurprising because 1--2 day blackouts cannot plausibly affect annual average radiance, particularly given measurement error in nightlights. The dose-response evidence (Table 4) relies on fewer than 40 district-years with 50+ day shutdowns, likely insufficient for precise inference. If monthly VIIRS data are unavailable, the paper should abandon the exam-triggered strategy and focus exclusively on prolonged shutdowns (e.g., J\&K's 552-day blackout) using synthetic control methods where annual data might suffice.

\textbf{(2) Implausible Coefficient Reporting and Empirical Anomalies.} Table 2, Column (3) reports that ``Exam Intensity'' increases nighttime lights by 3.174 log points (SE = 1.578)---implying a 3,174\% increase in economic activity from exam shutdowns. This is either a coding error, a mislabeled variable, or a missing negative sign. The positive point estimate for exam shutdowns in Column (2), while insignificant, contradicts the theoretical framework and warrants investigation. Similarly, the ``Exam Intensity'' coefficient in Column (4) equals exactly 3.174 with the same standard error as Column (3), suggesting a copy-paste error or collinearity issue. These anomalies must be resolved; until then
