# Research Plan: The Disclosure Cliff

## Research Question
Do pharmaceutical and device manufacturers strategically avoid disclosure by keeping individual payments to physicians just below the CMS Open Payments per-transaction reporting threshold? How large is the disclosure avoidance elasticity, and does it vary by payment type?

## Background
The Physician Payments Sunshine Act (ACA Section 6002, effective 2013) mandates that manufacturers report individual payments to physicians exceeding a per-transaction minimum, CPI-adjusted annually ($10.22 in 2016 to ~$13.46 in 2025). Payments below this threshold that don't cumulate above a separate annual aggregate ($100, also CPI-adjusted) are exempt from public disclosure. This creates a censoring notch: manufacturers can avoid disclosure of a payment by keeping its value just below the threshold.

## Identification Strategy
**Moving-threshold bunching estimator.** The CPI-indexed threshold shifts annually, creating year-specific counterfactual distributions. I exploit:

1. **Cross-sectional bunching:** In each year, test for excess mass just below the reporting threshold and missing mass just above. The counterfactual distribution is estimated via polynomial fit excluding the manipulation region.

2. **Cross-year validation:** If bunching is strategic (not mechanical), the bunching point must track the CPI-adjusted threshold across years. A placebo test checks for bunching at prior-year thresholds in years when the threshold has moved.

3. **Payment-type heterogeneity:** Food & Beverage payments (~95% of small transactions) have highly elastic amounts (a meal can cost $9 or $11). Consulting/speaking fees are negotiated at round numbers and should show less bunching. This is a mechanism test: strategic avoidance should concentrate where amount manipulation is cheap.

## Expected Effects and Mechanisms
- **Positive bunching below threshold:** Excess mass of 5-20% of the counterfactual density in the manipulation region
- **Mechanism:** Manufacturers set meal/gift values to stay under the disclosure threshold, either through direct price management or vendor instructions
- **Heterogeneity:** Food/Beverage >> Consulting/Speaking fees >> Research payments
- **Time pattern:** Bunching should increase as awareness of disclosure grows (later years > earlier years)

## Primary Specification
For each program year $t$, estimate the bunching mass $\hat{b}_t$ as the excess number of payments in a window $[\tau_t - \delta, \tau_t]$ relative to a counterfactual polynomial fitted to the distribution excluding $[\tau_t - \delta, \tau_t + \delta]$, where $\tau_t$ is the year-$t$ threshold and $\delta$ is the manipulation bandwidth (optimally chosen via cross-validation).

The disclosure avoidance elasticity:
$$e = \frac{\hat{b}}{h_0(\tau) \cdot \tau}$$
where $h_0(\tau)$ is the counterfactual density at the threshold.

## Data Source and Fetch Strategy
1. **CMS Open Payments General Payment Data (2016-2024):** REST API at `openpaymentsdata.cms.gov`. 15-16M records/year, 130M+ total. Key fields: `total_amount_of_payment_usdollars`, `nature_of_payment_or_transfer_of_value`, `covered_recipient_npi`, `applicable_manufacturer_or_applicable_gpo_making_payment_name`, `date_of_payment`, `program_year`.

   **Strategy:** Query the API for payments in a narrow band around each year's threshold (e.g., $5-$25) to keep download size manageable. For distribution plots, also pull broader ranges.

2. **CMS Per-Transaction Thresholds:** Published annually in Federal Register. Manual lookup for each program year 2016-2024.

3. **Medicare Part D Prescriber PUF (optional mechanism):** Link via NPI to test whether physicians receiving just-below-threshold payments prescribe differently from those receiving just-above-threshold payments.

## Key Risks
- The API may rate-limit or paginate large queries → batch by year and manufacturer
- Small payments may be rounded to whole dollars mechanically → check for heaping at round numbers and distinguish from strategic bunching
- The aggregate annual threshold ($100) creates a second margin of avoidance → focus analysis on the per-transaction threshold, note the aggregate as a limitation
