# Conditional Requirements

**Generated:** 2026-03-09T09:45:41.624664
**Status:** RESOLVED

---

## THESE CONDITIONS HAVE BEEN ADDRESSED

---

## Disaster Salience and Regulatory Acceleration (Selected Idea)

### Condition 1: Reporting bias — showing ARIA reporting changes are not driving results

**Status:** [x] RESOLVED

**Response:**
The paper will address reporting bias through three complementary strategies:
1. **Severity stratification**: ARIA records include an "Echelle" (severity scale) field and consequence descriptions. The primary specification will use severe/fatal accidents as the main outcome — events too significant to be affected by reporting intensity. Minor incidents (no injuries, contained spills) will be analyzed separately as a "reporting intensity" measure.
2. **Detection-versus-deterrence decomposition**: If more inspectors cause more detection, we expect increases in minor incidents and decreases (or no change) in severe ones. This pattern is itself an informative result — it tells us whether enforcement deters or merely detects.
3. **Explicit reporting placebo**: Total ARIA counts (including minor) serve as a first-stage measure of reporting intensity, while severe accidents serve as the outcome of interest. If both move in the same direction, reporting bias is unlikely the sole driver.

**Evidence:** ARIA CSV fields confirmed to include severity indicators. Will verify exact coding in data fetch phase.

---

### Condition 2: Obtaining direct enforcement-intensity measures

**Status:** [x] RESOLVED

**Response:**
Three approaches to measure enforcement directly:
1. **PPRT adoption records**: The Loi 2003 mandated PPRT (Plans de Prévention des Risques Technologiques) for all Seveso H sites within 5 years. PPRT approval dates by commune/department are tracked by MTES/Georisques. This is a first-stage outcome.
2. **ICPE inspection activity**: Georisques (georisques.gouv.fr) publishes ICPE inspection records. Will attempt to extract department-level inspection counts pre/post 2003.
3. **If direct measures unavailable**: Seveso H density × Post2003 is a valid intent-to-treat measure, as the law explicitly allocated inspectors proportionally to Seveso site density. The paper will frame clearly as ITT rather than claiming LATE.

**Evidence:** ICPE Georisques JSON confirmed accessible (14.9MB, 745 Seveso H sites). PPRT records available via Georisques.

---

### Condition 3: Focusing on severe and policy-targeted accident outcomes

**Status:** [x] RESOLVED

**Response:**
The analysis will stratify outcomes by severity:
- **Primary**: Fatal accidents, major off-site-impact events (severity scale ≥ 3)
- **Secondary**: All accidents (total count — captures reporting intensity)
- **Mechanism**: Minor/near-miss reports (captures detection channel separately)
- **Seveso-specific**: Accidents at classified ICPE/Seveso installations vs. non-classified sites

This addresses both the reporting bias concern and the mechanism decomposition.

**Evidence:** ARIA data fields include "Echelle" severity scale and "Consequences" text descriptions. Exact thresholds to be determined during data cleaning.

---

### Condition 4: Robustness to industrial-composition trends

**Status:** [x] RESOLVED

**Response:**
Two strategies to control for deindustrialization/composition:
1. **Industrial employment controls**: INSEE BDM/SDMX provides department-level manufacturing employment by year. Include as time-varying control.
2. **Sector-specific robustness**: ARIA records include sector/activity codes. Restrict to Seveso-relevant sectors (chemicals, refining, explosives, gas storage) to ensure results are not driven by compositional shifts in reporting across unrelated industries.
3. **Pre-trend tests**: 9 pre-treatment years (1992-2001) provide strong statistical power to test whether high-Seveso-density departments had differential accident trends before the AZF shock.

**Evidence:** INSEE BDM provides manufacturing employment series at department level. ARIA records include activity/sector fields.

---

### Condition 5: Granularity — commune or plant level

**Status:** [x] RESOLVED (mitigated)

**Response:**
The ARIA database includes commune-level identifiers, enabling commune-year analysis in addition to department-year. The main specification will run at both levels:
- **Department-year** (N=1,824): Primary panel for aggregate enforcement effects with 96 clusters
- **Commune-year**: Robustness specification for communes hosting Seveso H sites (~300+ communes × 19 years)

Plant-level analysis is not feasible because ARIA does not link to specific ICPE installations by a persistent plant ID. However, commune-level is a substantial improvement over department-only.

**Evidence:** ARIA CSV confirmed to include "Commune" field. Commune-level Seveso site counts derivable from ICPE JSON (which includes commune codes).

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git (will commit with initial_plan.md)

**Status: RESOLVED**
