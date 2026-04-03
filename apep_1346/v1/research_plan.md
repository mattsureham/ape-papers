# Research Plan: The Lag Windfall

## Research Question
Does Medicare Part B's 2-quarter ASP update lag slow generic drug adoption by creating a temporary "lag windfall" — a period where prescribing the brand-name drug is mechanically more profitable than the generic?

## Background
Medicare Part B reimburses physician-administered drugs at ASP+6% (Section 1847A SSA), updated quarterly with a 2-quarter lag. When a generic enters:
- Quarters t and t+1: reimbursement uses pre-generic ASP data → brand reimbursement stays high
- Quarter t+2 onward: post-entry ASP flows through → reimbursement drops

During the lag window, the spread between reimbursement (high, based on old ASP) and acquisition cost (low, reflecting generic competition) creates a **mechanical windfall**. Physicians who continue prescribing brand during this window earn higher margins than those who switch to generic immediately.

## Identification Strategy
**Sharp event-study around generic entry dates.** Each drug's generic entry (from FDA Orange Book) creates a mechanical before/after in the ASP pricing files. The key variable:

**Lag Windfall = ASP Payment Rate − Market Acquisition Cost**

This is mechanically positive during the 2-quarter lag window and converges to zero after. The identification is unusually clean because:
1. The lag is a formula artifact (not a policy choice)
2. Generic entry timing is driven by patent expiry + FDA review (orthogonal to physician behavior)
3. The windfall's magnitude varies cross-sectionally by drug (larger brand-generic price gaps = larger windfalls)

## Expected Effects
- **Primary:** Part B spending per claim stays elevated during the 2-quarter lag window relative to the counterfactual of immediate ASP adjustment
- **Mechanism:** If physicians respond to the windfall, brand market share should decline more slowly during lag quarters than immediately after the lag closes
- **Heterogeneity:** Effects should be larger for drugs with bigger brand-generic price gaps and for drugs with higher per-claim reimbursement (where the 6% markup matters more in dollar terms)

## Primary Specification
Within-drug event study centered on generic entry quarter:
```
log(ASP_Payment)_{d,t} = α_d + α_t + Σ_k β_k × 1(t = entry_q + k) + ε_{d,t}
```
where d indexes drugs and t indexes quarters. Event-time dummies k ∈ {-8, ..., +12}.

## Data Sources
1. **CMS ASP Quarterly Pricing Files** (2016Q1–2025Q2): ~866 HCPCS codes per quarter, drug-level ASP and payment limits
2. **Medicare Part B Spending by Drug** (annual + quarterly): HCPCS-level total spending, beneficiaries, claims, costs
3. **FDA Orange Book**: Generic approval dates by NDA/ANDA number, matched to HCPCS via NDC crosswalk
4. **CMS HCPCS-NDC Crosswalk**: Links billing codes to specific products

## Analysis Plan
1. Build drug-quarter panel from ASP files (2016-2025)
2. Identify generic entry dates from FDA Orange Book
3. Construct lag windfall measure per drug-quarter
4. Event study: ASP payment evolution around generic entry
5. Cross-sectional heterogeneity: larger brand-generic gaps → larger windfall persistence
6. Back-of-envelope: aggregate cost of the lag formula to Medicare
7. Robustness: exclude biologics/biosimilars, restrict to small-molecule generics

## Key Risk
Sample size — need ≥30 clean generic entry events with sufficient ASP file coverage. If too few drugs have clean entry in the 2016-2025 window, the event study will lack power.
