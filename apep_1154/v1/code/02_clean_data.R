## 02_clean_data.R — Construct analysis panel
## apep_1154: EU Transposition Delay and Firm Entry

source("00_packages.R")

cat("\n=== Constructing Analysis Panel ===\n")

limbo_panel <- readRDS("../data/limbo_panel.rds")
directive_sectors <- readRDS("../data/directive_sectors.rds")
firm_panel <- readRDS("../data/firm_panel.rds")

# ---- 2a. Fix treatment definition ----
# Problem: 17K "still not transposed" are mostly missing NIM data, not real limbo
# Solution: Only use directives where we observe SOME countries transposing
# A directive is "in limbo" only if: deadline passed AND other countries DID transpose

# Which directives have at least some countries transposing?
dir_observed <- limbo_panel %>%
  filter(!still_not_transposed) %>%
  group_by(celex) %>%
  summarise(
    n_countries_transposed = n(),
    n_late = sum(was_late),
    n_ontime = sum(!was_late),
    .groups = "drop"
  ) %>%
  # Keep directives where at least 10 countries have transposition records
  # AND there's variation in timing (some late, some on-time)
  filter(n_countries_transposed >= 10, n_late >= 3, n_ontime >= 3)

cat("Directives with clean cross-country variation:", nrow(dir_observed), "\n")

# Restrict to these well-observed directives
limbo_clean <- limbo_panel %>%
  semi_join(dir_observed, by = "celex") %>%
  # Drop "still not transposed" — these are missing data, not true limbo
  filter(!still_not_transposed)

cat("Clean limbo observations:", nrow(limbo_clean), "\n")
cat("Late:", sum(limbo_clean$was_late), "On-time:", sum(!limbo_clean$was_late), "\n")

# ---- 2b. Build treatment panel using clean limbo data ----
# Merge with sector assignments
limbo_sectored <- limbo_clean %>%
  inner_join(
    directive_sectors %>% select(celex, nace_section, sector_label),
    by = "celex",
    relationship = "many-to-many"
  )

cat("Limbo-sector observations:", nrow(limbo_sectored), "\n")

# For each country-sector-year, compute treatment intensity
years <- 2008:2020

treatment_panel <- limbo_sectored %>%
  crossing(year = years) %>%
  mutate(
    # A directive is in limbo in year t if deadline_year <= t AND transposed_year > t
    in_limbo = (deadline_year <= year) & (transposed_year > year),
    # On-time transposition: deadline_year <= t AND transposed_year <= t
    transposed = (deadline_year <= year) & (transposed_year <= year)
  ) %>%
  group_by(country2, nace_section, sector_label, year) %>%
  summarise(
    n_limbo = sum(in_limbo, na.rm = TRUE),
    n_transposed = sum(transposed, na.rm = TRUE),
    n_applicable = sum(deadline_year <= year),
    .groups = "drop"
  ) %>%
  mutate(
    limbo_share = ifelse(n_applicable > 0, n_limbo / n_applicable, 0),
    any_limbo = as.integer(n_limbo > 0)
  )

cat("\nTreatment panel:", nrow(treatment_panel), "\n")
cat("Observations with any_limbo=1:", sum(treatment_panel$any_limbo), "\n")
cat("Observations with any_limbo=0:", sum(treatment_panel$any_limbo == 0), "\n")
cat("Mean limbo share:", round(mean(treatment_panel$limbo_share), 4), "\n")
cat("SD limbo share:", round(sd(treatment_panel$limbo_share), 4), "\n")

# ---- 2c. Merge with firm data ----
firm_clean <- firm_panel %>%
  filter(
    nace_section %in% unique(treatment_panel$nace_section),
    !is.na(births)
  ) %>%
  group_by(geo2, nace_section, year) %>%
  summarise(
    births = sum(births, na.rm = TRUE),
    active_ent = sum(active_ent, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(birth_rate = births / active_ent * 100) %>%
  filter(!is.na(birth_rate), is.finite(birth_rate))

cat("\nFirm data (country-section-year):", nrow(firm_clean), "\n")

analysis_df <- firm_clean %>%
  rename(country2 = geo2) %>%
  left_join(
    treatment_panel %>% select(country2, nace_section, year,
                                n_limbo, any_limbo, limbo_share, n_applicable),
    by = c("country2", "nace_section", "year")
  ) %>%
  mutate(
    n_limbo = replace_na(n_limbo, 0),
    any_limbo = replace_na(any_limbo, 0),
    limbo_share = replace_na(limbo_share, 0),
    n_applicable = replace_na(n_applicable, 0),
    cs_id = paste0(country2, "_", nace_section),
    log_births = log(births + 1),
    log_active = log(active_ent + 1),
    log_birth_rate = log(birth_rate + 0.01)
  )

cat("\n=== Final Analysis Panel ===\n")
cat("Rows:", nrow(analysis_df), "\n")
cat("Countries:", n_distinct(analysis_df$country2), "\n")
cat("Sectors:", n_distinct(analysis_df$nace_section), "\n")
cat("Years:", paste(range(analysis_df$year), collapse = " - "), "\n")
cat("Country-sector units:", n_distinct(analysis_df$cs_id), "\n")
cat("Obs with any_limbo=1:", sum(analysis_df$any_limbo), "\n")
cat("Obs with any_limbo=0:", sum(analysis_df$any_limbo == 0), "\n")
cat("Mean limbo_share:", round(mean(analysis_df$limbo_share), 4), "\n")
cat("SD limbo_share:", round(sd(analysis_df$limbo_share), 4), "\n")

# Summary stats
cat("\n=== Treatment variation ===\n")
analysis_df %>%
  group_by(country2) %>%
  summarise(
    mean_limbo_share = round(mean(limbo_share), 4),
    sd_limbo_share = round(sd(limbo_share), 4),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_limbo_share)) %>%
  print(n = 30)

# Sector summary
sector_summary <- analysis_df %>%
  group_by(nace_section) %>%
  summarise(
    n_obs = n(),
    n_countries = n_distinct(country2),
    mean_births = round(mean(births, na.rm = TRUE)),
    mean_birth_rate = round(mean(birth_rate, na.rm = TRUE), 2),
    mean_limbo_share = round(mean(limbo_share), 4),
    .groups = "drop"
  )

cat("\n=== Sector Summary ===\n")
print(as.data.frame(sector_summary))

# Save
saveRDS(analysis_df, "../data/analysis_df.rds")
saveRDS(treatment_panel, "../data/treatment_panel.rds")
saveRDS(sector_summary, "../data/sector_summary.rds")

cat("\nSaved analysis_df.rds:", nrow(analysis_df), "rows\n")
