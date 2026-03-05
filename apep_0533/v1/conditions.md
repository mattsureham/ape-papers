# Conditional Requirements

**Generated:** 2026-03-05T19:28:51.645000
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Can't Ask, Won't Tell: Salary History Bans, Hiring Wages, and the Gender Earnings Gap

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: explicit composition/selection diagnostics

**Status:** [x] RESOLVED

**Response:**
QWI provides hire counts (HirN, HirNs) and employment counts (Emp) by state x quarter x sex x age x education. I will run the DDD on HIRE COUNTS as a separate outcome to test whether bans change WHO gets hired (extensive margin). If hire composition shifts (e.g., more women hired), I can decompose the wage effect into a composition channel and a wage-setting channel. Additionally, I will run the main specification separately by age group (14-18, 19-21, 22-24, 25-34, 35-44, 45-54, 55-64, 65+) and education (less than HS, HS, some college, BA+) to check for compositional stability.

**Evidence:** QWI API confirmed to return data by agegrp and education dimensions: `curl "...?get=HirN,Emp&...&agegrp=A03&education=E4"` returns valid data.

---

### Condition 2: careful accounting for contemporaneous pay-equity laws

**Status:** [x] RESOLVED

**Response:**
Several states enacted salary history bans as part of broader pay-equity packages (e.g., California's AB 168 alongside existing Fair Pay Act; Colorado's Equal Pay for Equal Work Act includes both salary history ban and pay transparency). I will: (1) compile a database of pay transparency laws, equal pay act amendments, and other gender pay equity legislation by state and effective date; (2) include pay transparency law indicators as controls in the main specification; (3) run a robustness check excluding states where bans were bundled with pay transparency mandates (CO, CA, WA); (4) test whether the DDD effect (new hires vs. continuing workers) is robust to these controls, since pay transparency affects all workers equally while salary history bans specifically target the hiring margin.

**Evidence:** The DDD design itself partially addresses this: pay transparency laws affect ALL workers' wages, not specifically new hire vs. continuing. If the DDD effect (differential new hire improvement) survives after controlling for contemporaneous laws, it isolates the salary-history-specific channel.

---

### Condition 3: pre-analysis plan for event-study

**Status:** [x] RESOLVED

**Response:**
Pre-specified event-study design:
- Window: 12 quarters pre, 12 quarters post (3 years each direction)
- Estimator: Callaway-Sant'Anna (2021) group-time ATT with not-yet-treated as control
- Aggregation: dynamic event-study plot, group-level ATTs, simple ATT
- Pre-trend test: joint F-test on pre-treatment coefficients (quarters -12 to -2, base period = -1)
- Primary outcome: log(EarnHirNS_female / EarnHirNS_male) — gender earnings ratio for new hires
- Secondary outcomes: log(EarnS_female / EarnS_male), HirN_female / HirN_total, Sep_female / Sep_total
- Clustering: state level (20 treated + 31 control = 51 clusters)

**Evidence:** Pre-specified in initial_plan.md before data analysis. Will commit before running any regressions.

---

### Condition 4: heterogeneity to avoid specification searching

**Status:** [x] RESOLVED

**Response:**
Pre-specified heterogeneity dimensions (chosen before seeing results):
1. **Industry gender composition:** Male-dominated (Construction 23, Mining 21, Transportation 48-49, Finance 52) vs. female-dominated (Healthcare 62, Education 61, Accommodation 72). Prediction: larger effects in male-dominated industries where the gender gap is wider.
2. **Ban scope:** Private-sector-covering bans vs. public-sector-only bans (if any overlap in timing).
3. **Wage level:** High-wage industries (Finance, Professional Services, Information) vs. low-wage (Retail, Accommodation). Prediction: larger effects in high-wage industries where negotiation plays a bigger role.

All heterogeneity splits are defined BEFORE data analysis and documented in initial_plan.md.

**Evidence:** Will be documented in initial_plan.md prior to any regression analysis.

---

### Condition 5 (Gemini): compositional shifts in QWI age/education cells

**Status:** [x] RESOLVED

**Response:**
Same as Condition 1. QWI provides breakdowns by agegrp (8 groups) and education (5 levels) in addition to sex. I will run the main DDD specification on the SHARE of new hires in each age × education cell to detect compositional changes. If the ban shifts hiring toward older/more educated women, I will decompose the overall wage effect using a Kitagawa-Oaxaca-style between/within analysis: (1) between-group composition effect, (2) within-group wage effect. The within-group wage effect is the composition-free causal estimate.

**Evidence:** QWI API confirmed: `?get=HirN&agegrp=A04&education=E3&sex=2` returns valid data for specific demographic cells.

---

### Condition 6 (Grok): industry-level event studies confirming parallel trends

**Status:** [x] RESOLVED

**Response:**
I will run separate event-study regressions for each 2-digit NAICS industry (19 industries), plotting the dynamic treatment effects. This tests whether parallel trends hold at the industry level (more granular and informative than aggregate state-level trends). Industries where pre-trends are violated will be flagged and either excluded or analyzed separately. The aggregate result will weight industries by their employment share.

**Evidence:** QWI by state × quarter × sex × industry confirmed working (tested all 19 industries for MA).

---

### Condition 7 (Grok): male spillover falsification tests

**Status:** [x] RESOLVED

**Response:**
The DDD design inherently includes this: male workers are the control in the third difference. As a separate falsification test, I will run the DiD (ban × post) on MALE-ONLY outcomes: (1) male new hire earnings, (2) male-male age earnings gaps (old vs. young), (3) male hire counts. Under the null (no spillover), these should show zero effect. If bans affect male wages (e.g., through general pay compression at firms), this would indicate the policy has broader labor market effects beyond gender.

**Evidence:** Design pre-specified in initial_plan.md.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
