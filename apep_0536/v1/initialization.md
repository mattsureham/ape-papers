# Human Initialization
Timestamp: 2026-03-06T10:15:00Z

## Launch Prompt

> This paper estimates the causal effect of France's fixed broadband rollout on political polarization and the demand for unreliable information. The setting is the staggered expansion of fiber-to-the-home (FTTH) and the planned decommissioning of the legacy copper network, which create large, policy-driven improvements in connectivity that vary across places and time. The core hypothesis is ambiguous ex ante and therefore informative: better connectivity can reduce misinformation by improving access to high-quality information, or it can increase it by expanding exposure to low-quality content and attention-grabbing narratives; either way, it can shift electoral outcomes by changing information diets and belief formation. I construct a panel of French geographic units over time (preferred: departments-month or departments-quarter; optional: communes-quarter) with treatment defined as FTTH availability/coverage (and, in a second design, entry into a scheduled copper-closure lot), and outcomes defined in two families: (1) political polarization outcomes from official election results (vote shares for anti-system parties, turnout, blank/null voting, and vote dispersion across parties), and (2) information-environment outcomes measuring the salience of misinformation and fact-checking using digital traces available at scale, prioritizing API-accessible sources such as GDELT-based counts of local news coverage that mentions conspiracy/misinformation terms and fact-checking brands, and optionally complementing with Google Trends indices for a pre-registered basket of conspiracy keywords and fact-checking queries if stable regional extraction is possible. The main identification uses staggered adoption/event-study difference-in-differences that compares within-unit changes in outcomes as connectivity improves relative to units not yet treated, with unit and time fixed effects, flexible pre-trend diagnostics, and robustness to alternative treatment definitions (continuous coverage, threshold crossings, copper-closure timing). To strengthen plausibility, I use zoning/institutional constraints from the deployment program (e.g., deployment zones such as RIP vs private zones) and the copper-closure schedule as sources of quasi-exogenous timing variation, and I show that pre-treatment political trends do not predict subsequent rollout timing within comparable zones. I then test heterogeneity that speaks directly to mechanism: effects should be larger where online media is a closer substitute for offline information (rurality, baseline newsstand density proxies, age structure) and where exposure to contested narratives is higher (baseline far-right vote share, baseline misinformation-topic coverage in GDELT). The paper contributes a clean, France-based estimate of how information infrastructure policy changes the information ecosystem and political polarization, with direct policy relevance to broadband subsidies and the management of the copper switch-off.

## Contributor (Immutable)

**GitHub User:** @olafdrw

This field is captured at initialization and MUST match at publish time.

## System Information

- **Claude Model:** claude-opus-4-6

## Questions Asked

1. **Country:** France
2. **Method:** DiD (staggered adoption, specified in prompt)
3. **API keys:** Yes (INSEE Sirene, PISTE credentials configured)
4. **External review:** Yes (Recommended)
5. **Other preferences:** None

## User Responses

1. France (from prompt)
2. DiD (from prompt)
3. Yes
4. Yes (Recommended)
5. None

## Setup Results

- **Country:** france
- **Domain:** France policy — broadband infrastructure, political polarization, misinformation
- **Method:** DiD (user-specified)
- **Data era:** Modern
- **Risk appetite:** Novel angle (classic broadband infrastructure + novel polarization/misinformation outcomes in France)
- **Other preferences:** none
