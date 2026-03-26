# =============================================================================
# 03_main_analysis.R — Main DiD estimation (TWFE + Sun-Abraham)
# apep_1031: Kitchen Table Capitalism
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
df_placebo <- readRDS("../data/placebo_panel.rds")
treatment <- readRDS("../data/treatment_coding.rds")

results <- list()

# =============================================================================
# Helper: create post-treatment indicator
# =============================================================================
add_post <- function(data) {
  data %>%
    mutate(post = as.numeric(first_treat > 0 & time_q >= first_treat))
}

# =============================================================================
# 1. MAIN SPECIFICATION: NAICS 722 (Food Services) — Employment
# =============================================================================
cat("=== TWFE: NAICS 722 Employment ===\n")

df_722 <- df %>% filter(industry == "722", !is.na(log_emp)) %>% add_post()

twfe_722_emp <- feols(log_emp ~ post | state_fips + time_q, data = df_722,
                      cluster = ~state_fips)
results$twfe_722_emp <- twfe_722_emp
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_722_emp)["post"], se(twfe_722_emp)["post"],
            pvalue(twfe_722_emp)["post"]))

# =============================================================================
# 2. NAICS 722 — Firm Entry Rate
# =============================================================================
cat("=== TWFE: NAICS 722 Entry Rate ===\n")

df_722_entry <- df_722 %>% filter(!is.na(entry_rate))

twfe_722_entry <- feols(entry_rate ~ post | state_fips + time_q, data = df_722_entry,
                        cluster = ~state_fips)
results$twfe_722_entry <- twfe_722_entry
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_722_entry)["post"], se(twfe_722_entry)["post"],
            pvalue(twfe_722_entry)["post"]))

# =============================================================================
# 3. NAICS 311 (Food Manufacturing) — Employment
# =============================================================================
cat("=== TWFE: NAICS 311 Employment ===\n")

df_311 <- df %>% filter(industry == "311", !is.na(log_emp)) %>% add_post()

twfe_311_emp <- feols(log_emp ~ post | state_fips + time_q, data = df_311,
                      cluster = ~state_fips)
results$twfe_311_emp <- twfe_311_emp
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_311_emp)["post"], se(twfe_311_emp)["post"],
            pvalue(twfe_311_emp)["post"]))

# =============================================================================
# 4. NAICS 311 — Firm Entry Rate
# =============================================================================
cat("=== TWFE: NAICS 311 Entry Rate ===\n")

df_311_entry <- df_311 %>% filter(!is.na(entry_rate))

twfe_311_entry <- feols(entry_rate ~ post | state_fips + time_q, data = df_311_entry,
                        cluster = ~state_fips)
results$twfe_311_entry <- twfe_311_entry
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_311_entry)["post"], se(twfe_311_entry)["post"],
            pvalue(twfe_311_entry)["post"]))

# =============================================================================
# 5. NAICS 722 — Average Earnings
# =============================================================================
cat("=== TWFE: NAICS 722 Average Earnings ===\n")

df_722_earn <- df_722 %>% filter(!is.na(avg_earnings)) %>% mutate(log_earn = log(avg_earnings))

twfe_722_earn <- feols(log_earn ~ post | state_fips + time_q, data = df_722_earn,
                       cluster = ~state_fips)
results$twfe_722_earn <- twfe_722_earn
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_722_earn)["post"], se(twfe_722_earn)["post"],
            pvalue(twfe_722_earn)["post"]))

# =============================================================================
# 6. PLACEBO: Manufacturing (31-33) — Employment
# =============================================================================
cat("=== TWFE: PLACEBO — Manufacturing Employment ===\n")

df_mfg_clean <- df_placebo %>% filter(!is.na(log_emp)) %>% add_post()

twfe_mfg <- feols(log_emp ~ post | state_fips + time_q, data = df_mfg_clean,
                  cluster = ~state_fips)
results$twfe_mfg <- twfe_mfg
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_mfg)["post"], se(twfe_mfg)["post"],
            pvalue(twfe_mfg)["post"]))

# =============================================================================
# 7. SUN-ABRAHAM (heterogeneity-robust) — NAICS 722 Employment
# =============================================================================
cat("=== Sun-Abraham: NAICS 722 Employment ===\n")

df_722_sa <- df_722 %>%
  mutate(
    cohort = ifelse(first_treat > 0, first_treat, 10000),
    rel_time = time_q - first_treat
  )

# Interaction-weighted estimator via fixest
sa_722 <- feols(log_emp ~ sunab(cohort, time_q) | state_fips + time_q,
                data = df_722_sa, cluster = ~state_fips)

results$sa_722 <- sa_722
agg_sa <- tryCatch({
  agg_obj <- aggregate(sa_722, agg = "ATT")
  cat(sprintf("  SA ATT: %.4f\n", agg_obj[1]))
  agg_obj
}, error = function(e) {
  cat(sprintf("  SA aggregation error: %s\n", e$message))
  NULL
})

# =============================================================================
# SUMMARY TABLE
# =============================================================================
cat("\n=== RESULTS SUMMARY ===\n")
cat(sprintf("%-35s %8s %8s %8s\n", "Outcome", "Coef", "SE", "p-val"))
cat(paste(rep("-", 65), collapse = ""), "\n")

spec_list <- list(
  list("NAICS 722: log(Employment)", twfe_722_emp),
  list("NAICS 722: Entry Rate", twfe_722_entry),
  list("NAICS 722: log(Avg Earnings)", twfe_722_earn),
  list("NAICS 311: log(Employment)", twfe_311_emp),
  list("NAICS 311: Entry Rate", twfe_311_entry),
  list("Placebo — Mfg: log(Employment)", twfe_mfg)
)

for (s in spec_list) {
  cat(sprintf("%-35s %8.4f %8.4f %8.4f\n",
              s[[1]], coef(s[[2]])["post"], se(s[[2]])["post"], pvalue(s[[2]])["post"]))
}

# =============================================================================
# SAVE RESULTS
# =============================================================================
saveRDS(results, "../data/main_results.rds")

# --- Compute pre-treatment SD(Y) for SDE calculations ---
pre_sds <- list()

pre_722 <- df_722 %>% filter(time_q < 2010)
pre_sds$sd_log_emp_722 <- sd(pre_722$log_emp, na.rm = TRUE)

pre_722_entry <- df_722_entry %>% filter(time_q < 2010)
pre_sds$sd_entry_722 <- sd(pre_722_entry$entry_rate, na.rm = TRUE)

pre_722_earn <- df_722_earn %>% filter(time_q < 2010)
pre_sds$sd_log_earn_722 <- sd(pre_722_earn$log_earn, na.rm = TRUE)

pre_311 <- df_311 %>% filter(time_q < 2010)
pre_sds$sd_log_emp_311 <- sd(pre_311$log_emp, na.rm = TRUE)

pre_311_entry <- df_311_entry %>% filter(time_q < 2010)
pre_sds$sd_entry_311 <- sd(pre_311_entry$entry_rate, na.rm = TRUE)

saveRDS(pre_sds, "../data/pre_treatment_sds.rds")

# --- Diagnostics for validator ---
jsonlite::write_json(list(
  n_treated = n_distinct(df_722$state_fips[df_722$first_treat > 0]),
  n_pre = length(unique(df_722$time_q[df_722$time_q < 2010])),
  n_obs = nrow(df_722)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults saved. Diagnostics written.\n")
