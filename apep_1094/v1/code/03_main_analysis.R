# =============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + Event Studies
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

source("00_packages.R")

panel_all   <- readRDS("../data/panel_all.rds")
panel_white <- readRDS("../data/panel_white.rds")
panel_black <- readRDS("../data/panel_black.rds")
panel_hisp  <- readRDS("../data/panel_hisp.rds")
panel_722   <- readRDS("../data/panel_722.rds")

# =============================================================================
# 1. Callaway-Sant'Anna: Overall NAICS 512 employment
# =============================================================================
cat("Running CS-DiD for overall employment (race=A0)...\n")

cs_all <- att_gt(
  yname  = "log_emp",
  tname  = "period",
  idname = "state_id",
  gname  = "first_treat",
  data   = panel_all %>% filter(first_treat >= 0),
  control_group = "nevertreated",
  allow_unbalanced_panel = TRUE,
  base_period = "universal"
)

# Aggregate: simple ATT
agg_all <- aggte(cs_all, type = "simple", na.rm = TRUE)
cat(sprintf("Overall ATT: %.4f (SE: %.4f)\n", agg_all$overall.att, agg_all$overall.se))

# Event study
es_all <- aggte(cs_all, type = "dynamic", min_e = -12, max_e = 20, na.rm = TRUE)

# =============================================================================
# 2. Race-specific CS-DiD
# =============================================================================
cat("Running CS-DiD by race...\n")

run_cs <- function(df, label) {
  cs <- att_gt(
    yname  = "log_emp",
    tname  = "period",
    idname = "state_id",
    gname  = "first_treat",
    data   = df %>% filter(first_treat >= 0),
    control_group = "nevertreated",
    allow_unbalanced_panel = TRUE,
    base_period = "universal"
  )
  agg <- aggte(cs, type = "simple", na.rm = TRUE)
  es <- aggte(cs, type = "dynamic", min_e = -12, max_e = 20, na.rm = TRUE)
  cat(sprintf("  %s ATT: %.4f (SE: %.4f)\n", label, agg$overall.att, agg$overall.se))
  list(cs = cs, agg = agg, es = es)
}

res_white <- run_cs(panel_white, "White")
res_black <- run_cs(panel_black, "Black")
res_hisp  <- run_cs(panel_hisp, "Hispanic")

# =============================================================================
# 3. Hires (new entrants by race) — the flow margin
# =============================================================================
cat("Running CS-DiD for hires by race...\n")

run_cs_hir <- function(df, label) {
  cs <- att_gt(
    yname  = "log_hir",
    tname  = "period",
    idname = "state_id",
    gname  = "first_treat",
    data   = df %>% filter(first_treat >= 0),
    control_group = "nevertreated",
    allow_unbalanced_panel = TRUE,
    base_period = "universal"
  )
  agg <- aggte(cs, type = "simple", na.rm = TRUE)
  cat(sprintf("  %s Hires ATT: %.4f (SE: %.4f)\n", label, agg$overall.att, agg$overall.se))
  list(cs = cs, agg = agg)
}

hir_all   <- run_cs_hir(panel_all, "All")
hir_white <- run_cs_hir(panel_white, "White")
hir_black <- run_cs_hir(panel_black, "Black")
hir_hisp  <- run_cs_hir(panel_hisp, "Hispanic")

# =============================================================================
# 4. Earnings
# =============================================================================
cat("Running CS-DiD for earnings by race...\n")

run_cs_earn <- function(df, label) {
  cs <- att_gt(
    yname  = "log_earn",
    tname  = "period",
    idname = "state_id",
    gname  = "first_treat",
    data   = df %>% filter(first_treat >= 0),
    control_group = "nevertreated",
    allow_unbalanced_panel = TRUE,
    base_period = "universal"
  )
  agg <- aggte(cs, type = "simple", na.rm = TRUE)
  cat(sprintf("  %s Earnings ATT: %.4f (SE: %.4f)\n", label, agg$overall.att, agg$overall.se))
  list(cs = cs, agg = agg)
}

earn_all   <- run_cs_earn(panel_all, "All")
earn_white <- run_cs_earn(panel_white, "White")
earn_black <- run_cs_earn(panel_black, "Black")
earn_hisp  <- run_cs_earn(panel_hisp, "Hispanic")

# =============================================================================
# 5. TWFE comparison (show Button 2019 was misled by heterogeneity)
# =============================================================================
cat("Running TWFE for comparison...\n")

twfe_all <- feols(log_emp ~ post | state_abbr + period,
                  data = panel_all, cluster = ~state_abbr)

twfe_white <- feols(log_emp ~ post | state_abbr + period,
                    data = panel_white, cluster = ~state_abbr)

twfe_black <- feols(log_emp ~ post | state_abbr + period,
                    data = panel_black, cluster = ~state_abbr)

twfe_hisp <- feols(log_emp ~ post | state_abbr + period,
                   data = panel_hisp, cluster = ~state_abbr)

# =============================================================================
# Save all results
# =============================================================================
results <- list(
  cs_all = cs_all, agg_all = agg_all, es_all = es_all,
  res_white = res_white, res_black = res_black, res_hisp = res_hisp,
  hir_all = hir_all, hir_white = hir_white,
  hir_black = hir_black, hir_hisp = hir_hisp,
  earn_all = earn_all, earn_white = earn_white,
  earn_black = earn_black, earn_hisp = earn_hisp,
  twfe_all = twfe_all, twfe_white = twfe_white,
  twfe_black = twfe_black, twfe_hisp = twfe_hisp
)

saveRDS(results, "../data/results.rds")

# Diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(panel_all$state_id[panel_all$treated]),
  n_pre = min(panel_all$first_treat[panel_all$treated & panel_all$first_treat > 0], na.rm = TRUE) - 1,
  n_obs = nrow(panel_all)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
