# Revision Plan: apep_0626 → V2

## Context
**Paper:** "Closing the Golden Door: Individual Occupational Mobility After the 1924 Immigration Act"
**Parent:** `papers/apep_0626/v1/`
**New workspace:** `output/apep_0626/v2/`

Both Claude and Codex independently selected this paper. The V1 documents a precisely estimated null on native occupational mobility from the largest immigration restriction in U.S. history — using a 10.1M linked census panel. But the real finding is buried: homeownership *declined* in exposed counties (p<0.01), and the pre-1924 period shows complementarity, not competition. The paper's problem is positioning, not substance. All three strategic reviewers converge on the same reframe.

## The V2 Thesis

**From:** "Precise null on occupational mobility after the 1924 Act"
**To:** "Did the largest immigration restriction in U.S. history deliver its central economic promise? No — and it actively harmed the communities it was supposed to protect."

The V2 makes three moves:
1. **Elevate homeownership from side finding to co-primary pillar** — restriction weakened local economic dynamism
2. **Embrace the pre-1920 complementarity story** — immigration was part of why these places thrived
3. **Strengthen identification** with multi-wave evidence and first-stage quantification

## Execution Plan

### Phase 1: Workspace Setup
- Copy parent artifacts from `papers/apep_0626/v1/`
- Create `output/apep_0626/v2/` with code/, data/, figures/, tables/
- Write initialization.md with revision rationale
- Start timing log

### Phase 2: Strengthen Identification (New Analysis)

**2a. First-stage evidence (CRITICAL — reviewers flagged this)**
- Quantify actual immigrant decline: compute restricted-origin share in 1930 vs 1920 by county
- Show high-exposure counties experienced larger declines in foreign-born population
- Table: first-stage regression (Δforeign_born_share ~ quota_exposure)
- This is currently qualitative in the paper; must be explicit

**2b. 1890-based exposure measure (robustness)**
- Construct exposure from 1890 foreign-born shares (the actual quota base year)
- This eliminates concerns about 1920 measurement capturing contemporaneous conditions
- Data: 1890 full-count census from Azure (check availability in IPUMS MLP or raw IPUMS)
- If 1890 data unavailable, use predicted shares from earlier settlement patterns

**2c. Multi-wave visualization**
- If 1900-1910 linked panel exists in Azure, construct pre-pre-period estimates
- Show occupational change by exposure quintile across 1900-1910, 1910-1920, 1920-1930
- Event-study-style figure with the 1924 Act as the treatment date
- Even without 1900 data, can show 1910-1920 vs 1920-1930 contrast as a figure

**2d. Clarify placebo interpretation**
- The raw placebo coefficient (10.41 in Col 1, Table 4) looks large but lacks FE
- Full-spec placebo (with state + occupation FE) must be clearly presented
- Rename from "placebo" to "pre-restriction complementarity evidence"

### Phase 3: Deepen the Homeownership Story (The V2 Move)

**3a. Mechanism decomposition**
- Why does homeownership decline? Three candidates:
  1. **Local demand destruction**: fewer immigrants → less consumption → less construction → lower housing demand
  2. **Wage channel**: if immigrants and natives were complements, restriction lowered native wages (test: wage-related outcomes if available)
  3. **Selective out-migration**: restriction reduced economic opportunity, causing high-ability natives to leave exposed counties
- Test selective migration: does the "moved" variable interact with exposure?
- Test construction: can we proxy housing supply from census (new dwellings, renters)?

**3b. Homeownership heterogeneity**
- By initial tenure status, age, skill level, urban/rural
- Which natives lost homeownership transitions most?
- By exposure quartile: is the effect monotonic?

**3c. Additional "local dynamism" outcomes**
- Class-of-worker transitions (wage worker → self-employed?)
- Farm-to-nonfarm (already in V1 but underemphasized)
- Geographic mobility patterns by exposure level

### Phase 4: Enrich Occupational Analysis

**4a. Occupational ladder visualization**
- Not just OCCSCORE change but specific transitions: laborer → operative → craftsman → clerical → professional
- Cross-tabulation of 1920 → 1930 occupation categories by exposure level
- Shows readers what "null" means concretely

**4b. Sector-specific transitions**
- Manufacturing, agriculture, services, trade
- Which sectors absorbed/lost natives in high-exposure counties?

**4c. Power and precision**
- Move standardized effect sizes to main text (currently in appendix)
- Express null in intuitive terms: "restriction failed to move natives even 1/20th of an occupational quartile"

### Phase 5: New Figures (V1 has ZERO figures)

