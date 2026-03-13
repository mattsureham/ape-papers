## 03_main_analysis.R — Main DiD regressions
## Callaway-Sant'Anna + fixest two-way FE for robustness

source("00_packages.R")

panel <- fread("../data/panel_main.csv")
df_triple <- fread("../data/panel_triple.csv")
df_men <- fread("../data/panel_placebo_men.csv")

cat("=== MAIN ANALYSIS ===\n")
cat(sprintf("Panel: %d states x %d years = %d obs\n",
            length(unique(panel$statefip)),
            length(unique(panel$year)),
            nrow(panel)))

# ============================================================
# A. Callaway-Sant'Anna — Healthcare share (62)
# ============================================================
cat("\n--- CS-DiD: Healthcare employment share ---\n")

# Remove rows with missing outcome
panel_cs <- panel[!is.na(share_62) & is.finite(share_62)]

# CS-DiD requires: yname, tname, idname, gname
cs_health <- att_gt(
  yname = "share_62",
  tname = "year",
  idname = "state_id",
  gname = "eitc_adopt_year",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "statefip",
  bstrap = TRUE,
  biters = 1000
)

cat("CS ATT(g,t) summary:\n")
print(summary(cs_health))

# Aggregate: simple ATT
att_simple_health <- aggte(cs_health, type = "simple")
cat(sprintf("\nSimple ATT (healthcare share): %.4f (SE: %.4f, p: %.3f)\n",
            att_simple_health$overall.att,
            att_simple_health$overall.se,
            2 * pnorm(-abs(att_simple_health$overall.att / att_simple_health$overall.se))))

# Dynamic event study
es_health <- aggte(cs_health, type = "dynamic", min_e = -6, max_e = 10)
cat("\nEvent study (healthcare share):\n")
es_health_df <- data.table(
  event_time = es_health$egt,
  att = es_health$att.egt,
  se = es_health$se.egt
)
es_health_df[, ci_lo := att - 1.96 * se]
es_health_df[, ci_hi := att + 1.96 * se]
print(es_health_df)

# ============================================================
# B. CS-DiD: Food services share (72)
# ============================================================
cat("\n--- CS-DiD: Food services employment share ---\n")

panel_cs2 <- panel[!is.na(share_72) & is.finite(share_72)]

cs_food <- att_gt(
  yname = "share_72",
  tname = "year",
  idname = "state_id",
  gname = "eitc_adopt_year",
  data = panel_cs2,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "statefip",
  bstrap = TRUE,
  biters = 1000
)

att_simple_food <- aggte(cs_food, type = "simple")
cat(sprintf("Simple ATT (food services share): %.4f (SE: %.4f, p: %.3f)\n",
            att_simple_food$overall.att,
            att_simple_food$overall.se,
            2 * pnorm(-abs(att_simple_food$overall.att / att_simple_food$overall.se))))

es_food <- aggte(cs_food, type = "dynamic", min_e = -6, max_e = 10)

# ============================================================
# C. CS-DiD: Retail share (44-45)
# ============================================================
cat("\n--- CS-DiD: Retail employment share ---\n")

panel_cs3 <- panel[!is.na(share_4445) & is.finite(share_4445)]

cs_retail <- att_gt(
  yname = "share_4445",
  tname = "year",
  idname = "state_id",
  gname = "eitc_adopt_year",
  data = panel_cs3,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "statefip",
  bstrap = TRUE,
  biters = 1000
)

att_simple_retail <- aggte(cs_retail, type = "simple")
cat(sprintf("Simple ATT (retail share): %.4f (SE: %.4f, p: %.3f)\n",
            att_simple_retail$overall.att,
            att_simple_retail$overall.se,
            2 * pnorm(-abs(att_simple_retail$overall.att / att_simple_retail$overall.se))))

# ============================================================
# D. CS-DiD: Log total employment (extensive margin check)
# ============================================================
cat("\n--- CS-DiD: Log total employment (extensive margin) ---\n")

