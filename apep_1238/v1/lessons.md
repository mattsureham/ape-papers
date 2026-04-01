## Discovery
- **Idea selected:** idea_2051 — Hill-Burton hospital infrastructure and Medicare spending
- **Data source:** CMS Geographic Variation PUF + Hospital Compare — data.json catalog was key to finding download URLs on CMS's JavaScript-rendered site
- **Key risk:** Exclusion restriction for state-level instrument; balance tests confirm it predicts covariates

## Execution
- **What worked:** CMS data is rich (247 variables, 10 years of county-level Medicare spending). OLS-IV sign reversal is clean and tells a compelling story about selection bias in hospital competition research.
- **What didn't:** County-level Hill-Burton data from HathiTrust proved inaccessible for automated extraction. State-level income proxy is coarse and fails the exclusion restriction. Equal-share HHI is crude.
- **Review feedback adopted:** State-level clustering for SEs (F drops from 28.2 to 8.4), weakened IV claims to "suggestive," added explicit magnitude-implausibility discussion for binary specification.
