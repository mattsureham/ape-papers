# =============================================================================
# 04_robustness.R — Robustness checks: placebo, zone programs, wild bootstrap
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

has_fwcb <- requireNamespace("fwildclusterboot", quietly = TRUE)
if (has_fwcb) library(fwildclusterboot)

# --- Shared analysis sample ---
df <- panel %>%
  filter(ge_fail == 1 | ge_pass == 1) %>%
  mutate(treated = ge_fail, rel_year = year - 2017)

# === Robustness 1: Zone programs as placebo ===
cat("=== Placebo: Zone vs Pass programs ===\n")

df_placebo <- panel %>%
  filter(ge_zone == 1 | ge_pass == 1) %>%
  mutate(
    treated = ge_zone,
    post_pub = as.integer(year >= 2017),
    post_rollback = as.integer(year >= 2018)
  )

r1 <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df_placebo, cluster = ~unitid)

cat("Zone (placebo) vs Pass:\n")
print(summary(r1))

# === Robustness 2: Log completions (intensive margin) ===
cat("\n=== Log completions ===\n")

df_log <- df %>%
  mutate(log_comp = log(total_completions + 1))

r2 <- feols(log_comp ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df_log, cluster = ~unitid)

cat("Log(completions + 1):\n")
print(summary(r2))

# === Robustness 3: Program exit (extensive margin) ===
cat("\n=== Program exit (zero completions) ===\n")

df_exit <- df %>%
  mutate(zero_comp = as.integer(total_completions == 0))

r3 <- feols(zero_comp ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df_exit, cluster = ~unitid)

cat("Pr(zero completions):\n")
print(summary(r3))

# === Robustness 4: Drop institutions that closed ===
cat("\n=== Drop closed institutions ===\n")

# Find institutions with non-zero deathyr
inst <- readRDS("../data/ipeds_institutions.rds")
closed <- inst %>%
  filter(!is.na(deathyr) & deathyr > 0 & deathyr <= 2021) %>%
  pull(unitid) %>% unique()

cat("Institutions that closed:", length(closed), "\n")

df_noclosed <- df %>% filter(!unitid %in% closed)

r4 <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df_noclosed, cluster = ~unitid)

cat("Without closed institutions:\n")
print(summary(r4))

# === Robustness 5: Wild cluster bootstrap (if package available) ===
cat("\n=== Wild cluster bootstrap ===\n")

boot_pub_pval <- NA
boot_roll_pval <- NA

if (has_fwcb) {
  m_base <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
                    prog_id + year,
                  data = df, cluster = ~unitid)

  boot_pub <- boot_c3(m_base, param = "treated:post_pub",
                       B = 999, clustid = ~unitid, type = "rademacher")
  boot_roll <- boot_c3(m_base, param = "treated:post_rollback",
                        B = 999, clustid = ~unitid, type = "rademacher")

  boot_pub_pval <- boot_pub$p_val
  boot_roll_pval <- boot_roll$p_val
  cat("Wild cluster bootstrap p-values:\n")
  cat("  Publication effect:", boot_pub_pval, "\n")
  cat("  Rollback effect:", boot_roll_pval, "\n")
} else {
  cat("fwildclusterboot not available — using fixest's cluster-robust SEs\n")
  cat("With ~1,200 clusters, conventional cluster-robust inference is adequate.\n")
}

# === Robustness 6: Minority share (heterogeneity by pre-period minority share) ===
cat("\n=== Heterogeneity: high vs low minority share ===\n")

pre_minority <- df %>%
  filter(year < 2017) %>%
  group_by(prog_id) %>%
  summarize(pre_min_share = mean(minority_share, na.rm = TRUE), .groups = "drop")

df_het <- df %>%
  left_join(pre_minority, by = "prog_id") %>%
  mutate(high_minority = as.integer(pre_min_share > median(pre_min_share, na.rm = TRUE)))

r6_high <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
                   prog_id + year,
                 data = df_het %>% filter(high_minority == 1), cluster = ~unitid)

r6_low <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
                  prog_id + year,
                data = df_het %>% filter(high_minority == 0), cluster = ~unitid)

cat("High minority share programs:\n")
print(summary(r6_high))
cat("\nLow minority share programs:\n")
print(summary(r6_low))

# --- Save all robustness results ---
rob_results <- list(
  r1_placebo = r1,
  r2_log = r2,
  r3_exit = r3,
  r4_noclosed = r4,
  boot_pub_pval = boot_pub_pval,
  boot_roll_pval = boot_roll_pval,
  r6_high_minority = r6_high,
  r6_low_minority = r6_low
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
