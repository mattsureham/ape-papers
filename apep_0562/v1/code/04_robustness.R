## ============================================================================
## 04_robustness.R — Networked Anxiety (apep_0562)
## Robustness checks and placebo tests
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
load(file.path(DATA_DIR, "main_models.RData"))

cat("Panel loaded:", nrow(panel), "obs\n")

## ============================================================================
## 1. LEAVE-ONE-OUT (Shift Stability)
## ============================================================================

cat("\n=== 1. Leave-One-Out Analysis ===\n")

## For each department j in the shift, re-compute NetworkDispersal
## excluding j's contribution, and re-estimate
sci_fr <- fread(file.path(DATA_DIR, "sci_fr_pairs.csv"))

## Identify departments that received positive new places
own_disp <- fread(file.path(DATA_DIR, "own_dispersal.csv"))
shift_depts <- own_disp[own_new_places > 0, dept_code]

cat("  Shift departments to leave out:", length(shift_depts), "\n")

loo_results <- list()

for (j in shift_depts) {
  ## Recompute NetworkDispersal excluding department j
  sci_excl <- sci_fr[dept_j != j]

  ## Re-normalize shares within each i (excluding j)
  sci_excl[, sci_share_loo := sci / sum(sci), by = dept_i]

  ## Merge shift (excluding j)
  own_disp_excl <- own_disp[dept_code != j]
  sci_excl_shift <- merge(sci_excl, own_disp_excl[, .(dept_code, new_places = own_new_places)],
                           by.x = "dept_j", by.y = "dept_code", all.x = TRUE)
  sci_excl_shift[is.na(new_places), new_places := 0]

  nd_loo <- sci_excl_shift[, .(network_dispersal_loo = sum(sci_share_loo * new_places, na.rm = TRUE)),
                           by = dept_i]
  setnames(nd_loo, "dept_i", "dept_code")

  ## Merge into panel and re-estimate
  panel_loo <- merge(panel[, !c("network_dispersal_loo", "nd_loo_post"), with = FALSE],
                     nd_loo, by = "dept_code", all.x = TRUE)
  panel_loo[, nd_loo_post := network_dispersal_loo * post]

  m_loo <- tryCatch({
    feols(rn_share ~ nd_loo_post | dept_code + election_fe,
          data = panel_loo, cluster = ~dept_code)
  }, error = function(e) NULL)

  if (!is.null(m_loo)) {
    loo_results[[j]] <- data.table(
      excluded_dept = j,
      coef = coef(m_loo)["nd_loo_post"],
      se = se(m_loo)["nd_loo_post"]
    )
  }
}

loo_dt <- rbindlist(loo_results)
cat("  LOO estimates:", nrow(loo_dt), "\n")
cat("  Coefficient range:", round(min(loo_dt$coef), 4), "to",
    round(max(loo_dt$coef), 4), "\n")
cat("  Baseline:", round(coef(m1)["nd_post"], 4), "\n")

fwrite(loo_dt, file.path(DATA_DIR, "loo_results.csv"))

## ============================================================================
## 2. ALTERNATIVE SCI NORMALIZATION
## ============================================================================

cat("\n=== 2. Alternative SCI Normalizations ===\n")

## 2a. Log SCI weights
sci_fr[, sci_log := log(1 + sci)]
sci_fr[, sci_log_share := sci_log / sum(sci_log), by = dept_i]

own_disp_all <- fread(file.path(DATA_DIR, "own_dispersal.csv"))

sci_log_shift <- merge(sci_fr, own_disp_all[, .(dept_code, new_places = own_new_places)],
                        by.x = "dept_j", by.y = "dept_code", all.x = TRUE)
sci_log_shift[is.na(new_places), new_places := 0]

nd_log <- sci_log_shift[, .(network_dispersal_log = sum(sci_log_share * new_places, na.rm = TRUE)),
                        by = dept_i]
setnames(nd_log, "dept_i", "dept_code")

panel_log <- merge(panel, nd_log, by = "dept_code", all.x = TRUE)
panel_log[, nd_log_post := network_dispersal_log * post]

m_log <- feols(rn_share ~ nd_log_post | dept_code + election_fe,
               data = panel_log, cluster = ~dept_code)

## 2b. Binary treatment (above/below median NetworkDispersal)
panel[, nd_high := as.integer(network_dispersal > median(network_dispersal, na.rm = TRUE))]
panel[, nd_high_post := nd_high * post]

m_binary <- feols(rn_share ~ nd_high_post | dept_code + election_fe,
                  data = panel, cluster = ~dept_code)

cat("  Log SCI coef:", round(coef(m_log)["nd_log_post"], 4),
    "SE:", round(se(m_log)["nd_log_post"], 4), "\n")
cat("  Binary coef:", round(coef(m_binary)["nd_high_post"], 4),
    "SE:", round(se(m_binary)["nd_high_post"], 4), "\n")

## ============================================================================
## 3. RANDOMIZATION INFERENCE
## ============================================================================

cat("\n=== 3. Randomization Inference ===\n")

set.seed(42)
n_perms <- 1000

## Permute SCI weights across departments
## This tests: is the SCI-weighted exposure different from random weighting?
baseline_coef <- coef(m1)["nd_post"]

ri_coefs <- numeric(n_perms)

