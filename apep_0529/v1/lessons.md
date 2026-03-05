## Discovery
- **Policy chosen:** French ZFE (low-emission zones) — uniquely enables multi-level political conflict measurement with staggered national mandates and rich open data at both national (roll-call, debates) and local (elections, ZFE boundaries) levels.
- **Ideas rejected:** Standalone spillback test (Idea 2, too narrow for top journal) and spatial DiD on green backlash (Idea 3, SUTVA violation from commuter spillovers, endogenous boundaries).
- **Data source:** Assemblee nationale open data (votes JSON, debates XML), data.gouv.fr aggregated elections (Parquet), transport.data.gouv.fr BNZFE (GeoJSON), Geodair air quality (CSV/API). All confirmed accessible, no auth for core sources.
- **Key risk:** Endogeneity of air-quality mandate timing (bigger/more polluted cities have different political trajectories). Mitigated by using population threshold as primary treatment rule and pre-2015 pollution for classification.

## Review
- **Advisor review**: GPT-5.2 persistently flags @CONTRIBUTOR_GITHUB placeholders (structural false-positive, filled at publish). Gemini-3-Flash finds new issues each round. Grok and Codex consistently PASS.
- **Pre-trends dominate**: With 59 treated units (France's largest metros), parallel trends are fundamentally violated. Urban-rural cleavage drives everything. Future France papers should use within-metro designs or population threshold RDD.
- **CS-DiD is underpowered**: Only 2 post-treatment elections (2022, 2024) for Wave 1. MDE for ENP is huge (SE=0.141 on a ~5-point scale).
- **Climate vote table bug**: Always verify weighted averages match row-level data (adoption rate was 49.3%, not 66.6%).
- **All 3 external referees**: MAJOR REVISION. Core concern: violated pre-trends + need for honest DiD bounds (Rambachan-Roth), treatment heterogeneity (binding vs vigilance ZFEs), and residential sorting test.

## Summary
The paper's contribution is showing that naive DiD of spatially-targeted environmental policy produces spurious "polarization" effects driven by pre-existing urban-rural cleavages. The null ENP result and suggestive 5.3pp RN decline are honest findings but limited by violated pre-trends and short post-treatment windows. Key lesson: ambitious question + honest methodology can succeed even with null primary results, if the framing adds value.
