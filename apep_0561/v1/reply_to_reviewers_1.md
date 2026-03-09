# Reply to Reviewers — apep_0561 v1 (Round 1)

## Reviewer 1 (GPT-5.4 R1): Reject and Resubmit

**R1.1 (Identification):** "The current DiD design is not sufficiently credible for the stated causal claim."

**Response:** We agree that the design has fundamental limitations, particularly the single post-treatment election and significant placebo. We have substantially recalibrated all claims. The abstract now leads with "I find no robust evidence" rather than claiming a negative causal effect. The paper frames the result as suggestive throughout.

**R1.2 (EPCI clustering):** "Rebuild inference at the actual treatment-assignment level."

**Response:** We attempted EPCI-level clustering but the commune-to-EPCI crosswalk for the 2017 period proved unavailable (0% merge rate with available crosswalk data). We report department-level clustering (84 departments) as a conservative alternative — departments are coarser than EPCIs and thus provide even more conservative inference. The result is insignificant (p=0.396), which we report prominently in Table 6.

**R1.3 (Threshold-based design):** "Redesign the identification strategy around the threshold-based assignment rule."

**Response:** An RD design around the EPCI density threshold would require EPCI-level running variable data and commune-to-EPCI linkage that we were unable to obtain for the relevant period. We note this as a promising direction for future work.

**R1.4 (Treatment timing):** "Resolve treatment timing and estimand ambiguity."

**Response:** We have harmonized treatment timing language throughout. All tables and text now use a consistent framework: "2015 legislative reform, administrative reclassification effective 2017-2018, full economic effect after 2020." Table 2 notes explain why Post=2022 (transition provisions extended benefits through 2020).

**R1.5 (Placebo/pre-trends):** "Directly confront the failed placebo and pre-trend evidence."

**Response:** We now report the significant placebo (p=0.013) prominently and add a new "Dropping the 2002 Election" subsection showing the result weakens to p=0.065 without 2002. This is presented as further evidence of fragility.

**R1.6 (Denominator/composition):** "Reframe the main result around vote-share decomposition."

**Response:** Table 3 (denominator outcomes) is now prominently placed and discussed. The paper explicitly notes that "differential electorate growth—rather than preference change—may partly drive the vote-share result."

---

## Reviewer 2 (GPT-5.4 R2): Reject and Resubmit

**R2.1–R2.5:** Concerns substantially overlap with R1. See responses above.

**R2.6 (First-stage evidence):** "Add first-stage economic evidence."

**Response:** We acknowledge this as a limitation. SIRENE/DADS data for firm creation and employment would strengthen the paper but were beyond the scope of currently available data. This is noted as future work in the conclusion.

**R2.7 (Symmetric test):** "Reduce emphasis on the symmetric gainer-vs-never exercise."

**Response:** The symmetric test has been moved to the appendix and is framed as a "cautionary illustration of comparison-group selection" rather than supporting evidence.

---

## Reviewer 3 (Gemini): Major Revision

**R3.1 (Clustering):** Same as R1.2. See response above.

**R3.2 (Denominator effect):** "Provide more evidence on who these new voters are."

**Response:** We report the differential growth in registered voters, valid votes, and voter counts. Census-level demographic data at the commune level for the relevant period is not readily available through our data pipeline. This decomposition is noted as an important direction for future work.

**R3.3 (Economic first stage):** Same as R2.6. See response above.

**R3.4 (2002 nuance):** "Test if the 2002 deviation is driven by specific regions."

**Response:** We add a "Dropping the 2002 Election" specification showing the result weakens (p=0.065 vs 0.005), confirming that 2002 is influential. Regional heterogeneity in the 2002 effect was not pursued given the already-fragile baseline.
