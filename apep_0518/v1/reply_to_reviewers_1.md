# Reply to Reviewers

## Reviewer 1 (GPT-5.2): REJECT AND RESUBMIT

### 1.1 Core DiD identification violated
**Response:** We agree. We have reframed the paper's narrative throughout to present the estimates as descriptive associations rather than causal effects. The abstract, introduction, identification section, and conclusion all now explicitly acknowledge the pre-trend violation and frame the DiD as an upper bound. We have removed the "quasi-random" language and instead explain the selection mechanism upfront.

### 1.2 "Quasi-random mapping" claim overstated
**Response:** Fixed. We now state that the income-based criterion means neighborhoods that improved were less likely to qualify as QPV, making the mapping non-random with respect to economic trajectories. This is presented as a central feature of the analysis rather than hidden.

### 1.3 Treatment assignment coarse
**Response:** We acknowledge this limitation clearly and note it in both the data section and conclusion. Given the unavailability of ZUS polygons, the commune-level approach is the best available option. The threshold sensitivity analysis shows stability across definitions.

### 1.4 Unit of analysis concerns
**Response:** Outcomes are aggregated to the ZUS level (summing across constituent communes) before estimation. Fixed effects are at the ZUS level. This is consistent.

### 1.5 Displacement not convincingly addressed
**Response:** We have added a note clarifying the unequal time periods in the displacement table and acknowledge this analysis is only suggestive.

## Reviewer 2 (Grok-4.1-Fast): MAJOR REVISION

### Pre-trends invalidate causal DiD
**Response:** Agreed. We have reframed throughout to present as descriptive. The Rambachan-Roth results are now presented prominently in both the empirical strategy and appendix sections.

### Coarse treatment geography
**Response:** Acknowledged as a limitation. We note that geocoded SIRENE data could sharpen this in future work.

### No mechanism tests
**Response:** We have qualified the mechanism discussion as speculative and noted future directions.

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### Re-center narrative as descriptive
**Response:** Done throughout. We now lead with the selection story and frame the contribution as documenting the correlation pattern rather than claiming causality.

### Addressing the IPW result
**Response:** Expanded the IPW discussion to explain why the effect vanishes: IPW accounts for the pre-trend differential, confirming that observable pre-treatment differences drive the raw DiD. This is now presented as confirmatory evidence of selection rather than a puzzle.

### Spatial spillovers
**Response:** Noted as an important direction for future work but beyond the scope of this paper given the commune-level data limitations.