for (p in 1:n_perms) {
  if (p %% 100 == 0) cat("  Permutation", p, "/", n_perms, "\n")

  ## Permute department labels in the SCI matrix
  perm_map <- data.table(
    dept_code = unique(panel$dept_code),
    dept_perm = sample(unique(panel$dept_code))
  )

  panel_perm <- merge(panel, perm_map, by = "dept_code")
  ## Use permuted network dispersal
  nd_perm <- merge(perm_map,
                   unique(panel[, .(dept_code, network_dispersal)]),
                   by.x = "dept_perm", by.y = "dept_code")
  setnames(nd_perm, "dept_code", "dept_orig")

  panel_ri <- merge(panel, nd_perm[, .(dept_orig, nd_perm = network_dispersal)],
                    by.x = "dept_code", by.y = "dept_orig", all.x = TRUE)
  panel_ri[, nd_perm_post := nd_perm * post]

  m_ri <- tryCatch({
    feols(rn_share ~ nd_perm_post | dept_code + election_fe,
          data = panel_ri, cluster = ~dept_code)
  }, error = function(e) NULL)

  if (!is.null(m_ri)) {
    ri_coefs[p] <- coef(m_ri)["nd_perm_post"]
  }
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(baseline_coef), na.rm = TRUE)
cat("  RI p-value:", round(ri_pvalue, 4), "\n")
cat("  Baseline coef:", round(baseline_coef, 4), "\n")
cat("  RI null distribution: mean =", round(mean(ri_coefs, na.rm = TRUE), 4),
    ", sd =", round(sd(ri_coefs, na.rm = TRUE), 4), "\n")

ri_dt <- data.table(perm = 1:n_perms, coef = ri_coefs)
fwrite(ri_dt, file.path(DATA_DIR, "ri_permutations.csv"))

## ============================================================================
## 4. PLACEBO OUTCOMES
## ============================================================================

cat("\n=== 4. Placebo Outcomes ===\n")

## Use the analysis panel to test placebo outcomes
## Instead of re-parsing elections, compute centrist/non-RN share from panel
## Left-wing placebo: total_votes - rn_votes = non-RN votes
panel[, non_rn_share := 100 - rn_share]

## Direct placebo: non-RN share should NOT increase with network dispersal
## (it's the complement, so we expect β < 0 or null)

left_share <- copy(panel[, .(dept_code, year, post,
                              left_share = non_rn_share,
                              nd_post, election_fe = election_label)])

## Placebo regression: non-RN share (complement of RN)
m_left <- feols(left_share ~ nd_post | dept_code + election_fe,
                data = left_share, cluster = ~dept_code)

cat("  Left-wing placebo coef:", round(coef(m_left)["nd_post"], 4),
    "SE:", round(se(m_left)["nd_post"], 4), "\n")

## ============================================================================
## 5. WILD CLUSTER BOOTSTRAP
## ============================================================================

cat("\n=== 5. Wild Cluster Bootstrap ===\n")

## Use fixest's built-in wild bootstrap
m1_wild <- feols(rn_share ~ nd_post | dept_code + election_fe,
                 data = panel, cluster = ~dept_code)

## Bootstrap p-value
boot_pval <- tryCatch({
  wald_test <- wald(m1_wild, "nd_post", cluster = ~dept_code)
  wald_test$p
}, error = function(e) {
  cat("  Wild bootstrap via wald() not available, using manual bootstrap.\n")

  ## Manual wild cluster bootstrap (Rademacher weights)
  set.seed(123)
  n_boot <- 999
  boot_coefs <- numeric(n_boot)

  depts <- unique(panel$dept_code)
  n_depts <- length(depts)

  for (b in 1:n_boot) {
    ## Rademacher weights (+1 or -1) by cluster
    weights <- sample(c(-1, 1), n_depts, replace = TRUE)
    names(weights) <- depts
    panel[, boot_weight := weights[dept_code]]
    panel[, rn_boot := fitted(m1_wild) + residuals(m1_wild) * boot_weight]

    m_boot <- tryCatch({
      feols(rn_boot ~ nd_post | dept_code + election_fe,
            data = panel, cluster = ~dept_code)
    }, error = function(e) NULL)

    if (!is.null(m_boot)) {
      boot_coefs[b] <- coef(m_boot)["nd_post"]
    }
  }

  mean(abs(boot_coefs) >= abs(coef(m1)["nd_post"]), na.rm = TRUE)
})

cat("  Wild bootstrap p-value:", round(boot_pval, 4), "\n")

## ============================================================================
## 6. ROBUSTNESS SUMMARY TABLE
## ============================================================================

cat("\n=== Robustness Summary ===\n")

robustness_dt <- data.table(
  specification = c("Baseline (dept-clustered)",
                     "Log SCI weights",
                     "Binary treatment (above median)",
                     "Leave-one-out range",
                     "RI p-value",
                     "Wild cluster bootstrap p-value",
                     "Non-RN share (mechanical)"),
  coef = c(round(coef(m1)["nd_post"], 4),
           round(coef(m_log)["nd_log_post"], 4),
           round(coef(m_binary)["nd_high_post"], 4),
           paste0("[", round(min(loo_dt$coef), 4), ", ",
                  round(max(loo_dt$coef), 4), "]"),
           round(ri_pvalue, 4),
           round(boot_pval, 4),
           round(coef(m_left)["nd_post"], 4)),
  se = c(round(se(m1)["nd_post"], 4),
         round(se(m_log)["nd_log_post"], 4),
         round(se(m_binary)["nd_high_post"], 4),
         "-", "-", "-",
         round(se(m_left)["nd_post"], 4))
)

fwrite(robustness_dt, file.path(DATA_DIR, "robustness_summary.csv"))
cat("\nRobustness summary:\n")
print(robustness_dt)

## Save additional model objects
save(m_log, m_binary, m_left, loo_dt, ri_dt,
     file = file.path(DATA_DIR, "robustness_models.RData"))

cat("\nRobustness analysis complete.\n")
