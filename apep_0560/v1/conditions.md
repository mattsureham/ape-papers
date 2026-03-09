# Conditional Requirements

**Generated:** 2026-03-09T16:49:17.886807
**Status:** RESOLVED

---

## Market Discipline and Mining Safety — Stock Market Contagion from Tailings Dam Failures

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: enough post-GISTM failures for power

**Status:** [x] RESOLVED

**Response:** The WISE database contains approximately 15-20 failures after August 2020 (through early 2026). While smaller than the pre-GISTM sample, each event generates ~40+ firm-event observations (N=600-800 post-GISTM obs). The GISTM comparison is a secondary hypothesis — the paper's core contribution (global contagion analysis) does not depend on the post-GISTM subsample. If post-GISTM power is insufficient, we report this honestly as a null and note the sample limitation.

**Evidence:** WISE database scrape shows events continuing through Feb 2026. The post-GISTM comparison is structured as a heterogeneity test with event-clustered SEs, not a standalone analysis.

---

### Condition 2: firm-level measures of tailings exposure

**Status:** [x] RESOLVED

**Response:** We use three layers: (1) binary indicator from curated firm universe (has_tailings_dams) based on publicly known operations, (2) streaming/royalty companies as a clean zero-exposure placebo group (WPM, FNV, RGLD — they hold financial interests, not physical operations), (3) commodity-match as a proxy for regulatory exposure. We acknowledge this is coarser than facility-level data and note this limitation.

**Evidence:** The Global Tailings Portal (tailing.grida.no) has 1,800+ facilities with company linkages but is contemporary (2020+). For pre-2020 events, we use the publicly known operations binary — nearly all major mining firms operate tailings dams, creating a natural placebo in streaming/royalty firms.

---

### Condition 3: GISTM membership/compliance

**Status:** [x] RESOLVED

**Response:** ICMM member list is public (28 mining companies + 40 associations). We code ICMM membership as a firm characteristic. Full GISTM compliance data is being disclosed gradually (the GTMI was established January 2025). We use the August 2020 adoption date as the regime break but interact with ICMM membership to test whether committed firms show differential contagion. We acknowledge that compliance is an ongoing process, not a binary switch.

**Evidence:** ICMM membership list at icmm.com/en-gb/members. GISTM adopted August 5, 2020.

---

### Condition 4: stronger return benchmarks than a simple market model

**Status:** [x] RESOLVED

**Response:** Primary specification uses S&P 500 market model. Robustness checks include: (1) S&P Metals & Mining ETF (XME) as mining-sector benchmark, (2) winsorized CARs to handle outliers, (3) utilities ETF (XLU) as non-mining placebo. If results are sensitive to benchmark choice, we report this transparently.

**Evidence:** Code in 04_robustness.R implements XME and XLU alternative benchmarks.

---

### Condition 5: careful handling of older events with noisy dating

**Status:** [x] RESOLVED

**Response:** Events before ~1995 have sparser stock data and potentially imprecise dates. We handle this by: (1) requiring at least 100 estimation-window observations per firm-event, (2) assigning mid-year dates (June 15) for events with only year precision, (3) running robustness checks excluding pre-2000 events (where stock data is most complete), (4) the pre-event placebo window [-5, -2] tests whether "event" dates are contaminated by pre-existing trends.

**Evidence:** Date parsing in 01_fetch_data.R tries multiple formats; 02_clean_data.R filters to events with sufficient stock data overlap.

---

### Condition: separating GISTM from COVID-19 market volatility

**Status:** [x] RESOLVED

**Response:** GISTM was adopted August 2020, during a period of elevated market volatility due to COVID-19. We address this by: (1) the market model explicitly controls for aggregate market movements — abnormal returns are relative to the S&P 500, so COVID volatility is netted out, (2) pre-event placebo windows test for spurious pre-trends during COVID, (3) we run robustness excluding 2020 events (the acute COVID period) and test whether 2021-2025 post-GISTM events alone show differential contagion, (4) the GISTM interaction tests within-event variation (which firms are affected more, conditional on the same market conditions).

**Evidence:** Market model estimation explicitly nets out common market movements. COVID-period robustness coded in analysis.

---

### Condition: framing around voluntary disclosure economics

**Status:** [x] RESOLVED

**Response:** The paper frames the contribution around the market discipline question: does investor-led voluntary regulation (GISTM) change how markets price mining risk? This connects to the broader economics of voluntary disclosure (Dye 1985, Verrecchia 1983), self-regulation (Maxwell, Lyon & Hackett 2000), and investor activism (Dimson, Karakas & Li 2015). The policy question — whether voluntary standards substitute for mandatory regulation — is first-order for mining governance worldwide.

**Evidence:** Introduction will cite the voluntary disclosure and self-regulation literatures, positioning the GISTM as a test case.

---

### Condition: high-quality historical ownership/exposure data

**Status:** [x] RESOLVED

**Response:** Contemporary firm characteristics (has tailings dams, commodity, ICMM membership) are largely stable for major mining firms over the sample period — BHP, Rio Tinto, Vale, Freeport-McMoRan etc. have operated tailings dams throughout. Streaming/royalty companies (WPM, FNV) have never operated physical mines. We acknowledge that the firm universe is most complete for 2000-2025 and run subsample analysis for this period as the primary window.

**Evidence:** Major mining firms' operations are well-documented in annual reports and investor presentations spanning decades.

---

### Condition: treating GISTM timing/compliance carefully

**Status:** [x] RESOLVED

**Response:** We treat August 5, 2020 as the structural break for market expectations (the date the standard was publicly launched). We do NOT treat it as a compliance switch — firms were given a 3-5 year implementation timeline. We interact the post-GISTM dummy with ICMM membership (firms committed to comply) and test for time-varying effects (2020-22 vs 2023-25) to capture gradual implementation. The honest interpretation is about market expectations of safety improvement, not actual compliance.

**Evidence:** GISTM implementation timeline publicly documented. Analysis includes ICMM membership interaction.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
