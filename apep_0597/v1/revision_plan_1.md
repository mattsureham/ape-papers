# Revision Plan — Round 1 (Internal + Stage C External)

## Round 1 (Internal review)
1. Fix RI permutation count: 500 → 1,000
2. Reframe abstract/intro with cereal headline
3. Distance: 1,400 km → 1,160 km Haversine
4. RTEP data quality discussion added
5. Welfare calculation added

## Stage C (External referee reviews)

### Key Concerns Addressed

1. **Food price identification** (R1 #1, R2 #1)
   - Added cereal-specific event study (Figure 8)
   - Added commodity-by-month FE (coefficient unchanged: 0.0674 vs 0.0704)
   - Softened language: "reduced-form geographic differentials" not "structural pass-through"

2. **Spatial inference** (R1 #2, R2 #2)
   - Added Conley spatial HAC SEs (200km cutoff)
   - Cereals: Conley SE = 0.022 vs state-clustered 0.005, still significant (t ≈ 3.2)

3. **Magnitude reconciliation** (R1 #3, R2 #3)
   - New subsection explaining supply chain amplification and non-coincident transport routes

4. **Roots/tubers transparency** (Gemini #2)
   - Added Column 6 to Table 3 with roots/tubers coefficient
   - Explicit discussion of negative gradient and production geography

5. **Causal language** (R1 #5, R2 #5)
   - "First causally identified" → "new reduced-form evidence"
   - "Built-in placebos" → "contrast groups that probe the mechanism"

### Not Changed (with justification)
- IV/2SLS fuel→food: Different paper scope
- Road distance: No routing data available
- NBS validation: State-level (not market-level) data
- Excluding northeast: Removes key identifying variation
