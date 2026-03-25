## Discovery
- **Idea selected:** idea_1022 — Swiss CO2 Act referendum rejection and compensatory cantonal climate action
- **Data source:** BFS GWR (new buildings by canton) + manually coded referendum results and cantonal legislation dates
- **Key risk:** BFS API was completely unresponsive for heating data; pivoted to construction as proxy

## Execution
- **What worked:** The political economy framing (compensatory federalism) is clean and compelling. Cross-sectional R²=0.40 for policy adoption is striking. The mechanism split (adopters vs non-adopters) strongly supports the legislative channel.
- **What didn't:** BFS PXWeb API returned 400 errors for all GWR heating tables. Spent ~20 minutes debugging before pivoting. Municipal-level analysis was infeasible without heating data.
- **Review feedback adopted:** Added mechanism test (adopter split showing β=2.15 vs -0.58), probed the 2018 pre-trend blip (excluding 2018 leaves result unchanged at 1.40), and moderated decarbonization claims per reviewer suggestions.
