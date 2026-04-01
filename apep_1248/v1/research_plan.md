# Research Plan: Thin Formality

## Research Question
Did Colombia's 2012 payroll tax cut (Law 1607) produce "thin formality" — formal employment registration without delivery of legally mandated non-wage benefits? While the literature documents increased social-security registration, no study tests whether newly formalized workers actually received prima de servicios, cesantías, paid vacation, and pension contributions.

## Identification Strategy
**Triple-difference design:**
- **Dimension 1 (Earnings):** Workers below vs. above the 10 minimum-wage threshold (reform applied only below 10 MW)
- **Dimension 2 (Time):** Pre-reform (2010–2012) vs. post-reform (2013–2016)
- **Dimension 3 (Firm size):** Small firms (<11 employees) vs. larger firms (11–50 employees)

The logic: if the reform expanded formal contracts at the extensive margin (documented by Kugler et al.), but firms at the margin of compliance — disproportionately small firms — cut corners on costly non-wage benefits (prima = 1 month salary, cesantías = 1 month salary/year, pension = 12% employer share), then the social gain from formalization is overstated. The third difference (firm size) isolates firms most likely to be marginal compliers.

**Key identifying assumption:** Absent the reform, the gap in benefit receipt between small and larger firms would have evolved similarly for workers above and below 10 MW. We test this with event-study plots showing parallel pre-trends.

## Expected Effects and Mechanisms
- **Main hypothesis:** Formal registration increased (replicate), but benefit completeness *declined* among newly formalized small-firm workers — "thin formality."
- **Mechanism:** Firms that formalized to avoid the net tax penalty still face substantial benefit costs (prima + cesantías + pension ≈ 25–30% of salary). For marginal formalizers, registration is cheap but benefit delivery is expensive. The reform changed the formality/informality boundary without changing the benefit-compliance boundary.
- **Null scenario:** Benefits tracked registration 1:1 — the reform produced "thick" formality. This would be an important positive finding.

## Primary Specification
```
Y_{it} = α + β₁(Below10MW_i × Post_t × SmallFirm_i)
         + β₂(Below10MW_i × Post_t)
         + β₃(Below10MW_i × SmallFirm_i)
         + β₄(Post_t × SmallFirm_i)
         + γ_city + δ_quarter + X_i'θ + ε_{it}
```
Where Y is: (1) benefit completeness index (0–4), (2) each benefit indicator separately.

Clustering: city-level (23 major cities in GEIH).

## Data Source and Fetch Strategy
**Gran Encuesta Integrada de Hogares (GEIH)**, DANE Colombia.
- URL: https://microdatos.dane.gov.co/
- Years: 2010–2016 (7 years × ~250K individuals/year)
- Key variables: formal contract status, firm size, earnings (monthly), benefit receipt (prima, cesantías, vacation, pension), city, age, education, sector
- Sample restriction: wage/salary workers ages 18–65 in the 13 main metropolitan areas (consistent GEIH coverage)
- Expected analytic sample: ~350,000–500,000 person-year observations

**Fetch approach:** Download GEIH microdata files from DANE's microdata catalog. Files are in CSV/SAV format. Will download 2010–2016 occupation/labor force module which contains benefit-receipt questions.

## Literature Context
- Kugler, Kugler & Herrera Prada (NBER w23308): Documents extensive-margin formalization gains, especially for small firms
- Bernal & Meléndez (Economía, 2017): Firm-level wages and employment effects
- Morales & Medina (IZA): PILA administrative data on registration — captures contributions but not prima/cesantías/vacation delivery
- **Gap:** No paper examines benefit-receipt quality as an outcome. GEIH uniquely asks these questions.
