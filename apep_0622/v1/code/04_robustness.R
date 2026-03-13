# 04_robustness.R — Robustness checks
# APEP-0622: Taxing the Transition — EV Registration Fees and Adoption

source("code/00_packages.R")

cat("=== 04_robustness.R ===\n")

# ============================================================
# 1. LOAD DATA
# ============================================================
panel <- readRDS("data/analysis_panel.rds")
cat("Panel loaded:", nrow(panel), "obs\n")

# ============================================================
# 2. PLACEBO: PHEV AS OUTCOME
# ============================================================
# PHEVs are sometimes exempt from EV fees or face lower fees.
# If fees deter BEV adoption, we should see a smaller (or null) effect on PHEVs.
cat("\n=== Placebo: log(PHEV) as outcome ===\n")

cs_phev_gt <- att_gt(
  yname    = "log_phev",
  tname    = "year",
  idname   = "state_id",
  gname    = "first_treat",
  xformla  = ~ 1,
  data     = panel,
  control_group = "notyettreated",
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000,
  clustervars   = "state_id",
  print_details = FALSE
)

cs_phev_simple <- aggte(cs_phev_gt, type = "simple")
cs_phev_es     <- aggte(cs_phev_gt, type = "dynamic", min_e = -5, max_e = 5)

cat("PHEV ATT:", round(cs_phev_simple$overall.att, 4),
    "(SE:", round(cs_phev_simple$overall.se, 4), ")\n")

# TWFE comparison for PHEV
twfe_phev <- feols(log_phev ~ treated | state_id + year,
                   data = panel, cluster = ~state_id)
cat("TWFE PHEV:", round(coef(twfe_phev)["treated"], 4),
    "(SE:", round(se(twfe_phev)["treated"], 4), ")\n")

# ============================================================
# 3. ALTERNATIVE OUTCOME: log(ev_total)
# ============================================================
cat("\n=== Alternative outcome: log(ev_total) ===\n")

cs_total_gt <- att_gt(
  yname    = "log_ev_total",
  tname    = "year",
  idname   = "state_id",
  gname    = "first_treat",
  xformla  = ~ 1,
  data     = panel,
  control_group = "notyettreated",
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000,
  clustervars   = "state_id",
  print_details = FALSE
)

cs_total_simple <- aggte(cs_total_gt, type = "simple")
cs_total_es     <- aggte(cs_total_gt, type = "dynamic", min_e = -5, max_e = 5)

cat("EV Total ATT:", round(cs_total_simple$overall.att, 4),
    "(SE:", round(cs_total_simple$overall.se, 4), ")\n")

# ============================================================
# 4. DOSE-RESPONSE: CONTINUOUS FEE AMOUNT
# ============================================================
cat("\n=== Dose-response: fee amount ===\n")

# Fee in $100s for interpretability
panel <- panel %>%
  mutate(fee_100 = fee_amount / 100)

# TWFE with continuous treatment (fee amount)
twfe_dose <- feols(log_bev ~ fee_100 | state_id + year,
                   data = panel, cluster = ~state_id)

cat("Dose-response (per $100 fee):", round(coef(twfe_dose)["fee_100"], 4),
    "(SE:", round(se(twfe_dose)["fee_100"], 4), ")\n")
summary(twfe_dose)

# Also with log(ev_total) as outcome
twfe_dose_total <- feols(log_ev_total ~ fee_100 | state_id + year,
                         data = panel, cluster = ~state_id)

# ============================================================
# 5. ALTERNATIVE CONTROL GROUP: NEVER-TREATED ONLY
# ============================================================
cat("\n=== CS-DiD with never-treated control group ===\n")

cs_never_gt <- att_gt(
  yname    = "log_bev",
  tname    = "year",
  idname   = "state_id",
  gname    = "first_treat",
  xformla  = ~ 1,
  data     = panel,
  control_group = "nevertreated",
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000,
  clustervars   = "state_id",
  print_details = FALSE
)

cs_never_simple <- aggte(cs_never_gt, type = "simple")
cs_never_es     <- aggte(cs_never_gt, type = "dynamic", min_e = -5, max_e = 5)

cat("Never-treated ATT:", round(cs_never_simple$overall.att, 4),
    "(SE:", round(cs_never_simple$overall.se, 4), ")\n")

# ============================================================
# 6. SAVE ALL ROBUSTNESS RESULTS
# ============================================================
robustness <- list(
  # Placebo: PHEV
  phev_cs_gt     = cs_phev_gt,
  phev_cs_simple = cs_phev_simple,
  phev_cs_es     = cs_phev_es,
  phev_twfe      = twfe_phev,
  # Alternative outcome: ev_total
  total_cs_gt     = cs_total_gt,
  total_cs_simple = cs_total_simple,
  total_cs_es     = cs_total_es,
  # Dose-response
  dose_twfe       = twfe_dose,
  dose_twfe_total = twfe_dose_total,
  # Never-treated control
  never_cs_gt     = cs_never_gt,
  never_cs_simple = cs_never_simple,
  never_cs_es     = cs_never_es
)

saveRDS(robustness, "data/robustness_results.rds")
cat("\nSaved: data/robustness_results.rds\n")

# ============================================================
# 7. SUMMARY TABLE
# ============================================================
cat("\n=== Robustness Summary ===\n")
cat(sprintf("%-35s  %8s  %8s  %s\n", "Specification", "ATT", "SE", "Sig"))
cat(paste(rep("-", 65), collapse = ""), "\n")

specs <- list(
  list("(1) Baseline CS-DiD (log BEV)",
       readRDS("data/cs_results.rds")$simple$overall.att,
       readRDS("data/cs_results.rds")$simple$overall.se),
  list("(2) Placebo: log(PHEV)",
       cs_phev_simple$overall.att, cs_phev_simple$overall.se),
  list("(3) Alt outcome: log(ev_total)",
       cs_total_simple$overall.att, cs_total_simple$overall.se),
  list("(4) Never-treated control",
       cs_never_simple$overall.att, cs_never_simple$overall.se),
  list("(5) Dose-response (per $100)",
       coef(twfe_dose)["fee_100"], se(twfe_dose)["fee_100"])
)

for (s in specs) {
  t_stat <- abs(s[[2]] / s[[3]])
  sig <- ifelse(t_stat > 2.576, "***",
         ifelse(t_stat > 1.960, "**",
         ifelse(t_stat > 1.645, "*", "")))
  cat(sprintf("%-35s  %8.4f  %8.4f  %s\n", s[[1]], s[[2]], s[[3]], sig))
}

cat("\n=== 04_robustness.R complete ===\n")
