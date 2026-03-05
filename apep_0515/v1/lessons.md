## Discovery
- **Policy chosen:** England's 2016 National Living Wage (NLW) effect on care home closures — clear policy shock with predetermined geographic variation in bite intensity, understudied sector with inelastic demand
- **Ideas rejected:** Several UK labour policies considered but NLW + care homes had best data availability (CQC administrative register + NOMIS ASHE wages) and cleanest identification (continuous treatment DiD)
- **Data source:** CQC provider register (active + deactivated care homes 2012-2019) via data.gov.uk; ASHE median hourly wages via NOMIS API (NM_99_1, TYPE464 geography). NOMIS API worked reliably; CQC data required careful deactivation date parsing
- **Key risk:** Only 134 of 379 LAs matched between CQC and ASHE due to naming conventions; moderate power (MDE ~6pp vs point estimate ~4.6pp)

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-5.2, Grok-4.1-Fast, Codex-Mini passed; Gemini-3-Flash failed on contributor placeholder and table label issues)
- **Top criticism:** All three referees flagged "well-powered null" as overclaimed given MDE exceeds point estimate; LA fee-setting confounder identified as major omitted variable
- **Surprise feedback:** Gemini referee wanted LA fee controls from ADASS data as a control variable — a good suggestion but data not publicly available for this period
- **What changed:** Replaced "well-powered null" with "informative null" throughout; added Threat 3 (LA fee-setting confounder); added sample selection discussion (134 vs 379 LAs); added IQR-scaled magnitude to abstract; softened welfare calculation framing; added beds lost as formal Table 6; fixed all table labels and threeparttable wrapping

## Summary
- **Core finding:** Honest null — NLW had no statistically significant effect on care home closure rates despite strong first-stage wage effects. Point estimate suggests 7% increase but CI includes zero.
- **What worked well:** CQC administrative data gave complete universe of care homes (not a sample); continuous treatment DiD with HonestDiD sensitivity analysis added methodological credibility; sector focus (inelastic demand, regulated prices) made the null interesting
- **What could improve:** Care-worker-specific wages (SOC 4-digit) would sharpen bite measurement but not available at LA geography; LA fee data would address main confounder; longer pre-period would strengthen parallel trends (only 3 pre-treatment years)
- **Process note:** Advisor review caught important issues (contributor placeholders, table labels) that would have blocked publication; external referees provided substantive improvements to framing and threat identification
