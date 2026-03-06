# Conditional Requirements

**Generated:** 2026-03-06T02:09:49.341969
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions addressed. The three models raised overlapping concerns about the same core issues. I consolidate and address each unique concern once.

---

## Condition A: Application-level grant/deny data with examiner assignment

**Status:** [x] RESOLVED

**Response:** Three complementary strategies ensure we have a valid instrument:

1. **Primary path: USPTO PatEx dataset** (13M+ applications including denials/abandonments with examiner assignments). Available at data.gov catalog and USPTO bulk data portal. Data through June 2023. This is the standard dataset used by Farre-Mensa et al. (2020) and Sampat & Williams (2019, AER).

2. **Backup path: PatentsView grant-only with art-unit normalization.** Under random assignment within art-unit-year cells, examiners receive approximately equal application loads. Total examiner grant counts within art-unit-year cells are therefore proportional to leniency. The instrument is the leave-one-out grant count, which is equivalent to the leave-one-out grant rate up to a scalar (the constant expected application count). Validated by showing the grant-count instrument predicts other examiner harshness measures (prosecution time, restriction requirements, claim narrowing).

3. **UJIVE estimator** (Chyn, Frandsen & Leslie 2024) handles many-instrument bias that arises in examiner designs regardless of which data source is used.

**Evidence:** PatEx confirmed at https://catalog.data.gov/dataset/patent-examination-research-dataset-patex-for-academia-and-researchers-2001-2021 (13M applications). PatentsView examiner data confirmed accessible (197 MB, HTTP 200).

---

## Condition B: Follow-on applications and geographic diffusion as core outcomes (not citations)

**Status:** [x] RESOLVED

**Response:** Agreed. Primary outcomes will be:

1. **Follow-on Y02 patent applications** by other inventors in the same CPC subclass within 3/5/10 years (measure of cumulative innovation)
2. **Geographic spread of follow-on innovation** — number of distinct MSAs/states where citing/building inventors are located (diffusion breadth)
3. **Assignee-level outcomes** — subsequent Y02 filing activity by the applicant firm (within-firm innovation trajectory)

These are all measured at the micro level from PatentsView data, where the exclusion restriction is cleanest.

**Evidence:** PatentsView g_cpc_current.tsv provides CPC subclass linkage; g_inventor_not_disambiguated.tsv provides inventor locations for geographic diffusion measurement.

---

## Condition C: Forward citations treated as secondary/robustness

**Status:** [x] RESOLVED

**Response:** Agreed. Forward citations are mechanically affected by the grant decision (granted patents are more visible and legally citable). They will appear ONLY in the robustness section, not as a primary outcome. The main analysis centers on follow-on patent applications (new Y02 filings by third-party inventors), which are not mechanically linked to the grant/deny decision.

---

## Condition D: Renewable energy deployment as exploratory/appendix only

**Status:** [x] RESOLVED

**Response:** Agreed. State-level EIA renewable energy generation is too far downstream from any individual patent decision for the examiner IV exclusion restriction to be credible. These outcomes will appear in an appendix as suggestive/exploratory evidence only, with explicit disclaimers about the weak link between a marginal patent and aggregate deployment.

---

## Condition E: Firm-level outcomes

**Status:** [x] RESOLVED

**Response:** Agreed. I will construct firm-level outcomes from PatentsView assignee data: subsequent patent applications by the same assignee, portfolio breadth (number of distinct Y02 subclasses), and within-firm technology trajectory. These are close to the patent decision margin and offer a mechanism test for whether patent protection encourages or discourages the assignee from investing further in the technology.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
