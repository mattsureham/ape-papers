# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-31T14:42:13.575880

---

 **Referee Report**

**Manuscript:** "Preempted from the Doctor's Screen: Municipal Broadband Restrictions and the COVID-19 Telehealth Divide"

**Recommendation:** Revise and Resubmit

---

### 1. Idea Fidelity

The paper deviates from the original manifest in three critical respects that undermine its empirical credibility. First, the manifest explicitly promised a "Staggered DiD (CS)" design using Callaway-Sant'Anna estimators to handle the 1997–2019 staggered adoption of preemption laws; the delivered paper instead uses a static two-way fixed effects (TWFE) specification that treats all preemption laws as identical and ignores their staggered timing. Second, the manifest highlighted a 9.1 percentage point rural gap as a central finding; the paper instead reports a null triple-difference interaction for rural areas, directly contradicting the posited mechanism. Third, the manifest promised to leverage Arkansas and Washington's 2021 repeals as part of the identification strategy and to use FCC Form 477 data to measure broadband supply; the paper omits both elements, leaving the mechanism (broadband infrastructure constraints) entirely unsubstantiated.

---

### 2. Summary

This paper estimates the effect of state municipal broadband preemption laws on Medicare telehealth utilization during COVID-19. Using CMS state-quarter data from 2020–2025, the author finds that preemption reduced telehealth adoption by 2.4 percentage points (14% relative to control), with effects peaking at 6.4pp during the acute pandemic phase. The contribution lies in documenting a "restriction trap": regulations that appear costless in normal times impose severe welfare costs during crises when suppressed infrastructure becomes essential.

---

### 3. Essential Points

**1. Identification Strategy Mismatch and Staggered Treatment Timing**
The manuscript treats preemption as a static binary treatment (active as of January 2020) interacted with a post-COVID indicator. However, preemption laws were adopted between 1997 and 2019—decades apart. By ignoring this staggered timing, the paper conflates the effects of recently enacted restrictions (e.g., Indiana 2019) with those enshrined for decades (e.g., Texas 1997), potentially biasing estimates if treatment effects vary with law vintage or if early adopters differ systematically in unobserved ways. More critically, the manifest promised Callaway-Sant'Anna (CS) estimators to address the negative weighting problems inherent in staggered DiD (Goodman-Bacon 2021), but the paper delivers standard TWFE. This is not merely a deviation from the proposal—it is a methodological error given the heterogeneous treatment effects likely present across this long adoption window. The authors must either implement CS/Sun-Abraham estimators or convincingly justify why static TWFE is appropriate despite the staggered treatment.

**2. Mechanism Evidence and the Null Rural Interaction**
The paper posits that preemption harmed telehealth by constraining broadband infrastructure, particularly in rural areas where private investment is weakest. Yet the triple-difference specification (Table 1, Column 4) reveals a precisely estimated null effect for the rural interaction (−0.18pp, *p* = 0.72), contradicting the manifest's promised 9.1pp rural gap. This null result undermines the entire mechanism: if preemption matters because it prevents municipal fiber in underserved rural markets, the effect should be concentrated there. The null suggests either (a) preemption affects telehealth through non-infrastructure channels (e.g., generally anti-regulatory environments), or (b) the mechanism is broadband quality/adoption in urban areas too. The paper must reconcile this null finding with the theoretical framework or abandon the rural infrastructure story. Crucially, the manifest promised FCC Form 477 data to measure actual provider entry; without this (or similar) data showing that preemption manifestly reduced broadband supply, the paper cannot credibly claim infrastructure as the mechanism.

**3. Parallel Trends and Pre-COVID Infrastructure Divergence**
While the authors correctly note that telehealth utilization was near-zero pre-COVID (making outcome pre-trends moot), this does not absolve the need for parallel trends in the *mechanism*. If preempted states were already diverging in broadband quality, digital literacy, or healthcare access prior to 2020, the DiD comparison captures differential trends rather than causal effects. The paper shows balance in 2019 ACS broadband subscription rates (85.5% vs. 86.0%), but subscriptions are a coarse measure; FCC Form 477 data (promised in the manifest) would reveal whether provider density, speeds, or prices were trending differently. The authors must provide event-study evidence for broadband infrastructure outcomes (using 2010–2019 data) to validate the common trends assumption for the mechanism, or acknowledge that the design cannot rule out pre-existing divergence in digital readiness.

---

### 4. Suggestions

**A. Implement Staggered DiD Corrections or Heterogeneity Analysis**
If the authors maintain that all preemption laws are equivalent regardless of enactment date, they should explicitly defend this "static treatment" assumption. More persuasively, they could implement the Callaway-Sant'anna (2021) estimator using the actual enactment years (1997–2019) as treatment dates, with COVID as the shock that reveals the infrastructure deficit. This would yield cleaner estimates by comparing each treated state to not-yet-treated or never-treated controls. Alternatively, test for heterogeneity by dividing laws into "early" (pre-2005) and "late" (post-2010) adopters; the robustness check excluding early adopters (Table 3, Col 2) suggests effect heterogeneity, which should be explored systematically.

**B. Leverage the Repeal Variation**
The manifest mentioned Arkansas and Washington repealing preemption in 2021. This is a valuable opportunity for a placebo test or triple-difference: do these states experience faster telehealth growth or convergence after repeal relative to persistent preemption states? Even with only two repeal states, an event-study around the repeal dates would strengthen causal interpretation and validate the mechanism (if repeal accelerates broadband deployment and telehealth).

**C. Sharpen the Mechanism Evidence**
Use the FCC Form 477 data (cited in the manifest but absent from the paper) to show that preemption actually reduced broadband provider entry, speeds, or competition. A mediation analysis—regressing telehealth on preemption with and without broadband controls—would quantify how much of the effect operates through infrastructure. If the rural triple-diff is null because urban areas also suffered from reduced competitive pressure (as speculated in the text), show this using measures of market concentration (e.g., HHI) from FCC data.

**D. County-Level Analysis**
The state-level analysis (50 clusters) is underpowered for detecting heterogeneous effects. If CMS data can be merged with county-level telehealth measures (or if the author can access restricted CMS data), a county-level analysis would provide thousands of clusters, enabling more precise estimation of rural effects and allowing for county-specific fixed effects that absorb local healthcare market conditions.

**E. Clarify the Counterfactual**
The paper notes that federal broadband subsidies (BEAD) narrowed the gap post-2021. A compelling extension would interact preemption with subsidy intensity (e.g., BEAD funding per capita) to test whether federal investment can remediate state-level regulatory constraints. This would move beyond documenting the "restriction trap" to quantifying the cost of delay in infrastructure investment.

**F. Health Outcomes**
While the paper acknowledges it cannot measure welfare consequences, even suggestive evidence on COVID mortality or emergency department visits differentially affecting preempted states would strengthen the policy implications. CDC death data (mentioned in the manifest) should be leveraged to test whether reduced telehealth access translated into worse health outcomes.

**Minor Comments:**
- Table 2 appears truncated in the provided source (no coefficients shown). Ensure the full event study is reported in the final version.
- The "standardized effect sizes" table (Appendix Table A1) reports SDEs >1, which is unusual for percentage-point outcomes; verify the standard deviation calculations (is this the SD of the outcome or the SD of the treatment effect?).
- Define "restriction trap" earlier (currently appears in Discussion) and connect it explicitly to the option value of infrastructure literature (e.g., Pindyck 1988 on irreversible investment under uncertainty).
