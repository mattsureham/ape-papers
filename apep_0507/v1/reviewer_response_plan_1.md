# Reviewer Response Plan

## Key themes across reviewers

### 1. Aggregation weighting (GPT, Gemini)
- GPT: "use eligible voters, not population, for pre-merger turnout aggregation"
- Gemini: "Clarify the population-weighting of pre-merger turnout"
- **Resolution**: Code already uses eligible-voter weighting (02_clean_data.R line 204). Paper text incorrectly says "population-weighted." Fix text.

### 2. Placebo/falsification tests (GPT, Grok)
- GPT: Placebo treatment dates, pre-period pseudo-events
- Grok: Implement election placebo
- **Resolution**: Add placebo test with shifted treatment dates. Election data has insufficient frequency for reliable placebo.

### 3. Chain mergers (GPT)
- "First merger" treatment mixes later intensifications
- **Resolution**: Add robustness spec restricting to single-merger municipalities.

### 4. Inference with few canton clusters (GPT)
- 26 clusters may be unreliable for CRVE
- Canton-cluster SE being smaller than municipality SE is "counterintuitive"
- **Resolution**: Add wild cluster bootstrap for canton clustering.

### 5. Selection/anticipation (GPT, Gemini)
- Voluntary timing can be endogenous to engagement trajectories
- **Resolution**: Strengthen discussion, note that flat pre-trends over 10 years mitigate.

### 6. Literature (Grok)
- Add Jordahl & Liang (2010), Borusyak et al. (2024)
- **Resolution**: Add citations.

### 7. Prose improvements (Exhibit + Prose reviews)
- Clean variable names in tables (already done)
- Tighter results narration (already done)
- Single contribution narrative (already done)

## Changes to make

### Code (04_robustness.R)
1. Add placebo test with randomized treatment dates
2. Add single-merger-only robustness
3. Add wild cluster bootstrap for canton clustering

### Paper text (paper.tex)
1. Fix "population-weighted" → "eligible-voter-weighted"
2. Add placebo test results
3. Add single-merger robustness results
4. Add wild cluster bootstrap results
5. Strengthen selection/anticipation discussion
6. Add citations
7. Note on chain mergers
8. Brief spillovers discussion
