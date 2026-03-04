# Human Initialization
Timestamp: 2026-03-03T12:00:00Z

## Launch Prompt

> write a paper on france. Question: What is the causal return to actually attending an ultra-elite school (ENS) versus being essentially equally strong but not admitted? explore something different but adjacent if the data is not available

## Contributor (Immutable)

**GitHub User:** @olafdrw

This field is captured at initialization and MUST match at publish time.

## System Information

- **Claude Model:** claude-opus-4-6

## Questions Asked

1. **Country:** Which country?
   - Options: USA, France, India, Switzerland, Nigeria, United Kingdom, Other

**France Path:**
2. **Method:** Which identification method?
3. **API keys:** Are French API credentials configured? (INSEE Sirene, PISTE/Légifrance)
4. **External review:** Include external model reviews?
5. **Other preferences:** Any other preferences or constraints?

## User Responses

1. France (specified in launch prompt)
2. RDD (Recommended) — "Regression discontinuity — natural fit for exam score cutoffs at elite schools like ENS"
3. Yes — "INSEE Sirene, PISTE/Légifrance credentials are in .env"
4. Yes (Recommended) — "Tri-model hybrid reviews for quality assurance"
5. Go broad on grandes écoles — "Any elite school threshold design in France — ENS, ENA, Polytechnique, HEC, etc."

## Setup Results

- **Country:** France
- **Domain:** Education / Elite schools / Grandes écoles
- **Method:** RDD
- **Data era:** Modern
- **Risk appetite:** Novel angle (classic data + new question: elite school access → housing markets)
- **Other preferences:** Broad on grandes écoles; pivot to adjacent topic if individual exam data unavailable
