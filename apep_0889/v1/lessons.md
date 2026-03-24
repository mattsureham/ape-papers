## Discovery
- **Idea selected:** idea_1757 — USPS postal infrastructure × democratic participation. Novel intersection of voting costs and infrastructure literatures.
- **Data source:** BLS QCEW (NAICS 491110) for USPS establishments; MIT Election Lab for county presidential returns; Census ACS for demographics. QCEW API only available 2014+, limiting pre-treatment observation of establishment counts.
- **Key risk:** Endogeneity of USPS closures — RAOI targeted low-volume offices in declining communities.

## Execution
- **What worked:** QCEW API provided clean county-level USPS establishment panel (3,263 counties, 2014-2023). MIT Election Lab data was comprehensive (7 presidential elections, 2000-2024). CS-DiD with HonestDiD gave honest bounds.
- **What didn't:** Pre-existing convergence trend undermined causal identification (parallel trends pre-test p=0.004). EAVS mail-ballot data was too thin for panel analysis. Treatment measurement via net QCEW establishment changes is noisy.
- **Review feedback adopted:** Toned down causal language in conclusion. Added explicit caveats about measurement error, external validity, and what the study can/cannot claim.

## Key Takeaway
QCEW establishment counts are a useful proxy for institutional presence but too noisy for sharp causal designs. Pre-trends in county-level turnout data run deep — larger counties have been converging toward smaller ones for decades. Future work should use geocoded closure data and mail delivery performance metrics rather than net establishment counts.
