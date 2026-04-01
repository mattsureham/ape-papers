# Research Plan: The Opacity Premium — Bunching Below the 25% Beneficial Ownership Disclosure Threshold in UK Companies

## Research Question

Do companies strategically restructure ownership to avoid the UK's 25% beneficial ownership disclosure threshold? If so, what is the implied cost of transparency, and which sectors drive avoidance?

## Policy Context

The UK's Small Business, Enterprise and Employment Act 2015 created the world's first public beneficial ownership register (PSC register), effective April 6, 2016. Any individual holding >25% of shares or voting rights must be publicly disclosed as a "Person with Significant Control." The threshold creates a sharp notch: at 25.01%, name, date of birth, nationality, and country of residence become public; at 24.99%, no disclosure is required. The Economic Crime and Corporate Transparency Act (ECCTA) 2023 strengthened enforcement with Companies House verification powers.

This 25% threshold is the global FATF standard, adopted by EU AMLD4/5/6 and the US Corporate Transparency Act (2024). If strategic restructuring to avoid disclosure is substantial, the $2 trillion global AML regime has a quantifiable leak.

## Identification Strategy

**Notch-bunching estimation (Kleven and Waseem 2013).** The 25% disclosure threshold creates a notch in the cost of ownership transparency. Below 25%, there is zero disclosure cost. Above 25%, there is a discrete jump to full public disclosure. Strategic avoidance will manifest as:

1. **Excess mass at exactly 4 PSCs per company** — splitting equal ownership 4 ways places each at 25%, just at the threshold. Companies with 5+ equal shareholders (each <25%) avoid disclosure entirely.
2. **Excess mass at 4 PSCs in the 25-50% band** — the smoke test already shows 70.4% of 4-PSC companies have all four in the 25-50% band.
3. **Missing mass above the threshold** — fewer companies than expected with a single PSC holding 75-100%.

The counterfactual distribution is estimated via a polynomial fitted to the PSC-count distribution excluding the bunching region.

**Difference-in-bunching:** Two natural experiments:
- April 2016: PSC register launch (before = no disclosure; after = disclosure above 25%)
- ECCTA 2023: enforcement tightening (before = weak enforcement; after = verification powers)

**Mechanism tests:**
- Bunching concentrated in high-risk SIC sectors (real estate, financial holding, professional services)
- Company service provider addresses (registered office services = anonymity-seeking)
- Foreign-national PSC patterns (cross-border ownership opacity)

## Expected Effects

- Substantial excess mass at exactly 4 PSCs per company (each 25%)
- Excess mass larger in high-risk sectors (real estate, financial holdings)
- Missing mass in the "natural" single-owner concentration range
- The implied "opacity premium" — the ownership value people sacrifice to stay below 25% — should be economically meaningful

## Primary Specification

Bunching estimation: excess mass b = (B - B_cf) / f_cf(z*), where B is the observed count in the bunching region, B_cf is the counterfactual, and f_cf(z*) is the counterfactual density at the threshold. Standard errors via bootstrap.

## Data Source and Fetch Strategy

1. **UK Companies House PSC Bulk Snapshot** — Free HTTP download, JSON format, 31 chunks (~72MB each). Contains all PSC records with ownership bands and company numbers.
2. **UK Companies House Company Profile Data** — Bulk CSV snapshot for SIC codes, incorporation dates, registered office addresses. Free download.
3. **Cross-reference:** Link PSC records to company profiles via company number to get sector and incorporation date.

All data is publicly available with no API key required.
