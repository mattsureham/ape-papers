# 04_robustness.R — Robustness checks, HonestDiD, diagnostics
# APEP-0889: Slower Mail, Fewer Voters

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "estimation_results.RData"))

# Balance panel
county_counts <- panel[, .N, by = fips]
balanced_fips <- county_counts[N == 7, fips]
bp <- panel[fips %in% balanced_fips]
setorder(bp, fips, year)

# Fix CS first_treat: must be numeric for the `did` package
bp[, first_treat_num := as.numeric(first_treat)]
bp[, cohort_sa := fifelse(first_treat == 0, 10000L, first_treat)]
bp[, post := year >= first_treat & first_treat > 0]
bp[, post_2016 := as.integer(year >= 2016)]

cat(sprintf("Balanced panel: %d counties, %d obs\n",
            uniqueN(bp$fips), nrow(bp)))

# ============================================================================
# 1. Fixed CS-DiD with proper never-treated group
# ============================================================================
cat("\n=== Fixed Callaway-Sant'Anna (numeric gname) ===\n")

# The `did` package needs gname as numeric with 0 = never-treated
cs_fixed <- att_gt(
  yname = "log_votes",
  tname = "year",
  idname = "fips",
  gname = "first_treat_num",
  data = as.data.frame(bp[!is.na(log_votes)]),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cat("Fixed CS group-time ATTs:\n")
summary(cs_fixed)

es_fixed <- aggte(cs_fixed, type = "dynamic", min_e = -4, max_e = 2)
att_fixed <- aggte(cs_fixed, type = "simple")

cat("\nFixed event study:\n")
summary(es_fixed)
cat("\nFixed overall ATT:\n")
summary(att_fixed)

# ============================================================================
# 2. Bacon decomposition
# ============================================================================
cat("\n=== Bacon Decomposition ===\n")

library(bacondecomp)

bp_bacon <- as.data.frame(bp[!is.na(log_votes),
                              .(log_votes, fips, year, post = as.numeric(post))])

bacon_out <- tryCatch({
  bacon(log_votes ~ post, data = bp_bacon,
        id_var = "fips", time_var = "year")
}, error = function(e) {
  cat(sprintf("Bacon decomposition error: %s\n", e$message))
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition weights:\n")
  print(aggregate(cbind(weight, estimate) ~ type, data = bacon_out, FUN = sum))
}

# ============================================================================
# 3. HonestDiD sensitivity analysis
# ============================================================================
cat("\n=== HonestDiD Sensitivity Analysis ===\n")

# Use Sun-Abraham for HonestDiD (requires fixest output)
sa_log <- feols(log_votes ~ sunab(cohort_sa, year) | fips + year,
                 data = bp[!is.na(log_votes)], cluster = ~state_fips)

# Extract event study for HonestDiD
sa_coefs <- coef(sa_log)
sa_vcov <- vcov(sa_log)

# Identify pre and post coefficients
coef_names <- names(sa_coefs)
pre_idx <- grep("year::-", coef_names)
post_idx <- grep("year::[0-9]", coef_names)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  betahat <- sa_coefs[c(pre_idx, post_idx)]
  sigma <- sa_vcov[c(pre_idx, post_idx), c(pre_idx, post_idx)]
  n_pre <- length(pre_idx)

  honest_result <- tryCatch({
    createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.03, by = 0.005)
    )
  }, error = function(e) {
    cat(sprintf("HonestDiD error: %s\n", e$message))
    NULL
  })

  if (!is.null(honest_result)) {
    cat("HonestDiD bounds (relative magnitude):\n")
    print(honest_result)
  }
}

# ============================================================================
# 4. Placebo: Urban counties (many post offices, diluted treatment)
# ============================================================================
cat("\n=== Placebo: Urban vs Rural ===\n")

# Define urban = pop > median
median_pop <- median(bp$pop_2015, na.rm = TRUE)
bp[, urban := pop_2015 > median_pop]

# TWFE on urban subsample (expect weaker effect since treatment is diluted)
twfe_urban <- feols(log_votes ~ post | fips + year,
                     data = bp[urban == TRUE], cluster = ~state_fips)
twfe_rural <- feols(log_votes ~ post | fips + year,
                     data = bp[urban == FALSE], cluster = ~state_fips)
cat("TWFE — Urban subsample:\n")
print(summary(twfe_urban))
cat("TWFE — Rural subsample:\n")
print(summary(twfe_rural))

