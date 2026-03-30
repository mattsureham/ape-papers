## Discovery
- **Idea selected:** idea_0738 — UI administrative capacity erosion during the Great Recession
- **Data source:** DOL BTQ (timeliness), Census QWI (Bartik shares), ASPEP (govt staffing), ETA 539 (claims)
- **Key risk:** BTQ data turned out to be annual, not monthly — severely limits power

## Execution
- **What worked:** Strong first stage (F=68), clean Bartik construction, significant interaction result
- **What didn't:** The main 2SLS is null and wrong-signed. Annual frequency limits identification. The thinness proxy (total govt FTE) is too broad — UI-specific staffing would be stronger. BTQ API ignores month parameters.
- **Review feedback adopted:** Toned down causal claims, fixed table rounding, better explained magnitude calculations, discussed thick-state positive sign
- **Lesson for future:** Check data frequency BEFORE committing to an idea. Monthly BTQ data is essential for this research question but not available through the POST API. Also, broad administrative capacity proxies don't substitute for program-specific staffing measures.
