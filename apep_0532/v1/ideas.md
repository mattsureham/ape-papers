# Research Ideas

## Idea 1: When the Monsoon Fails — Shift-Share Weather Shocks and Climate Beliefs in India (Google Trends + WVS)

**Policy:** India's escalating extreme weather regime (2004-2024): monsoon anomalies, heat waves, and agricultural weather shocks intensifying under climate change. India experienced 573 extreme weather events during 2004-2023 (EM-DAT), with monsoon rainfall coefficient of variation increasing ~15% since 2000. Key shock years: 2009 drought (-23% below normal monsoon), 2014-15 consecutive droughts, 2018 Kerala floods, 2023 record heat waves. The treatment is continuous weather exposure at the state-month level, instrumented by Bartik shares.

**Outcome:** (a) Google Trends state-monthly search interest for climate-related terms ("global warming," "climate change," "जलवायु परिवर्तन"), providing a high-frequency revealed-preference measure of climate awareness; (b) World Values Survey India waves (2006, 2012, 2022) for direct belief measures (environmental protection priority, seriousness of global warming).

**Identification:** Shift-share (Bartik) instrument.
- **Shares (s_ik):** State i's pre-period (triennium ending 2000) share of cultivated area under crop k (rice, wheat, pulses, oilseeds, cotton, sugarcane, coarse cereals). Source: ICRISAT District Level Database.
- **Shifts (g_kt):** National (leave-one-out) deviation of crop k's growing-season rainfall from long-run mean in year-month t. Source: IMD gridded rainfall via IMDLIB or NOAA GHCN.
- **Instrument:** B_it = sum_k s_ik * g_kt — predicted local weather shock from pre-determined agricultural vulnerability interacted with national weather anomalies.
- **Exclusion restriction:** National weather anomalies for specific crops affect climate awareness in state i only through the channel of differential local economic/experiential exposure. Different states respond differently to the same national shock because of different crop compositions.

**First stage:** Actual extreme weather (rainfall anomaly, temperature anomaly) in state i at time t instrumented by B_it.
**Second stage:** Climate awareness/belief = f(predicted weather shock).

**Why it's novel:**
1. Nearly all weather-beliefs literature is US/Europe-focused (Egan and Mullin 2012; Deryugina 2013; Zaval et al. 2014). India — where 600M+ people depend on agriculture and weather has first-order economic consequences — is unstudied.
2. Shift-share instrument is new to this literature. Prior work relies on OLS with local weather anomalies.
3. Google Trends provides high-frequency state-month panel (2004-2024, ~28 states x 240 months = ~6,700 obs) — far more variation than typical survey-based studies.
4. No partisan polarization of climate beliefs in India (unlike the US), so weather-to-beliefs channel operates without the filter of political identity.

**Feasibility check:**
- Google Trends: Confirmed accessible via gtrendsR R package, state-level for India
- IMD weather: Confirmed accessible via IMDLIB Python library or NOAA GHCN API
- ICRISAT crop shares: Confirmed free download from data.icrisat.org
- WVS India: Freely downloadable microdata (3 waves with India, state-identified)
- No APEP paper on this topic exists

**Key risks:**
- Google Trends measures attention/search, not beliefs per se — but Herrnstadt and Muehlegger (2014) validate this proxy for US congressional climate voting
- WVS state identification may be coarse — limited to ~28 states with ~50-100 respondents per state per wave
- First-stage power: crop-based Bartik may be weak if all crops respond similarly to weather

---

## Idea 2: Flood Exposure and Climate Awareness — EM-DAT Disasters + Google Trends

**Policy:** Major catastrophic flood events in India with clear dates: 2005 Mumbai floods (July 26, 2005, Maharashtra), 2013 Uttarakhand floods (June 16-17, 2013), 2014 Kashmir floods (September 2014, J&K), 2015 Chennai floods (November-December 2015, Tamil Nadu), 2018 Kerala floods (August 2018), 2023 North India floods (July 2023, Himachal Pradesh/Uttarakhand). Each event is a discrete natural disaster affecting specific states at known dates.

**Outcome:** Google Trends search interest for "global warming" / "climate change" at state-monthly level.

**Identification:** Event-study DiD around major flood events. Treated states = those experiencing the flood. Control states = unaffected states. Estimate pre/post dynamics.

**Why it's novel:** Event-study design with large discrete shocks; clean identification window.

**Feasibility check:**
- Google Trends: accessible
- EM-DAT: requires registration but free
- Risk: Few treated states per event (often N=1), so pooling across events needed. May be underpowered.

**Key weakness:** Only ~5-8 major flood events, each treating 1-3 states. Total treated clusters may be insufficient. DiD with few clusters is a known credibility problem (lessons_global: "4 treated clusters is near-automatic credibility haircut").

---

## Idea 3: Heat Waves and Environmental Concern — IMD Temperature + IHDS Panel

**Policy:** Intensifying heat waves across India (2004-2012): 2003 Andhra Pradesh heat wave (May 2003, 1,500+ deaths), 2010 Ahmedabad heat wave (May 2010, 1,344 deaths), 2007 northern India heat wave. IMD declared heat wave days increased ~30% between IHDS wave I (2004-05) and wave II (2011-12) survey periods.

**Outcome:** India Human Development Survey (IHDS) household panel (wave I: 2004-05, wave II: 2011-12). Environmental perception questions (changes in rainfall, temperature, crop yields noticed by household).

**Identification:** Shift-share instrument with agricultural shares and national temperature shifts, applied to household panel with household fixed effects.

**Why it's novel:** Panel structure allows within-household estimation; IHDS has ~42,000 households across 384 districts.

**Feasibility check:**
- IHDS data: Requires ICPSR download (registration needed). Not clear if programmatic access is possible.
- IMD temperature: Accessible via IMDLIB.
- ICRISAT shares: Accessible.
- Risk: IHDS environmental questions may be about perceived local changes, not global warming beliefs per se. Also, IHDS download may fail if ICPSR is inaccessible.

**Key weakness:** IHDS data access uncertainty. The questions are about local environmental perceptions rather than global warming beliefs specifically.
