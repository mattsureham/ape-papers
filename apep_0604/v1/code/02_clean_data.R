# 02_clean_data.R — Clean and merge education + conflict data
# APEP-0604: Colombia FARC Peace and Education

source("code/00_packages.R")

# ---------------------------------------------------------------
# 1. Clean education data
# ---------------------------------------------------------------
cat("=== Cleaning education data ===\n")

edu <- read_csv("data/edu_raw.csv", show_col_types = FALSE) %>%
  rename(
    year = a_o,
    mun_code = c_digo_municipio,
    mun_name = municipio,
    dept_code = c_digo_departamento,
    dept_name = departamento,
    pop_5_16 = poblaci_n_5_16,
    enroll_rate_5_16 = tasa_matriculaci_n_5_16,
    net_total = cobertura_neta,
    net_transition = cobertura_neta_transici_n,
    net_primary = cobertura_neta_primaria,
    net_secondary = cobertura_neta_secundaria,
    net_media = cobertura_neta_media,
    gross_total = cobertura_bruta,
    gross_secondary = cobertura_bruta_secundaria,
    gross_media = cobertura_bruta_media,
    dropout_total = deserci_n,
    dropout_primary = deserci_n_primaria,
    dropout_secondary = deserci_n_secundaria,
    dropout_media = deserci_n_media,
    approval_total = aprobaci_n,
    approval_secondary = aprobaci_n_secundaria,
    class_size = tama_o_promedio_de_grupo,
    internet_pct = sedes_conectadas_a_internet
  ) %>%
  mutate(
    year = as.integer(year),
    mun_code = as.integer(mun_code),
    dept_code = as.integer(dept_code),
    across(c(net_secondary, net_primary, net_total, net_media,
             dropout_total, dropout_secondary, dropout_primary,
             approval_total, approval_secondary,
             gross_secondary, gross_total, gross_media,
             pop_5_16, class_size, internet_pct),
           as.numeric)
  )

cat("Education panel: ", n_distinct(edu$mun_code), "municipalities x",
    n_distinct(edu$year), "years =", nrow(edu), "rows\n")
cat("Year range:", range(edu$year, na.rm = TRUE), "\n")

# ---------------------------------------------------------------
# 2. Clean UCDP conflict data — identify FARC events
# ---------------------------------------------------------------
cat("\n=== Cleaning UCDP conflict data ===\n")

ucdp <- read_csv("data/ucdp_colombia_raw.csv", show_col_types = FALSE)

# Identify FARC events (in either side_a or side_b, including FARC-EMC splinter)
farc_events <- ucdp %>%
  filter(grepl("FARC", side_a, ignore.case = TRUE) |
         grepl("FARC", side_b, ignore.case = TRUE)) %>%
  mutate(
    # Clean municipality name from adm_2
    mun_name_ucdp = gsub(" municipality$", "", adm_2),
    deaths_total = as.numeric(best)
  )

cat("Total FARC-related events:", nrow(farc_events), "\n")
cat("Year range:", range(farc_events$year), "\n")

# ---------------------------------------------------------------
# 3. Create municipality-level FARC intensity measure
# Use pre-ceasefire period: 2010-2014
# ---------------------------------------------------------------
cat("\n=== Building FARC intensity measure ===\n")

# Pre-ceasefire events (2010-2014)
farc_pre <- farc_events %>%
  filter(year >= 2010 & year <= 2014)

cat("Pre-ceasefire FARC events (2010-2014):", nrow(farc_pre), "\n")

