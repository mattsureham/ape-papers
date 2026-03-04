# Research Ideas

## Idea 1: Municipal Mergers and Direct Democracy: The Political Cost of Administrative Consolidation in Switzerland

**Policy:** Swiss municipal mergers (Gemeindefusionen). Switzerland reduced from ~2,900 municipalities in 2000 to ~2,200 by 2020 through voluntary bottom-up mergers. Major waves in Fribourg, Ticino, Glarus, Graubünden, Thurgau. Each merger has a precise effective date from the BFS Historisiertes Gemeindeverzeichnis (SMMT). The SwissCommunes R package (Knechtl 2021, SPSR) provides programmatic mapping of all mutations.

**Outcome:** Federal referendum participation at the commune level. BFS PXWeb table `px-x-1703030000_101` provides turnout, yes/no votes, eligible voters, and ballots cast for **503 federal referendums** across **2,367 geographic units** from **1960 to 2025**. Additional outcomes: blank/invalid votes (engagement quality), vote composition shifts (do merged communes change how they vote?), and referendum-type heterogeneity (high-salience vs. low-salience votes).

**Identification:** Staggered DiD using Callaway & Sant'Anna (2021) or Sun & Abraham (2021). Treatment = merger event. Units = communes observed across referendum dates. ~700 merger events since 2000 (far exceeding the ≥20 treated threshold). Pre-treatment: decades of referendum participation before merger. Controls: never-merged communes + not-yet-merged communes. Event study traces dynamic effects over time — do participation losses persist, fade, or deepen?

