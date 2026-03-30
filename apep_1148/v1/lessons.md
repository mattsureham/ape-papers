## Discovery
- **Idea selected:** idea_2063 — Medicare RHC 50-bed payment notch creates dramatic bunching
- **Data source:** CMS HCRIS Form 2552-10 cost reports, FY2012-2023 — required downloading 13 individual FY zip files from CMS
- **Key risk:** Mechanism attribution (bunching at 50 may reflect other regulations or round-number heaping, not just RHC payment rules)

## Execution
- **What worked:** The bunching is dramatic and immediately visible in raw data (5.7:1 drop at 50→51 beds). Kleven-style polynomial estimation is clean and produces stable results across specifications. The BBA pre/post comparison provides a natural experiment that yields an informative null.
- **What didn't:** Cannot directly link bunching to RHC-affiliated hospitals — would need CMS RHC enrollment data linkage. HCRIS data comes as per-FY zip files (not cumulative), requiring iteration over 13 downloads. The initial attempt to download a single cumulative file failed.
- **Review feedback adopted:** Added back-of-envelope revenue calculation (~$200K-$500K per hospital), strengthened institutional detail on bed count manipulation feasibility, reframed BBA null as "regulatory anticipation" finding, clarified 5.7:1 (pooled) vs 7.2:1 (2023) ratios, tempered causal language about capacity distortion.
