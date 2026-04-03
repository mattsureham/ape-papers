# 03_main_analysis.R — Main econometric analysis
# apep_1343: Private Governance and Bangladesh Apparel Exports After Rana Plaza
#
# Design: Triple DiD
#   Regime destination (Accord vs Alliance vs Control)
#   × Product (apparel vs non-apparel)
#   × Period (pre-Rana Plaza vs post)

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. LOAD DATA
# ============================================================================
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
partner <- fread(file.path(data_dir, "partner_panel.csv"))

cat("=== Analysis panel ===\n")
cat("Regime-product level:", nrow(panel), "obs\n")
cat("Partner level:", nrow(partner), "obs,", uniqueN(partner$partnerCode), "partners\n")

# ============================================================================
# 2. MAIN SPECIFICATION — REGIME-PRODUCT LEVEL DiD
# ============================================================================
cat("\n=== Main DiD Regressions (regime-product level) ===\n")

# Model 1: Simple DiD — Accord × Post (apparel only)
m1 <- feols(log_exports ~ is_accord * post + is_alliance * post |
              regime_dest + year,
            data = panel[product_type == "apparel"],
            vcov = "hetero")
cat("\nModel 1: Apparel-only DiD\n")
summary(m1)

# Model 2: DDD — regime × product × post
m2 <- feols(log_exports ~ accord_apparel_post + alliance_apparel_post +
              accord_post + alliance_post + apparel_post +
              accord_apparel + alliance_apparel |
              regime_dest + year,
            data = panel,
            vcov = "hetero")
cat("\nModel 2: Triple DiD (regime × product × post)\n")
summary(m2)

# ============================================================================
# 3. PARTNER-LEVEL REGRESSIONS (much more power)
# ============================================================================
cat("\n=== Partner-level regressions ===\n")

# Model 3: Partner-level DiD (apparel only)
m3 <- feols(log_exports ~ is_accord:post + is_alliance:post |
              partnerCode + year,
            data = partner[product_type == "apparel"],
            cluster = ~partnerCode)
cat("\nModel 3: Partner-level apparel DiD\n")
summary(m3)

# Model 4: Partner-level DDD
partner[, accord_apparel_post := is_accord * is_apparel * post]
partner[, alliance_apparel_post := is_alliance * is_apparel * post]
partner[, accord_post := is_accord * post]
partner[, alliance_post := is_alliance * post]
partner[, apparel_post := is_apparel * post]
partner[, accord_apparel := is_accord * is_apparel]
partner[, alliance_apparel := is_alliance * is_apparel]

m4 <- feols(log_exports ~ accord_apparel_post + alliance_apparel_post +
              accord_post + alliance_post + apparel_post |
              partnerCode^product_type + year^product_type,
            data = partner,
            cluster = ~partnerCode)
cat("\nModel 4: Partner-level Triple DiD\n")
summary(m4)

# Model 5: Continuous treatment — use pre-Rana Plaza EU export share
# as continuous treatment intensity
pre_shares <- partner[year <= 2012 & product_type == "apparel",
                      .(pre_eu_share = sum(export_value[is_accord == 1]) /
                          sum(export_value)),
                      by = partnerCode]
# This doesn't make sense at partner level (each partner IS one country).
# Instead, use continuous year interactions for event study.

# ============================================================================
# 4. EVENT STUDY — Dynamic effects by year
# ============================================================================
cat("\n=== Event study (apparel only, partner level) ===\n")

# Create year dummies interacted with Accord/Alliance
apparel_partner <- partner[product_type == "apparel"]

# Drop 2012 as reference year (last full pre-Rana Plaza year)
apparel_partner[, year_f := factor(year)]
apparel_partner[, year_f := relevel(year_f, ref = "2012")]

m5 <- feols(log_exports ~ i(year, is_accord, ref = 2012) +
              i(year, is_alliance, ref = 2012) |
              partnerCode + year,
            data = apparel_partner,
            cluster = ~partnerCode)
cat("\nModel 5: Event study\n")
summary(m5)

# ============================================================================
# 5. ALLIANCE DISBANDMENT TEST (treatment removal)
# ============================================================================
cat("\n=== Alliance disbandment analysis ===\n")

# The Alliance disbanded in December 2018
# Test: Did Alliance-destination exports change trajectory after 2018?
# We only have data through 2018, so this is limited.
# But we can test whether the Accord-Alliance gap widened in 2018 vs earlier post years
panel_apparel <- panel[product_type == "apparel"]
panel_apparel[, late_post := as.integer(year >= 2017)]  # 2017-2018 vs 2015-2016

m6 <- feols(log_exports ~ is_accord * late_post + is_alliance * late_post |
              regime_dest + year,
            data = panel_apparel[post == 1],
            vcov = "hetero")
cat("\nModel 6: Late-period divergence\n")
summary(m6)

# ============================================================================
# 6. SAVE DIAGNOSTICS AND RESULTS
# ============================================================================

# Diagnostics for validate_v1.py
n_treated_accord <- uniqueN(partner[is_accord == 1]$partnerCode)
n_treated_alliance <- uniqueN(partner[is_alliance == 1]$partnerCode)
n_pre <- length(unique(panel[post == 0]$year))
n_obs <- nrow(partner)

diagnostics <- list(
  n_treated = n_treated_accord + n_treated_alliance,
  n_pre = n_pre,
  n_obs = n_obs,
  n_accord_partners = n_treated_accord,
  n_alliance_partners = n_treated_alliance,
  n_control_partners = uniqueN(partner[is_accord == 0 & is_alliance == 0]$partnerCode),
  years = sort(unique(panel$year))
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save coefficient table for paper
coef_table <- data.table(
  model = c("M1_accord_post", "M1_alliance_post",
            "M3_accord_post", "M3_alliance_post",
            "M4_ddd_accord", "M4_ddd_alliance"),
  estimate = c(coef(m1)["is_accord:post"], coef(m1)["is_alliance:post"],
               coef(m3)["is_accord:post"], coef(m3)["is_alliance:post"],
               coef(m4)["accord_apparel_post"], coef(m4)["alliance_apparel_post"]),
  se = c(se(m1)["is_accord:post"], se(m1)["is_alliance:post"],
         se(m3)["is_accord:post"], se(m3)["is_alliance:post"],
         se(m4)["accord_apparel_post"], se(m4)["alliance_apparel_post"])
)
coef_table[, `:=`(
  t_stat = estimate / se,
  p_value = 2 * pt(-abs(estimate / se), df = Inf)
)]
fwrite(coef_table, file.path(data_dir, "main_coefficients.csv"))

cat("\n=== Key coefficients ===\n")
print(coef_table)

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m6, file = file.path(data_dir, "main_models.RData"))

cat("\n=== Main analysis complete ===\n")
