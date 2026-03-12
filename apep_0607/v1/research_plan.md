# Research Plan: The Amnesty Dividend

## Research Question
Did Brazil's 2012 Forest Code amnesty — which retroactively legalized ~21 million hectares of illegal deforestation — deliver agricultural productivity gains, or did it create moral hazard for continued forest clearing?

## Policy Setting
Brazil's New Forest Code (Law 12,651/2012, signed May 25, 2012) replaced the 1965 Forest Code with three key changes:
1. **Amnesty**: All illegal clearing before July 22, 2008 was retroactively legalized for properties enrolled in CAR (Rural Environmental Registry). This reduced the total area requiring restoration from 50M to 21M hectares.
2. **Reduced legal reserve requirements**: Small properties (up to 4 fiscal modules) exempted from restoring Legal Reserve if deforested before 2008.
3. **Reduced riparian buffer (APP) requirements**: APPs reduced from 30m to 5-15m for small properties.

## Identification Strategy
**Continuous-treatment DiD (amnesty windfall design):**

Y_{it} = α_i + γ_{st} + β × (Windfall_i × Post_t) + ε_{it}

- **Treatment**: Municipality-level amnesty windfall = share of municipality area converted from natural vegetation to agricultural/pasture use by 2008. Municipalities with more pre-2008 clearing received larger windfalls from amnesty.
- **Post period**: 2012 onward
- **Pre-treatment**: 2006–2011 (6 years)
- **Fixed effects**: Municipality FE (α_i) + State×Year FE (γ_{st})
- **Clustering**: Municipality level (5,570 clusters)

Event study specification:
Y_{it} = α_i + γ_{st} + Σ_k β_k × (Windfall_i × 1[t=k]) + ε_{it}

## Exposure Alignment
The treatment (farming share in 2008) captures the pre-amnesty agricultural footprint. Municipalities with higher farming share had more land that was potentially illegally deforested and thus stood to benefit more from the amnesty's retroactive legalization. The treatment is measured pre-policy (2008, four years before the 2012 reform) and is time-invariant, avoiding reverse causality. However, farming share conflates legal and illegal clearing — the ideal treatment would be the area of illegal deforestation exempted from restoration obligations, which requires crossing land cover with biome-specific legal reserve requirements. As a robustness check, I use forest loss share (1985–2008) as an alternative treatment that more directly captures the amnesty windfall.

The treatment operates through two channels: (1) directly, by removing restoration obligations on illegally cleared land, freeing it for continued productive use; and (2) indirectly, by signaling that future illegal clearing may also be amnestied (moral hazard). The units of analysis are municipalities, which aggregate heterogeneous properties. The treatment effect captures the municipality-level average response, which may mask within-municipality variation in property-level exposure.

## Expected Effects
1. **Crop area**: Positive — amnesty freed land for legal agricultural use
2. **Agricultural output**: Positive — both extensification and intensification possible
3. **Cattle herd**: Positive — pasture expansion on amnestied land
4. **Post-2012 deforestation**: Positive if moral hazard (expectation of future amnesties)

## Mechanism Tests
- **Extensification vs. intensification**: Decompose output growth into area expansion vs. yield
- **Crop composition**: Shift toward land-extensive crops (soy, cattle) vs. intensive (horticulture)
- **Moral hazard**: Do high-amnesty municipalities have higher post-2012 deforestation rates?
- **Biome heterogeneity**: Amazon (80% legal reserve) vs. Cerrado (35%) vs. Atlantic Forest (20%)

## Primary Specification
Outcome: Log soybean planted area (municipality-year)
Treatment: Pre-2008 deforestation share (continuous, municipality-level)
FE: Municipality + State×Year
Cluster: Municipality

## Data Sources
1. **IBGE PAM (SIDRA API)**: Table 5457 — municipality-level crop planted area and production value, 2006–2020
2. **IBGE PPM (SIDRA API)**: Table 3939 — municipality-level cattle herd, 2006–2020
3. **MapBiomas Collection 9**: Municipality-level land cover statistics (Dataverse, DOI: 10.58053/MapBiomas/VEJDZC)
4. **PRODES (INPE)**: Annual deforestation by municipality (Legal Amazon)

## Fetch Strategy
1. IBGE SIDRA API (free, no key needed): `https://apisidra.ibge.gov.br/`
2. MapBiomas Dataverse: Direct download of municipality-level Excel file
3. PRODES: INPE website download or TerraBrasilis API
