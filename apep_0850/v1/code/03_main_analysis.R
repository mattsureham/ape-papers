## 03_main_analysis.R — apep_0850
## Triple-difference estimation: Geneva × high-bite × post
## Uses: fixest, data.table, dplyr

source("00_packages.R")
library(fixest)
library(data.table)

panel <- readRDS("../data/analysis_panel_fr.rds")

cat("=== Main Analysis: Geneva Minimum Wage and Cross-Border Workers ===\n\n")

# ============================================================
# 1. TRIPLE-DIFFERENCE (DDD) — Main specification
# ============================================================

# Restrict to high-bite and low-bite sectors only (drop medium)
ddd_panel <- panel[bite %in% c("high", "low")]
cat(sprintf("DDD panel: %s obs (high + low bite sectors)\n", format(nrow(ddd_panel), big.mark = ",")))

# Main specification: log(CBW) ~ Geneva × HighBite × Post
# FE: canton-sector, sector-quarter, canton-quarter
m1_ddd <- feols(
  log_cbw ~ geneva:high_bite:post + geneva:post + high_bite:post + geneva:high_bite |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- Model 1: DDD (canton-sector, sector-quarter, canton-quarter FE) ---\n")
summary(m1_ddd)

# Simpler FE: canton-sector + time FE
m2_ddd <- feols(
  log_cbw ~ geneva:high_bite:post + geneva:post + high_bite:post + geneva:high_bite |
    canton_sector + t,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- Model 2: DDD (canton-sector + time FE) ---\n")
summary(m2_ddd)

# Level specification (CBW in levels, not logs)
m3_ddd_level <- feols(
  cbw ~ geneva:high_bite:post + geneva:post + high_bite:post + geneva:high_bite |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- Model 3: DDD in levels ---\n")
summary(m3_ddd_level)

# ============================================================
# 2. WITHIN-GENEVA DiD (high-bite vs low-bite sectors)
# ============================================================

geneva_panel <- ddd_panel[canton == 25]

m4_geneva <- feols(
  log_cbw ~ high_bite:post | noga + t,
  data = geneva_panel,
  cluster = ~noga
)

cat("\n--- Model 4: Within-Geneva DiD (sector FE + time FE) ---\n")
summary(m4_geneva)

# ============================================================
# 3. EVENT STUDY (DDD) — Dynamic effects
# ============================================================

# Create event-time dummies (bin endpoints)
ddd_panel[, event_time_bin := fcase(
  event_time <= -9, -9L,
  event_time >= 16, 16L,
  default = event_time
)]

# Interaction term for i()
ddd_panel[, ge_hb := geneva * high_bite]

m5_event <- feols(
  log_cbw ~ i(event_time_bin, ge_hb, ref = -1) |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- Model 5: Event Study (DDD) ---\n")
summary(m5_event)

# ============================================================
# 4. WITHIN-GENEVA EVENT STUDY
# ============================================================

geneva_panel[, event_time_bin := fcase(
  event_time <= -9, -9L,
  event_time >= 16, 16L,
  default = event_time
)]

m6_event_ge <- feols(
  log_cbw ~ i(event_time_bin, high_bite, ref = -1) |
    noga + t,
  data = geneva_panel,
  cluster = ~noga
)

# Also store ge_hb on geneva panel for consistency
geneva_panel[, ge_hb := high_bite]

cat("\n--- Model 6: Within-Geneva Event Study ---\n")
summary(m6_event_ge)

# ============================================================
# 5. HETEROGENEITY: By individual sector
# ============================================================

# Sector-specific treatment effects within Geneva
m7_sector <- feols(
  log_cbw ~ i(noga, post, ref = 64) | noga + t,
  data = geneva_panel[bite %in% c("high", "low")],
  cluster = ~noga
)

cat("\n--- Model 7: Sector-specific effects within Geneva ---\n")
summary(m7_sector)

# ============================================================
# 6. SAVE RESULTS
# ============================================================

# Extract DDD coefficient and SE for reporting
ddd_coef <- coef(m1_ddd)["geneva:high_bite:post"]
ddd_se   <- se(m1_ddd)["geneva:high_bite:post"]
ddd_pval <- pvalue(m1_ddd)["geneva:high_bite:post"]

cat(sprintf("\n=== HEADLINE RESULT ===\n"))
cat(sprintf("DDD coefficient (log): %.4f (SE: %.4f, p: %.4f)\n", ddd_coef, ddd_se, ddd_pval))
cat(sprintf("DDD coefficient (%%): %.2f%%\n", (exp(ddd_coef) - 1) * 100))

# Pre-treatment SD of log CBW for SDE calculation
sd_y_pre <- sd(ddd_panel[post == 0]$log_cbw, na.rm = TRUE)
cat(sprintf("Pre-treatment SD(log CBW): %.4f\n", sd_y_pre))
cat(sprintf("SDE: %.4f\n", ddd_coef / sd_y_pre))

# Level result
level_coef <- coef(m3_ddd_level)["geneva:high_bite:post"]
level_se   <- se(m3_ddd_level)["geneva:high_bite:post"]
cat(sprintf("Level DDD: %.1f workers (SE: %.1f)\n", level_coef, level_se))

# Within-Geneva DiD
ge_coef <- coef(m4_geneva)["high_bite:post"]
ge_se   <- se(m4_geneva)["high_bite:post"]
cat(sprintf("Within-Geneva DiD (log): %.4f (SE: %.4f)\n", ge_coef, ge_se))

# Diagnostics JSON
diag <- list(
  n_treated = uniqueN(ddd_panel[canton == 25 & high_bite == 1]$canton_sector),
  n_pre = sum(ddd_panel$event_time < 0) / uniqueN(ddd_panel$canton_sector),
  n_obs = nrow(ddd_panel),
  n_cantons = uniqueN(ddd_panel$canton),
  n_sectors = uniqueN(ddd_panel$noga),
  n_quarters = uniqueN(ddd_panel$TIME_PERIOD),
  ddd_coef = round(ddd_coef, 4),
  ddd_se = round(ddd_se, 4),
  ddd_pval = round(ddd_pval, 4),
  sd_y_pre = round(sd_y_pre, 4),
  sde = round(ddd_coef / sd_y_pre, 4)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# Save model objects
saveRDS(list(
  m1_ddd = m1_ddd,
  m2_ddd = m2_ddd,
  m3_ddd_level = m3_ddd_level,
  m4_geneva = m4_geneva,
  m5_event = m5_event,
  m6_event_ge = m6_event_ge,
  m7_sector = m7_sector
), "../data/models.rds")

cat("\n=== Main analysis complete ===\n")
