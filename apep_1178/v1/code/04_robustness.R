# ==============================================================================
# 04_robustness.R — Robustness checks for CRNA opt-out analysis
# ==============================================================================

source("00_packages.R")

panel_full <- readRDS("../data/analysis_panel.rds")
panel_main <- readRDS("../data/panel_main.rds")
cs_result  <- readRDS("../data/cs_result.rds")

main <- panel_main %>%
  filter(year >= 1998 & year <= 2023) %>%
  arrange(state_id, year)

# ==========================================================================
# 1. LEAVE-ONE-WAVE-OUT: Drop each adoption wave sequentially
# ==========================================================================

cat("=== Leave-One-Wave-Out ===\n")

waves <- c(2002, 2003, 2004, 2005, 2009, 2010, 2012, 2020)
lowo_results <- list()

for (w in waves) {
  main_sub <- main %>% filter(g_period != w)
  if (length(unique(main_sub$state_id[main_sub$g_period > 0])) < 3) next

  twfe_sub <- feols(
    log_emp ~ post_optout | state_id + year,
    data = main_sub,
    cluster = ~state_id
  )
  cf <- coef(twfe_sub)[1]  # First (only) coefficient
  se_val <- se(twfe_sub)[1]
  lowo_results[[as.character(w)]] <- list(
    wave    = w,
    coef    = cf,
    se      = se_val,
    n_states = length(unique(main_sub$state_id[main_sub$g_period > 0]))
  )
  cat(sprintf("  Drop wave %d: β=%.4f (%.4f), %d treated states\n",
              w, cf, se_val,
              lowo_results[[as.character(w)]]$n_states))
}

# ==========================================================================
# 2. ALTERNATIVE CONTROL GROUP: Never-treated only (not NYT)
# ==========================================================================

cat("\n=== C-S with never-treated control ===\n")

cs_never <- att_gt(
  yname      = "log_emp",
  tname      = "year",
  idname     = "state_id",
  gname      = "g_period",
  data       = as.data.frame(main),
  control_group = "nevertreated",
  est_method = "reg",
  base_period = "universal",
  allow_unbalanced_panel = TRUE
)

cs_never_agg <- aggte(cs_never, type = "simple")
cat("ATT (never-treated control):\n")
summary(cs_never_agg)

# ==========================================================================
# 3. HOSPITAL (NAICS 622) as active placebo for BA+ workers
# ==========================================================================

cat("\n=== Hospital placebo: BA+ in NAICS 622 ===\n")

panel_622 <- panel_full %>%
  filter(ed_group == "BA_plus", industry == "622",
         year >= 1998 & year <= 2023)

twfe_622 <- feols(
  log_emp ~ post_optout | state_id + year,
  data = panel_622,
  cluster = ~state_id
)
cat("BA+ hospital employment (placebo — tests substitution):\n")
summary(twfe_622)

# ==========================================================================
# 4. HIRES AND SEPARATIONS
# ==========================================================================

cat("\n=== Hiring and Separation Dynamics ===\n")

main$log_hires <- log(pmax(main$hires, 1))
main$log_seps  <- log(pmax(main$seps, 1))
main$log_jobgn <- log(pmax(main$job_gn, 1))

twfe_hires <- feols(log_hires ~ post_optout | state_id + year,
                     data = main, cluster = ~state_id)
twfe_seps  <- feols(log_seps ~ post_optout | state_id + year,
                     data = main, cluster = ~state_id)
twfe_jobgn <- feols(log_jobgn ~ post_optout | state_id + year,
                     data = main, cluster = ~state_id)

cat("Hires:\n"); summary(twfe_hires)
cat("Separations:\n"); summary(twfe_seps)
cat("Firm job gains:\n"); summary(twfe_jobgn)

# ==========================================================================
# 5. HonestDiD SENSITIVITY: Rambachan-Roth bounds
# ==========================================================================

cat("\n=== HonestDiD Sensitivity Analysis ===\n")

tryCatch({
  # Get the event study for HonestDiD
  cs_event <- aggte(cs_result, type = "dynamic", min_e = -8, max_e = 10)

  honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat        = cs_event$att.egt,
    sigma          = cs_event$se.egt^2 * diag(length(cs_event$se.egt)),
    numPrePeriods  = sum(cs_event$egt < 0),
    numPostPeriods = sum(cs_event$egt >= 0),
    Mbarvec        = seq(0.5, 2, by = 0.5)
  )

  saveRDS(honest_result, "../data/honest_did.rds")
  cat("HonestDiD bounds saved.\n")
}, error = function(e) {
  cat(sprintf("HonestDiD warning: %s\n", e$message))
  cat("Proceeding without HonestDiD bounds.\n")
})

# ==========================================================================
# 6. PRE-TREATMENT BALANCE
# ==========================================================================

cat("\n=== Pre-treatment Balance (2000-2001) ===\n")

pre_balance <- main %>%
  filter(year %in% c(2000, 2001)) %>%
  group_by(ever_optout) %>%
  summarise(
    mean_emp  = mean(emp, na.rm = TRUE),
    sd_emp    = sd(emp, na.rm = TRUE),
    mean_earn = mean(earn, na.rm = TRUE),
    sd_earn   = sd(earn, na.rm = TRUE),
    n_states  = n_distinct(state_abbr),
    .groups   = "drop"
  )

cat("Pre-treatment balance:\n")
print(pre_balance)

# ==========================================================================
# 7. Save all robustness results
# ==========================================================================

robustness <- list(
  lowo_results    = lowo_results,
  cs_never_agg    = cs_never_agg,
  twfe_622        = twfe_622,
  twfe_hires      = twfe_hires,
  twfe_seps       = twfe_seps,
  twfe_jobgn      = twfe_jobgn,
  pre_balance     = pre_balance
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nAll robustness results saved.\n")
