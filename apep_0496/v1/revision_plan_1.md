# Revision Plan

## Review Summary
- GPT-5.2: REJECT AND RESUBMIT — proxy boundary is not carte scolaire; reframe as descriptive
- Grok-4.1-Fast: MAJOR REVISION — add boundary validation, finer FE, continuous private school interaction
- Gemini-3-Flash: MAJOR REVISION — re-center as null result for stigma; boundary FE

## Key Changes (Priority Order)

### 1. Reframe narrative: "gradient analysis" not "boundary RDD identifies causal label effect"
- Abstract/intro: remove "quasi-random variation" language; frame as "price gradient at equidistance loci"
- Emphasize this as a descriptive contribution showing geographic sorting, not causal identification
- Lead with the null result: REP labels don't impose a measurable stigma tax

### 2. Add commune fixed effects to parametric specifications (new Column 5)
- This addresses the "département FE too coarse" criticism
- Add commune FE to Eq. 10 and report in Table 2
- Will likely further shrink the already-small coefficient

### 3. Strengthen private school mechanism analysis
- Add continuous interaction (count × REP_side) in addition to binary split
- Show results within IDF and outside separately

### 4. Rewrite interpretation throughout
- "Boundary gap" → "equidistance gradient"
- Remove cost-benefit section (reviewers say it's not meaningful with non-causal estimates)
- Clearly state what the design identifies and doesn't identify

### 5. Address minor points
- Acknowledge proxy boundary limitations more prominently
- Discuss what actual carte scolaire data would add
- Add cubic/quartic distance polynomial robustness

## What NOT to change
- The basic empirical approach (data, running variable, rdrobust)
- The private school mechanism (strongest part per all reviewers)
- The transparency about RDD violations (praised by all reviewers)
