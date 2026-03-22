# 03_main_analysis.R — Main DiD analysis
# APEP-0750: Rescue or Ruin?

source("00_packages.R")

if (!requireNamespace("did", quietly = TRUE)) {
  install.packages("did", repos = "https://cloud.r-project.org")
}
library(did)

cat("=== Loading cleaned panel ===\n")
panel <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)
panel_country <- read_csv("../data/panel_country.csv", show_col_types = FALSE)

# ============================================================
# 1. CALLAWAY-SANT'ANNA: Country-level (total sector)
# ============================================================
cat("\n=== 1. Callaway-Sant'Anna: Country-level ===\n")

# Prepare data: need numeric id
cs_data <- panel_country %>%
  mutate(id = as.numeric(factor(country))) %>%
  filter(!is.na(bkrt_index)) %>%
  arrange(id, time_q)

# CS-DiD with not-yet-treated comparison group
cs_out <- tryCatch(
  att_gt(
    yname = "log_bkrt",
    tname = "time_q",
    idname = "id",
    gname = "first_treat",
    data = cs_data,
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",   # Doubly-robust
    base_period = "varying"
  ),
  error = function(e) {
    cat(sprintf("  CS-DiD error: %s\n", e$message))
    cat("  Trying with never-treated control...\n")
    att_gt(
      yname = "log_bkrt",
      tname = "time_q",
      idname = "id",
      gname = "first_treat",
      data = cs_data,
      control_group = "nevertreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "varying"
    )
  }
)

# Aggregate to overall ATT
att_overall <- aggte(cs_out, type = "simple", na.rm = TRUE)
cat("\n--- Overall ATT ---\n")
summary(att_overall)

# Event study aggregation
att_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 12, na.rm = TRUE)
cat("\n--- Event Study ATT ---\n")
summary(att_es)

# Save CS results
saveRDS(cs_out, "../data/cs_results.rds")
saveRDS(att_es, "../data/cs_event_study.rds")

# ============================================================
# 2. TWFE WITH FIXEST: Sector-level panel
# ============================================================
cat("\n=== 2. TWFE with fixest: Sector-level panel ===\n")

# Prepare sector-level data
sector_panel <- panel %>%
  filter(!is.na(bkrt_index), !is.na(first_treat)) %>%
  mutate(
    country_sector = paste(country, sector, sep = "_"),
    cs_id = as.numeric(factor(country_sector)),
    country_id = as.numeric(factor(country)),
    sector_id = as.numeric(factor(sector)),
    sector_time = paste(sector, time_q, sep = "_")
  )

# Main spec: log bankruptcy index ~ post × treatment
# with country×sector FE and sector×quarter FE
# Cluster SEs at country level
m1 <- feols(
  log_bkrt ~ post | country_sector + sector_time,
  data = sector_panel,
  cluster = ~country
)
cat("\n--- Model 1: TWFE (sector-level) ---\n")
summary(m1)

# Model 2: Add COVID stringency control
m2 <- feols(
  log_bkrt ~ post + stringency_mean | country_sector + sector_time,
  data = sector_panel,
  cluster = ~country
)
cat("\n--- Model 2: TWFE with COVID stringency ---\n")
summary(m2)

# Model 3: Country-level only (total sector)
m3 <- feols(
  log_bkrt ~ post | country + time_q,
  data = panel_country %>% filter(!is.na(bkrt_index)),
  cluster = ~country
)
cat("\n--- Model 3: Country-level TWFE ---\n")
summary(m3)

# Model 4: Country-level with stringency
m4 <- feols(
  log_bkrt ~ post + stringency_mean | country + time_q,
  data = panel_country %>% filter(!is.na(bkrt_index)),
  cluster = ~country
)
cat("\n--- Model 4: Country-level TWFE with stringency ---\n")
summary(m4)

# ============================================================
# 3. BY-SECTOR ANALYSIS
# ============================================================
cat("\n=== 3. By-sector analysis ===\n")

sectors <- unique(sector_panel$sector)
sector_results <- list()

for (s in sectors) {
  cat(sprintf("\n  Sector: %s\n", s))
  sdata <- sector_panel %>% filter(sector == s)

  m_s <- feols(
    log_bkrt ~ post | country + time_q,
    data = sdata,
    cluster = ~country
  )
  sector_results[[s]] <- m_s
  cat(sprintf("    β = %.4f, SE = %.4f, N = %d\n",
              coef(m_s)["post"], se(m_s)["post"], nobs(m_s)))
}

# ============================================================
# 4. SAVE DIAGNOSTICS
# ============================================================
cat("\n=== 4. Saving diagnostics ===\n")

# Count treated units
n_treated <- panel_country %>%
  filter(first_treat > 0) %>%
  distinct(country) %>%
  nrow()

# Count pre-periods (for earliest cohort)
earliest_treat <- min(panel_country$first_treat[panel_country$first_treat > 0], na.rm = TRUE)
n_pre <- earliest_treat - 1  # quarters before first treatment

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(sector_panel),
  n_countries = n_distinct(sector_panel$country),
  n_sectors = n_distinct(sector_panel$sector),
  n_quarters = n_distinct(sector_panel$time_q),
  att_overall = att_overall$overall.att,
  att_se = att_overall$overall.se,
  twfe_coef = as.numeric(coef(m1)["post"]),
  twfe_se = as.numeric(se(m1)["post"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics saved.\n")

# Save all TWFE models for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, sector = sector_results),
        "../data/twfe_models.rds")

cat("\n=== Main analysis complete ===\n")
cat(sprintf("  CS-DiD overall ATT: %.4f (SE: %.4f)\n", att_overall$overall.att, att_overall$overall.se))
cat(sprintf("  TWFE sector-level: %.4f (SE: %.4f)\n", coef(m1)["post"], se(m1)["post"]))
