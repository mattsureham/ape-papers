## Discovery
- **Idea selected:** idea_0513 — EU Trade Secrets Directive (2016/943) and business R&D. Chose over Ghana DDEP (SCM with N=1 country), Switzerland MuKEn (only 26 cantons), and others from a random draw of 10.
- **Data source:** Eurostat BERD (rd_e_gerdreg) at NUTS2, GDP (nama_10r_2gdp), transposition dates from CELLAR SPARQL. All open, no API keys needed.
- **Key risk:** Compressed transposition window (10 months) with annual data = only 2 effective cohorts.

## Execution
- **What worked:** CELLAR SPARQL gave exact transposition dates for all 28 countries. The balanced panel (83 regions) produced clean pre-trends and a clear null result. The heterogeneity gradient (low-protection positive, high-protection negative) gave the paper its most interesting substantive content.
- **What didn't:** The unbalanced panel was contaminated by biennial BERD reporters creating a saw-tooth composition artifact. Running CS on the raw panel gave a spuriously large positive (+0.42) with failed pre-trends. Debugging this was the critical methodological catch. Employment data from Eurostat also had hidden triplicates (EMP/SAL/SELF) that needed filtering.
- **Review feedback adopted:** Fixed text-table inconsistency in heterogeneity results (Table 5 showed -0.238 for high-protection but text said -0.053). Added justification for 431→83 region reduction. Noted that the high-protection coefficient is driven by only 2 treated countries.
