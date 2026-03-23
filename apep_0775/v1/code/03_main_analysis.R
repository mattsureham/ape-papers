## =============================================================================
## 03_main_analysis.R — Triple-difference estimation
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

source("00_packages.R")

cat("=== Main Analysis: Triple-Difference ===\n")

df <- fread("../data/state_panel.csv")

## Create numeric time variable (quarters since 2010Q1)
df[, time_q := (year - 2010) * 4 + quarter]

## =============================================================================
## DESIGN 1: Triple-difference with correct FE structure
## State FE + Quarter FE + Education FE (not fully saturated)
## =============================================================================
cat("\n--- Design 1: Triple-Difference ---\n")

## Main triple-diff specification
reg_ddd <- feols(
  log_emp ~ treated_state:low_ed:post +
            treated_state:post +
            low_ed:post +
            treated_state:low_ed |
            state_fips + yq + education,
  data = df,
  cluster = ~state_fips
)

cat("Triple-difference (log employment):\n")
print(coeftable(reg_ddd))

## Hires
reg_ddd_hires <- feols(
  log_hires ~ treated_state:low_ed:post +
              treated_state:post +
              low_ed:post +
              treated_state:low_ed |
              state_fips + yq + education,
  data = df,
  cluster = ~state_fips
)

## Earnings
reg_ddd_earn <- feols(
  log_earn ~ treated_state:low_ed:post +
             treated_state:post +
             low_ed:post +
             treated_state:low_ed |
             state_fips + yq + education,
  data = df,
  cluster = ~state_fips
)

cat("\nTriple-diff results:\n")
for (nm in c("treated_state:low_ed:post")) {
  cat(sprintf("  Employment: %.4f (SE: %.4f, p: %.3f)\n",
              coef(reg_ddd)[nm], se(reg_ddd)[nm], pvalue(reg_ddd)[nm]))
  cat(sprintf("  Hires:      %.4f (SE: %.4f, p: %.3f)\n",
              coef(reg_ddd_hires)[nm], se(reg_ddd_hires)[nm], pvalue(reg_ddd_hires)[nm]))
  cat(sprintf("  Earnings:   %.4f (SE: %.4f, p: %.3f)\n",
              coef(reg_ddd_earn)[nm], se(reg_ddd_earn)[nm], pvalue(reg_ddd_earn)[nm]))
}

## =============================================================================
## DESIGN 2: Education-specific DiD (separately for E1, E2, E3, E4)
## This is the cleanest way to show the placebo pattern
## =============================================================================
cat("\n--- Design 2: Education-Specific DiD ---\n")

educ_results <- list()
for (ed in c("E1", "E2", "E3", "E4")) {
  sub <- df[education == ed]
  reg_ed <- feols(
    log_emp ~ treated_state:post | state_fips + yq,
    data = sub,
    cluster = ~state_fips
  )
  educ_results[[ed]] <- reg_ed
  cat(sprintf("  %s: %.4f (SE: %.4f, p: %.3f)\n",
              ed,
              coef(reg_ed)["treated_state:post"],
              se(reg_ed)["treated_state:post"],
              pvalue(reg_ed)["treated_state:post"]))
}

## Combined low-ed
reg_low <- feols(
  log_emp ~ treated_state:post | state_fips + yq,
  data = df[low_ed == 1],
  cluster = ~state_fips
)
cat(sprintf("  Low-ed (E1+E2): %.4f (SE: %.4f, p: %.3f)\n",
            coef(reg_low)["treated_state:post"],
            se(reg_low)["treated_state:post"],
            pvalue(reg_low)["treated_state:post"]))

## Combined high-ed (placebo)
reg_high <- feols(
  log_emp ~ treated_state:post | state_fips + yq,
  data = df[low_ed == 0],
  cluster = ~state_fips
)
cat(sprintf("  High-ed (E3+E4): %.4f (SE: %.4f, p: %.3f)\n",
            coef(reg_high)["treated_state:post"],
            se(reg_high)["treated_state:post"],
            pvalue(reg_high)["treated_state:post"]))

## =============================================================================
## Store pre-treatment SDs for SDE computation
## =============================================================================
pre_sd <- df[post == 0 | treated_state == 0, .(
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  sd_log_hires = sd(log_hires, na.rm = TRUE),
  sd_log_earn = sd(log_earn, na.rm = TRUE),
  mean_emp = mean(emp, na.rm = TRUE)
), by = low_ed]
cat("\nPre-treatment SDs:\n")
print(pre_sd)

## =============================================================================
## Write diagnostics
## =============================================================================
diag <- list(
  n_treated = uniqueN(df[treated_state == 1, state_fips]),
  n_pre = length(unique(df[treated_state == 1 & post == 0, yq])),
  n_obs = nrow(df)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

## Save all results
saveRDS(list(
  ddd_emp = reg_ddd,
  ddd_hires = reg_ddd_hires,
  ddd_earn = reg_ddd_earn,
  educ_results = educ_results,
  reg_low = reg_low,
  reg_high = reg_high,
  pre_sd = pre_sd
), "../data/main_results.rds")

cat("\n=== Main analysis complete ===\n")