# Municipality-level intensity: events and deaths in pre-period
farc_intensity <- farc_pre %>%
  group_by(mun_name_ucdp) %>%
  summarise(
    farc_events_pre = n(),
    farc_deaths_pre = sum(deaths_total, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(farc_events_pre))

cat("Municipalities with pre-ceasefire FARC events:", nrow(farc_intensity), "\n")
cat("Top 10 by events:\n")
print(head(farc_intensity, 10))

# Also compute year-by-year FARC events for event study
farc_yearly <- farc_events %>%
  filter(year >= 2005) %>%
  group_by(mun_name_ucdp, year) %>%
  summarise(
    farc_events = n(),
    farc_deaths = sum(deaths_total, na.rm = TRUE),
    .groups = "drop"
  )

# ---------------------------------------------------------------
# 4. Match UCDP municipality names to DANE codes
# ---------------------------------------------------------------
cat("\n=== Matching UCDP names to DANE codes ===\n")

# Build lookup from education data (mun_code → mun_name)
mun_lookup <- edu %>%
  distinct(mun_code, mun_name, dept_code, dept_name) %>%
  # Clean names for matching

  mutate(
    mun_name_clean = tolower(trimws(mun_name)),
    # Remove accents for fuzzy matching
    mun_name_ascii = iconv(mun_name_clean, from = "UTF-8", to = "ASCII//TRANSLIT")
  )

# Clean UCDP names for matching
farc_intensity <- farc_intensity %>%
  mutate(
    ucdp_clean = tolower(trimws(mun_name_ucdp)),
    ucdp_ascii = iconv(ucdp_clean, from = "UTF-8", to = "ASCII//TRANSLIT")
  )

# Exact match first
matched <- farc_intensity %>%
  left_join(mun_lookup, by = c("ucdp_ascii" = "mun_name_ascii")) %>%
  filter(!is.na(mun_code))

cat("Exact ASCII match:", n_distinct(matched$mun_name_ucdp), "of",
    nrow(farc_intensity), "UCDP municipalities\n")

# For unmatched: try partial/fuzzy matching
unmatched <- farc_intensity %>%
  anti_join(matched %>% distinct(mun_name_ucdp), by = "mun_name_ucdp")

if (nrow(unmatched) > 0) {
  cat("Attempting fuzzy match for", nrow(unmatched), "remaining municipalities...\n")

  # Use agrep for approximate matching
  fuzzy_matches <- list()
  for (i in seq_len(nrow(unmatched))) {
    idx <- agrep(unmatched$ucdp_ascii[i], mun_lookup$mun_name_ascii,
                 max.distance = 0.2, ignore.case = TRUE)
    if (length(idx) == 1) {
      fuzzy_matches[[i]] <- tibble(
        mun_name_ucdp = unmatched$mun_name_ucdp[i],
        mun_code = mun_lookup$mun_code[idx],
        mun_name = mun_lookup$mun_name[idx],
        dept_code = mun_lookup$dept_code[idx],
        dept_name = mun_lookup$dept_name[idx]
      )
    }
  }

  if (length(fuzzy_matches) > 0) {
    fuzzy_df <- bind_rows(fuzzy_matches)
    cat("Fuzzy matched:", nrow(fuzzy_df), "additional municipalities\n")

    # Add fuzzy matches to main matched set
    fuzzy_joined <- unmatched %>%
      select(mun_name_ucdp, farc_events_pre, farc_deaths_pre) %>%
      inner_join(fuzzy_df, by = "mun_name_ucdp")

    matched <- bind_rows(
      matched %>% select(mun_name_ucdp, farc_events_pre, farc_deaths_pre, mun_code, mun_name, dept_code, dept_name),
      fuzzy_joined
    )
  }
}

# Deduplicate (some names match multiple codes — take first)
matched <- matched %>%
  group_by(mun_name_ucdp) %>%
  slice(1) %>%
  ungroup()

cat("Final matched FARC municipalities:", n_distinct(matched$mun_code), "\n")
cat("These account for", sum(matched$farc_events_pre), "of",
    sum(farc_intensity$farc_events_pre), "pre-ceasefire events\n")

# ---------------------------------------------------------------
# 5. Build FARC intensity lookup by DANE code
# ---------------------------------------------------------------
intensity_lookup <- matched %>%
  select(mun_code, farc_events_pre, farc_deaths_pre)

# Also match yearly events
farc_yearly <- farc_yearly %>%
  mutate(
    ucdp_clean = tolower(trimws(mun_name_ucdp)),
    ucdp_ascii = iconv(ucdp_clean, from = "UTF-8", to = "ASCII//TRANSLIT")
  ) %>%
  left_join(
    matched %>% select(mun_name_ucdp, mun_code),
    by = "mun_name_ucdp"
  ) %>%
  filter(!is.na(mun_code))

# ---------------------------------------------------------------
# 6. Load PDET municipalities
# ---------------------------------------------------------------
cat("\n=== Loading PDET municipality list ===\n")
pdet <- read_csv("data/pdet_municipalities.csv", show_col_types = FALSE)
pdet_codes <- pdet$cod_dane
cat("PDET municipalities:", length(pdet_codes), "\n")

# ---------------------------------------------------------------
# 7. Build analysis panel
# ---------------------------------------------------------------
cat("\n=== Building analysis panel ===\n")

panel <- edu %>%
  # Add FARC intensity
  left_join(intensity_lookup, by = "mun_code") %>%
  mutate(
    farc_events_pre = replace_na(farc_events_pre, 0),
    farc_deaths_pre = replace_na(farc_deaths_pre, 0),
    # Treatment indicators
    any_farc = as.integer(farc_events_pre > 0),
    high_farc = as.integer(farc_events_pre >= 3),  # top quartile of affected
    # PDET status
    pdet = as.integer(mun_code %in% pdet_codes),
    # Post indicators (treatment = formal peace agreement, Nov 2016)
    # Pre-period: 2011-2015 (5 years); Post: 2016-2024 (9 years)
    post_ceasefire = as.integer(year >= 2016),
    post_pdet = as.integer(year >= 2018),
    # Interaction terms
    farc_x_post = farc_events_pre * post_ceasefire,
    farc_x_pdet = farc_events_pre * post_pdet,
    # Log transform of intensity (adding 1 to handle zeros)
    log_farc_intensity = log(1 + farc_events_pre)
  )

# Add year-level FARC events for event study of violence itself
violence_panel <- farc_yearly %>%
  select(mun_code, year, farc_events_yr = farc_events, farc_deaths_yr = farc_deaths)

panel <- panel %>%
  left_join(violence_panel, by = c("mun_code", "year")) %>%
  mutate(
    farc_events_yr = replace_na(farc_events_yr, 0),
    farc_deaths_yr = replace_na(farc_deaths_yr, 0)
  )

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "columns\n")
cat("Municipalities:", n_distinct(panel$mun_code), "\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Municipalities with any pre-ceasefire FARC events:", sum(panel$any_farc[panel$year == 2011]), "\n")
cat("PDET municipalities in panel:", sum(panel$pdet[panel$year == 2011]), "\n")

# ---------------------------------------------------------------
# 8. Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary statistics ===\n")

# Compare high-FARC vs low-FARC municipalities in pre-period
pre_summary <- panel %>%
  filter(year <= 2014) %>%
  group_by(any_farc) %>%
  summarise(
    n_munis = n_distinct(mun_code),
    mean_net_secondary = mean(net_secondary, na.rm = TRUE),
    mean_dropout = mean(dropout_total, na.rm = TRUE),
    mean_net_primary = mean(net_primary, na.rm = TRUE),
    mean_approval = mean(approval_total, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-ceasefire means by FARC exposure:\n")
print(pre_summary)

# ---------------------------------------------------------------
# 9. Save analysis panel
# ---------------------------------------------------------------
write_csv(panel, "data/analysis_panel.csv")
cat("\nSaved data/analysis_panel.csv\n")
cat("Done.\n")