# ============================================================================
# 5. Leave-one-state-out
# ============================================================================
cat("\n=== Leave-One-State-Out ===\n")

states <- unique(bp$state_fips)
loso_coefs <- numeric(length(states))
names(loso_coefs) <- states

for (i in seq_along(states)) {
  st <- states[i]
  sub <- bp[state_fips != st]
  m <- feols(log_votes ~ post | fips + year, data = sub, cluster = ~state_fips)
  loso_coefs[i] <- coef(m)[1]
}

cat(sprintf("LOSO coefficient range: [%.4f, %.4f]\n",
            min(loso_coefs), max(loso_coefs)))
cat(sprintf("LOSO mean: %.4f, SD: %.4f\n",
            mean(loso_coefs), sd(loso_coefs)))

# ============================================================================
# 6. Wild cluster bootstrap (few-cluster inference)
# ============================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

n_clusters <- uniqueN(bp$state_fips)
cat(sprintf("Number of clusters (states): %d\n", n_clusters))

if (n_clusters < 50) {
  cat("Running wild cluster bootstrap...\n")
  twfe_wcb <- feols(log_votes ~ post | fips + year,
                     data = bp, cluster = ~state_fips)
  # fwildclusterboot if available
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)
    boot_result <- tryCatch(
      boottest(twfe_wcb, clustid = "state_fips", param = "postTRUE",
               B = 999, type = "webb"),
      error = function(e) {
        cat(sprintf("Bootstrap error: %s\n", e$message))
        NULL
      }
    )
    if (!is.null(boot_result)) {
      cat("Wild cluster bootstrap:\n")
      print(summary(boot_result))
    }
  } else {
    cat("fwildclusterboot not installed — skipping.\n")
  }
}

# ============================================================================
# 7. Randomization inference
# ============================================================================
cat("\n=== Randomization Inference ===\n")

# Permute treatment assignment 500 times
set.seed(20260324)
n_perms <- 500
perm_coefs <- numeric(n_perms)
treated_counties <- unique(bp[first_treat > 0, fips])
n_treated <- length(treated_counties)
all_counties <- unique(bp$fips)

for (i in 1:n_perms) {
  fake_treated <- sample(all_counties, n_treated)
  bp_perm <- copy(bp)
  bp_perm[, fake_post := fips %in% fake_treated & year >= 2016]
  m <- feols(log_votes ~ fake_post | fips + year, data = bp_perm)
  perm_coefs[i] <- coef(m)[1]
}

actual_coef <- coef(feols(log_votes ~ post | fips + year, data = bp))[1]
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("RI 95%% interval: [%.4f, %.4f]\n",
            quantile(perm_coefs, 0.025), quantile(perm_coefs, 0.975)))

# ============================================================================
# 8. Excluding 2020 (COVID confound)
# ============================================================================
cat("\n=== Excluding 2020 (COVID) ===\n")

twfe_no2020 <- feols(log_votes ~ post | fips + year,
                      data = bp[year != 2020], cluster = ~state_fips)
cat("TWFE excluding 2020:\n")
print(summary(twfe_no2020))

# ============================================================================
# 9. Minimum detectable effect
# ============================================================================
cat("\n=== Minimum Detectable Effect ===\n")

# From the CS-DiD
att_se <- att_fixed$overall.se
mde_80 <- 2.8 * att_se  # 80% power at 5% significance
mde_95 <- 3.5 * att_se  # 95% power

# In terms of votes
mean_log_votes <- mean(bp$log_votes, na.rm = TRUE)
mean_votes <- exp(mean_log_votes)

cat(sprintf("CS-DiD SE: %.4f\n", att_se))
cat(sprintf("MDE (80%% power): %.4f log-points = %.1f%% of mean votes\n",
            mde_80, 100 * (exp(mde_80) - 1)))
cat(sprintf("MDE (95%% power): %.4f log-points = %.1f%% of mean votes\n",
            mde_95, 100 * (exp(mde_95) - 1)))
cat(sprintf("Mean county votes: %.0f\n", mean_votes))
cat(sprintf("We can rule out effects larger than %.1f%% of county turnout\n",
            100 * (exp(mde_80) - 1)))

# ============================================================================
# Save all robustness results
# ============================================================================
save(cs_fixed, es_fixed, att_fixed,
     bacon_out, sa_log, loso_coefs, ri_pvalue, perm_coefs,
     twfe_urban, twfe_rural, twfe_no2020,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== Robustness Complete ===\n")
