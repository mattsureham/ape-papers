## Discovery
- **Idea selected:** idea_0220 — India's 2023 rice export ban; irresistible framing (40% of global trade removed overnight), clean within-market across-commodity identification, massive WFP dataset
- **Data source:** WFP HDX yearly files (2021-2025) + FAO Detailed Trade Matrix. The global WFP dataset was outdated (only to 2021); the yearly files updated weekly were the correct source. COMTRADE API returned 401 (subscription auth), but FAO bilateral trade data was a perfect substitute.
- **Key risk:** Rice commodity classification in WFP includes all varieties (local, imported, basmati, parboiled), not just the banned non-basmati white rice. This attenuates the estimate conservatively.

## Execution
- **What worked:** The within-market, across-commodity DiD with market×time + country×commodity FE was extremely effective. Country×commodity FE were critical — without them, the cross-national commodity price level differences overwhelmed the signal. The FAO bilateral trade data gave clean treatment intensity variation across 195 countries.
- **What didn't:** The event study specification with market×time FE and interacted event dummies was tricky — collinearity absorbed the rice indicator. Had to use control commodity coefficients (flipped sign) to show the pattern. Wild cluster bootstrap failed due to singleton FE issues.
- **Review feedback adopted:** Clarified estimating equation (which terms absorbed by FE), explained Column 3→4 FE jump, added reversal test discussion, addressed rice variety measurement concern, fixed abstract to clarify coefficient units.
