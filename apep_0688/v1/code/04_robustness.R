## 04_robustness.R — Robustness checks
source("00_packages.R")

data_dir <- "../data"
knife <- fread(file.path(data_dir, "knife_panel_clean.csv"))

cat("=== Robustness Checks ===\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1. Randomization Inference for spillover estimate
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Randomization Inference ---\n")

## The key finding is the spillover to boundary forces
## Permute which forces are labeled "boundary"
contiguity <- fread(file.path(data_dir, "force_contiguity.csv"))
treat <- fread(file.path(data_dir, "vru_treatment.csv"))

## Actual spillover estimate
knife[, boundary_post := as.integer(boundary == 1 & post == 1)]
actual_spill <- feols(knife_rate ~ boundary_post | force_id + year_end,
                      data = knife[vru == 0], cluster = ~force_id)
actual_coef <- coef(actual_spill)["boundary_post"]

## Also compute direct effect for RI
actual_direct <- feols(knife_rate ~ vru_post | force_id + year_end,
                       data = knife, cluster = ~force_id)
actual_direct_coef <- coef(actual_direct)["vru_post"]

## Permutation: randomly assign VRU status, recompute boundary
set.seed(42)
n_perms <- 1000
all_forces <- unique(knife$force_std)
n_treated <- sum(treat$force_name %in% all_forces)
all_vru <- treat$force_name[treat$force_name %in% all_forces]

perm_direct_coefs <- numeric(n_perms)
perm_spill_coefs <- numeric(n_perms)

for (p in 1:n_perms) {
  if (p %% 200 == 0) cat(sprintf("  Permutation %d/%d\n", p, n_perms))

  ## Random VRU assignment
  perm_vru <- sample(all_forces, n_treated)
  perm_boundary <- unique(c(
    contiguity[force_1 %in% perm_vru & !(force_2 %in% perm_vru), force_2],
    contiguity[force_2 %in% perm_vru & !(force_1 %in% perm_vru), force_1]
  ))

  kp <- copy(knife)
  kp[, p_vru := as.integer(force_std %in% perm_vru)]
  kp[, p_boundary := as.integer(force_std %in% perm_boundary)]
  kp[, p_vru_post := as.integer(p_vru == 1 & post == 1)]
  kp[, p_boundary_post := as.integer(p_boundary == 1 & post == 1)]

  ## Direct effect
  m_d <- tryCatch(feols(knife_rate ~ p_vru_post | force_id + year_end, data = kp), error = function(e) NULL)
  if (!is.null(m_d)) perm_direct_coefs[p] <- coef(m_d)["p_vru_post"]

  ## Spillover
  kp_untreated <- kp[p_vru == 0]
  if (nrow(kp_untreated) > 0 && any(kp_untreated$p_boundary_post == 1)) {
    m_s <- tryCatch(feols(knife_rate ~ p_boundary_post | force_id + year_end,
                          data = kp_untreated), error = function(e) NULL)
    if (!is.null(m_s)) perm_spill_coefs[p] <- coef(m_s)["p_boundary_post"]
  }
}

ri_direct_p <- mean(abs(perm_direct_coefs) >= abs(actual_direct_coef))
ri_spill_p <- mean(abs(perm_spill_coefs) >= abs(actual_coef))

cat("Direct effect RI p-value:", ri_direct_p, "\n")
cat("Spillover RI p-value:", ri_spill_p, "\n")

saveRDS(list(
  direct = list(actual = actual_direct_coef, perms = perm_direct_coefs, p = ri_direct_p),
  spillover = list(actual = actual_coef, perms = perm_spill_coefs, p = ri_spill_p)
), file.path(data_dir, "ri_results.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 2. Cluster Bootstrap
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Cluster Bootstrap ---\n")

set.seed(43)
n_boot <- 999
force_ids <- unique(knife[vru == 0, force_id])
n_f <- length(force_ids)

boot_spill <- numeric(n_boot)
for (b in 1:n_boot) {
  if (b %% 200 == 0) cat(sprintf("  Bootstrap %d/%d\n", b, n_boot))
  boot_ids <- sample(force_ids, n_f, replace = TRUE)
  boot_data <- rbindlist(lapply(seq_along(boot_ids), function(j) {
    d <- knife[vru == 0 & force_id == boot_ids[j]]
    d <- copy(d)
    d[, boot_id := j]
    d
  }))
  m <- tryCatch(feols(knife_rate ~ boundary_post | boot_id + year_end, data = boot_data),
                error = function(e) NULL)
  if (!is.null(m)) boot_spill[b] <- coef(m)["boundary_post"]
}

boot_se <- sd(boot_spill, na.rm = TRUE)
boot_p <- mean(abs(boot_spill) >= abs(actual_coef), na.rm = TRUE)
cat("Cluster bootstrap SE:", boot_se, "\n")
cat("Cluster bootstrap p-value:", boot_p, "\n")

saveRDS(list(coefs = boot_spill, se = boot_se, p = boot_p),
        file.path(data_dir, "cluster_bootstrap.rds"))

cat("\n=== Robustness complete ===\n")
