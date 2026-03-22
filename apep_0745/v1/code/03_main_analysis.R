## 03_main_analysis.R — Main DiD analysis
## APEP-0745: The Freeport Gamble

source("00_packages.R")

cat("=== Main Analysis ===\n")
panel <- readRDS("../data/panel.rds")

# --- 1. TWFE baseline ---
cat("\n--- 1. TWFE Baseline ---\n")

twfe_main <- feols(
  log_inc ~ treat_post | la_code + time_int,
  data = panel,
  cluster = ~la_code
)
cat("TWFE coefficient:", round(coef(twfe_main)["treat_post"], 4),
    "SE:", round(se(twfe_main)["treat_post"], 4), "\n")

# Logistics sector
twfe_logistics <- feols(
  log(1 + n_logistics) ~ treat_post | la_code + time_int,
  data = panel,
  cluster = ~la_code
)
cat("TWFE logistics:", round(coef(twfe_logistics)["treat_post"], 4),
    "SE:", round(se(twfe_logistics)["treat_post"], 4), "\n")

# --- 2. Callaway-Sant'Anna ---
cat("\n--- 2. Callaway-Sant'Anna ---\n")

# Prepare for CS-DiD: need balanced panel with unique id, time, group
cs_data <- as.data.frame(panel[, .(
  la_id = as.integer(factor(la_code)),
  time = time_int,
  first_treat = first_treat,
  y = log_inc
)])

cs_out <- tryCatch({
  att_gt(
    yname = "y",
    tname = "time",
    idname = "la_id",
    gname = "first_treat",
    data = cs_data,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  cat("Trying with not-yet-treated control group...\n")
  att_gt(
    yname = "y",
    tname = "time",
    idname = "la_id",
    gname = "first_treat",
    data = cs_data,
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "universal"
  )
})

# Overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("CS-DiD ATT:", round(cs_agg$overall.att, 4),
    "SE:", round(cs_agg$overall.se, 4), "\n")

# Dynamic event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -24, max_e = 36)

# --- 3. Sun-Abraham (fixest) ---
cat("\n--- 3. Sun-Abraham ---\n")

sa_main <- feols(
  log_inc ~ sunab(first_treat, time_int) | la_code + time_int,
  data = panel[first_treat > 0 | treated_la == FALSE],
  cluster = ~la_code
)

# --- 4. Poisson model (count outcome) ---
cat("\n--- 4. Poisson ---\n")

pois_main <- fepois(
  n_inc ~ treat_post | la_code + time_int,
  data = panel,
  cluster = ~la_code
)
cat("Poisson IRR:", round(exp(coef(pois_main)["treat_post"]), 4),
    "(coef:", round(coef(pois_main)["treat_post"], 4), ")\n")

# --- Save results ---
results <- list(
  twfe_main = twfe_main,
  twfe_logistics = twfe_logistics,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_es = cs_es,
  sa_main = sa_main,
  pois_main = pois_main
)
saveRDS(results, "../data/results_main.rds")

# --- Write diagnostics.json ---
n_treated <- n_distinct(panel$la_code[panel$treated_la])
n_pre <- panel[treated_la == TRUE, n_distinct(ym[post == FALSE])]
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(panel$la_code[!panel$treated_la]),
  n_months = n_distinct(panel$ym),
  twfe_coef = round(coef(twfe_main)["treat_post"], 6),
  twfe_se = round(se(twfe_main)["treat_post"], 6),
  cs_att = round(cs_agg$overall.att, 6),
  cs_se = round(cs_agg$overall.se, 6)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics: n_treated=", n_treated, "n_pre=", n_pre, "n_obs=", n_obs, "\n")
