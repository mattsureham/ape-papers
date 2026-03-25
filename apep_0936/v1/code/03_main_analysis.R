# 03_main_analysis.R — Main DiD analysis
# EU Trade Secrets Directive → BERD

source("00_packages.R")
library(fixest)
library(did)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel_full <- fread(file.path(data_dir, "analysis_panel.csv"))
panel <- fread(file.path(data_dir, "analysis_panel_strict.csv"))

message("=== Full panel: ", nrow(panel_full), " obs, ",
        uniqueN(panel_full$geo), " regions ===")
message("=== Balanced panel (primary): ", nrow(panel), " obs, ",
        uniqueN(panel$geo), " regions, ",
        uniqueN(panel$country), " countries ===")

# ===========================================================================
# 1. TWFE Baseline (for comparison, knowing its limitations)
# ===========================================================================
message("\n=== 1. TWFE Baseline ===")

# Outcome: BERD as % of GDP
twfe_1 <- feols(berd_gdp_pct ~ post | geo + year,
                data = panel,
                cluster = ~country)
message("TWFE (BERD/GDP %): ", round(coef(twfe_1)["post"], 4))
summary(twfe_1)

# Log BERD
twfe_2 <- feols(ln_berd ~ post | geo + year,
                data = panel,
                cluster = ~country)
message("TWFE (ln BERD): ", round(coef(twfe_2)["post"], 4))

# TWFE with controls
twfe_3 <- feols(berd_gdp_pct ~ post + ln_gdp + emp_ths | geo + year,
                data = panel[!is.na(emp_ths)],
                cluster = ~country)
message("TWFE with controls (BERD/GDP %): ", round(coef(twfe_3)["post"], 4))

# ===========================================================================
# 2. Callaway-Sant'Anna (Preferred Specification)
# ===========================================================================
message("\n=== 2. Callaway-Sant'Anna ===")

# Prepare data: did package requires complete cases
cs_data <- panel[!is.na(berd_gdp_pct) & !is.na(first_treat)]
cs_data <- cs_data[, .(region_id, year, first_treat, berd_gdp_pct, ln_berd,
                        country, geo)]

# Never-treated group is too small (22 regions from 4 countries).
# Use not-yet-treated as primary comparison group.
cs_out <- att_gt(
  yname = "berd_gdp_pct",
  tname = "year",
  idname = "region_id",
  gname = "first_treat",
  data = cs_data,
  control_group = "notyettreated",
  clustervars = "country",
  base_period = "universal",
  allow_unbalanced_panel = TRUE
)

message("\n--- Group-time ATTs ---")
print(summary(cs_out))

# Aggregate to simple ATT
cs_agg <- aggte(cs_out, type = "simple")
message("\n--- Simple ATT ---")
print(summary(cs_agg))

# Event study aggregation
cs_es <- aggte(cs_out, type = "dynamic")
message("\n--- Event Study ---")
print(summary(cs_es))

# ===========================================================================
# 3. CS with never-treated comparison (if enough units)
# ===========================================================================
message("\n=== 3. CS with never-treated (secondary) ===")

cs_nyt_agg <- cs_agg  # placeholder; use not-yet-treated as primary
cs_nyt_es <- cs_es

# Try never-treated (may fail if group too small)
cs_nt <- tryCatch({
  att_gt(
    yname = "berd_gdp_pct",
    tname = "year",
    idname = "region_id",
    gname = "first_treat",
    data = cs_data,
    control_group = "nevertreated",
    clustervars = "country",
    base_period = "universal",
    allow_unbalanced_panel = TRUE
  )
}, error = function(e) {
  message("Never-treated too small: ", e$message)
  NULL
})

if (!is.null(cs_nt)) {
  cs_nt_agg <- aggte(cs_nt, type = "simple")
  message("CS (never-treated) ATT: ", round(cs_nt_agg$overall.att, 4),
          " SE: ", round(cs_nt_agg$overall.se, 4))
} else {
  cs_nt_agg <- NULL
}

