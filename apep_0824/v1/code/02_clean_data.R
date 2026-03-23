## 02_clean_data.R — Clean and construct analysis panel
## apep_0824: Romania micro-enterprise threshold and firm dynamics
source("00_packages.R")

# ---- 1. Load and combine old (2005-2020) and new (2021-2024) SBS data ----
sbs_old <- readRDS("../data/sbs_raw.rds")
sbs_new <- readRDS("../data/sbs_new.rds")

cat("Old SBS:", nrow(sbs_old), "rows, years:", paste(sort(unique(sbs_old$TIME_PERIOD)), collapse = ", "), "\n")
cat("New SBS:", nrow(sbs_new), "rows, years:", paste(sort(unique(sbs_new$TIME_PERIOD)), collapse = ", "), "\n")

# Map old indicator codes to new indicator names
# Old: V11110 = enterprises, V12110 = turnover, V91110 = persons employed
# New: ENT_NR, NETTUR_MEUR, EMP_NR
cat("\nOld indicators:", paste(sort(unique(sbs_old$indic_sb)), collapse = ", "), "\n")
cat("New indicators:", paste(sort(unique(sbs_new$indic_sbs)), collapse = ", "), "\n")

# ---- 2. Extract key variables from old SBS ----
# Define peer countries: Romania + Central/Eastern European peers + Western benchmarks
peers <- c("RO", "BG", "HU", "CZ", "PL", "SK", "HR", "SI", "EE", "LT", "LV")
western <- c("AT", "DE", "FR", "IT", "ES", "NL", "BE", "FI", "SE", "DK")
all_countries <- c(peers, western)

# Harmonize NACE codes — need sector-level AND total
# Total business economy varies by dataset version
nace_total_codes <- c("B-S_X_K642", "B-N_X_K642", "B-N", "B_TO_S_X_K")

# Extract enterprise counts
ent_old <- sbs_old %>%
  filter(
    indic_sb == "V11110",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, enterprises = values)

cat("\nEnterprise counts (old):", nrow(ent_old), "rows\n")
cat("NACE codes in data:", length(unique(ent_old$nace)), "\n")

# Check which NACE total code is present
for (nc in nace_total_codes) {
  n <- sum(ent_old$nace == nc)
  if (n > 0) cat("  Total code", nc, ":", n, "rows\n")
}

# Also check specific sectors we want
key_nace <- c("C", "F", "G", "H", "I", "J", "K", "L", "M", "N")
for (nc in key_nace) {
  n <- sum(ent_old$nace == nc)
  cat("  NACE", nc, ":", n, "rows\n")
}

# Extract turnover
turn_old <- sbs_old %>%
  filter(
    indic_sb == "V12110",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, turnover_m = values)

# Extract employment
emp_old <- sbs_old %>%
  filter(
    indic_sb == "V91110",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, employment = values)

cat("Turnover rows:", nrow(turn_old), "\n")
cat("Employment rows:", nrow(emp_old), "\n")

# ---- 3. Extract from new SBS (2021-2024) ----
ent_new <- sbs_new %>%
  filter(
    indic_sbs == "ENT_NR",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, enterprises = values)

turn_new <- sbs_new %>%
  filter(
    indic_sbs == "NETTUR_MEUR",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, turnover_m = values)

emp_new <- sbs_new %>%
  filter(
    indic_sbs == "EMP_NR",
    geo %in% all_countries
  ) %>%
  select(nace = nace_r2, size = size_emp, geo, year = TIME_PERIOD, employment = values)

cat("\nNew data - Enterprises:", nrow(ent_new), ", Turnover:", nrow(turn_new),
    ", Employment:", nrow(emp_new), "\n")

# Check size class harmonization
cat("Old size classes:", paste(sort(unique(ent_old$size)), collapse = ", "), "\n")
cat("New size classes:", paste(sort(unique(ent_new$size)), collapse = ", "), "\n")

