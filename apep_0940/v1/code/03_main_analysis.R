## 03_main_analysis.R — Main DiD analysis
## Denmark Parallel Society Designation and Displacement (apep_0940)

library(data.table)
library(fixest)
library(did)
library(jsonlite)

cat("=== Main analysis for apep_0940 ===\n")

panel <- fread("data/panel.csv")

# Ensure numeric
panel[, mun_code_num := as.integer(mun_code)]

# -------------------------------------------------------------------
# 1. Two-way Fixed Effects (TWFE) DiD — Baseline
# -------------------------------------------------------------------
cat("\n--- TWFE DiD estimates ---\n")

# Primary outcome: non-Western immigrant/descendant share
m1 <- feols(nw_share ~ treat_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)
cat("\nModel 1: NW share ~ treat_post | mun + year FE\n")
print(summary(m1))

# Log non-Western population
m2 <- feols(log_nw ~ treat_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)
cat("\nModel 2: log(NW pop) ~ treat_post | mun + year FE\n")
print(summary(m2))

# Non-Western employment rate (among non-Western immigrants)
m3 <- feols(emp_nw_imm ~ treat_post | mun_code_num + year,
            data = panel[!is.na(emp_nw_imm)], cluster = ~mun_code_num)
cat("\nModel 3: NW immigrant employment rate ~ treat_post | mun + year FE\n")
print(summary(m3))

# Total population (check if total pop is affected)
m4 <- feols(log_total ~ treat_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)
cat("\nModel 4: log(total pop) ~ treat_post | mun + year FE\n")
print(summary(m4))

# -------------------------------------------------------------------
# 2. Treatment intensity specification
# -------------------------------------------------------------------
cat("\n--- Treatment intensity estimates ---\n")

m5 <- feols(nw_share ~ intensity_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)
cat("\nModel 5: NW share ~ intensity_post | mun + year FE\n")
print(summary(m5))

m6 <- feols(log_nw ~ intensity_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)
cat("\nModel 6: log(NW pop) ~ intensity_post | mun + year FE\n")
print(summary(m6))

# -------------------------------------------------------------------
# 3. Event study (annual leads/lags)
# -------------------------------------------------------------------
cat("\n--- Event study ---\n")

# Drop observations before 2010 (less reliable) and cap event time
panel_es <- panel[year >= 2010]
panel_es[, event_time_f := factor(event_time)]

# Omit t = -1 as reference
es1 <- feols(nw_share ~ i(event_time, treated, ref = -1) | mun_code_num + year,
             data = panel_es, cluster = ~mun_code_num)
cat("\nEvent study: NW share\n")
print(summary(es1))

es2 <- feols(log_nw ~ i(event_time, treated, ref = -1) | mun_code_num + year,
             data = panel_es, cluster = ~mun_code_num)
cat("\nEvent study: log(NW pop)\n")
print(summary(es2))

es3 <- feols(emp_nw_imm ~ i(event_time, treated, ref = -1) | mun_code_num + year,
             data = panel_es[!is.na(emp_nw_imm)], cluster = ~mun_code_num)
cat("\nEvent study: NW employment rate\n")
print(summary(es3))

# -------------------------------------------------------------------
# 4. Callaway-Sant'Anna (robust to heterogeneous treatment effects)
# -------------------------------------------------------------------
cat("\n--- Callaway-Sant'Anna ---\n")

# For CS, need: yname, tname, idname, gname
# gname = first treatment period (2019 for all treated, 0 for never-treated)
panel_cs <- copy(panel[year >= 2010])
panel_cs[, g := fifelse(treated == 1, 2019L, 0L)]

tryCatch({
  cs_nw <- att_gt(
    yname = "nw_share",
    tname = "year",
    idname = "mun_code_num",
    gname = "g",
    data = as.data.frame(panel_cs),
    control_group = "nevertreated",
    base_period = "universal"
  )
  cat("\nCS group-time ATTs:\n")
  print(summary(cs_nw))

  cs_agg <- aggte(cs_nw, type = "dynamic")
  cat("\nCS dynamic aggregation:\n")
  print(summary(cs_agg))

  cs_simple <- aggte(cs_nw, type = "simple")
  cat("\nCS simple aggregation (overall ATT):\n")
  print(summary(cs_simple))

  saveRDS(cs_nw, "data/cs_nw.rds")
  saveRDS(cs_agg, "data/cs_agg.rds")
}, error = function(e) {
  cat("CS estimation failed:", conditionMessage(e), "\n")
  cat("Continuing with TWFE results.\n")
})

# -------------------------------------------------------------------
# 5. Save key results and diagnostics
# -------------------------------------------------------------------
cat("\n--- Saving results ---\n")

results <- list(
  twfe_nw_share = list(
    coef = coef(m1)["treat_post"],
    se = sqrt(vcov(m1)["treat_post", "treat_post"]),
    pval = summary(m1)$coeftable["treat_post", "Pr(>|t|)"]
  ),
  twfe_log_nw = list(
    coef = coef(m2)["treat_post"],
    se = sqrt(vcov(m2)["treat_post", "treat_post"]),
    pval = summary(m2)$coeftable["treat_post", "Pr(>|t|)"]
  ),
  twfe_emp = list(
    coef = coef(m3)["treat_post"],
    se = sqrt(vcov(m3)["treat_post", "treat_post"]),
    pval = summary(m3)$coeftable["treat_post", "Pr(>|t|)"]
  ),
  intensity_nw_share = list(
    coef = coef(m5)["intensity_post"],
    se = sqrt(vcov(m5)["intensity_post", "intensity_post"]),
    pval = summary(m5)$coeftable["intensity_post", "Pr(>|t|)"]
  )
)

saveRDS(results, "data/main_results.rds")
saveRDS(m1, "data/m1_nw_share.rds")
saveRDS(m2, "data/m2_log_nw.rds")
saveRDS(m3, "data/m3_emp.rds")
saveRDS(m4, "data/m4_log_total.rds")
saveRDS(m5, "data/m5_intensity_nw.rds")
saveRDS(m6, "data/m6_intensity_log_nw.rds")
saveRDS(es1, "data/es1_nw_share.rds")
saveRDS(es2, "data/es2_log_nw.rds")
saveRDS(es3, "data/es3_emp.rds")

# Diagnostics for validation
# Treatment is defined at estate level: 29 estates designated in 2018
# across 15 municipalities (clustered SEs at municipality level)
designation <- fread("data/designation_2018.csv")
diagnostics <- list(
  n_treated = nrow(designation),  # 29 treated estates
  n_pre = length(unique(panel$year[panel$year < 2019])),
  n_obs = nrow(panel)
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
