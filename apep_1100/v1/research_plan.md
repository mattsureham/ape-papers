# Research Plan: The Lottery of Legal Licensing

## Research Question
How much of the geographic disparity in Italian bar exam pass rates (26–73%) reflects examiner leniency vs. candidate quality?

## Institutional Setting
Italy's bar exam (esame avvocato) assigns grading commissions to candidate pools via a public lottery (sorteggio). ~20,000 candidates sit at 26 Courts of Appeal annually. After written exams, a central commission draws lots to pair courts within 5 size tiers (fasce). Anonymous papers from Court X are shipped to Court Y for correction. This means the same candidate population faces different grading standards depending on the lottery draw.

## Identification Strategy
The sorteggio randomizes grading court assignment within tiers. The key estimating equation:

PassRate_{candidate_court c, year t} = α_c + β * GradingCourtLeniency_{g(c,t)} + γ_t + ε_{ct}

where g(c,t) is the lottery-assigned grading court. GradingCourtLeniency is the leave-one-out mean pass rate when court g grades other courts' papers (excluding the current observation).

### Balance Tests
- Sorteggio pairings should be uncorrelated with predetermined characteristics within tiers
- Candidate counts should not predict grading court assignment

### Main Analysis
1. Variance decomposition: candidate-court FE vs grading-court leniency
2. Grading court leniency → pass rate (OLS with candidate-court + year FE)
3. Heterogeneity: small vs large courts, North vs South

### Placebos
- Self-grading courts (Bolzano) as natural placebo
- Year-to-year within-court pass rate variation explained by grading court rotation

## Data
1. Sorteggio pairings: Ministry of Justice verbales (2017-2025)
2. Pass rates: formazionegiuridica.org + legal news aggregators (2016-2024)
3. Court characteristics: Cassa Forense lawyer counts, ISTAT income

## Data Limitation
COVID 2020-2022 switched to oral format (doppio orale). Will include with format FE and test robustness excluding those years.

## Expected Results
Grading court leniency explains a substantial share of cross-court pass rate variation. This implies the licensing gate is partially arbitrary — determined by lottery, not competence.

## Scope (V1 / AER: Insights)
- Focus on sorteggio + pass rate decomposition
- Do NOT attempt downstream labor market effects (save for V2)
- Keep paper tight: 8-10 pages