**Why it's novel:**
1. *Scale*: Previous Swiss studies used single cantons (Koch & Rochat 2017 on Glarus: 25→3 communes) or simpler methods (Frey 2023 in SPSR). This uses the ENTIRE universe of mergers × ALL federal referendums over 65 years.
2. *Direct democracy outcome*: Existing merger literature (Lassen & Serritzlew 2011 AJPS on Denmark; Blom-Hansen et al. 2016) studies representative democracy (election turnout). Switzerland's direct democratic system — where citizens vote on POLICY, not politicians — is a fundamentally different institution. Whether consolidation erodes direct democratic engagement is an open question.
3. *Mechanism decomposition*: Community size effect (larger units → free-riding), identity loss (absorbed commune loses autonomy), composition effect (merger partner's political culture). Built-in placebos: vote on topics unrelated to local governance should show no merger effect if the channel is identity/engagement rather than rational abstention.
4. *Multi-margin outcomes*: Not just turnout, but vote composition (convergence toward absorbing commune's pattern), blank vote rates (disengagement vs. abstention), and heterogeneous effects by referendum type (fiscal, social, environmental, institutional).
5. *Trade-off discovery*: Administrative efficiency gains from consolidation (well-documented) vs. democratic participation losses (understudied). This trade-off is globally relevant as municipalities worldwide consolidate.

**Feasibility check:**
- [x] Commune-level voting data confirmed via BFS PXWeb API (tested, returns JSON)
- [x] SwissCommunes R package available for merger timeline construction
- [x] ~700 merger events since 2000 (well above ≥20 threshold)
- [x] 5+ decades of pre-treatment data for late mergers
- [x] Not in APEP list (existing Swiss papers: childcare mandates, energy referendums, Lex Weber, gender attitudes — no mergers)
- [x] HonestDiD sensitivity, randomization inference feasible with this N

**Key risk:** Post-merger, absorbed communes disappear from the data (results reported only for merged entity). Analysis must compare merged-entity turnout to population-weighted pre-merger average. The SwissCommunes package handles the ID mapping.

---

## Idea 2: Green Building Mandates and the Construction Trade-off: Evidence from Swiss Cantonal Energy Codes

**Policy:** Cantonal energy building codes (Mustervorschriften der Kantone im Energiebereich, MuKEn). Cantons adopted the 2008 and 2014 model prescriptions at staggered times: GR (2010), BE (2011), AG (2012), BL (2016), BS (2016), LU (2017), FR (2019), AI (2020). Requirements include energy performance certificates for buildings, minimum insulation standards, and mandatory renewable energy for new heating systems.

**Outcome:** Building permits (Baubewilligungen), construction volume, and renovation activity at the cantonal and municipal level from BFS. Secondary outcomes: residential energy consumption per canton (BFS energy statistics), property market indicators.

**Identification:** Staggered DiD exploiting cantonal adoption timing (8+ cantons over 2010-2020). Unit of observation: canton-year or municipality-year. Pre-treatment periods: 5-10 years before first adopter. Controls: cantons that adopted later or have not yet adopted MuKEn 2014.

**Why it's novel:** The "green vs. affordable" housing trade-off is a first-order policy question worldwide. The Swiss setting is ideal: staggered adoption, comparable cantons, and building-level administrative data. Unlike studies of US building codes (which often lack clean variation), Swiss cantonal autonomy creates genuine policy experiments. The mechanism decomposition — does MuKEn reduce NEW construction (supply restriction) or shift activity toward RENOVATIONS (upgrade channel)? — speaks directly to the net welfare effect.

**Feasibility check:**
- [x] Adoption dates verified via EnDK and pre-scored opportunity list (8 cantons)
- [x] BFS construction statistics available via PXWeb API
- [x] Cantonal energy consumption data from BFS
- [ ] Property price data uncertain (may need restricted Wüest & Partner data)
- [x] Not in APEP list
- [x] 8 cantons is borderline but with municipality-level outcomes, effective N is large

**Key risk:** Only 8 treated cantons with staggered timing. Inference with few clusters requires wild cluster bootstrap or RI. Municipal-level analysis within cantons helps power but requires careful treatment definition.

---

## Idea 3: When School Starts Earlier: The HarmoS Concordat and Female Labor Supply in Switzerland

**Policy:** HarmoS (Interkantonale Vereinbarung über die Harmonisierung der obligatorischen Schule). This concordat standardized school entry at age 4, making two years of kindergarten mandatory. 15 cantons ratified between 2008-2010, with implementation required by school year 2015/2016. 11 cantons rejected HarmoS via popular referendum (LU, AG, GR, NW, UR, SZ, TG, AR, AI, ZG, VS).

**Outcome:** Female labor force participation (especially part-time → full-time transitions) from BFS Labour Force Survey (SAKE/ESPA) at the cantonal level. Secondary: maternal employment by child age, childcare utilization, cantonal enrollment rates.

**Identification:** DiD comparing cantons that adopted HarmoS (treatment) vs. those that rejected it (control), exploiting staggered implementation timing across adopting cantons (2009-2015). The referendum rejection provides a clean control group — these cantons COULD have adopted but voters chose not to. Triple-diff possible: compare mothers of 4-year-olds (directly affected) vs. mothers of older children (unaffected) across adopting vs. rejecting cantons.

**Why it's novel:** Differs from apep_0070 (childcare mandates → political feedback via spatial RDD at borders). This paper studies a DIFFERENT policy (education reform, not childcare mandate), a DIFFERENT outcome (labor supply, not political preferences), and a DIFFERENT identification strategy (staggered cantonal DiD with referendum-based control group, not spatial RDD). The mechanism is that mandatory earlier school start provides de facto free childcare for 4-year-olds, freeing maternal labor time.

**Feasibility check:**
- [x] HarmoS adoption/rejection by canton well-documented (EDK)
- [x] 15 treated cantons, 11 control cantons (good balance)
- [x] Implementation staggered over 2009-2015 (6 years)
- [ ] Cantonal labor force data may lack granularity (SAKE is sample-based, ~100K nationally)
- [x] Differentiated from apep_0070 (different policy, outcome, and method)
- [x] Established literature connection (Bauernschuster & Schlotter 2015 on German kindergarten reform)

**Key risk:** Some rejecting cantons independently lowered school entry age anyway, contaminating the control group. Need to verify actual school entry age changes in control cantons. SAKE sample sizes at the cantonal level may be too small for precise estimates, especially for subgroups (mothers of 4-year-olds).
