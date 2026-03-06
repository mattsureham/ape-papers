# Research Ideas

## Idea 1: Less Cash, Less Crime? The Nationwide Effect of Electronic Benefit Transfer on Property Crime
**Policy:** The Personal Responsibility and Work Opportunity Reconciliation Act of 1996 mandated all states implement EBT systems for food stamp delivery by October 1, 2002. States adopted at different times over a 10-year window (1996-2005): Maryland, South Carolina, Texas (1996) through California, Minnesota, Vermont (2004-05). EBT replaced paper food stamps — which were liquid, anonymous, routinely stolen, and traded at ~$0.50 on the black market — with PIN-protected debit cards.
**Outcome:** FBI Uniform Crime Reports (UCR) state-level annual data: property crime rate (total), burglary rate, larceny-theft rate, robbery rate. Available from FBI Crime Data Explorer, 1960-present, all 50 states + DC. Treatment timing from USDA ERS SNAP Policy Database (`ebtissuance` column).
**Identification:** Callaway-Sant'Anna CS-DiD with staggered state-level EBT adoption dates. 51 jurisdictions over a 10-year rollout. Mechanism tests: burglary (directly linked) vs. motor vehicle theft (unrelated); high-SNAP-caseload dose-response; white-collar crime placebo. Treatment timing driven by state administrative capacity and federal compliance pressure, not crime trends.
**Why it's novel:** Wright et al. (2017 JLE) found 9.2% crime reduction using Missouri counties only. No nationwide CS-DiD exists. The cross-domain mechanism — welfare payment technology reform destroying an underground currency — is a genuine belief-changing twist rarely studied in economics.
**Feasibility check:** Confirmed: 51 state-level EBT adoption dates spanning 1996-2005 from USDA ERS. FBI UCR state-level accessible. No overlap with 403 published APEP papers.

## Idea 2: The Economic Integration Lottery: How Immigration Judge Leniency Shapes Local Labor Markets
**Policy:** US asylum system adjudicates ~270,000 cases/year across 68+ courts. Cases randomly assigned to judges within courts; judges exhibit 56-pp median within-court leniency disparity (TRAC 2024). Grant → work authorization + benefits; denial → deportation/unauthorized status.
**Outcome:** EOIR case-level data (4.24 GB, DOJ FOIA), BLS QCEW county-industry employment/wages, Census ACS noncitizen populations.
**Identification:** Immigration judge leniency IV (UJIVE estimator). Within-court random case assignment instruments for court-level asylum grant rates, linked to county economic outcomes. 56-pp first stage far exceeds bankruptcy judges (~5 pp) or SSDI ALJs (~15 pp).
**Why it's novel:** No existing paper uses immigration judge leniency IV for economic outcomes. Separates legal status from immigration itself. 2.7M cases, 735 judges, 500 counties.
**Feasibility check:** EOIR data confirmed (HTTP 200, 4.24GB). BLS QCEW and Census ACS APIs working. Zero APEP overlap.

## Idea 3: The Symmetric Tax Shock: Housing Capitalization of the SALT Deduction Cap and Its Reversal
**Policy:** 2018 TCJA capped SALT deduction at $10K (negative shock to high-tax areas). 2025 OBBB raised cap to $40K (positive shock). Same zip codes treated twice — symmetric experiment testing whether housing capitalization is reversible.
**Outcome:** Zillow ZHVI (26,300 zips, monthly, 2000-2026), FHFA zip HPI (668K rows), Redfin Market Tracker (9.5M rows), IRS SOI migration flows.
**Identification:** Continuous-treatment DiD using pre-reform (2017) zip-code SALT exposure. Parallel trends testable with 5+ pre-years. Metro x year FE isolates within-metro variation. Formal symmetry test: H0: |beta_cap| = |beta_uncap|.
**Why it's novel:** No published paper studies the 2025 OBBB reversal. First test of whether housing capitalization is reversible — fundamental question in public finance since Rosen (1979).
**Feasibility check:** 3,676 zips above $10K cap. Zillow, FHFA, Redfin, IRS SOI all publicly downloadable. Confirmed via smoke tests.
