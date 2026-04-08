# Research Plan: Comment Period Length and Rule Text Change

## Research Question
Does extending the public comment period cause federal agencies to change the text of their final rules more, relative to what they originally proposed? Comment period length has been studied as a determinant of comment volume (apep_0670), but never as a determinant of rule revision — the substantive policy outcome.

## Data
- **Federal Register API:** All proposed (`PRORULE`) and final (`RULE`) rules, 2015–2022. Fields: document_number, publication_date, comments_close_on, significant, agencies, page_length, regulation_id_numbers (RIN), raw_text_url.
- **Linkage:** Match proposed→final rules by shared RIN (Regulation Identifier Number), keeping the chronologically nearest final following each proposal.
- **Text:** Full plain-text from `raw_text_url` for both halves of each pair.

## Identification
- **OLS / within-agency-year FE:** Conditional on agency × year fixed effects, log page count, and significance flag, the realized comment period length is plausibly quasi-random with respect to *the magnitude of subsequent textual revision* (this is distinct from the OIRA significance designation, which determines length).
- **IV (preferred):** EO 12866 "significant" designation as instrument for `days_open`. Significance is determined by OIRA from estimated $100M+ economic impact *before* the comment window opens; it shifts the legally binding floor from 30 to 60 days. The exclusion restriction is that, conditional on agency-year FE, log page count, and topic FE, significance affects rule revision *only* through the additional comment time it forces. We discuss the threats to exclusion (significance correlates with controversy) and provide a falsification test.
- **Reduced form:** Direct effect of significance on text distance.

## Outcome
Primary: $\text{TextDist}_i = 1 - \cos(\text{TFIDF}(\text{proposed}_i),\text{TFIDF}(\text{final}_i))$ — cosine distance between TF-IDF vectors of the proposed and final rule.
Secondary: log absolute change in page length, $|\text{pages}_{\text{final}}-\text{pages}_{\text{proposed}}|$.

## Specification
$$\text{TextDist}_i = \beta\,\text{DaysOpen}_i + \gamma'\mathbf{X}_i + \delta_{a,t} + \varepsilon_i$$
IV first stage: $\text{DaysOpen}_i = \pi\,\text{Significant}_i + \gamma'\mathbf{X}_i + \delta_{a,t} + u_i$.
SEs clustered by agency.

## Sample
Proposed rules 2015–2022 with non-missing `significant`, valid `comments_close_on`, RIN present, and a matched final rule within 36 months. Expected n ≈ 5,000–8,000 matched pairs.

## Method Notes
- TF-IDF vocabulary built once on the matched corpus (English stopwords, min_df=5, max_df=0.5, 1-2 grams capped at 50,000 features).
- IV via `feols(... | fe | d ~ z, ...)` in `fixest`.
- Robustness: drop EPA, drop the longest-period decile, cluster by parent agency, restrict to non-significant subsample to estimate the OLS within-stratum slope.
