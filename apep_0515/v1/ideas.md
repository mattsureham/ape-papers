# Research Ideas

## Idea 1: The Minimum Wage as a Hidden Tax on Elderly Care: National Living Wage Bite and Care Home Closures in England

**Policy:** UK National Living Wage (NLW), introduced April 2016 at £7.20/hr for workers aged 25+ (replacing the £6.50 NMW), with annual increases to £11.44 by 2024. Care sector employs ~1.6M workers, ~60% of costs are labour, and most care workers earned between the old NMW and new NLW at introduction.

**Outcome:** Care home closures, bed capacity changes, and CQC quality ratings at the LA level. Primary data: CQC care directory (registration/deactivation dates for all regulated locations, weekly bulk download + API with historical deactivations). Secondary: NOMIS BRES employment in SIC 87 (residential care) and SIC 88 (social work) by LA; ASHE wages for SOC 6145 (care workers) by LA.

**Identification:** Continuous-treatment DiD. Treatment intensity = NLW "bite" in each LA, constructed from pre-2016 ASHE data as (NLW - LA median care worker wage) / LA median care worker wage. High-bite LAs (low-wage areas in the North/Midlands where care workers were far below the new NLW) vs. low-bite LAs (London/South East where most workers already earned above). Panel: ~150 upper-tier LAs × 2010-2024 (6 pre-treatment, 8 post-treatment years). Modern CS-DiD estimator with bite as continuous treatment; event-study coefficients for each year relative to April 2016. Multiple NLW increases (2017, 2018, ..., 2024) create internal replication—each increase re-shocks the high-bite LAs.

**Why it's novel:** Existing NLW literature focuses on aggregate employment and wages (IFS 2021, LPC annual reports). The care sector is mentioned descriptively in policy reports but no clean causal paper uses CQC administrative data on closures/quality + differential NLW bite in a DiD framework. The closest is Gerontologist 2023 (cross-sectional wage-quality correlation). This paper would provide the first causal estimates of how the minimum wage affects care market structure, quality, and the elderly welfare implications of a wage floor in a monopsonistic-but-publicly-funded sector.

**Feasibility check:** CQC data confirmed accessible (bulk CSV weekly, ODS monthly with beds/ratings, API for historical deactivations). NOMIS ASHE confirmed via nomisr package. BRES employment by SIC×LA available. 150+ upper-tier LAs provides ample cross-sectional variation. Pre-2016 ASHE wages vary substantially across LAs (median care worker wage ranged from ~£6.80 in Blackpool to ~£9.50 in parts of London). Built-in placebos: NHS hospitals (SIC 86, publicly funded with different wage structure); high-wage sectors (finance, tech).

---

## Idea 2: Priced Out of Patrol: Austerity PCSO Cuts and the Geography of Property Crime in England

**Policy:** Police Community Support Officers (PCSOs) were introduced in 2002 as non-sworn patrol officers. From ~16,000 in 2010, forces cut to ~9,000 by 2019 under austerity. The pace and depth of cuts varied across the 43 police forces in England and Wales, creating staggered treatment intensity variation.

**Outcome:** Monthly crime counts by type (anti-social behaviour, shoplifting, burglary, robbery, vehicle crime) from data.police.uk bulk downloads (Dec 2010–present), aggregated to police force area × month.

**Identification:** Continuous-treatment DiD with treatment = % PCSO reduction by police force relative to 2010 baseline. Home Office publishes police workforce statistics by force and rank (including PCSOs separately) twice yearly. Event-study around each force's PCSO reduction path, controlling for total police officer numbers. 43 forces with differential cut rates; ≥30 made substantial reductions.

**Why it's novel:** Mello (2019, REStud) uses the 2005 London terror attacks as an IV for police presence in a single city. Kirchmaier et al. (2021) study overall police funding cuts. No paper specifically isolates the PCSO patrol channel using cross-force variation. PCSOs are uniquely patrol-focused (no arrest powers), so their removal is a clean test of the deterrence-through-visibility hypothesis. Built-in placebos: domestic violence and online fraud (not deterred by patrol).

**Feasibility check:** Home Office workforce data confirmed available on gov.uk (CSV). Police API bulk downloads provide monthly crime by LSOA from Dec 2010. 43 forces may be borderline for DiD requirements (≥20 treated units), but most forces cut PCSOs so this should pass. Crime-type decomposition provides mechanism tests.

