## Discovery
- **Idea selected:** idea_2239 — Eisensee-Strömberg competing-news IV applied to congressional oversight hearings
- **Data source:** GovInfo API (62K hearings) + Google Trends (scandal salience proxy) + pre-determined mega-event calendar
- **Key risk:** TV closed-caption data (Internet Archive) not programmable accessible; BigQuery ADC not set up; pivoted to Google Trends

## Execution
- **What worked:** GovInfo API POST search is excellent for hearing data. 19 agencies × 16 years = rich panel. The asymmetric finding (divided vs unified government) is genuinely novel and more interesting than the original hypothesis.
- **What didn't:** BigQuery GDELT not available (no ADC credentials on this machine). Internet Archive TV News API doesn't support caption-level search. Google Trends is a noisy proxy with missing data for some agencies.
- **Review feedback adopted:** Strengthened threats to validity section (impeachment endogeneity, political cycle confounding). Acknowledged weak first stage for IV. Noted Olympics-only specification as purest instrument.
- **Surprise finding:** The "scandal timing lottery" sign-switches by government structure — opposition parties INCREASE oversight during mega-events (exploiting the distraction), while majority parties DECREASE it. This is more interesting than a uniform media displacement effect.
