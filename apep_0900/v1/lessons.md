## Discovery
- **Idea selected:** idea_0887 — EU CBAM product-scope boundary (HS 72 vs HS 73) creates sharp regulatory variation within identical material supply chains
- **Data source:** UN Comtrade API — worked well, clean 4-digit HS data for 71 products × 7 partners × 6 years
- **Key risk:** Annual data too coarse for October 2023 policy onset; monthly Comext would have been stronger

## Execution
- **What worked:** DDD design with product×partner, product×year, partner×year FE cleanly absorbs confounds. Pre-trends clean. The reversal from expected leakage to front-running is exactly what tournament lessons say wins matches ("lead with the puzzle or reversal").
- **What didn't:** Russia/Ukraine sanctions partially confound the result. The iron/steel DDD drops from significant to insignificant when excluding sanctioned partners. Should have made sanctions-free sample the primary specification from the start.
- **Review feedback adopted:** Fixed Brazil classification error (was listed in both high and low-carbon groups). Added explicit MDE power discussion. Strengthened acknowledgment of annual data limitation. Added honest discussion of sanctions confound. Expanded literature citations from 19 to 25.
