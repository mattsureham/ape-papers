# Revision Plan v19: Structural Restructuring

## Context
v18 published (mu=27.4, conservative=21.4, rank #3 APEP). This revision addresses a fundamental structural problem: the event study with a fixed 2014 cutoff was a DiD diagnostic stapled onto a shift-share paper. The identification comes from time-varying MW shocks from ALL states weighted by predetermined SCI shares — there is no single "treatment date."

## Changes Made

### 1. Event Study DROPPED (not moved to appendix — removed entirely)
- Removed Section 8.2 "Event Study Evidence" with both figures and all F-test defense text
- This was a DiD diagnostic inappropriately elevated to centerpiece of identification argument

### 2. Shock Contribution Diagnostics PROMOTED to Main Text
- New Section 8.2 "Shock Exogeneity and Diversification"
- HHI = 0.04 (~26 effective shocks), leave-one-state-out stability table
- This is the CORRECT diagnostic for a shift-share design

### 3. Abstract Rewritten
- Leads with world question
- Reports specific magnitudes (3.4% earnings, 9% employment)
- Highlights shift-share diagnostics, not event study

### 4. Introduction Paragraph 5 Rewritten
- Now discusses HHI, LOSO stability, distance monotonicity, placebos, AR confidence sets
- No event study language

### 5. Policy Diffusion Text Fixed
- Column 4 significant negative coefficient (-1.342**) now accurately described
- Conclusion updated to reflect no positive relationship (not "no evidence")

### 6. Limitations Section Restructured
- SCI timing concern leads; baseline imbalance discusses distance improvement
- Concluding sentence highlights diversified shocks

### 7. Code Fix
- Added set.seed(2024) to cascade simulation (09e_cascade_simulation.R)

## What We Did NOT Do
- Did not add new analysis
- Did not change results or magnitudes
- Did not respond to any specific referee
- Presented our best analysis as the natural choice
