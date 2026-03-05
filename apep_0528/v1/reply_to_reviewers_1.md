# Reply to Reviewers — APEP-0528 v1

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1.1 Design framing (RDD vs DiD)
**Addressed.** We now explicitly describe the design as a "border-pair DiD with spatial controls" — a hybrid that combines spatial RDD distance controls with time-varying treatment and year FE. The identifying assumption is stated as parallel trends conditional on distance within border pairs.

### 1.2 Static mixed border definition
**Partially addressed.** The static definition (ever-treated vs never-treated) is maintained and clearly documented. Including reform-reform borders during interim years would require a staggered-adoption spatial design beyond the scope of the current paper; we note this as a direction for future work.

### 1.3 Treatment timing
**Noted.** The event study (Figure 2) with Sun & Abraham estimator provides dynamic estimates that capture lead/lag patterns. We note ElCom's forward-looking tariff publication timeline in the data section.

### 1.4 Border assignment
**Noted.** Centroid-based assignment is standard in Swiss spatial studies. We note this as a limitation.

### 2.1 Clustering and inference
**Addressed.** We now explicitly note that canton-level clustering with 8 treated units warrants caution and that the economic (rather than statistical) magnitude drives our conclusions. Border-pair heterogeneity significance is downgraded to descriptive.

### 2.2 Staggered adoption in main spec
**Partially addressed.** The event study uses Sun & Abraham (2021). The main cross-sectional specification restricts to ever-treated vs never-treated borders, which reduces TWFE bias concerns.

### 2.3 Placebo strength
**Addressed.** The placebo is now described as a "necessary-condition" check rather than decisive validation.

### 3.1 Cross-border DSOs
**Noted.** DSO FE robustness is discussed; quantifying cross-border DSO prevalence is a useful future extension.

### 3.4 Variance decomposition
**Addressed.** Language now reads "accounts for 2% of tariff dispersion" (descriptive) rather than "explains 2% of variance" (causal).

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

### Sample restriction
**Acknowledged.** We clarify the 22-mixed-border restriction and its rationale.

### DSO FE
**Noted.** Code runs DSO FE; results are discussed in text but not separately tabled due to collinearity absorption.

### Variance decomposition
**Addressed.** Labeled as descriptive throughout.

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### Balance table
**Noted.** Pre-reform balance on tariff components is reported in Section 6.4.

### DSO overlap
**Noted.** The vast majority of Swiss DSOs operate within a single canton; quantifying the exception rate would strengthen the paper.

### Revenue neutrality
**Noted.** Mechanism section acknowledges the limitation of aggregate charge data.
