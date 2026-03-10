# Revision Plan 1 — apep_0579/v1

## Overview

Address feedback from tri-model referee panel (2 Reject-and-Resubmit, 1 Major Revision), exhibit review, and prose review.

## Workstreams

### 1. Temper Causal Claims (All 3 Referees)
- Rewrite abstract to lead with "suggestive evidence" rather than definitive claims
- Remove all instances of "amplification is the rule"
- Conclusion reframed as "proof of concept for the reversal ratio framework, not a definitive test of policy irreversibility"
- Discussion changed from "is, in most cases, a fiction" to "raise the possibility"

### 2. Poland Identification (GPT R1, Gemini)
- Strengthen placebo failure caveat: "severely undermines the parallel trends assumption"
- Label Poland reversal ratio as "suggestive rather than causal"
- Replace defensive language with direct acknowledgment of design limitations

### 3. France Confounds (GPT R1, GPT R2)
- Acknowledge Pacte de responsabilite confounding explicitly
- Note aggregate outcome (economy-wide labor costs) vs targeted treatment (salaries > EUR 1M)
- Temper claims in abstract and discussion accordingly

### 4. Denmark Outcome Variable (GPT R2)
- Verify and clarify: dataset is prc_hicp_midx (standard HICP), NOT constant-tax variant prc_hicp_cmon
- Standard HICP includes mechanical tax effect — this is what we want to measure
- State explicitly in data description

### 5. Reversal Ratio Inference (GPT R2, Gemini)
- Acknowledge delta method SE limitation (shared pre-period covariance)
- Note Fieller intervals and bootstrap as future improvements
- Suppress Italy RR (near-zero denominator makes ratio uninformative)

### 6. Small-Cluster Inference (GPT R1)
- Acknowledge cluster-robust SEs unreliable with 4-5 clusters
- Use heteroskedasticity-robust SEs for Germany-only specification
- Note wild cluster bootstrap as future improvement

### 7. Exhibit Review Fixes
- Remove Czech row from Table 3 (placeholder dashes)
- Retain Figure 4 with "N=3, purely suggestive" caveat

### 8. Prose Review Fixes
- Revise abstract for accuracy
- Retain roadmap paragraph (common in empirical papers)

## Verification
- Recompile PDF and verify all changes render correctly
- Check no unresolved references
- Verify page 1 contains only front matter
