# 03_main_analysis.R — DiD estimation of clawback threshold effects on cross-border flows
# Identification: episodes in the "clawback window" (newly treated) vs shorter episodes (control)
# Two reforms: 6h→4h (Jan 2021), 4h→3h (Jan 2024)

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_episode_neighbor.csv"))

# ============================================================
# 1. The 2021 Reform: 6h → 4h threshold
# ============================================================
cat("=== 2021 REFORM ANALYSIS (6h → 4h) ===\n\n")

# Sample: episodes of 1-5 hours only (exclude >=6h "always treated")
# Treatment: duration 4-5h vs control 1-3h
# Period: 2019-2023 (exclude 2024+ which has the 3h rule)
df_2021 <- panel[treat_2021 %in% c("treated", "control") & year <= 2023]

cat(sprintf("Sample: %d episode-neighbor obs\n", nrow(df_2021)))
cat(sprintf("Treated episodes: %d, Control episodes: %d\n",
            uniqueN(df_2021[treated_2021 == 1]$episode_id),
            uniqueN(df_2021[treated_2021 == 0]$episode_id)))

# Create interaction variable
df_2021[, did_2021 := treated_2021 * post_2021]

# --- Model 1: Basic DiD with neighbor FE ---
m1 <- feols(mean_export_mw ~ did_2021 + treated_2021 + post_2021 | neighbor,
            data = df_2021, vcov = ~yearmonth)

# --- Model 2: Neighbor + year-month FE ---
m2 <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
            data = df_2021, vcov = ~yearmonth)

# --- Model 3: Add episode controls (price, day of week) ---
m3 <- feols(mean_export_mw ~ did_2021 + treated_2021 + mean_price + day_of_week |
              neighbor + yearmonth,
            data = df_2021, vcov = ~yearmonth)

# --- Model 4: Neighbor × post FE (most stringent) ---
df_2021[, neighbor_post := paste0(neighbor, "_", post_2021)]
m4 <- feols(mean_export_mw ~ did_2021 + treated_2021 + mean_price |
              neighbor_post + yearmonth,
            data = df_2021, vcov = ~yearmonth)

cat("\n--- 2021 Reform: DiD Results ---\n")
etable(m1, m2, m3, m4, se.below = TRUE,
       headers = c("Basic", "+YM FE", "+Controls", "+Nb×Post"))

# ============================================================
# 2. The 2024 Reform: 4h → 3h threshold
# ============================================================
cat("\n\n=== 2024 REFORM ANALYSIS (4h → 3h) ===\n\n")

df_2024 <- panel[treat_2024 %in% c("treated", "control") & year >= 2021]
df_2024[, did_2024 := treated_2024 * post_2024]

cat(sprintf("Sample: %d episode-neighbor obs\n", nrow(df_2024)))

m5 <- feols(mean_export_mw ~ did_2024 + treated_2024 | neighbor + yearmonth,
            data = df_2024, vcov = ~yearmonth)

m6 <- feols(mean_export_mw ~ did_2024 + treated_2024 + mean_price |
              neighbor + yearmonth,
            data = df_2024, vcov = ~yearmonth)

cat("\n--- 2024 Reform: DiD Results ---\n")
etable(m5, m6, se.below = TRUE,
       headers = c("+YM FE", "+Controls"))

# ============================================================
# 3. Pooled specification
# ============================================================
cat("\n\n=== POOLED SPECIFICATION ===\n\n")

# "Newly clawbacked" = episode duration now triggers clawback but wouldn't under old rule
panel[, newly_clawbacked := fcase(
  regime == "4h_rule" & duration_hours >= 4 & duration_hours <= 5, 1L,
  regime == "3h_rule" & duration_hours == 3, 1L,
  regime == "6h_rule" & duration_hours <= 5, 0L,
  regime == "4h_rule" & duration_hours <= 3, 0L,
  regime == "3h_rule" & duration_hours <= 2, 0L,
  default = NA_integer_
)]

df_pooled <- panel[!is.na(newly_clawbacked)]

m7 <- feols(mean_export_mw ~ newly_clawbacked | neighbor + yearmonth,
            data = df_pooled, vcov = ~yearmonth)

m8 <- feols(mean_export_mw ~ newly_clawbacked + mean_price | neighbor + yearmonth,
            data = df_pooled, vcov = ~yearmonth)

cat("--- Pooled Results ---\n")
etable(m7, m8, se.below = TRUE, headers = c("Pooled", "+Controls"))

# ============================================================
# 4. Heterogeneity: high vs low interconnector capacity
# ============================================================
cat("\n\n=== HETEROGENEITY ===\n\n")

# High-capacity neighbors (major interconnectors with Germany)
high_cap <- c("Austria", "France", "Switzerland", "Netherlands", "Denmark")
df_2021[, high_ic := as.integer(neighbor %in% high_cap)]

m_high <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
                data = df_2021[high_ic == 1], vcov = ~yearmonth)
m_low <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
               data = df_2021[high_ic == 0], vcov = ~yearmonth)

cat("High interconnector capacity:\n")
etable(m_high, se.below = TRUE)
cat("\nLow interconnector capacity:\n")
etable(m_low, se.below = TRUE)

# Interaction model
m_interact <- feols(mean_export_mw ~ did_2021 * high_ic + treated_2021 | neighbor + yearmonth,
                    data = df_2021, vcov = ~yearmonth)
cat("\nInteraction model:\n")
etable(m_interact, se.below = TRUE)

# ============================================================
# 5. Save diagnostics and model objects
# ============================================================

beta_2021 <- coef(m2)["did_2021"]
se_2021 <- se(m2)["did_2021"]
cat(sprintf("\n\nPreferred 2021 estimate: %.1f MW (SE: %.1f)\n", beta_2021, se_2021))

beta_2024 <- coef(m5)["did_2024"]
se_2024 <- se(m5)["did_2024"]
cat(sprintf("Preferred 2024 estimate: %.1f MW (SE: %.1f)\n", beta_2024, se_2024))

beta_pooled <- coef(m8)["newly_clawbacked"]
se_pooled <- se(m8)["newly_clawbacked"]
cat(sprintf("Pooled estimate: %.1f MW (SE: %.1f)\n", beta_pooled, se_pooled))

# Pre-treatment SD of outcome
sd_y_pre <- sd(df_2021[post_2021 == 0]$mean_export_mw)
cat(sprintf("Pre-treatment SD(Y): %.1f MW\n", sd_y_pre))

# Diagnostics for validate_v1.py
n_treated_2021 <- uniqueN(df_2021[treated_2021 == 1]$episode_id)
n_pre_2021 <- uniqueN(df_2021[post_2021 == 0]$yearmonth)
diag <- list(
  n_treated = n_treated_2021,
  n_pre = n_pre_2021,
  n_obs = nrow(df_2021)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

save(m1, m2, m3, m4, m5, m6, m7, m8, m_high, m_low, m_interact,
     df_2021, df_2024, df_pooled, panel,
     file = file.path(data_dir, "models.RData"))
cat("\nSaved models.RData\n")
cat("=== Main analysis complete ===\n")
