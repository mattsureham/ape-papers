# Research Plan: The Carboniferous Lottery

## Research Question

Does surface coal mining cause worse environmental and health outcomes than underground mining? The existing literature (Hendryx and colleagues) documents strong cross-sectional associations between Appalachian coal mining and mortality, but cannot distinguish surface from underground mining effects, nor address selection into mining method.

## Identification Strategy

**Instrumental Variables (2SLS).** Instrument: average coal seam depth from USGS NCRDS drill-hole data (~254,000 drill points, 1M+ coal unit records). Coal seam depth was determined by Carboniferous-era sedimentation ~300 million years ago and subsequent tectonic deformation. Surface mining becomes uneconomical above ~200ft overburden depth (20:1 stripping ratio), creating a sharp engineering threshold.

**First stage:** County-level average depth-to-top-of-seam → share of coal production from surface mining.

**Reduced form:** County-level seam depth → water quality / mortality.

**Second stage:** Instrumented surface mining share → outcomes.

## Expected Effects and Mechanisms

Surface mining (especially mountaintop removal) involves:
1. Removal of overburden and vegetation → sediment runoff → elevated specific conductance and selenium in streams
2. Valley fills burying headwater streams → permanent hydrological disruption
3. Airborne particulate matter from blasting → respiratory and cardiovascular disease
4. Chemical leachate from exposed coal seams → groundwater contamination

We expect: surface mining share ↑ → specific conductance ↑, selenium ↑, mortality ↑ (lung cancer, cardiovascular, kidney), low birth weight ↑.

## Exclusion Restriction

Coal seam depth affects outcomes ONLY through mining method. Threats and responses:
1. **Depth ↔ total reserves:** Control for estimated reserves (EIA coal production data)
2. **Depth ↔ coal quality:** Control for sulfur content, BTU (USGS COALQUAL)
3. **Depth ↔ topography:** Control for ruggedness, elevation, slope (USGS NED). Within the coal basin, depth varies from geological structure (anticlines vs synclines) at similar elevations.
4. **Natural leaching:** Negligible compared to mining disturbance; placebo counties confirm.

## Primary Specification

Cross-sectional 2SLS at county level:

**First stage:**
SurfaceShare_c = α + γ · AvgSeamDepth_c + X_c'δ + State_FE + ε_c

**Second stage:**
Y_c = β₀ + β₁ · SurfaceShare_c_hat + X_c'β₂ + State_FE + u_c

Controls (X_c): log population, median income, percent Black, percent poverty, elevation, ruggedness, total coal production, coal quality (sulfur, BTU), state fixed effects.

Clustering: State level (conservative, ~6-8 Appalachian coal states).

## Placebo Tests

1. **Ceased-mining counties:** In counties where all mining ceased before 1970 (before modern surface mining), seam depth should NOT predict current water quality.
2. **Unrelated outcomes:** Motor vehicle mortality, diabetes prevalence — should be unrelated to seam depth conditional on controls.
3. **Upstream/downstream:** Water quality should deteriorate downstream of surface mines but not upstream.

## Data Sources and Fetch Strategy

| Data | Source | Method | Unit |
|------|--------|--------|------|
| Coal seam depth | USGS NCRDS USTRAT | Bulk download or API | Drill hole → county avg |
| Mining method | MSHA Mines dataset | Download CSV (msha.gov) | Mine → county share |
| Coal production | EIA Annual Coal Reports | API/download | Mine → county total |
| Water quality | Water Quality Portal | REST API | Monitoring station → county/HUC-8 |
| Mortality | CDC WONDER | API | County-year |
| Birth outcomes | CDC WONDER Natality | API | County-year |
| Topography | USGS NED (summary stats) | Derived from existing | County |
| Demographics | Census ACS | Census API | County |

## Sample

~100-200 coal-producing counties in the Appalachian coal basin (WV, KY, VA, PA, OH, TN, AL), where geological variation in seam depth is strongest.

## Key Risks

1. **Sample size:** ~100-200 counties is modest. Mitigate with HUC-8 watershed alternative unit.
2. **Spatial correlation:** Nearby counties share geology. Mitigate with Conley spatial HAC standard errors.
3. **Multiple testing:** Many outcomes. Present primary outcome (specific conductance) prominently; others as mechanism tests.
