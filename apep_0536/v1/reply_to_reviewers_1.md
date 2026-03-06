# Reply to Reviewers — apep_0536/v1

## Response to Common Concerns

### 1. Identification and Causal Claims
All three reviewers correctly note that the pre-trend placebo rejection (p=0.012) and the TWFE/CS-DiD disagreement undermine causal interpretation. We have:
- Softened causal language throughout (abstract, introduction, conclusion now use "associated with" rather than "estimates the causal effect")
- Added citation to Roth (2022) on pre-test conditioning
- Explicitly framed the TWFE result as conditional on identifying assumptions that the paper's own diagnostics question
- Acknowledged that the European-only effect (-5.1 pp) may partly reflect pre-existing trend differences

### 2. Election-Type Mixing
Reviewers correctly identify pooling as a design concern. We note that:
- Election fixed effects absorb level differences by election type
- The by-election-type split (Section 6.1) is presented as the most informative specification
- We removed the spurious "election-type × year FE" robustness check (mechanically identical to baseline)
- The sign reversal across election types is honestly presented as the key puzzle

### 3. Literature
Added: de Chaisemartin & D'Haultfœuille (2020), Borusyak, Jaravel & Spiess (2024), Roth (2022), Boxell, Gentzkow & Shapiro (2017), Guriev, Melnikov & Zhuravskaya (2021).

### 4. Sun-Abraham Results
Added numerical estimates (ATT = -0.009, SE = 0.004, p = 0.03) with event-study description. Only 1 post-treatment period available.

## Items Not Addressed (Future Revision)
- Commune-level analysis: requires substantial data work beyond current scope
- Rambachan-Roth sensitivity bounds: would strengthen causal claims but requires additional estimation
- GDELT mechanism data: API limitations at department level documented in paper
