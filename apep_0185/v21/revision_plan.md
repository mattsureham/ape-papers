# Revision Plan: apep_0185 v21 — Demographic Heterogeneity

## Parent: apep_0185/v20

## Goal
Add demographic heterogeneity analysis using QWI bulk data from Azure (age, education, sector).
Restructure paper to make mechanism evidence the centerpiece.

## Key Changes
1. Azure QWI fetch (replaces Census API for industry demographics)
2. New panels: age (7 groups), education (4 levels), sector (~20 NAICS)
3. Stratified 2SLS for each demographic slice
4. 3 new coefficient plots + 3 new tables
5. Move Tables 5,7,8,10,13 to appendix
6. New "Who Responds?" section (Section 8)
7. Update abstract/intro conditional on results
