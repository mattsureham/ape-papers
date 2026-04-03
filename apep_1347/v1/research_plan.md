# Research Plan: The Regulatory Anatomy of US Hospitals — A Bunching Atlas of Medicare Payment Thresholds

## Research Question
Do Medicare payment discontinuities at 25, 50, and 100 hospital beds cause systematic capacity distortion? Which threshold generates the most bunching per dollar of payment differential? How much of the observed bed distribution reflects regulatory response versus cognitive round-number heaping?

## Institutional Background
Three distinct Medicare payment programs create sharp notches:

1. **CAH at 25 beds** (BBA 1997, MMA 2003): 101% cost-based reimbursement vs PPS.
2. **RHC/REH at 50 beds** (BBA 2018, CAA 2021): RHC per-visit cap exemption; REH conversion eligibility.
3. **DSH at 100 beds** (42 CFR 412.106): Large urban DSH formula for uncompensated care.

## Identification Strategy
Multi-threshold bunching estimation (Kleven 2016) with heaping decomposition.
- Running variable: total facility bed count (integer)
- Joint decomposition: regulatory bunching at 25/50/100 + round-number heaping at multiples of 5/10
- Placebos: non-regulatory round numbers, urban-only subsample at 25 beds, pre-2003 at 15 beds

## Data Source
CMS Provider of Services (POS) file + HCRIS Form 2552-10.
~6,000 hospitals/year, FY2010-2023, ~84,000 hospital-year observations.
