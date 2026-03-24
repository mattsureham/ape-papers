## 02_clean_data.R — Construct analysis panel
## APEP-0861: Austerity Triage and Domestic Abuse Justice

source("00_packages.R")
setwd("..")

# ===============================================================
# A. POLICE WORKFORCE PANEL (2007-2025)
# ===============================================================
cat("=== PROCESSING WORKFORCE DATA ===\n")

wf_raw <- readODS::read_ods("data/police_workforce.ods", sheet = "Data")
wf_raw <- janitor::clean_names(wf_raw)

# Convert numeric columns from character (ODS reader artifact)
wf_raw <- wf_raw %>%
  mutate(
    as_at_31_march = as.numeric(as_at_31_march),
    total_headcount = as.numeric(total_headcount),
    total_fte = as.numeric(total_fte)
  )

cat("Raw workforce rows:", nrow(wf_raw), "\n")
cat("Columns:", paste(names(wf_raw), collapse = ", "), "\n")

# Aggregate to force-year level: total police officers (FTE)
officers <- wf_raw %>%
  filter(worker_type == "Police Officer") %>%
  group_by(year = as_at_31_march, force = force_name, geocode) %>%
  summarise(officer_fte = sum(total_fte, na.rm = TRUE), .groups = "drop")

cat("Officer panel: ", n_distinct(officers$force), " forces, ",
    n_distinct(officers$year), " years\n")

# Also get PCSOs
pcsos <- wf_raw %>%
  filter(worker_type == "Police Community Support Officer") %>%
  group_by(year = as_at_31_march, force = force_name) %>%
  summarise(pcso_fte = sum(total_fte, na.rm = TRUE), .groups = "drop")

# Merge
workforce <- officers %>%
  left_join(pcsos, by = c("year", "force")) %>%
  mutate(pcso_fte = replace_na(pcso_fte, 0),
         total_fte = officer_fte + pcso_fte)

cat("Workforce panel dimensions:", nrow(workforce), "rows\n")
cat("Forces:\n")
print(sort(unique(workforce$force)))

# ===============================================================
# B. CRIME OUTCOMES PANEL (2015-2024)
# ===============================================================
cat("\n=== PROCESSING CRIME OUTCOMES ===\n")

outcomes_raw <- read_excel("data/crime_outcomes_supplementary.xlsx", sheet = "Outcomes")
outcomes_raw <- janitor::clean_names(outcomes_raw)

cat("Outcomes columns:", paste(names(outcomes_raw), collapse = ", "), "\n")

# Main outcome: victim-based charge rate (most relevant for DA)
# Keep Q4 (year ending March) as annual snapshot
charge_rates <- outcomes_raw %>%
  filter(
    offence_level == "All crime",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("charge outcome.*victim-based", metric_full_name, ignore.case = TRUE)
  ) %>%
  select(force = geographic_area_name, year,
         charge_rate_pct = percent) %>%
  mutate(charge_rate_pct = as.numeric(charge_rate_pct))

cat("Charge rate panel: ", n_distinct(charge_rates$force), " forces, ",
    n_distinct(charge_rates$year), " years\n")
cat("Years:", sort(unique(charge_rates$year)), "\n")

# No-suspect rate (victim-based)
no_suspect <- outcomes_raw %>%
  filter(
    offence_level == "All crime",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("no suspect.*victim-based", metric_full_name, ignore.case = TRUE)
  ) %>%
  select(force = geographic_area_name, year,
         no_suspect_pct = percent) %>%
  mutate(no_suspect_pct = as.numeric(no_suspect_pct))

# Victim does not support police action
victim_nosupport <- outcomes_raw %>%
  filter(
    offence_level == "All crime",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("victim does not support", metric_full_name, ignore.case = TRUE)
  ) %>%
  select(force = geographic_area_name, year,
         victim_nosupport_pct = percent) %>%
  mutate(victim_nosupport_pct = as.numeric(victim_nosupport_pct))

# Successful outcome rate (victim-based)
success_rate <- outcomes_raw %>%
  filter(
    offence_level == "All crime",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("Victim-based.*successful outcome", metric_full_name)
  ) %>%
  select(force = geographic_area_name, year,
         success_rate_pct = percent) %>%
  mutate(success_rate_pct = as.numeric(success_rate_pct))

# ===============================================================
# C. DA OUTCOMES (2024 cross-section for validation)
# ===============================================================
cat("\n=== PROCESSING DA OUTCOMES (2024) ===\n")

