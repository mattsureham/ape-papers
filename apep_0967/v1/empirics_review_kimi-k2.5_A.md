# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-25T22:19:23.146737

---

 **1. Idea Fidelity**

The paper largely follows the research design outlined in the manifest, exploiting the 2017 Ordonnances Macron to test whether dismantling firm-level worker voice fueled Rassemblement National (RN) voting. However, it deviates from the proposed identification strategy in one critical respect: the manifest envisioned using the 2017 Sirene stock file to measure pre-reform exposure, specifically highlighting the 50–99 employee bracket as the primary treatment intensity. Instead, the paper uses the *2026* Sirene stock file (as acknowledged in Appendix A), introducing severe measurement error. While the paper examines the 50–99 bracket as a robustness check (Table 1, column 4), the primary specification relies on 50+ employees. More importantly, the manifest’s emphasis on using pre-reform (2017) establishment data—which is essential for a valid difference-in-differences design—is violated by the use of current (2026) data to proxy for 2017 treatment status.

**2. Summary**

This paper tests whether France’s 2017 CSE reform—which merged three worker representation bodies and halved elected representatives in firms with 50+ employees—increased far-right voting between 2012 and 2022. Using a difference-in-differences design comparing commune-level exposure (share of establishments above the threshold), the authors find a precisely estimated null effect on Marine Le Pen’s vote share, suggesting that institutional dismantling of worker voice did not drive radicalization through the electoral channel.

**3. Essential Points**

*Measurement Error in Treatment Assignment.* The treatment variable is constructed from the 2026 Sirene establishment stock file rather than the 2017 distribution. This is not a minor limitation but a fundamental threat to identification. If firms crossed the 50-employee threshold between 2017 and 2026—either growing above or shrinking below—the treatment intensity is measured with error that is likely systematic rather than classical. For example, if firms in economically distressed areas (which trend toward RN voting) shrank below the threshold during this period, the 2026 data would understate their treatment intensity, inducing artificial negative bias. The claim that this error "strengthens the null interpretation" (Appendix A) is incorrect; attenuation bias toward zero prevents rejecting the null, but it does not provide evidence for it. The authors must either obtain the 2017 Sirene vintage or convincingly demonstrate that threshold-crossing is orthogonal to political trends using historical panel data on firm size.

*Ecological Fallacy and Spatial Mismatch.* The mechanism—workers losing institutional voice—operates at the individual-firm level, but the analysis aggregates to the commune of residence. In France, substantial commuting flows mean workers often reside in communes with few large establishments while working in urban centers with many (and vice versa). Because the Sirene data capture workplace location while electoral data capture residence, the treatment is likely mismeasured for a significant share of the electorate. This mismatch is exacerbated by using establishment counts rather than employment weights; a commune with one major employer (1,000 employees) receives the same treatment intensity as one with a single 50-employee workshop, despite vastly different political economy implications. The authors should construct treatment measures at the commuting zone (*zone d'emploi*) level or weight establishments by employment size to better align the mechanism with the unit of analysis.

*Temporal Confounding and Anticipatory Effects.* The identification strategy treats 2012 and 2017 as pre-reform periods, but Macron was elected in May 2017 on an explicit platform of labor market flexibility, with the CSE reform announced in September 2017. Consequently, the 2017 election likely reflects anticipatory responses to the reform agenda, not merely baseline political preferences. If workers who expected to lose voice already shifted to RN or Macron in 2017, the 2017–2022 comparison estimates the effect of *implementation* conditional on anticipation, not the total effect of the reform. Moreover, parallel trends are only validated for 2012–2017, but if the 2017 outcome is already affected by treatment expectations, the pre-trend test is contaminated. The authors should use 2007 as the sole pre-period or explicitly model the anticipation channel by testing for differential trends between 2012 and 2017 as a function of exposure.

**4. Suggestions**

*Address Measurement Error Through Instrumental Variables or Bounding.* If the 2017 Sirene vintage is unavailable, the authors should use an instrumental variable correlated with 2017 firm size but uncorrelated with post-2017 growth shocks—such as 2014 establishment counts from archived sources or industrial composition from the Census. Alternatively, implement a "measurement error robust" bounding approach (e.g., using the 2026 data as a noisy proxy and assuming specific reliability ratios) to demonstrate that the null persists even under conservative assumptions about the signal-to-noise ratio.

*Shift to Employment-Weighted, Workplace-Based Analysis
