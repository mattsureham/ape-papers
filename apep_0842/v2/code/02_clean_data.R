# 02_clean_data.R — Build panel and construct treatment matrix
# apep_0842: The Safe Country Lottery

source("00_packages.R")

decisions_raw <- readRDS("../data/decisions_raw.rds")
applications_raw <- readRDS("../data/applications_raw.rds")

# ============================================================
# 1. Clean asylum decisions → recognition rates
# ============================================================

cat("=== Cleaning asylum decisions ===\n")
cat(sprintf("  Decision types available: %s\n", paste(unique(decisions_raw$decision), collapse = ", ")))
cat(sprintf("  Column names: %s\n", paste(names(decisions_raw), collapse = ", ")))

# Rename TIME_PERIOD to year if needed
if ("TIME_PERIOD" %in% names(decisions_raw)) {
  decisions_raw <- decisions_raw %>% rename(time = TIME_PERIOD)
}

# Filter to first-instance decisions, total sex, total age
# Decision types: POS (positive), NEG (negative), TOTAL
dec <- decisions_raw %>%
  filter(
    sex == "T",           # Total (both sexes)
    age == "TOTAL",       # All ages
    decision %in% c("POS", "NEG", "TOTAL"),
    !citizen %in% c("TOTAL", "EXT_EU27_2020", "EXT_EU28"),  # Exclude aggregates
    !geo %in% c("EU27_2020", "EU28", "TOTAL", "EEA")        # Exclude EU aggregates
  ) %>%
  select(citizen, geo, time, decision, values) %>%
  rename(
    origin = citizen,
    destination = geo,
    year = time
  )

cat(sprintf("  After filtering: %d rows\n", nrow(dec)))

# Pivot wider: each row = origin x destination x year
dec_wide <- dec %>%
  pivot_wider(
    names_from = decision,
    values_from = values,
    values_fill = 0
  )

cat(sprintf("  Wide format: %d rows\n", nrow(dec_wide)))
cat(sprintf("  Columns: %s\n", paste(names(dec_wide), collapse = ", ")))

# Construct recognition rate
# Recognition rate = positive decisions / total decisions
dec_panel <- dec_wide %>%
  mutate(
    total_decisions = if ("TOTAL" %in% names(.)) TOTAL else POS + NEG,
    positive_decisions = if ("POS" %in% names(.)) POS else 0,
    rejected_decisions = if ("NEG" %in% names(.)) NEG else 0,
    recog_rate = ifelse(total_decisions > 0, positive_decisions / total_decisions, NA_real_)
  ) %>%
  filter(total_decisions >= 10)  # Minimum cell size for reliable rates

cat(sprintf("  After cell size filter (>=10 decisions): %d rows\n", nrow(dec_panel)))

# ============================================================
# 1b. Decision-type decomposition (Geneva vs subsidiary/humanitarian)
# ============================================================

cat("\n=== Building decision-type decomposition ===\n")
cat(sprintf("  All decision codes: %s\n", paste(unique(decisions_raw$decision), collapse = ", ")))

# Extract sub-type decisions: POS_RFG (Geneva/refugee), POS_SPROT (subsidiary), POS_HUM (humanitarian)
dec_subtypes <- decisions_raw %>%
  filter(
    sex == "T",
    age == "TOTAL",
    decision %in% c("TOTAL", "POS_RFG", "POS_SPROT", "POS_HUM"),
    !citizen %in% c("TOTAL", "EXT_EU27_2020", "EXT_EU28"),
    !geo %in% c("EU27_2020", "EU28", "TOTAL", "EEA")
  ) %>%
  select(citizen, geo, time, decision, values) %>%
  rename(origin = citizen, destination = geo, year = time) %>%
  pivot_wider(names_from = decision, values_from = values, values_fill = 0)

# Compute sub-type rates where TOTAL > 0
dec_subtypes <- dec_subtypes %>%
  mutate(
    total_decisions = TOTAL,
    geneva_rate = ifelse(total_decisions >= 10, POS_RFG / total_decisions, NA_real_),
    subsidiary_rate = ifelse(total_decisions >= 10,
                             (POS_SPROT + POS_HUM) / total_decisions,
                             NA_real_)
  ) %>%
  filter(total_decisions >= 10) %>%
  select(origin, destination, year, geneva_rate, subsidiary_rate)

cat(sprintf("  Decision sub-type panel: %d rows\n", nrow(dec_subtypes)))
cat(sprintf("  Geneva rate available: %d non-NA\n", sum(!is.na(dec_subtypes$geneva_rate))))

# ============================================================
# 2. Clean asylum applications
# ============================================================

cat("\n=== Cleaning asylum applications ===\n")

# Rename TIME_PERIOD if needed
if ("TIME_PERIOD" %in% names(applications_raw)) {
  applications_raw <- applications_raw %>% rename(time = TIME_PERIOD)
}

cat(sprintf("  Application columns: %s\n", paste(names(applications_raw), collapse = ", ")))
cat(sprintf("  Applicant types: %s\n", paste(unique(applications_raw$applicant), collapse = ", ")))

