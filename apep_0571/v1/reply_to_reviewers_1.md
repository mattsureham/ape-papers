# Reply to Reviewers — Round 1

## Response to GPT-5.4 (R1)

**1A. Treatment conflates voluntary voting with automatic registration**
We agree this is an important interpretive concern. We have added explicit discussion in Section 2.6 acknowledging that $Z_i$ reflects both behavioral abstention and denominator expansion from automatic registration, and that we cannot fully decompose the two channels. We have reframed the predicted-treatment exercise (Section 7.4) as a descriptive proxy check rather than an IV-style identification strategy. The caveat is now prominently placed.

**1B. Parallel trends is not convincingly assessed (1 pre-period)**
We agree the single pre-period limits the test's power. We have revised the text in Section 5 and the introduction to acknowledge this limitation directly rather than present the F-test as strong support. We have also added tipología-by-year fixed effects and covariate-by-post interactions as additional identification checks (new Section 7.5).

**1C. Six-year data gap**
We cannot resolve this with currently available data. The DMCS-CEAD gap reflects Chile's institutional transition. We have substantially expanded the Limitations section to discuss this as a first-order concern and added the new robustness specifications to show the results survive richer trend controls (tipología×year FE, covariate×post interactions).

**1D. Differential trends from observables**
We have added two new specifications: (1) tipología-by-year fixed effects, which allow each type of comuna to have its own time trend; (2) covariate-by-post interactions, controlling for baseline comuna size and 2008 turnout level interacted with the post indicator. Main results survive both specifications.

**1E. Mechanism is inferred, not shown**
We agree that direct policing data would strengthen the paper. We have softened language throughout, replacing definitive causal claims with "consistent with" and "suggests." The mechanism remains the most parsimonious interpretation of the detection-gap pattern, but we now acknowledge alternative channels more explicitly.

**2B. Randomization inference critique**
We retain the RI as a supplementary check on inference (not identification) but no longer present it as strong validation of the design. The text clarifies that RI addresses inference under non-normality rather than causal identification.

**2C-D. Functional form and rates**
We have added inverse hyperbolic sine (IHS) transformation robustness for all main outcomes. Results are qualitatively identical. Crime rates per 100K registered voters show directionally consistent but noisier estimates, as expected.

**3B. Predicted treatment is not a valid instrument**
We have reframed this exercise explicitly as a descriptive check. The text now states that the exclusion restriction is not credible and the exercise should not be interpreted as IV identification.

**3C. DV as placebo**
We agree DV is not a perfect placebo. The text now acknowledges that reporting is sensitive to institutional factors beyond police patrol intensity.

**5A. Over-claiming causality**
Language has been softened throughout. Abstract, introduction, and conclusion now use "consistent with," "suggests," and "appears to" rather than definitive causal language.

---

## Response to GPT-5.4 (R2)

The R2 concerns overlap substantially with R1. In addition:

**1.5. Treatment decomposition**
See response to R1, point 1A. New paragraph in Section 2.6.

**1.6. Data comparability**
We have expanded the Limitations section with explicit discussion of the DMCS-to-CEAD transition, classification revisions, and the assumption of stable category mappings. Year FEs absorb common shifts; tipología×year FEs address differential shifts by comuna type.

**1.7. Population scaling**
We now report crime rates per 100K registered voters as a robustness check. Results are directionally consistent. We note that padron_2012 is time-invariant (a limitation), but annual population data at the comuna level are not available for the full panel.

**3.2. Predicted treatment reframing**
Reframed as descriptive check; IV language removed.

**3.5. Homicide may reflect broader post-2018 trends**
The tipología×year FE specification absorbs differential trends by comuna type. The covariate×post specification further controls for baseline characteristics. Homicide remains significant in both specifications, though attenuated with covariate×post controls (from +0.0132 to +0.0093, p=0.009).

---

## Response to Gemini-3-Flash

**Homicide zeros and log transformation**
We have added IHS transformation robustness. Results are qualitatively identical for all outcomes.

**Reporting vs. effort**
We acknowledge this distinction in the revised Limitations section. With available data, we cannot separate police-effort reductions from changes in citizen reporting behavior for categories like burglary where both channels operate.

**Direct resource evidence**
SINIM municipal budget data do not cleanly isolate public safety spending. We note this data limitation in the revised Limitations section.

**Spatial spillovers**
An important suggestion for future work. We note the absence of spatial analysis in the Limitations section.
