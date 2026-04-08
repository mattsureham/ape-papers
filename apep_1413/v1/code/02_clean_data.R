# 02_clean_data.R — Construct analysis panel for ASAN SCM
# Paper: apep_1413

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================

wdi <- read.csv(file.path(data_dir, "wdi_panel.csv"), stringsAsFactors = FALSE)
es <- read.csv(file.path(data_dir, "enterprise_survey.csv"), stringsAsFactors = FALSE)
wgi <- read.csv(file.path(data_dir, "governance_indicators.csv"), stringsAsFactors = FALSE)

cat(sprintf("WDI: %d obs, ES: %d obs, WGI: %d obs\n", nrow(wdi), nrow(es), nrow(wgi)))

# ============================================================
# 2. Pivot WDI to wide format (one row per country-year)
# ============================================================

# Rename indicators for cleaner column names
indicator_names <- c(
  "IC.BUS.NREG"       = "new_registrations",
  "NY.GDP.PCAP.PP.KD" = "gdp_pc",
  "NV.IND.TOTL.ZS"    = "industry_va",
  "SL.UEM.TOTL.ZS"    = "unemployment",
  "FP.CPI.TOTL.ZG"    = "inflation",
  "BX.KLT.DINV.WD.GD.ZS" = "fdi_gdp",
  "GC.REV.XGRT.GD.ZS" = "revenue_gdp"
)

wdi$var_name <- indicator_names[wdi$indicator]
wdi <- wdi[!is.na(wdi$var_name), ]

panel_wide <- wdi %>%
  select(iso3, year, var_name, value) %>%
  pivot_wider(names_from = var_name, values_from = value)

cat(sprintf("Panel (wide): %d country-year observations\n", nrow(panel_wide)))

# ============================================================
# 3. Add governance indicators
# ============================================================

wgi_names <- c(
  "CC.EST" = "corruption_control",
  "GE.EST" = "govt_effectiveness"
)

wgi$var_name <- wgi_names[wgi$indicator]
wgi <- wgi[!is.na(wgi$var_name), ]

wgi_wide <- wgi %>%
  select(iso3, year, var_name, value) %>%
  pivot_wider(names_from = var_name, values_from = value)

panel_wide <- panel_wide %>%
  left_join(wgi_wide, by = c("iso3", "year"))

# ============================================================
# 4. Add treatment indicator
# ============================================================

# Azerbaijan treated from 2013 (ASAN operational)
panel_wide$treated <- ifelse(panel_wide$iso3 == "AZE", 1, 0)
panel_wide$post <- ifelse(panel_wide$year >= 2013, 1, 0)
panel_wide$treat_post <- panel_wide$treated * panel_wide$post

# ============================================================
# 5. Filter to balanced panel for SCM
# ============================================================

# Keep countries with sufficient business registration data
# Need data for at least 2008-2019 (4 pre + 7 post)
reg_coverage <- panel_wide %>%
  filter(!is.na(new_registrations)) %>%
  group_by(iso3) %>%
  summarize(
    n = n(),
    min_yr = min(year),
    max_yr = max(year),
    has_pre = sum(year < 2013) >= 4,
    has_post = sum(year >= 2013) >= 5,
    .groups = "drop"
  ) %>%
  filter(has_pre & has_post)

cat("\nCountries with sufficient coverage:\n")
print(reg_coverage)

# Keep only these countries
panel <- panel_wide %>%
  filter(iso3 %in% reg_coverage$iso3) %>%
  filter(year >= 2006 & year <= 2022) %>%
  arrange(iso3, year)

# Log-transform registrations for more symmetric distribution
panel$log_reg <- log(panel$new_registrations + 1)

# Create country numeric ID for SCM
panel$country_id <- as.numeric(factor(panel$iso3))

cat(sprintf("\nFinal panel: %d obs, %d countries, years %d-%d\n",
            nrow(panel), length(unique(panel$iso3)),
            min(panel$year), max(panel$year)))

# ============================================================
# 6. Create Enterprise Survey cross-country panel
# ============================================================

# Bribery data (sparse — only ES survey years)
es_brib <- es %>%
  filter(indicator == "IC.FRM.BRIB.ZS") %>%
  select(iso3, year, value) %>%
  rename(bribery_pct = value)

# Gifts for contracts
es_gifts <- es %>%
  filter(indicator == "IC.FRM.CORR.ZS") %>%
  select(iso3, year, value) %>%
  rename(gifts_pct = value)

es_panel <- es_brib %>%
  full_join(es_gifts, by = c("iso3", "year"))

es_panel$treated <- ifelse(es_panel$iso3 == "AZE", 1, 0)
es_panel$post <- ifelse(es_panel$year >= 2013, 1, 0)

cat(sprintf("\nEnterprise Survey panel: %d obs\n", nrow(es_panel)))

# ============================================================
# 7. Summary statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

# Azerbaijan vs. donor pool, pre vs. post
summary_stats <- panel %>%
  mutate(group = ifelse(iso3 == "AZE", "Azerbaijan", "Donor Pool"),
         period = ifelse(year < 2013, "Pre-ASAN (2006-2012)", "Post-ASAN (2013-2022)")) %>%
  group_by(group, period) %>%
  summarize(
    across(c(new_registrations, gdp_pc, unemployment, inflation, fdi_gdp),
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE))),
    n = n(),
    .groups = "drop"
  )

cat("Summary by group and period:\n")
print(summary_stats)

# ============================================================
# 8. Save cleaned datasets
# ============================================================

write.csv(panel, file.path(data_dir, "analysis_panel.csv"), row.names = FALSE)
write.csv(es_panel, file.path(data_dir, "es_bribery_panel.csv"), row.names = FALSE)

cat("\nCleaned datasets saved.\n")
