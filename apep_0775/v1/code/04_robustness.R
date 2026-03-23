## =============================================================================
## 04_robustness.R — Robustness checks and mechanism tests
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

source("00_packages.R")

cat("=== Robustness Checks ===\n")

df <- fread("../data/state_panel.csv")

## -----------------------------------------------------------------------------
## 1. PLACEBO: High-education workers (E3, E4) should show null
## -----------------------------------------------------------------------------
cat("\n--- Placebo: High-education workers ---\n")

df_high <- df[low_ed == 0]
placebo_reg <- feols(
  log_emp ~ treated_state:post | state_fips + yq,
  data = df_high,
  cluster = ~state_fips
)
cat(sprintf("  High-ed (E3+E4) DiD: %.4f (SE: %.4f, p: %.3f)\n",
            coef(placebo_reg)["treated_state:post"],
            se(placebo_reg)["treated_state:post"],
            pvalue(placebo_reg)["treated_state:post"]))

## -----------------------------------------------------------------------------
## 2. INDUSTRY HETEROGENEITY
##    Effect should be largest in industries with high reentry rates:
##    NAICS 56 (Admin/Support), 72 (Accommodation), 23 (Construction)
## -----------------------------------------------------------------------------
cat("\n--- Industry heterogeneity (low-ed workers only) ---\n")

## Need raw (pre-aggregation) data for industry breakdowns
df_raw <- fread("../data/qwi_raw.csv")
treat <- fread("../data/treatment_states.csv")
treat[, state_fips := as.character(state_fips)]
df_raw[, state_fips := substr(geography, 1, 2)]
df_raw[, yq := year * 10 + quarter]
df_raw[, low_ed := as.integer(education %in% c("E1", "E2"))]
df_raw[, Emp := as.numeric(Emp)]
df_raw <- df_raw[!is.na(Emp) & Emp > 0]
df_raw[, treated_state := as.integer(state_fips %in% treat$state_fips)]
df_raw <- merge(df_raw, treat[, .(state_fips, treat_yq)],
                by = "state_fips", all.x = TRUE)
df_raw[is.na(treat_yq), treat_yq := 0L]
df_raw[, post := as.integer(treated_state == 1 & yq >= treat_yq)]

## Aggregate to state × quarter × industry for low-ed only
ind_panel <- df_raw[low_ed == 1, .(
  emp = sum(Emp, na.rm = TRUE)
), by = .(state_fips, yq, year, quarter, industry, treated_state, post)]
ind_panel[, log_emp := log(emp)]

ind_labels <- c("23" = "Construction", "44-45" = "Retail",
                "56" = "Admin/Support", "62" = "Healthcare",
                "72" = "Accommodation")

ind_results <- list()
for (ind in names(ind_labels)) {
  sub <- ind_panel[industry == ind]
  if (nrow(sub) < 100) next

  reg_ind <- feols(
    log_emp ~ treated_state:post | state_fips + yq,
    data = sub,
    cluster = ~state_fips
  )

  ind_results[[ind]] <- data.table(
    industry = ind,
    label = ind_labels[ind],
    coef = coef(reg_ind)["treated_state:post"],
    se = se(reg_ind)["treated_state:post"],
    pval = pvalue(reg_ind)["treated_state:post"],
    n = nrow(sub)
  )

  cat(sprintf("  %s (%s): %.4f (SE: %.4f, p: %.3f)\n",
              ind, ind_labels[ind],
              coef(reg_ind)["treated_state:post"],
              se(reg_ind)["treated_state:post"],
              pvalue(reg_ind)["treated_state:post"]))
}

ind_dt <- rbindlist(ind_results)

## -----------------------------------------------------------------------------
## 3. FULL vs PARTIAL BAN MODIFICATION
##    States that fully eliminated ban vs partially modified
## -----------------------------------------------------------------------------
cat("\n--- Full vs partial ban modification ---\n")

df_low <- df[low_ed == 1]

for (type in c("full", "partial")) {
  sub <- df_low[ban_type == type | treated_state == 0]
  reg_type <- feols(
    log_emp ~ treated_state:post | state_fips + yq,
    data = sub,
    cluster = ~state_fips
  )
  cat(sprintf("  %s ban removal: %.4f (SE: %.4f, p: %.3f)\n",
              type,
              coef(reg_type)["treated_state:post"],
              se(reg_type)["treated_state:post"],
              pvalue(reg_type)["treated_state:post"]))
}

## -----------------------------------------------------------------------------
## 4. PRE-TREND TEST: year-by-year low-ed effects pre-treatment
## -----------------------------------------------------------------------------
cat("\n--- Pre-trend test (low-ed, pre-2015) ---\n")

df_pre <- df[low_ed == 1 & year <= 2015]
df_pre[, year_fct := factor(year)]
pretrend_reg <- tryCatch(
  feols(
    log_emp ~ i(year_fct, treated_state, ref = "2010") | state_fips + yq,
    data = df_pre,
    cluster = ~state_fips
  ),
  error = function(e) { cat(sprintf("  Pre-trend failed: %s\n", e$message)); NULL }
)

if (!is.null(pretrend_reg)) {
  cat("Pre-trend coefficients:\n")
  print(coeftable(pretrend_reg))
}

## Save
saveRDS(list(
  placebo = placebo_reg,
  industry = ind_dt,
  pretrend = pretrend_reg
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
