## Discovery
- **Idea selected:** idea_1896 — America's first minimum wage laws (1912-1920) targeted women in specific industries; MLP linked census panel enables individual-level DDD
- **Data source:** IPUMS MLP 1910-1920 on Azure (43.9M individuals) — flawless access, no API issues
- **Key risk:** Only two census cross-sections limits pre-trend testing; addressed via 1900-1910 placebo panel

## Execution
- **What worked:** Azure MLP data pipeline is extremely reliable; 1.6M-woman estimation sample was well-powered; built-in placebo (men, exempt industries) provided clean falsification
- **What didn't:** Raw DDD of +7.8pp was misleading — driven by state composition, not policy. With state/industry FEs, effect shrinks to <1pp. Smoke test numbers from idea manifest should be treated cautiously
- **Review feedback adopted:** Added 1900-1910 pre-treatment placebo (null, supporting parallel trends); added enforcement heterogeneity split (advisory vs mandatory); added footnote clarifying DD/DDD terminology for panel cross-section
- **Key insight:** The null result IS the finding — well-powered zeros with 1.6M observations, ruling out effects >3.4pp. Tournament lessons confirm "nulls can win when they are definitive and central"
