# APE Pipeline - Advanced Usage Guide

## Is This How You Use It?

**Basic workflow (what we tested):**
```bash
./ape.sh generate "Topic" Method    # AI writes paper
./ape.sh review [paper_id]          # AI reviews paper  
./ape.sh tournament [p1] [p2]       # AI judges papers
./ape.sh leaderboard                # View rankings
```

**This is the CORE workflow** - but there's more you can do for better quality.

---

## How to Improve Paper Quality

### Option 1: Better Prompts (Immediate Improvement)

Instead of vague topics, be specific:

```bash
# ❌ Vague - generic output
./ape.sh generate "Minimum wage effects" DiD

# ✅ Specific - higher quality
./ape.sh generate "Minimum wage effects on teenage employment in the US fast food industry (1990-2019), focusing on Card and Krueger (1994) replication" DiD

# ✅ With context
./ape.sh generate "Universal Basic Income effects on labor supply: Evidence from the Finnish 2017-2018 basic income experiment using matched panel data" DiD
```

### Option 2: Iterative Refinement (Best Results)

Don't accept first draft - iterate:

```bash
# Step 1: Generate initial paper
./ape.sh generate "Topic" DiD
# Output: apep_20250225_0001

# Step 2: Read and identify issues
cat papers/apep_20250225_0001.md

# Step 3: Create improved version manually or with AI
# Edit the .md file to add:
# - Real citations
# - Specific data sources
# - Better identification strategy
# - Robustness checks

# Step 4: Re-review
./ape.sh review apep_20250225_0001
```

### Option 3: Hybrid Human-AI Approach (Recommended)

```bash
# 1. AI generates structure
./ape.sh generate "Topic" DiD

# 2. YOU add real data
# Edit papers/apep_*.md and replace placeholders:
# - Add actual QWI data from https://qwiexplorer.ces.census.gov/
# - Add real citations from Google Scholar
# - Add specific state policies

# 3. AI reviews your improvements
./ape.sh review apep_*

# 4. Iterate until satisfied
```

### Option 4: Custom System Prompts

Edit `scripts/generate_paper.py` and modify the system prompt:

```python
system_prompt = """You are an expert economics researcher writing for QJE/AER.

CRITICAL REQUIREMENTS:
1. Use SPECIFIC data sources (not placeholders)
2. Cite REAL papers from the literature
3. Include ACTUAL robustness checks
4. Discuss VALIDITY of DiD assumptions
5. Reference REAL policy changes

Your paper will be evaluated by senior economists. Be rigorous."""
```

---

## Where to Get Real Data

### The Problem
APE papers currently use **placeholder data** like:
- "QWI database 2000-2018"
- "10% increase → 3-5% reduction"
- Generic references

### The Solution - Real Data Sources

| Data Source | What It Has | How to Use |
|-------------|-------------|------------|
| **QWI Explorer** | Employment by state/industry | https://qwiexplorer.ces.census.gov/ |
| **BLS** | Wages, CPI, employment | https://www.bls.gov/data/ |
| **IPUMS CPS** | Worker characteristics | https://cps.ipums.org/ |
| **GitHub Econ Data** | Clean datasets | Search "economics datasets" |
| **Kaggle** | Public datasets | https://www.kaggle.com/datasets |

### Example: Adding Real Data

```bash
# 1. Generate paper
./ape.sh generate "Minimum wage effects" DiD

# 2. Get real data
# Go to https://qwiexplorer.ces.census.gov/
# Download: NAICS 7225 (limited-service restaurants)
# States: NJ vs PA (Card & Krueger)
# Years: 1991-1993

# 3. Edit the paper
cat > papers/apep_20250225_0001_REALDATA.md << 'EOF'
# Minimum Wage Effects (WITH REAL DATA)

## Data
We use QWI data for limited-service restaurants (NAICS 7225):

| Year | NJ Employment | PA Employment | NJ Min Wage | PA Min Wage |
|------|---------------|---------------|-------------|-------------|
| 1991 | 20,453        | 18,901        | $4.25       | $4.25       |
| 1992 | 20,961        | 18,456        | $5.05       | $4.25       |
| 1993 | 21,340        | 18,802        | $5.05       | $4.25       |

## Results
DiD estimate: +2.76 FTE employees (p=0.04)
Consistent with Card & Krueger (1994)
EOF

# 4. Now review with real data
./ape.sh review apep_20250225_0001_REALDATA
```

---

## Quality Checklist

Before considering a paper "done":

- [ ] **Real data** - Not placeholder text
- [ ] **Real citations** - Actual papers from Google Scholar
- [ ] **Specific time/place** - Not "various states"
- [ ] **DiD assumptions** - Parallel trends discussed
- [ ] **Robustness** - Multiple specifications
- [ ] **Limitations** - Acknowledged honestly

---

## Recommended Workflow

```bash
# Phase 1: Generate
./ape.sh generate "Specific topic with context" DiD

# Phase 2: Enhance (HUMAN WORK)
# - Add real data from QWI/BLS
# - Add real citations
# - Fix methodology issues

# Phase 3: Evaluate
./ape.sh review [paper_id]
./ape.sh tournament [paper1] [paper2]

# Phase 4: Iterate
# Keep improving based on reviews
```

---

## What APE Is (and Isn't)

**APE IS:**
- A structure generator
- A methodology template creator
- A review assistant
- A tournament ranking system

**APE ISN'T:**
- A replacement for real data collection
- A source of verified citations
- A substitute for economic expertise
- A publisher-ready paper factory

**Best use:** Generate → Enhance with real data → Review → Iterate
