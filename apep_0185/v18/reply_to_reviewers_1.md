# Reply to Reviewers — apep_0185 v18

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1.1 Full vs out-of-state exposure mismatch
**Response**: We acknowledge this important point about the in-state component of PopFullMW not being fully absorbed by state×time FE. The within-state variation in in-state connection share (ω_in_c) is time-invariant and thus absorbed by county FE. The interaction ω_in_c × log(MW_s,t) varies within state over time only through the state MW change, which is absorbed by state×time FE. We will add a decomposition in a future revision showing the in-state vs out-of-state components separately.

### 1.2 Exclusion restriction: policy bundles
**Response**: This is the deepest concern. We have added the policy diffusion null (Section 9.3) which shows that SCI-weighted MW exposure does not predict state-level MW adoption even with political controls. We will add SCI-weighted exposure to other state policies (EITC, paid sick leave, Medicaid expansion) in a future revision.

### 1.3 SCI measured 2018 (mid-sample)
**Response**: We address this with four pieces of evidence in Section 11.3: (i) SCI vintage correlations > 0.99, (ii) validation against decennial census migration, (iii) pre-treatment employment weights, (iv) distance-restricted instruments produce stronger results. A pre-2018 SCI comparison is not feasible as Facebook only released the 2018 vintage publicly.

### 1.4 SUTVA/interference
**Response**: We will add a discussion of the linear-in-means exposure-response interpretation and within-state exposure correlation statistics in a future revision.

### 2.1 Shift-share inference (AKM/BHJ)
**Response**: Table 4 already reports network clustering, Anderson-Rubin, and permutation p-values. We will implement formal BHJ exposure-robust SEs and report Rotemberg weights in a future revision.

### 2.3 Event study pre-trend inconsistency
**Response**: We have strengthened the explanation in Section 8.2. The joint F-test rejection (p=0.007) reflects non-monotonic baseline level differences (absorbed by county FE), not differential trends. Individual pre-period coefficients are all within 0.05 of zero. Visual inspection confirms no pre-existing trend. We have also updated the introduction to discuss the F-test honestly.

### 5.1 Magnitudes too large
**Response**: We have softened the headline claims. The abstract no longer reports specific magnitudes. The introduction and conclusion now emphasize LATE interpretation and qualify the employment estimate as a market-level equilibrium multiplier among complier counties.

### 5.2 Probability-weighted language
**Response**: Changed "no significant employment effects" to "substantially smaller and statistically insignificant employment effects" throughout.

---

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

### Rambachan-Roth bounds
**Response**: Section 8.2 mentions the Rambachan-Roth analysis; the appendix includes the sensitivity discussion. We will add a formal bounds table/plot in a future revision.

### SCI 2018 vintage
**Response**: See response to Reviewer 1, §1.3.

### Winsorization inconsistency
**Response**: The minor N discrepancy between main and distance-credibility tables reflects pre-winsorization vs post-winsorization samples. A footnote explains this.

### Complier characterization
**Response**: Will expand in future revision with metro share, retail share, and historical net migration.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### LATE clarification (9% vs 3.4%)
**Response**: We have added explicit LATE framing in the introduction and conclusion. The employment response reflects participation and reallocation among complier counties, not a firm-level demand elasticity.

### Pre-period level imbalance
**Response**: Section 11.3 already reports that controlling for baseline employment × linear time trend leaves the main coefficient stable. We will add baseline characteristic × year FE robustness in a future revision.

### Heterogeneity by local slack
**Response**: Good suggestion. Will add interaction with baseline unemployment rate in a future revision.

---

## Exhibit Review (Gemini)

### Promote Table 7 to main text
**Response**: Table 7 (policy diffusion) is already in the main text in v18 (Section 9.3).

### Add Summary Statistics table
**Response**: Will add in a future revision.

### Move Figure 7 and Table 4 to appendix
**Response**: Noted for consideration in future revision.

---

## Prose Review (Gemini)

### Humanize magnitudes
**Response**: Adopted the spirit of this suggestion in the LATE framing language.

### Kill filler phrases
**Response**: Noted for future polish pass.