apps <- applications_raw %>%
  filter(
    sex == "T",
    age == "TOTAL",
    applicant == "FRST",  # First-time applicants
    !citizen %in% c("TOTAL", "EXT_EU27_2020", "EXT_EU28"),
    !geo %in% c("EU27_2020", "EU28", "TOTAL", "EEA")
  ) %>%
  select(citizen, geo, time, values) %>%
  rename(
    origin = citizen,
    destination = geo,
    year = time,
    applications = values
  )

cat(sprintf("  After filtering: %d rows\n", nrow(apps)))

# ============================================================
# 3. Safe Country of Origin (SCO) Treatment Matrix
# ============================================================
# Sources: EUAA, AIDA database, national legislation
# Only coding events with clear legislative dates

cat("\n=== Building SCO treatment matrix ===\n")

sco_events <- tribble(
  ~destination, ~origin, ~year_designated, ~source,
  # Germany — Sichere Herkunftsstaaten
  # Serbia, North Macedonia, Bosnia: Nov 2014 (Asylverfahrensbeschleunigungsgesetz)
  "DE", "RS", 2014, "Germany Asylum Procedures Acceleration Act, Nov 2014",
  "DE", "MK", 2014, "Germany Asylum Procedures Acceleration Act, Nov 2014",
  "DE", "BA", 2014, "Germany Asylum Procedures Acceleration Act, Nov 2014",
  # Albania, Kosovo, Montenegro: Oct 2015 (Asylpaket I)
  "DE", "AL", 2015, "Germany Asylum Package I, Oct 2015",
  "DE", "XK", 2015, "Germany Asylum Package I, Oct 2015",
  "DE", "ME", 2015, "Germany Asylum Package I, Oct 2015",
  # Ghana, Senegal: already on list since 1993 (Asylverfahrensgesetz Anlage II)
  "DE", "GH", 2008, "Germany Asylum Procedures Act, Annex II (pre-sample)",
  "DE", "SN", 2008, "Germany Asylum Procedures Act, Annex II (pre-sample)",
  # Georgia: Sep 2023 — excluded from treatment (no full post-treatment year in annual data)
  # "DE", "GE", 2023, "Germany designation of Georgia, Sep 2023",
  # Moldova: Sep 2023 — excluded from treatment (no full post-treatment year in annual data)
  # "DE", "MD", 2023, "Germany designation of Moldova, Sep 2023",

  # France — Pays d'origine sûrs (OFPRA list)
  # Albania: added 2005
  "FR", "AL", 2008, "OFPRA safe country list (pre-sample)",
  # Kosovo: added Jun 2015 (CA OFPRA decision)
  "FR", "XK", 2015, "OFPRA decision, Jun 2015",
  # Georgia: added 2006
  "FR", "GE", 2008, "OFPRA safe country list (pre-sample)",
  # Serbia: added 2010
  "FR", "RS", 2010, "OFPRA safe country list, 2010",
  # North Macedonia: added 2006
  "FR", "MK", 2008, "OFPRA safe country list (pre-sample)",
  # Bosnia: added 2015
  "FR", "BA", 2015, "OFPRA safe country list, 2015",
  # Montenegro: added 2015
  "FR", "ME", 2015, "OFPRA safe country list, 2015",

  # Austria — Herkunftsstaatenverordnung
  # Serbia, Montenegro, North Macedonia, Bosnia, Kosovo: 2009 (HStV 2009)
  "AT", "RS", 2009, "Austria HStV 2009",
  "AT", "ME", 2009, "Austria HStV 2009",
  "AT", "MK", 2009, "Austria HStV 2009",
  "AT", "BA", 2009, "Austria HStV 2009",
  "AT", "XK", 2009, "Austria HStV 2009",
  # Albania: Oct 2014 (amendment to HStV)
  "AT", "AL", 2014, "Austria HStV amendment, Oct 2014",
  # Georgia: Jul 2018
  "AT", "GE", 2018, "Austria HStV amendment, Jul 2018",

  # Belgium — Safe countries list
  # Albania: 2012
  "BE", "AL", 2012, "Belgium Royal Decree, 2012",
  # Kosovo: 2012
  "BE", "XK", 2012, "Belgium Royal Decree, 2012",
  # North Macedonia: 2012
  "BE", "MK", 2012, "Belgium Royal Decree, 2012",
  # Serbia: 2012
  "BE", "RS", 2012, "Belgium Royal Decree, 2012",
  # Montenegro: 2012
  "BE", "ME", 2012, "Belgium Royal Decree, 2012",
  # Bosnia: 2012
  "BE", "BA", 2012, "Belgium Royal Decree, 2012",
  # Georgia: 2016
  "BE", "GE", 2016, "Belgium Royal Decree amendment, 2016",

  # Luxembourg — Safe countries list
  # Albania, Bosnia, Kosovo, Montenegro, North Macedonia, Serbia: 2007
  "LU", "AL", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",
  "LU", "BA", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",
  "LU", "XK", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",
  "LU", "ME", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",
  "LU", "MK", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",
  "LU", "RS", 2008, "Luxembourg Grand-Ducal Regulation (pre-sample)",

  # Bulgaria — Safe countries list
  # Serbia: 2016
  "BG", "RS", 2016, "Bulgaria Council of Ministers, 2016",
  # North Macedonia: 2016
  "BG", "MK", 2016, "Bulgaria Council of Ministers, 2016",

  # Czech Republic
  # Bosnia, Montenegro, North Macedonia, Serbia, Kosovo: 2015
  "CZ", "BA", 2015, "Czech Republic MoI Decree, 2015",
  "CZ", "ME", 2015, "Czech Republic MoI Decree, 2015",
  "CZ", "MK", 2015, "Czech Republic MoI Decree, 2015",
  "CZ", "RS", 2015, "Czech Republic MoI Decree, 2015",
  "CZ", "XK", 2015, "Czech Republic MoI Decree, 2015",
  # Albania: 2015
  "CZ", "AL", 2015, "Czech Republic MoI Decree, 2015"
)