---

## Idea 3: Did the Apprenticeship Levy Subsidize the Privileged? Training Displacement and Equity After England's Payroll Tax

**Policy:** Apprenticeship Levy, introduced April 2017: 0.5% payroll tax on employers with annual wage bills >£3M. Apprenticeship starts collapsed ~25% after introduction, especially for youth (under-19) and Level 2 (basic). Degree apprenticeships (Level 6/7) surged, disproportionately benefiting older, already-employed, more advantaged workers.

**Outcome:** Apprenticeship starts by age group, level, sector, and LA from DfE Explore Education Statistics. Employment in training-intensive sectors from NOMIS BRES by LA.

**Identification:** Differential exposure DiD. Treatment intensity = pre-2017 share of employment in levy-paying firms (>250 employees) by LA, from BRES. High-exposure LAs (urban, large-employer areas) vs. low-exposure LAs (rural, SME-dominated). Pre/post April 2017.

**Why it's novel:** CVER (LSE) documented descriptive trends. But no paper uses area-level differential exposure to estimate causal effects on training composition and equity. The distributional angle (who gained, who lost) is underexplored.

**Feasibility check:** DfE apprenticeship data available on Explore Education Statistics by LA. NOMIS BRES provides firm-size employment breakdowns. Challenge: DfE data may need scraping from the Explore Education Statistics portal rather than a clean API. BRES firm-size data confirmed via NOMIS.

---

## Idea 4: Does Enforcement Deterrence Shape the Workplace? Employment Tribunal Fees and Employer Conduct in England

**Policy:** Employment Tribunal fees introduced July 2013 (£160-£1,200 per claim), abolished July 2017 by Supreme Court. Claims dropped ~70% during the fee period, then doubled after abolition. The fees effectively reduced enforcement threat for employer misconduct.

**Outcome:** Workplace injury rates (HSE RIDDOR by LA/industry), employment structure changes (zero-hours contracts, self-employment from NOMIS LFS/APS), and ACAS early conciliation volumes.

**Identification:** Interrupted time series with two treatment points (fee introduction July 2013, abolition July 2017). Cross-sectional treatment intensity = pre-fee tribunal claim rate by region and industry type (discrimination vs. unfair dismissal vs. wages). High-claim sectors/regions experienced more deterrence reduction.

**Why it's novel:** Existing literature focuses on access-to-justice (Adams & Prassl 2017) and claim volumes. No paper examines whether reduced enforcement threat changed actual workplace outcomes—the employer moral hazard channel. The symmetric design (introduction + abolition) provides internal replication.

**Feasibility check:** HSE RIDDOR data available on HSE open data portal by LA and SIC. NOMIS LFS/APS data available for employment structure. MoJ tribunal statistics available. Challenge: linking the deterrence mechanism to measurable workplace outcomes at area level is indirect; the causal chain has multiple steps. Weakest identification of the five ideas.

---

## Idea 5: Empty Homes, Full Wallets? Council Tax Premiums and Housing Reactivation in England

**Policy:** Since April 2013, English councils can charge a premium of up to 100% on long-term empty properties (>2 years vacant). From April 2019: 200% premium for 5+ years empty. From April 2020: 300% for 10+ years. Councils adopted at different times and with different premium levels—some immediately in 2013, others years later, creating genuine staggered adoption across ~300 billing authorities.

**Outcome:** Number of long-term empty dwellings by LA (MHCLG/DLUHC council tax base statistics, published annually). House prices and transaction volumes from Land Registry PPD. New housing supply from DLUHC housing starts/completions data.

**Identification:** Staggered adoption DiD across ~300 billing authorities. Treatment = LA adopts empty homes premium. Clean staggered design with CS-DiD estimator. Pre-treatment periods: 2010-2012. Post-treatment varies by LA adoption date.

**Why it's novel:** The empty homes premium is widely discussed in housing policy but no published causal evaluation exists using the staggered LA adoption as identification. Most evidence is descriptive (LGA reports, Shelter briefings). A clean DiD with housing market outcomes would be the first rigorous evaluation.

**Feasibility check:** Council tax base statistics confirmed on data.gov.uk (annual, by LA). Land Registry PPD confirmed accessible. DLUHC housing supply data published annually. Staggered adoption provides clean variation. Challenge: this is housing policy, not directly labour & welfare; includes it here as an alternative if care home idea encounters data issues.
