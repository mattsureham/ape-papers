## Discovery
- **Idea selected:** idea_0073 — EU smoking bans and hospitality employment
- **Data source:** Eurostat nama_10_a10_e — fast, reliable
- **Key risk:** NACE G-I is broader than just hospitality (includes trade/transport)

## Execution
- **What worked:** CS-DiD cleanly handles staggered adoption where TWFE would be confounded by the financial crisis. Strong null finding with clear narrative.
- **What didn't:** Eurostat API requires explicit country codes (won't return all countries without geo filter). The NACE A*10 sector G-I aggregation is too broad — ideally we'd have I (hospitality) alone, but A*64 employment data would need separate queries.
- **Key finding:** Precisely estimated null (-1.6%, SE = 2.8%). Industry predictions were wrong across 18 countries. The "regulatory cost fallacy" label gives the paper a memorable object.
