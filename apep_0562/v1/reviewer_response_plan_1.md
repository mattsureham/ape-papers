# Reviewer Response Plan — apep_0562/v1

## Summary of Decisions

Three referee reviews received: GPT R1 (REJECT AND RESUBMIT), GPT R2 (REJECT AND RESUBMIT), Gemini (MAJOR REVISION). The core concerns are structural — they require honest recalibration of claims rather than new analyses.

## Workstream 1: Claim Recalibration (ALL THREE REVIEWERS)

**Concern:** Paper overclaims "networked anxiety without contact" when (a) hosting is imputed from regional data, (b) the mechanism is not directly observed, and (c) SCI bundles geography with social ties.

**Changes:**
1. **Title:** Keep title but add subtitle framing as "suggestive evidence" — actually, title is catchy and the Gemini reviewer liked it. Keep but temper claims throughout text.
2. **Abstract:** Rewrite to frame as "suggestive evidence of network-transmitted backlash" rather than definitive causal claims. Remove "consistent with the contact hypothesis" — replace with "null own-department effects, though own-hosting is imputed from regional data."
3. **Introduction:** Scale back causal language. Replace "our shift-share design provides a cleaner causal channel" with more honest framing. Acknowledge the treatment measurement limitation prominently.
4. **Results section:** Frame triple-difference as "exploratory heterogeneity" not definitive evidence for contact vs network separation.
5. **Conclusion:** Temper policy extrapolation. Remove "outweigh contact benefits" language.

## Workstream 2: Treatment Measurement Transparency (ALL THREE REVIEWERS)

**Concern:** Department-level shifts are imputed from regional aggregates; own-hosting is not directly observed.

**Changes:**
1. Add prominent paragraph in Introduction acknowledging this limitation explicitly
2. Rewrite Section 4.3 to lead with what data IS available, move what's not available to footnote (prose review suggestion)
3. Add explicit caveat to triple-difference discussion: hosting status is treatment-defined, not observed
4. Add sentence noting that the effective number of independent shocks is closer to the number of regions (~13) than departments (96)

## Workstream 3: Inference Acknowledgment (GPT R1, GPT R2)

**Concern:** Department-clustered SEs are not valid AKM-style shift-share inference.

**Changes:**
1. Add paragraph in Inference section explicitly acknowledging that AKM (Adão et al. 2019) shock-level inference would be more appropriate but is not implemented
2. Note that the effective shock count is ~13 regions, not 96 departments
3. Reframe the t-statistic discussion: acknowledge that precision may be overstated
4. Add this as a limitation — "Our inference does not implement the shock-level corrections recommended by Adão et al. (2019), which would account for the regional-level structure of the shifts"

## Workstream 4: Geography Confound (GPT R1, GPT R2, Gemini)

**Concern:** SCI is correlated with geography; network effects may be spatial spillovers.

**Changes:**
1. Add explicit discussion in identification section acknowledging geography-SCI correlation
2. Note that we cannot fully separate social network transmission from geographic proximity spillovers with available data
3. The geographic decay result (Section 8.4) provides some evidence, but acknowledge it's not definitive
4. Add this to limitations section

## Workstream 5: Pre-trend Treatment (ALL THREE REVIEWERS)

**Concern:** Significant 2014 coefficient with only 2 pre-periods is serious.

**Changes:**
1. Add formal joint pre-trend test statistic (F-test of 2014 and 2017 coefficients jointly = 0)
2. Note that with only 2 pre-periods, the pre-trend evidence is inherently limited
3. Mention that the excluding-2014 specification is already reported and confirms robustness

## Workstream 6: Election-Type Heterogeneity (GPT R1, GPT R2)

**Concern:** Pooling European and presidential elections may confound treatment with election-type effects.

**Changes:**
1. Add sentence acknowledging this concern explicitly
2. Note as limitation — separate election-type estimates would be underpowered (1 pre + 1 post for European-only post-treatment)
3. Acknowledge that election FE absorb level differences but not differential treatment-election interactions

## Workstream 7: Exhibit Improvements (Exhibit Review)

**Changes:**
1. Promote treatment map to main text as Figure 1
2. Clean up Table 2 variable labels (NetDisp → Network Dispersal)
3. Simplify event study y-axis label
4. Consolidate Table 3 (inference) into Table 4 or as notes
5. Fix SDE table notes (trim long text blocks)

## Workstream 8: Prose Improvements (Prose Review)

**Changes:**
1. Kill the roadmap paragraph at end of Introduction (let section headers work)
2. Active transitions: "Table 2 presents..." → lead with findings
3. Tighten Section 8.5 (2014 discussion) — less defensive
4. Replace "candidate mechanisms could drive" with direct language
5. Cut remaining throat-clearing phrases

## Priority Order

1. Claim recalibration (Workstream 1) — highest impact
2. Treatment measurement transparency (Workstream 2)
3. Inference acknowledgment (Workstream 3)
4. Geography + pre-trend + election-type (Workstreams 4-6)
5. Exhibits (Workstream 7)
6. Prose (Workstream 8)

## What We Will NOT Change

- **Title:** Keeping it — it's memorable and the Gemini reviewer praised it
- **Core analysis:** Not adding new regressions (AKM SEs, distance controls) — these require new code/data that we don't have. Instead, we honestly acknowledge these as limitations.
- **Structure:** Keeping all sections — the paper is already 39 pages
- **Mechanism section:** Keeping but reframing as "suggestive channels" not identified mechanisms
