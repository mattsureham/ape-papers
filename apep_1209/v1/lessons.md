## Discovery
- **Idea selected:** idea_2099 — Illinois cannabis dispensary license lotteries and property values. Selected for lottery-based identification and strong microdata accessibility via Socrata APIs.
- **Data source:** IDFPR Socrata API (dispensaries), Cook County Assessor (property sales), Chicago PD (crime). All free, no API keys needed.
- **Key risk:** Zip-centroid geocoding of dispensaries introduces measurement error that attenuates estimates.

## Execution
- **What worked:** The Socrata APIs delivered clean data quickly. Merging old and new Cook County datasets via PIN provided geocoordinates for 26,740 sales spanning 2019-2025. The DiD framework with dispensary-cluster FE was straightforward to implement.
- **What didn't:** The lottery identification promise was stronger than what the DiD could deliver. All three reviewers noted that the lottery randomizes who gets a license, not where they open (post-draw site selection). A true spatial IV using loser proposed locations would be needed for the strongest claim. Also, the Cook County data comes in two separate vintages with different schemas — required PIN-based coordinate matching that reduced the sample.
- **Review feedback adopted:** Toned down identification claims — the lottery provides supportive context, not decisive identification. Added explicit discussion of post-draw site selection endogeneity. Made the limitations paragraph more prominent. Changed drug crime percentage from 29% to 34% (correct exp(0.29)-1 conversion).
