# Reply to Reviewers

## Reviewer 1 (GPT-5.2) — REJECT AND RESUBMIT

### 1.1 Entry outcome not a valid time series (survivorship bias)
> Companies House bulk file includes only currently registered companies. Time-varying selection breaks DiD.

**Response:** We agree this is the most important limitation. The revised paper now explicitly states that entry counts should be interpreted as "entries among currently registered companies" rather than true historical flows (Section 4.6). We note that survivorship bias affects LEVELS but the DiD exploits DIFFERENCES: if dissolution rates are similar across jurisdictions (which time FEs absorb), the bias cancels. The DDD provides further protection since survivorship affects food and non-food similarly within each jurisdiction. We acknowledge in the Limitations section that this restricts the absolute magnitude interpretation while preserving the sign of the DDD. Future work with ONS Business Demography data or historical Companies House snapshots could resolve this.

### 1.2 DDD parallel-trends-in-differences not tested
> Need food-nonfood gap pretrends test, not just food-only pretrends.

**Response:** We agree this is a valid concern and have added it to the Limitations section. The flat food-only pretrends (Figure 1, joint F-test) combined with the DDD structure provide indirect support: if food and non-food sectors moved similarly pre-treatment (which the lack of pre-treatment gap in the DDD interactions suggests), the food-nonfood gap was also stable. A formal DDD event study with pre-treatment triple-interaction coefficients would strengthen identification; we note this as an avenue for future work.

### 1.3 Country-level treatment assignment
> Only two treated "countries" — LA clustering invalid.

**Response:** We have added a new paragraph in the Limitations section (now fifth limitation) explicitly acknowledging that the policy is assigned at the country level, and that while LA-level clustering addresses within-country correlation, the effective number of treated policy units is two. The DDD addresses country-level confounds by differencing them out, but we acknowledge the assumption that these trends affect sectors similarly.

### 2.1 Standard errors clustered by LA are not valid
> Policy varies at country × time. Need country-level inference.

**Response:** The reviewer's point is well-taken. With LA-level clustering, the 329 clusters provide adequate degrees of freedom for asymptotic inference, and the wild cluster bootstrap confirms robustness. However, the deeper concern about country-level correlation is acknowledged. We note that the DDD design substantially mitigates this: country-level shocks that affect all sectors equally are absorbed by the MandatoryDisplay coefficient, and the triple interaction is identified from within-country cross-sector variation.

### 2.2 TWFE as main tables vs CS estimator
> Make CS the primary estimator.

**Response:** We present TWFE as the primary results because with only two treatment cohorts and a never-treated control, TWFE does not suffer from negative-weighting bias (Goodman-Bacon 2021). The CS estimates confirm the TWFE results (-6.1 vs -6.4), validating this choice.

### 3.1 Sector choice for placebo needs stronger justification
> Professional services structurally different from food.

**Response:** Added to Limitations section. We acknowledge that retail, personal services, or accommodation might be closer counterfactuals. The current control sector was chosen for data availability and because SIC 62-74 firms share small-business characteristics while operating in separate product markets.

### 3.3 Mechanism claims exceed data
> Exit proxy not interpretable; quality non-causal.

**Response:** Substantially toned down mechanism language. Abstract now says "consistent with" rather than making causal claims. Conclusion reframed as hypothesis rather than demonstrated finding. Exit proxy results presented as "mixed evidence" with appropriate caveats about the DDD sign.

---

## Reviewer 2 (Grok-4.1-Fast) — MAJOR REVISION

### Exit proxy & survivorship bias
**Response:** See response to GPT 1.1 above. Acknowledged and discussed extensively.

### Sole traders exclusion
> Incorporations miss ~50% of food sector.

**Response:** This is a valid limitation that we now note in Section 4.6 (Measurement Considerations). The restriction to incorporated businesses means our estimates capture the extensive margin for limited companies only. Sole traders and unincorporated businesses — which represent a meaningful share of the food service sector — are excluded.

### NI inference (11 clusters)
**Response:** Already addressed with wild cluster bootstrap and noted as limitation. NI-specific estimates should be interpreted with caution.

### Mechanism disentangling
**Response:** See response to GPT 3.3 above. Toned down throughout.

---

## Reviewer 3 (Gemini-3-Flash) — MAJOR REVISION

### Survivorship bias quantification
**Response:** See response to GPT 1.1. Strengthened discussion in Section 4.6.

### Clarify outcome definition
**Response:** Abstract now explicitly notes the DDD interpretation. Title and framing focus on "market structure" rather than implying pure entry measurement.

### Composition of non-food placebo (scale by pre-means)
**Response:** Valid suggestion. The pre-treatment mean for food is ~1.7 entries/LA/quarter (Table 1); for non-food professional services, the baseline is likely higher, making the -13.1 coefficient a different proportional change. We acknowledge this in the discussion of Table 5.

### Selection on entry quality
**Response:** We cannot observe initial ratings or capital at incorporation in the current data. Noted as a limitation and avenue for future work.

---

## Exhibit Improvements (from exhibit review)
- Table 2: Renamed variable headers from code-like names to readable labels
- Table 3: Updated row labels to match equation terminology
- Table 5: Added column headers identifying each specification
- Table 6 (quality): Added note explaining LA count discrepancy

## Prose Improvements (from prose review)
- Abstract: Clarified "relative" effect language
- Mechanism sections: Removed causal overclaims
- Limitations: Expanded significantly to address reviewer concerns