da_raw <- read_excel("data/da_cjs_2024.xlsx", sheet = "Table 5", skip = 4)
da_raw <- janitor::clean_names(da_raw)
cat("DA table columns:", paste(names(da_raw), collapse = ", "), "\n")

# The DA table has force-level charge rates for DA-related crimes
# Columns are outcome categories; first col is area code, second is force name
# Need to parse the header row
da_header <- read_excel("data/da_cjs_2024.xlsx", sheet = "Table 5", skip = 3, n_max = 1)
cat("DA header:", paste(unlist(da_header), collapse = " | "), "\n")

# ===============================================================
# D. MERGE TO ANALYSIS PANEL
# ===============================================================
cat("\n=== CONSTRUCTING ANALYSIS PANEL ===\n")

# Standardize force names for merging
standardize_force <- function(x) {
  x <- trimws(x)
  x <- gsub("\\s+", " ", x)
  # Common variations
  x <- gsub("^London, City of$", "City of London Police", x)
  x <- gsub("^Metropolitan Police Service$", "Metropolitan Police", x)
  x <- gsub("^Gwent Constabulary$", "Gwent", x)
  x <- gsub("^North Wales Police$", "North Wales", x)
  x <- gsub("^Hampshire and Isle of Wight$", "Hampshire", x)
  x
}

workforce <- workforce %>% mutate(force_std = standardize_force(force))
charge_rates <- charge_rates %>% mutate(force_std = standardize_force(force))
no_suspect <- no_suspect %>% mutate(force_std = standardize_force(force))
victim_nosupport <- victim_nosupport %>% mutate(force_std = standardize_force(force))
success_rate <- success_rate %>% mutate(force_std = standardize_force(force))

# Merge outcomes
outcomes_panel <- charge_rates %>%
  left_join(no_suspect, by = c("force_std", "year")) %>%
  left_join(victim_nosupport, by = c("force_std", "year")) %>%
  left_join(success_rate, by = c("force_std", "year"))

# Check merge coverage
wf_forces <- unique(workforce$force_std)
out_forces <- unique(outcomes_panel$force_std)
cat("Workforce forces:", length(wf_forces), "\n")
cat("Outcomes forces:", length(out_forces), "\n")
cat("In both:", length(intersect(wf_forces, out_forces)), "\n")
cat("In workforce only:", paste(setdiff(wf_forces, out_forces), collapse = ", "), "\n")
cat("In outcomes only:", paste(setdiff(out_forces, wf_forces), collapse = ", "), "\n")

# Compute austerity exposure: officer change from 2010 baseline
baseline <- workforce %>%
  filter(year == 2010) %>%
  select(force_std, officer_fte_2010 = officer_fte, pcso_fte_2010 = pcso_fte)

workforce <- workforce %>%
  left_join(baseline, by = "force_std") %>%
  mutate(
    officer_change_pct = (officer_fte - officer_fte_2010) / officer_fte_2010 * 100,
    pcso_change_pct = ifelse(pcso_fte_2010 > 0,
                             (pcso_fte - pcso_fte_2010) / pcso_fte_2010 * 100, NA)
  )

# Merge workforce with outcomes (years 2015-2024 overlap)
panel <- outcomes_panel %>%
  inner_join(
    workforce %>% select(force_std, year, officer_fte, pcso_fte, total_fte,
                         officer_fte_2010, officer_change_pct, pcso_change_pct),
    by = c("force_std", "year")
  )

cat("\nFinal panel: ", nrow(panel), " observations (",
    n_distinct(panel$force_std), " forces x ",
    n_distinct(panel$year), " years)\n")

# ===============================================================
# E. SAVE
# ===============================================================
saveRDS(panel, "data/analysis_panel.rds")
saveRDS(workforce, "data/workforce_panel.rds")

cat("\nSaved analysis_panel.rds and workforce_panel.rds\n")

# Summary stats
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Charge rate: mean =", mean(panel$charge_rate_pct, na.rm = TRUE),
    ", sd =", sd(panel$charge_rate_pct, na.rm = TRUE), "\n")
cat("Officer FTE: mean =", mean(panel$officer_fte, na.rm = TRUE),
    ", sd =", sd(panel$officer_fte, na.rm = TRUE), "\n")
cat("Officer change %: mean =", mean(panel$officer_change_pct, na.rm = TRUE),
    ", sd =", sd(panel$officer_change_pct, na.rm = TRUE), "\n")
