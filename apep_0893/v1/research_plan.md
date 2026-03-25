# Research Plan: The Regulatory Budget Shock

## Research Question

Did Executive Order 13771's "two-for-one" regulatory budget constraint systematically alter the speed, composition, and completion rates of federal rulemaking? Did Biden's rescission (EO 13992) reverse these effects?

## Identification Strategy

**Difference-in-Differences with continuous treatment intensity.**

- **Unit:** Agency-semester panel (50+ agencies × 28 semesters, 2010H2–2024H1)
- **Treatment:** EO 13771 signed January 30, 2017; rescinded January 20, 2021
- **Treatment intensity:** Pre-2017 share of "Economically Significant" dockets per agency (time-invariant, predetermined)
- **Rationale:** Agencies with higher shares of economically significant rules faced a harder offset constraint because each new rule required identifying two existing rules for repeal *and* a net-zero cost cap

**Specification:**
```
Y_at = α_a + δ_t + β₁(Post2017_t × HighIntensity_a) + β₂(Post2021_t × HighIntensity_a) + ε_at
```

β₁: Effect of regulatory budget on high-intensity agencies during EO 13771
β₂: Reversal effect after Biden's rescission

## Expected Effects

1. **Duration (NPRM → Final Rule):** Positive β₁ — high-intensity agencies slow down protective rulemaking to find offsets
2. **Completion rate:** Negative β₁ — more proposed rules abandoned by high-intensity agencies
3. **Withdrawal rate:** Positive β₁ — more proposed rules formally withdrawn
4. **Composition:** Shift toward deregulatory dockets at high-intensity agencies
5. **Asymmetric reversal:** |β₂| < |β₁| — regulatory capacity lost during freeze is not instantly recovered ("ratchet")

## Exposure Alignment: Who Is Treated

The treatment (EO 13771) applies to all executive-branch agencies issuing new significant rules. The treatment intensity (pre-2017 significance share) is pre-determined and time-invariant. High-exposure agencies (HHS=0.84, Labor=0.83, Justice=0.74) had portfolios dominated by costly rules requiring OIRA review. Low-exposure agencies (Coast Guard, FAA routine) rarely triggered the threshold. The affected population is the agency's rulemaking pipeline — specifically the staff and processes that produce NPRMs, conduct cost-benefit analysis, and manage OIRA review. The treatment-eligible population is all executive-branch agencies (independent commissions are partially exempt from EO 13771).

## Mechanism

EO 13771 created a binding constraint: new rules require offsetting repeals and net-zero cost. This is hardest for agencies whose portfolio is dominated by economically significant rules (EPA, OSHA, NHTSA) because offsets are scarce. Routine-rule agencies (USCG routine safety, FAA airworthiness) face a slack constraint. The binding constraint channels through: (a) staff reallocation to offset search, (b) OIRA bottleneck for cost estimates, (c) voluntary shelving of rules that can't find offsets.

## Primary Specification

Agency-semester panel. Outcomes: mean NPRM-to-final duration (days), completion rate (share of NPRMs with matching final rule within 4 years), withdrawal rate. Cluster SEs at agency level (~50 clusters). Event study with semester-level leads and lags around January 2017.

## Data Source and Fetch Strategy

**Primary:** Regulations.gov API v4 (confirmed accessible)
- Fetch all rulemaking dockets → extract agency, docket type, priority category
- Fetch all Proposed Rule and Rule documents → extract postedDate, withdrawn, docketId, agencyId
- Match NPRMs to Final Rules within same docketId
- Compute duration, completion, withdrawal at agency-semester level

**Construction:**
1. Pull all dockets with `docketType=Rulemaking` (61,501 total)
2. Pull all documents with `documentType=Proposed Rule` and `documentType=Rule`
3. Within each docket, match NPRMs to Final Rules by docketId and compute duration
4. Aggregate to agency-semester cells
5. Compute treatment intensity from pre-2017 share of economically significant dockets

**Key fields confirmed via API smoke test:**
- `postedDate`, `documentType`, `docketId`, `agencyId`, `priorityCategory`, `eo13771Designation`, `withdrawn`
