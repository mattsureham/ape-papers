# Research Plan: apep_0849

## Research Question

Did Taiwan's 2010 transition from sector-targeted R&D tax credits (up to 35% for strategic industries) to a uniform 15% credit under the Industrial Innovation Act (IIA) reallocate patenting effort away from previously favored technology classes?

## Identification Strategy

**Difference-in-Differences** at the USPTO technology-class × quarter level.

- **Treatment group:** USPC classes corresponding to SUI strategic industries (semiconductors: 257/438, optoelectronics: 349/362)
- **Control group:** USPC classes for Taiwanese applicants in non-strategic technology areas
- **Pre-period:** 2005Q1–2009Q4 (20 quarters)
- **Post-period:** 2010Q1–2013Q4 (16 quarters)
- **Sharp timing:** SUI expired December 31, 2009; IIA effective January 1, 2010

**Key robustness:**
1. Israel and Singapore as placebo countries (same USPTO examiners, unaffected by Taiwan's IIA)
2. Examiner-leniency variation as additional source of identification
3. Event-study specification for pre-trend validation
4. Leave-one-out by technology class

## Exposure Alignment

**Who is treated:** Taiwan-based firms with USPTO patent filings in SUI-designated strategic technology classes (22 USPC mainclasses covering semiconductors, optoelectronics, communications, precision instruments, IT hardware). These firms received enhanced R&D tax credits of up to 35% under the SUI (1991-2009).

**Treatment exposure:** The IIA (January 2010) reduced the effective credit from up to 35% to a uniform 15% for treated-sector firms. The treated unit is the USPC technology class × year cell, where treatment is defined by the class's correspondence to SUI-designated sectors. Treatment operates at the firm-sector level (firms in strategic sectors lose their enhanced credit) but is measured at the technology class level (patent counts aggregated by USPC class).

**Exposure alignment concerns:** (1) Firms may patent across multiple technology classes; a treated firm losing its semiconductor credit might still file patents classified in untreated classes. This would attenuate the measured effect. (2) The IIA simultaneously extended a 15% credit to previously uncovered sectors, creating a dual treatment: treated classes lose credits while control classes gain them. The DiD captures relative reallocation, not absolute effects. (3) Patent filings at the USPTO are a downstream proxy for R&D investment; firms may adjust domestic R&D without changing international patent strategy.

## Expected Effects and Mechanisms

Previously favored sectors (semiconductors, optoelectronics) lose their 35% credit advantage, facing a relative ~20pp credit reduction. The "leveling" could:
1. **Reduce patenting in treated sectors** (direct incentive effect — the subsidy that made marginal R&D projects viable is gone)
2. **Increase patenting in untreated sectors** (reallocation — firms and inventors shift effort to previously disadvantaged fields)
3. **Shift patent quality** — if the marginal patent in treated sectors was subsidy-induced, average quality should rise when the subsidy drops (selection effect)

The economic object: **the reallocation dividend** (or cost) of switching from picking winners to a level playing field.

## Primary Specification

```
Y_{ct} = β(TreatedClass_c × Post_t) + α_c + γ_t + ε_{ct}
```

Where:
- Y = ln(applications + 1) or application count at technology-class × quarter level
- TreatedClass = 1 for SUI strategic USPC classes (257, 438, 349, 362)
- Post = 1 for quarters ≥ 2010Q1
- α_c = technology class FE
- γ_t = quarter FE
- Clustering: technology class level

Secondary outcomes: grant rate, office action severity, citation-based quality.

## Data Source and Fetch Strategy

**Google BigQuery** (confirmed accessible, project: scl-librechat):
- `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications with filing/grant dates, assignee country, USPC class
- `patents-public-data.uspto_oce_office_actions.office_actions` — 4.4M office actions with rejection codes

**Query plan:**
1. Extract all Taiwan-origin applications 2003–2015 from BigQuery (assignee_country or applicant fields)
2. Extract office actions for these applications
3. Extract Israel and Singapore applications as placebos
4. Aggregate to USPC class × quarter level
5. Merge outcomes

All data fetched via Python BigQuery client, saved as CSV, then analyzed in R.