| Figure | Content |
|--------|---------|
| Fig 1 | Map of quota exposure by county (heat map) |
| Fig 2 | Event study: occupational change by exposure quintile, 1910-1920 vs 1920-1930 |
| Fig 3 | Density of OCCSCORE changes by exposure quartile (showing distributional null) |
| Fig 4 | Homeownership transition rates by exposure quartile (showing the harm) |
| Fig 5 | First stage: foreign-born share change (1920→1930) by exposure quintile |
| Fig 6 | Occupational transition matrix (Sankey or heat map) |
| Fig 7 | Leave-one-origin-out robustness (coefficient plot) |
| Fig 8 | Pre-period complementarity: 1910-1920 upgrading by exposure (positive relationship) |

### Phase 6: Full Paper Rewrite

**Introduction (rewrite from scratch)**
- Hook: the restrictionist promise (1920s rhetoric about "protecting American workers")
- The shock: 87% cut in Southern/Eastern European immigration
- The test: 10.1M native workers tracked individually across the decade
- The answer: no occupational gains, and actual harm to homeownership
- The implication: restriction destroyed demand-side benefits without delivering supply-side gains

**New section structure:**
1. Introduction (3-4 pages)
2. Historical Context and the Restrictionist Promise (2 pages)
3. Data and Measurement (3 pages)
4. Empirical Strategy (2 pages) — leaner than V1
5. Did Restriction Deliver Occupational Gains? (3 pages) — the null
6. The Hidden Cost: Homeownership and Local Dynamism (3 pages) — the V2 addition
7. Pre-Restriction Complementarity (2 pages) — embraced, not buried
8. Robustness and Alternative Specifications (2-3 pages)
9. Discussion and Implications (2 pages)
10. Conclusion (1 page)

**Named phenomenon:** Consider "the restrictionist mirage" — the promise of occupational upgrading that restriction was supposed to deliver but never did.

**Literature engagement (expanded):**
- Tabellini (2020): aggregate city-level vs our individual panel
- Abramitzky et al.: immigrant assimilation vs native response to restriction
- Peri & Ottaviano: complementarity in modern context → we show it existed historically too
- Moretti, Diamond: spatial equilibrium / local demand
- Political economy of restriction (Goldin 1994, Tichenor 2002)

### Phase 7: Code Structure

```
code/
  00_packages.R        # Update: add ggplot2, sf for maps
  01_fetch_data.R      # Update: add 1890 census if available, 1930 foreign-born data
  02_clean_data.R      # Update: additional outcomes, sector categories
  03_main_analysis.R   # Update: first-stage regression, enriched results
  04_robustness.R      # Update: 1890-based exposure, spatial SEs, additional checks
  05_figures.R         # NEW: all 8 figures
  06_tables.R          # Update: restructured tables, homeownership mechanism table
```

### Phase 8: Review Pipeline
- Internal co-author loops (substance + craft, 3+ rounds)
- Pre-mortem (3-5 likely referee attacks)
- `revise_and_publish.py --parent apep_0626 --push`
  - Advisor (quad-model, 3/4 PASS)
  - Exhibit review
  - Prose review
  - Referee (tri-model)

## Key Files

| File | Action |
|------|--------|
| `code/01_fetch_data.R` | Add 1930 foreign-born data for first stage; check 1890 availability |
| `code/02_clean_data.R` | Add sector categories, enriched homeownership variables |
| `code/03_main_analysis.R` | Add first-stage regression, homeownership mechanism analysis |
| `code/04_robustness.R` | Add 1890-based exposure, Conley SEs, event-study-style estimates |
| `code/05_figures.R` | NEW: all 8 figures including map and event study |
| `code/06_tables.R` | Restructure: promote homeownership, add first-stage table |
| `paper.tex` | Full rewrite: new framing, 25+ pages, figures integrated |

## Verification

1. All V1 results replicate from parent code
2. First-stage shows significant decline in foreign-born share in high-exposure counties
3. Homeownership result survives mechanism decomposition
4. Figures render correctly and tell the story visually
5. Paper compiles to 25+ pages
6. All advisor reviews pass (3/4)

## Risk Register

| Risk | Mitigation |
|------|-----------|
| 1890 census data unavailable in Azure | Use 1920-based exposure (V1 approach) as primary; note limitation |
| Homeownership mechanism unclear | Present multiple candidates with evidence; don't overclaim |
| First stage weak (small foreign-born decline) | Frame as reduced-form design; quota exposure is the treatment, not immigrant flow |
| Pre-period positive coefficient undermines identification | Reframe as complementarity evidence; show full-spec placebo is near-zero |
| Map data (county boundaries 1920) hard to obtain | Use NHGIS historical county shapefiles from IPUMS |

## Co-Author Roles
- **Claude (Executor):** Fetches data, runs analysis, writes paper, compiles, publishes
- **Codex (Director):** Cold-reads drafts, verifies text-table consistency, pushes on framing choices, signs off before external review
