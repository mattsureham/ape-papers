# Research Plan: Comment Period Length and Public Participation in Federal Rulemaking

## Research Question

Does extending the public comment period for proposed federal rules cause more and more substantive public participation? The Administrative Procedure Act (APA) requires a minimum 30-day comment period, but agencies routinely choose 30–180 days. ACUS Recommendation 2011-2 called for empirical evidence on whether comment period length affects participation quality — no published study has answered this using modern data.

## Identification Strategy

### Primary: Dose-Response with Agency-Year Fixed Effects

Exploit within-agency, within-year variation in comment period length across proposed rules. Conditional on agency × year fixed effects, the exact comment period length is plausibly quasi-random — determined by administrative scheduling, staff availability, and statutory defaults rather than anticipated controversy. Controlling for rule complexity proxies (page count, CFR parts affected, RIN significance designation) addresses the main threat that agencies strategically extend periods for controversial rules.

### Secondary: Bunching at the 30-Day APA Floor

Document bunching of comment periods at exactly 30 days. Rules with 31–45 day periods are observationally similar to 30-day rules but received marginally more participation time. Estimate local effects in the 25–45 day bandwidth using a fuzzy RD framework.

## Expected Effects

- **Comment count:** Positive — longer periods allow more individuals/organizations to learn about and respond to the rule.
- **Unique (non-duplicate) comment share:** Ambiguous — longer periods could attract more substantive commenters, or could primarily extend the window for mass form-letter campaigns.
- **Organizational commenter share:** Positive — organizations have longer planning horizons and coordination costs; marginal days disproportionately benefit organized interests.
- **Rule finalization:** Null or slightly negative — longer periods may delay but should not fundamentally change whether rules are finalized.

## Primary Specification

$$\text{Comments}_{i} = \alpha + \beta \cdot \text{DaysOpen}_{i} + \mathbf{X}_i'\gamma + \delta_{a,t} + \varepsilon_i$$

where $i$ is a proposed rule, DaysOpen is comment period length in days, $\mathbf{X}_i$ are rule-level controls (page count, number of CFR parts, RIN significance), and $\delta_{a,t}$ are agency × year fixed effects.

Outcomes: (1) log comment count, (2) unique comment share, (3) organizational commenter share.

Robustness: Poisson regression for count outcome, bandwidth restriction to 25–60 day window, exclusion of major/"significant" rules, cross-agency expansion.

## Data Sources

1. **Federal Register API** (federalregister.gov/api/v1/) — All proposed rules 2010–2020. Fields: publication_date, comments_close_on, page_count, cfr_references, regulation_id_numbers, docket_ids, agency. Confirmed: 4,736 EPA proposed rules.
2. **Regulations.gov API** (api.regulations.gov/v4/) — Comment counts per docket, duplicateComments field, organization field. API key required (available via Data.gov). Confirmed: OSHA silica docket N=1,878; EPA Clean Power Plan N=34,479.
3. **Supplementary:** Federal Register full-text for final rule publication dates (to measure time-to-finalization).

## Fetch Strategy

1. Paginate through Federal Register API for all agency proposed rules 2010–2020 (not just EPA).
2. Calculate comment period length = comments_close_on − publication_date.
3. For each rule with a docket_id, query Regulations.gov for total comment count and sample comment metadata (duplicateComments, organization).
4. Merge rule-level characteristics with comment-level outcomes.

## Risks

- **Regulations.gov API rate limits:** 1,000 requests/hour. May need to batch over multiple hours or sample dockets.
- **Strategic comment period selection:** Main endogeneity concern. Mitigated by FE structure and bandwidth restriction.
- **Mass comment campaigns:** A few high-profile rules may dominate comment counts. Use log transformation and trim outliers.
