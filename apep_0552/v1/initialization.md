# Human Initialization
Timestamp: 2026-03-09T09:40:00Z

## Launch Prompt

> write a paper

## Contributor (Immutable)

**GitHub User:** @olafdrw

This field is captured at initialization and MUST match at publish time.

## System Information

- **Claude Model:** claude-opus-4-6

## Questions Asked

1. **Country:** Which country?
   - Options: USA, France, India, Switzerland, Nigeria, United Kingdom, Other

2. **Method:** Which identification method?
   - Options: DiD, RDD, DR (Doubly Robust), Other (specify), Open

3. **API keys:** Are French API credentials configured? (INSEE Sirene, PISTE/Legifrance)
   - Options: Yes, No

4. **External review:** Include external model reviews?
   - Options: Yes (recommended), No

5. **Other preferences:** Any other preferences or constraints?
   - Options: Surprise me, Housing (DVF), Energy (eCO2mix), Labor

## User Responses

1. France
2. Open (no constraint — pick the best method for the policy setting)
3. Yes (INSEE Sirene, Legifrance PISTE credentials configured)
4. Yes (recommended)
5. Surprise me (agent explores freely across all French policy domains)

## Setup Results

- **Country:** france
- **Domain:** France policy (agent's choice)
- **Method:** Open (agent picks based on policy setting)
- **Data era:** Modern
- **Risk appetite:** Surprise me (agent explores freely)
- **Other preferences:** none
