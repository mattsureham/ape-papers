# 04_robustness.R — Robustness checks (state-level)
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_panel.csv"),
            colClasses = c(state_fips = "character"))

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. Alternative GRP threshold
# ============================================================================
cat("\n1. Alternative GRP threshold (mean_grp > 1.5)\n")
df[, high_grp_alt := as.integer(mean_grp > 1.5)]
df[, treat_x_grp_alt := post_rrnc * high_grp_alt]

m_alt_grp <- feols(cancer_aadr ~ post_rrnc + treat_x_grp_alt | state_fips + year,
                   data = df, cluster = ~state_fips)
print(summary(m_alt_grp))

# ============================================================================
# 2. Drop early adopters (NJ 1995, WA 1997)
# ============================================================================
cat("\n2. Drop early adopters\n")
df_late <- df[!(state_fips %in% c("34", "53"))]
m_late <- feols(cancer_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
                data = df_late, cluster = ~state_fips)
print(summary(m_late))

# ============================================================================
# 3. Log specification
# ============================================================================
cat("\n3. Log cancer rate\n")
df[, log_cancer := log(cancer_aadr)]
m_log <- feols(log_cancer ~ post_rrnc + treat_x_grp | state_fips + year,
               data = df, cluster = ~state_fips)
print(summary(m_log))

# ============================================================================
# 4. Drop small states (pop < 1M)
# ============================================================================
cat("\n4. Drop small states\n")
small_states <- df[, .(mean_pop = mean(population, na.rm = TRUE)), by = state_fips][mean_pop < 1e6]$state_fips
df_big <- df[!(state_fips %in% small_states)]
cat("Dropped", length(small_states), "small states\n")
m_big <- feols(cancer_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
               data = df_big, cluster = ~state_fips)
print(summary(m_big))

# ============================================================================
# 5. Population-weighted
# ============================================================================
cat("\n5. Population-weighted\n")
m_wt <- feols(cancer_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
              data = df, cluster = ~state_fips, weights = ~population)
print(summary(m_wt))

# ============================================================================
# 6. Permutation test (200 iterations)
# ============================================================================
cat("\n6. Permutation test\n")

set.seed(42)
actual_coef <- coef(feols(cancer_aadr ~ post_rrnc | state_fips + year,
                          data = df, cluster = ~state_fips))["post_rrnc"]

treated_states <- unique(df[treated_state == 1]$state_fips)
n_treated <- length(treated_states)
all_states <- unique(df$state_fips)
rrnc_years <- df[treated_state == 1, .(rrnc_year = rrnc_year[1]), by = state_fips]$rrnc_year

perm_coefs <- numeric(200)
for (i in 1:200) {
  df_perm <- copy(df)
  # Randomly assign treatment years to random states
  perm_states <- sample(all_states, n_treated)
  df_perm[, post_rrnc_perm := 0L]
  for (j in seq_along(perm_states)) {
    df_perm[state_fips == perm_states[j] & year >= rrnc_years[j], post_rrnc_perm := 1L]
  }
  m_perm <- tryCatch(
    feols(cancer_aadr ~ post_rrnc_perm | state_fips + year, data = df_perm, cluster = ~state_fips),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["post_rrnc_perm"]
  }
  if (i %% 50 == 0) cat("  Iteration", i, "\n")
}

perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Actual coef:", actual_coef, "\n")
cat("Permutation p-value:", perm_p, "\n")

fwrite(data.table(coef = perm_coefs), file.path(data_dir, "permutation_coeffs.csv"))

# ============================================================================
# 7. Bacon decomposition
# ============================================================================
cat("\n7. Bacon decomposition\n")
if (!requireNamespace("bacondecomp", quietly = TRUE)) {
  install.packages("bacondecomp", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(bacondecomp)

df_bacon <- as.data.frame(df[, .(state_fips, year, cancer_aadr, post_rrnc)])
df_bacon$state_fips <- as.numeric(df_bacon$state_fips)

bacon_out <- tryCatch({
  bacon(cancer_aadr ~ post_rrnc, data = df_bacon,
        id_var = "state_fips", time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})
if (!is.null(bacon_out)) {
  cat("Bacon decomposition:\n")
  print(summary(bacon_out))
}

# ============================================================================
# Save
# ============================================================================
robustness_models <- list(
  alt_grp = m_alt_grp,
  late_adopters = m_late,
  log_spec = m_log,
  big_states = m_big,
  weighted = m_wt,
  perm_p = perm_p,
  actual_coef = actual_coef
)
if (!is.null(bacon_out)) robustness_models$bacon <- bacon_out

saveRDS(robustness_models, file.path(data_dir, "robustness_models.rds"))

cat("\n=== Robustness checks complete ===\n")