# ---- 4. Harmonize size classes ----
# Old: 0-9, 10-19, 20-49, 50-249, GE250, TOTAL
# New: 0_1, 0-9, 2-9, 10-19, 20-49, 50-249, GE250, TOTAL
# Keep: 0-9, 10-19, 20-49, 50-249, GE250, TOTAL (common to both)
common_sizes <- c("0-9", "10-19", "20-49", "50-249", "GE250", "TOTAL")

ent_old <- ent_old %>% filter(size %in% common_sizes)
ent_new <- ent_new %>% filter(size %in% common_sizes)
turn_old <- turn_old %>% filter(size %in% common_sizes)
turn_new <- turn_new %>% filter(size %in% common_sizes)
emp_old <- emp_old %>% filter(size %in% common_sizes)
emp_new <- emp_new %>% filter(size %in% common_sizes)

# ---- 5. Combine old and new ----
ent_all <- bind_rows(ent_old, ent_new) %>%
  distinct(nace, size, geo, year, .keep_all = TRUE) %>%
  arrange(geo, nace, size, year)

turn_all <- bind_rows(turn_old, turn_new) %>%
  distinct(nace, size, geo, year, .keep_all = TRUE)

emp_all <- bind_rows(emp_old, emp_new) %>%
  distinct(nace, size, geo, year, .keep_all = TRUE)

# ---- 6. Build the analysis panel ----
# Merge enterprise counts, turnover, employment
panel <- ent_all %>%
  left_join(turn_all, by = c("nace", "size", "geo", "year")) %>%
  left_join(emp_all, by = c("nace", "size", "geo", "year")) %>%
  mutate(
    avg_turnover = ifelse(enterprises > 0, turnover_m / enterprises, NA),
    avg_employment = ifelse(enterprises > 0, employment / enterprises, NA),
    ro = as.integer(geo == "RO"),
    cee = as.integer(geo %in% peers),
    # Treatment periods based on Romania's threshold changes
    # Pre-reform: 2008-2015 (threshold = 65K EUR, relatively stable)
    # Expansion 1: 2016 (threshold raised to 100K, rate cut to 1%)
    # Expansion 2: 2017 (threshold raised to 500K)
    # Expansion 3: 2018 (threshold raised to 1M EUR)
    # Stable: 2019-2022 (1M EUR, made mandatory 2020)
    # Contraction: 2023 (threshold dropped to 500K)
    period = case_when(
      year <= 2015 ~ "pre",
      year == 2016 ~ "exp1",
      year == 2017 ~ "exp2",
      year >= 2018 & year <= 2022 ~ "post_expansion",
      year >= 2023 ~ "contraction",
      TRUE ~ "other"
    ),
    post_expansion = as.integer(year >= 2016),
    post_major = as.integer(year >= 2017)  # When threshold went to 500K+
  )

