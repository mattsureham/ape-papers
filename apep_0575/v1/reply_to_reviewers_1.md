# Reply to Reviewers — apep_0575/v1, Stage C (Round 2)

## Response to Reviewer 1 (GPT-5.4 R1)

**Treatment timing (transposition vs bail-in activation):** We acknowledge that the paper cannot definitively distinguish the effects of national transposition from the common January 2016 bail-in tool activation. This is discussed explicitly in Section 7.4 (Limitations, paragraph 4). The significant bail-in activation × uninsured interaction supports this concern. A full horse race between timing channels would require a substantially different research design and is noted as an important direction for future work.

**Main inference (analytical SEs with 19 clusters):** We have supplemented analytical SEs with a CS-DiD multiplier bootstrap (1,000 iterations, p=0.035), reported in Section 7.4. The bootstrap p-value is slightly more significant than the analytical p-value (0.041), strengthening confidence in the headline result. We now reference both in the main results discussion.

**CS vs SA divergence:** We treat the 4.6x magnitude difference as a signal of estimation instability (Section 7.3). The SA estimate is driven by a narrow subset of cohort-time cells due to 83 dropped interactions, and we now present CS as the preferred specification with SA as a directional check.

**TWFE-based robustness:** We have added a footnote (Section 6.5) transparently noting that the robustness exercises use TWFE and therefore test specification stability rather than directly validating the CS-DiD headline. The intensity-interaction results provide the strongest robustness evidence.

**Mechanism claims:** We have softened "insurance optimization" language throughout, reframing it as a plausible hypothesis rather than established fact. We acknowledge the aggregate data cannot directly observe deposit splitting or within-household restructuring.

**Sectoral comparison:** Reframed from "placebo" to "sectoral comparison" throughout. The section header is "Corporate Deposit Sectoral Comparison" and the text explicitly notes corporates are also subject to BRRD.

**Imputation estimator / pre-trend tests by exposure:** Noted as important extensions for future work. Beyond the scope of v1 Stage C.

## Response to Reviewer 2 (GPT-5.4 R2)

**Treatment timing:** Same response as R1 above.

**Bootstrap inference:** Same response as R1. The bootstrap result (p=0.035) is now referenced in the main results discussion alongside the analytical p-value.

**Narrow identifying variation:** Acknowledged. Section 6.2 footnote explicitly notes the CS control pool shrinks and is exhausted by December 2015, limiting identified post-treatment horizons.

**Exogeneity of timing:** Acknowledged as asserted rather than tested. Balance/predictability tests are noted as an important extension.

**TWFE robustness mismatch:** Acknowledged via footnote in Section 6.5.

**Compositional outcomes:** The three maturity shares are estimated separately. A formal compositional-data approach (log-ratios) is noted as a useful extension but beyond current scope.

**Additional modern estimator (BJS/dCDH):** Noted as a high-value extension for future work. The current paper presents CS as preferred and SA as a fragile sensitivity check.

## Response to Reviewer 3 (Gemini)

**Pre-determined intensity measure:** The EBA 2015 uninsured share data is the earliest available vintage. We acknowledge this is post-treatment for early adopters and note it as a limitation. Earlier vintages would strengthen the design but are not publicly available.

**CS vs SA reconciliation:** Addressed via explicit discussion of SA instability in Section 7.3 and the limitations section.

**Interest rate spreads:** Noted as a valuable extension; ECB MFI interest rate data could strengthen the mechanism evidence in a future version.
