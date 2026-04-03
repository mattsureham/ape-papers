# 04_robustness.R — Robustness checks
# apep_1343: Private Governance and Bangladesh Apparel Exports After Rana Plaza

source("00_packages.R")

data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
partner <- fread(file.path(data_dir, "partner_panel.csv"))

# Recreate interaction terms
partner[, `:=`(
  accord_apparel_post = is_accord * is_apparel * post,
  alliance_apparel_post = is_alliance * is_apparel * post,
  accord_post = is_accord * post,
  alliance_post = is_alliance * post,
  apparel_post = is_apparel * post
)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================================
# R1: ALTERNATIVE POST PERIOD (2013 instead of 2014)
# ============================================================================
cat("--- R1: Alternative post cutoff (2013) ---\n")
partner[, post_2013 := as.integer(year >= 2013)]
partner[, acc_app_post13 := is_accord * is_apparel * post_2013]
partner[, all_app_post13 := is_alliance * is_apparel * post_2013]
partner[, acc_post13 := is_accord * post_2013]
partner[, all_post13 := is_alliance * post_2013]

r1 <- feols(log_exports ~ acc_app_post13 + all_app_post13 +
              acc_post13 + all_post13 |
              partnerCode^product_type + year^product_type,
            data = partner,
            cluster = ~partnerCode)
cat("Alliance DDD (post=2013):", round(coef(r1)["all_app_post13"], 3),
    "SE:", round(se(r1)["all_app_post13"], 3), "\n")
cat("Accord DDD (post=2013):", round(coef(r1)["acc_app_post13"], 3),
    "SE:", round(se(r1)["acc_app_post13"], 3), "\n\n")

# ============================================================================
# R2: LEAVE-ONE-OUT — Drop largest EU partners individually
# ============================================================================
cat("--- R2: Leave-one-out (drop largest EU partners) ---\n")

# Major EU partner codes
eu_large <- c(276, 250, 826, 724, 380, 528)  # DE, FR, UK, ES, IT, NL
eu_names <- c("Germany", "France", "UK", "Spain", "Italy", "Netherlands")

loo_results <- list()
for (i in seq_along(eu_large)) {
  loo_data <- partner[partnerCode != eu_large[i]]
  loo_mod <- feols(log_exports ~ accord_apparel_post + alliance_apparel_post +
                     accord_post + alliance_post |
                     partnerCode^product_type + year^product_type,
                   data = loo_data,
                   cluster = ~partnerCode)
  loo_results[[i]] <- data.table(
    dropped = eu_names[i],
    accord_ddd = coef(loo_mod)["accord_apparel_post"],
    alliance_ddd = coef(loo_mod)["alliance_apparel_post"],
    accord_se = se(loo_mod)["accord_apparel_post"],
    alliance_se = se(loo_mod)["alliance_apparel_post"]
  )
}
loo_dt <- rbindlist(loo_results)
cat("Leave-one-out results:\n")
print(loo_dt[, .(dropped,
                 accord = paste0(round(accord_ddd, 3), " (", round(accord_se, 3), ")"),
                 alliance = paste0(round(alliance_ddd, 3), " (", round(alliance_se, 3), ")"))])

# ============================================================================
# R3: SEPARATE HS CHAPTERS (61 knitted vs 62 woven)
# ============================================================================
cat("\n--- R3: Separate HS chapters ---\n")

ct_raw <- fread(file.path(data_dir, "comtrade_bgd_bilateral.csv"))
ct_raw <- ct_raw[partnerCode != 0]

# Classification
accord_codes <- c(40, 56, 100, 191, 203, 208, 233, 246, 250, 276, 300,
                  348, 372, 380, 428, 440, 442, 470, 528, 616, 620,
                  642, 703, 705, 724, 752, 826)
alliance_codes <- c(840, 124)

ct_raw[, regime_dest := fifelse(partnerCode %in% accord_codes, "Accord",
                                fifelse(partnerCode %in% alliance_codes, "Alliance", "Control"))]
ct_raw[, is_accord := as.integer(regime_dest == "Accord")]
ct_raw[, is_alliance := as.integer(regime_dest == "Alliance")]

for (hs in c(61, 62)) {
  hs_data <- ct_raw[cmdCode == hs, .(
    export_value = sum(primaryValue, na.rm = TRUE),
    log_exports = log(sum(primaryValue, na.rm = TRUE) + 1)
  ), by = .(year = period, partnerCode, regime_dest, is_accord, is_alliance)]

  hs_data[, post := as.integer(year >= 2014)]

  hs_mod <- feols(log_exports ~ is_accord:post + is_alliance:post |
                    partnerCode + year,
                  data = hs_data,
                  cluster = ~partnerCode)
  cat("HS", hs, "- Accord×Post:", round(coef(hs_mod)[1], 3),
      "SE:", round(se(hs_mod)[1], 3),
      "| Alliance×Post:", round(coef(hs_mod)[2], 3),
      "SE:", round(se(hs_mod)[2], 3), "\n")
}

# ============================================================================
# R4: PLACEBO — Non-apparel products only (should show no effect)
# ============================================================================
cat("\n--- R4: Placebo — Non-apparel products ---\n")

nonapparel <- partner[product_type == "non_apparel"]
r4 <- feols(log_exports ~ is_accord:post + is_alliance:post |
              partnerCode + year,
            data = nonapparel,
            cluster = ~partnerCode)
cat("Placebo (non-apparel):\n")
cat("Accord×Post:", round(coef(r4)[1], 3), "SE:", round(se(r4)[1], 3), "\n")
cat("Alliance×Post:", round(coef(r4)[2], 3), "SE:", round(se(r4)[2], 3), "\n")

# ============================================================================
# R5: FORMAL PRE-TREND TEST
# ============================================================================
cat("\n--- R5: Pre-trend test (linear trend × treatment) ---\n")

pre_data <- partner[post == 0 & product_type == "apparel"]
pre_data[, trend := year - 2008]

r5 <- feols(log_exports ~ trend:is_accord + trend:is_alliance |
              partnerCode + year,
            data = pre_data,
            cluster = ~partnerCode)
cat("Pre-trend (Accord × linear trend):", round(coef(r5)[1], 4),
    "p =", round(pvalue(r5)[1], 3), "\n")
cat("Pre-trend (Alliance × linear trend):", round(coef(r5)[2], 4),
    "p =", round(pvalue(r5)[2], 3), "\n")

# ============================================================================
# R6: EXCLUDING CONTROL COUNTRIES WITH COMPETING RMG SECTORS
# ============================================================================
cat("\n--- R6: Excluding competitor RMG countries ---\n")

# Vietnam (704), Cambodia (116), Myanmar (104), Indonesia (360), India (356)
# These may have absorbed diverted orders, confounding the control group
competitor_codes <- c(704, 116, 104, 360, 356)
partner_no_comp <- partner[!partnerCode %in% competitor_codes]

r6 <- feols(log_exports ~ accord_apparel_post + alliance_apparel_post +
              accord_post + alliance_post |
              partnerCode^product_type + year^product_type,
            data = partner_no_comp,
            cluster = ~partnerCode)
cat("DDD excl. competitors - Accord:", round(coef(r6)["accord_apparel_post"], 3),
    "SE:", round(se(r6)["accord_apparel_post"], 3), "\n")
cat("DDD excl. competitors - Alliance:", round(coef(r6)["alliance_apparel_post"], 3),
    "SE:", round(se(r6)["alliance_apparel_post"], 3), "\n")

# ============================================================================
# SAVE ALL ROBUSTNESS MODELS
# ============================================================================
save(r1, loo_dt, r4, r5, r6,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