# Create full panel indicator
# SCO_{cjt} = 1 if origin c is designated safe by destination j in year t
sco_panel <- sco_events %>%
  select(destination, origin, year_designated) %>%
  distinct()

cat(sprintf("  SCO events: %d designation events across %d destinations\n",
            nrow(sco_panel), n_distinct(sco_panel$destination)))
cat(sprintf("  Origins with designations: %s\n",
            paste(sort(unique(sco_panel$origin)), collapse = ", ")))

# ============================================================
# 4. Merge into analysis panel
# ============================================================

cat("\n=== Building analysis panel ===\n")

# Focus on origins that have at least one SCO designation and meaningful flows
key_origins <- unique(sco_panel$origin)

# Focus on EU destinations that are major asylum countries
key_destinations <- c("DE", "FR", "AT", "BE", "IT", "NL", "SE", "EL", "ES",
                       "CH", "UK", "PL", "HU", "CZ", "LU", "BG", "RO", "HR",
                       "DK", "FI", "NO", "IE")

# Filter decisions panel
panel <- dec_panel %>%
  filter(
    origin %in% key_origins,
    destination %in% key_destinations,
    year >= 2008,
    year <= 2023
  )

cat(sprintf("  Panel before SCO merge: %d rows\n", nrow(panel)))

# Merge SCO treatment indicator
panel <- panel %>%
  left_join(sco_panel, by = c("origin", "destination")) %>%
  mutate(
    sco = ifelse(!is.na(year_designated) & year >= year_designated, 1L, 0L)
  ) %>%
  select(-year_designated)

cat(sprintf("  Treatment indicator: %d treated cells, %d untreated cells\n",
            sum(panel$sco == 1), sum(panel$sco == 0)))

# Also merge applications data
panel <- panel %>%
  left_join(apps, by = c("origin", "destination", "year"))

cat(sprintf("  Final panel: %d rows, %d unique origin-destination pairs\n",
            nrow(panel), n_distinct(paste(panel$origin, panel$destination))))
cat(sprintf("  Year range: %d - %d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Destinations: %d, Origins: %d\n",
            n_distinct(panel$destination), n_distinct(panel$origin)))

# Add never-designated origins as control group
# These are origins with large flows but no SCO designation
# Include them from the full decisions data
control_origins <- c("SY", "AF", "IQ", "ER", "IR", "SO", "PK", "NG", "TR", "RU")

control_panel <- dec_panel %>%
  filter(
    origin %in% control_origins,
    destination %in% key_destinations,
    year >= 2008,
    year <= 2023
  ) %>%
  mutate(sco = 0L) %>%
  left_join(apps, by = c("origin", "destination", "year"))

cat(sprintf("\n  Control origins panel: %d rows\n", nrow(control_panel)))

# Combine treated and control
full_panel <- bind_rows(panel, control_panel) %>%
  # Merge decision sub-types
  left_join(dec_subtypes, by = c("origin", "destination", "year")) %>%
  mutate(
    # Create pair fixed effects
    pair_id = paste(origin, destination, sep = "_"),
    # Origin-year and destination-year for DDD FE
    origin_year = paste(origin, year, sep = "_"),
    dest_year = paste(destination, year, sep = "_"),
    # Log applications (for deterrence regressions)
    log_apps = log(applications + 1)
  )

cat(sprintf("\n=== Final full panel ===\n"))
cat(sprintf("  Total rows: %d\n", nrow(full_panel)))
cat(sprintf("  Unique pairs: %d\n", n_distinct(full_panel$pair_id)))
cat(sprintf("  Treated cells: %d (%.1f%%)\n",
            sum(full_panel$sco == 1, na.rm = TRUE),
            100 * mean(full_panel$sco == 1, na.rm = TRUE)))
cat(sprintf("  Origins: %d (%d designated, %d control)\n",
            n_distinct(full_panel$origin),
            n_distinct(panel$origin),
            length(control_origins)))

# Save
saveRDS(full_panel, "../data/analysis_panel.rds")
saveRDS(sco_events, "../data/sco_events.rds")
cat("\n=== Analysis panel saved ===\n")