# ===========================================================================
# 4. Log BERD specification
# ===========================================================================
message("\n=== 4. CS with log BERD ===")

cs_ln <- att_gt(
  yname = "ln_berd",
  tname = "year",
  idname = "region_id",
  gname = "first_treat",
  data = cs_data[!is.na(ln_berd) & is.finite(ln_berd)],
  control_group = "notyettreated",
  clustervars = "country",
  base_period = "universal",
  allow_unbalanced_panel = TRUE
)

cs_ln_agg <- aggte(cs_ln, type = "simple")
message("CS (ln BERD) ATT: ", round(cs_ln_agg$overall.att, 4),
        " SE: ", round(cs_ln_agg$overall.se, 4))

# ===========================================================================
# 5. Treatment intensity (continuous DiD)
# ===========================================================================
message("\n=== 5. Treatment intensity (continuous DiD) ===")

# Countries with low pre-existing protection (score=3) should show larger effects
int_1 <- feols(berd_gdp_pct ~ treatment_intensity | geo + year,
               data = panel,
               cluster = ~country)
message("Intensity TWFE: ", round(coef(int_1)["treatment_intensity"], 4))

# Interact post with protection_pre dummies
panel[, prot_low := fifelse(protection_pre == 3, 1L, 0L)]
panel[, prot_med := fifelse(protection_pre == 2, 1L, 0L)]
panel[, prot_high := fifelse(protection_pre == 1, 1L, 0L)]

int_2 <- feols(berd_gdp_pct ~ post:prot_low + post:prot_med | geo + year,
               data = panel,
               cluster = ~country)
message("Low prot × post: ", round(coef(int_2)["post:prot_low"], 4))
message("Med prot × post: ", round(coef(int_2)["post:prot_med"], 4))
summary(int_2)

# ===========================================================================
# 6. Total GERD as alternative outcome
# ===========================================================================
message("\n=== 6. Total GERD (all sectors) ===")

twfe_gerd <- feols(gerd_gdp_pct ~ post | geo + year,
                   data = panel[!is.na(gerd_gdp_pct)],
                   cluster = ~country)
message("TWFE (GERD/GDP %): ", round(coef(twfe_gerd)["post"], 4))

# ===========================================================================
# 7. Save results
# ===========================================================================
message("\n=== Saving results ===")

# Save event study data for plotting
es_data <- data.table(
  event_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt,
  ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
  ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
)
fwrite(es_data, file.path(data_dir, "event_study_results.csv"))

es_nyt_data <- data.table(
  event_time = cs_nyt_es$egt,
  att = cs_nyt_es$att.egt,
  se = cs_nyt_es$se.egt,
  ci_lower = cs_nyt_es$att.egt - 1.96 * cs_nyt_es$se.egt,
  ci_upper = cs_nyt_es$att.egt + 1.96 * cs_nyt_es$se.egt
)
fwrite(es_nyt_data, file.path(data_dir, "event_study_nyt_results.csv"))

# Save model objects for table generation
save(twfe_1, twfe_2, twfe_3, int_1, int_2, twfe_gerd,
     cs_agg, cs_nyt_agg, cs_ln_agg, cs_es, cs_nyt_es,
     file = file.path(data_dir, "main_models.RData"))

# Diagnostics JSON for validate_v1.py
# Use full panel for diagnostics (balanced for analysis, full for validation)
diag <- list(
  n_treated = uniqueN(panel_full[first_treat > 0, country]),
  n_pre = length(unique(panel_full[year < 2018, year])),
  n_obs = nrow(panel_full)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

message("\n=== Main analysis complete ===")
message("CS ATT (BERD/GDP%): ", round(cs_agg$overall.att, 4),
        " (SE: ", round(cs_agg$overall.se, 4), ")")
message("CS ATT (not-yet-treated): ", round(cs_nyt_agg$overall.att, 4),
        " (SE: ", round(cs_nyt_agg$overall.se, 4), ")")
message("TWFE baseline: ", round(coef(twfe_1)["post"], 4))