panel_cs4 <- panel[!is.na(log_total_emp) & is.finite(log_total_emp)]

cs_emp <- att_gt(
  yname = "log_total_emp",
  tname = "year",
  idname = "state_id",
  gname = "eitc_adopt_year",
  data = panel_cs4,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "statefip",
  bstrap = TRUE,
  biters = 1000
)

att_simple_emp <- aggte(cs_emp, type = "simple")
cat(sprintf("Simple ATT (log employment): %.4f (SE: %.4f, p: %.3f)\n",
            att_simple_emp$overall.att,
            att_simple_emp$overall.se,
            2 * pnorm(-abs(att_simple_emp$overall.att / att_simple_emp$overall.se))))

# ============================================================
# E. TWFE with fixest (for comparison)
# ============================================================
cat("\n--- TWFE regressions (fixest) ---\n")

twfe_health <- feols(share_62 ~ treated | statefip + year,
                     data = panel, cluster = ~statefip)
twfe_food   <- feols(share_72 ~ treated | statefip + year,
                     data = panel, cluster = ~statefip)
twfe_retail <- feols(share_4445 ~ treated | statefip + year,
                     data = panel, cluster = ~statefip)
twfe_emp    <- feols(log_total_emp ~ treated | statefip + year,
                     data = panel, cluster = ~statefip)

cat("\nTWFE results:\n")
etable(twfe_health, twfe_food, twfe_retail, twfe_emp)

# ============================================================
# F. Triple-diff: low-edu vs high-edu women
# ============================================================
cat("\n--- Triple-diff: Low vs High education women ---\n")

triple_health <- feols(ind_share ~ treated_low + treated + low_edu |
                       statefip^edu_group + year^edu_group,
                       data = df_triple[industry == "62"],
                       cluster = ~statefip)

triple_food <- feols(ind_share ~ treated_low + treated + low_edu |
                     statefip^edu_group + year^edu_group,
                     data = df_triple[industry == "72"],
                     cluster = ~statefip)

cat("Triple-diff results:\n")
etable(triple_health, triple_food)

# ============================================================
# G. Placebo: men (low-edu)
# ============================================================
cat("\n--- Placebo: Low-edu MEN ---\n")

placebo_health <- feols(ind_share ~ treated | statefip + year,
                        data = df_men[industry == "62"],
                        cluster = ~statefip)

placebo_food <- feols(ind_share ~ treated | statefip + year,
                      data = df_men[industry == "72"],
                      cluster = ~statefip)

cat("Placebo (men) results:\n")
etable(placebo_health, placebo_food)

# ============================================================
# H. Save results for tables
# ============================================================

# Store CS results
cs_results <- list(
  health = list(att = att_simple_health$overall.att,
                se = att_simple_health$overall.se),
  food = list(att = att_simple_food$overall.att,
              se = att_simple_food$overall.se),
  retail = list(att = att_simple_retail$overall.att,
                se = att_simple_retail$overall.se),
  emp = list(att = att_simple_emp$overall.att,
             se = att_simple_emp$overall.se)
)

# Event study results
es_results <- list(
  health = es_health_df,
  food = data.table(event_time = es_food$egt,
                    att = es_food$att.egt,
                    se = es_food$se.egt)
)

# Save all model objects
save(cs_health, cs_food, cs_retail, cs_emp,
     att_simple_health, att_simple_food, att_simple_retail, att_simple_emp,
     es_health, es_food,
     twfe_health, twfe_food, twfe_retail, twfe_emp,
     triple_health, triple_food,
     placebo_health, placebo_food,
     cs_results, es_results,
     file = "../data/analysis_results.RData")

# ============================================================
# I. Diagnostics (for validate_v1.py)
# ============================================================
n_treated_states <- length(unique(panel$statefip[panel$eitc_adopt_year > 0]))
n_pre <- min(panel$year[panel$eitc_adopt_year > 0]) - min(panel$year)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = as.integer(n_pre),
  n_obs = nrow(panel)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