cat("\n=== Final panel ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Countries:", length(unique(panel$geo)), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("NACE sectors:", length(unique(panel$nace)), "\n")
cat("Size classes:", paste(sort(unique(panel$size)), collapse = ", "), "\n")

# Check Romania data availability
ro_panel <- panel %>% filter(geo == "RO", size == "TOTAL")
cat("\nRomania total enterprises by year:\n")
for (yr in sort(unique(ro_panel$year))) {
  # Sum across sectors using a broad NACE code
  total_naces <- ro_panel %>%
    filter(year == yr, nace %in% c("B-S_X_K642", "B-N_X_K642", "B-N"))
  if (nrow(total_naces) > 0) {
    cat("  ", yr, ":", total_naces$enterprises[1], "enterprises\n")
  }
}

# ---- 7. Create key analysis variables ----
# For micro-enterprise analysis, focus on size class 0-9 (captures most micro-enterprises)
# and look at the share relative to all firms

# Cross-country panel at the aggregate level (all sectors combined)
# Find working total NACE code
total_nace <- panel %>%
  filter(size == "TOTAL", geo == "RO") %>%
  group_by(nace) %>%
  summarise(n_years = n(), total_ent = sum(enterprises, na.rm = TRUE)) %>%
  arrange(desc(total_ent)) %>%
  head(5)

cat("\nTop NACE aggregates for Romania:\n")
print(total_nace)

# Use all NACE 1-letter sections for sector-level analysis
sector_panel <- panel %>%
  filter(nchar(nace) == 1) %>%
  filter(!nace %in% c("A", "O", "P", "Q", "R", "S", "T", "U"))  # Keep market sectors

cat("\nSector panel: ", nrow(sector_panel), "rows\n")
cat("Sectors:", paste(sort(unique(sector_panel$nace)), collapse = ", "), "\n")

# ---- 8. Create country-year aggregates ----
# Aggregate across sectors for the main country-level analysis
country_year <- panel %>%
  filter(nchar(nace) == 1, !nace %in% c("A", "O", "P", "Q", "R", "S", "T", "U")) %>%
  group_by(geo, year, size) %>%
  summarise(
    enterprises = sum(enterprises, na.rm = TRUE),
    turnover_m = sum(turnover_m, na.rm = TRUE),
    employment = sum(employment, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    avg_turnover = ifelse(enterprises > 0, turnover_m / enterprises, NA),
    avg_employment = ifelse(enterprises > 0, employment / enterprises, NA),
    ro = as.integer(geo == "RO"),
    cee = as.integer(geo %in% peers),
    post_expansion = as.integer(year >= 2016),
    post_major = as.integer(year >= 2017)
  )

# Create micro-enterprise share
micro_share <- country_year %>%
  select(geo, year, size, enterprises) %>%
  pivot_wider(names_from = size, values_from = enterprises, names_prefix = "ent_") %>%
  mutate(
    micro_share = `ent_0-9` / ent_TOTAL,
    small_share = `ent_10-19` / ent_TOTAL,
    medium_share = (`ent_20-49` + `ent_50-249`) / ent_TOTAL,
    large_share = ent_GE250 / ent_TOTAL
  )

cat("\n=== Country-year aggregates ===\n")
cat("Rows:", nrow(country_year), "\n")

# Romania micro-enterprise share over time
ro_micro <- micro_share %>% filter(geo == "RO")
cat("\nRomania micro-enterprise share (0-9 employees):\n")
for (i in seq_len(nrow(ro_micro))) {
  cat("  ", ro_micro$year[i], ": ", round(ro_micro$micro_share[i] * 100, 1), "%",
      " (", ro_micro$`ent_0-9`[i], " of ", ro_micro$ent_TOTAL[i], ")\n", sep = "")
}

# ---- 9. Save cleaned data ----
saveRDS(panel, "../data/panel.rds")
saveRDS(sector_panel, "../data/sector_panel.rds")
saveRDS(country_year, "../data/country_year.rds")
saveRDS(micro_share, "../data/micro_share.rds")

# Also save business demography data if available
if (file.exists("../data/bd_raw.rds")) {
  bd <- readRDS("../data/bd_raw.rds")

  # Extract birth and death rates
  # V11910 = enterprise births, V97010 = enterprise deaths, V11920 = enterprise births with employees
  bd_panel <- bd %>%
    filter(
      geo %in% all_countries,
      indic_sb %in% c("V11910", "V97010", "V11920", "V97020", "V11930", "V97030")
    ) %>%
    select(indic = indic_sb, legal_form = leg_form, nace = nace_r2,
           geo, year = TIME_PERIOD, value = values) %>%
    pivot_wider(names_from = indic, values_from = value) %>%
    rename(
      births = V11910,
      deaths = V97010
    )

  cat("\nBusiness demography panel:", nrow(bd_panel), "rows\n")
  cat("Years:", paste(sort(unique(bd_panel$year)), collapse = ", "), "\n")

  saveRDS(bd_panel, "../data/bd_panel.rds")
}

cat("\n=== Data cleaning complete ===\n")
