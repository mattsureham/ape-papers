# =============================================================================
# 03_main_analysis.R — Event study DiD, two-stage decomposition
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# --- 1. Restrict to clean comparison: FAIL vs PASS (drop ZONE) ---
cat("=== Constructing analysis sample ===\n")

df <- panel %>%
  filter(ge_fail == 1 | ge_pass == 1) %>%
  mutate(
    treated = ge_fail,
    # Year relative to publication (2017 = 0)
    rel_year = year - 2017,
    # Factor for event study (bin endpoints)
    rel_year_f = case_when(
      rel_year <= -4 ~ -4L,
      rel_year >= 4 ~ 4L,
      TRUE ~ as.integer(rel_year)
    )
  )

cat("Analysis sample: ", nrow(df), " program-years\n")
cat("Treated (FAIL):", sum(df$treated & df$year == 2016), "\n")
cat("Control (PASS):", sum(!df$treated & df$year == 2016), "\n")

# --- 2. Main specification: Two-period decomposition ---
cat("\n=== Main specification ===\n")

# Model 1: Simple post-publication effect
m1 <- feols(total_completions ~ treated:post_pub |
              prog_id + year,
            data = df, cluster = ~unitid)

cat("Model 1 — Publication effect:\n")
print(summary(m1))

# Model 2: Two-stage decomposition (publication + rollback)
m2 <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df, cluster = ~unitid)

cat("\nModel 2 — Two-stage decomposition:\n")
print(summary(m2))

# Model 3: Within-institution sample only
df_within <- df %>% filter(within_inst_sample)
cat("\nWithin-institution sample:", nrow(df_within), "obs\n")

m3 <- feols(total_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + unitid^year,  # Institution×year FE
            data = df_within, cluster = ~unitid)

cat("Model 3 — Within-institution:\n")
print(summary(m3))

# --- 3. Event study ---
cat("\n=== Event study ===\n")

# Reference year: t = -1 (2016)
es <- feols(total_completions ~ i(rel_year_f, treated, ref = -1) |
              prog_id + year,
            data = df, cluster = ~unitid)

cat("Event study coefficients:\n")
print(coeftable(es))

# --- 4. Minority completions ---
cat("\n=== Minority completions ===\n")

m4 <- feols(minority_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df, cluster = ~unitid)

cat("Model 4 — Minority completions:\n")
print(summary(m4))

m5 <- feols(black_completions ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df, cluster = ~unitid)

cat("Model 5 — Black completions:\n")
print(summary(m5))

# --- 5. Save results ---
results <- list(
  m1_publication = m1,
  m2_twostage = m2,
  m3_within = m3,
  es_event_study = es,
  m4_minority = m4,
  m5_black = m5
)

saveRDS(results, "../data/main_results.rds")

# --- 6. Write diagnostics.json ---
diag <- list(
  n_treated = n_distinct(df$prog_id[df$treated == 1]),
  n_control = n_distinct(df$prog_id[df$treated == 0]),
  n_pre = length(unique(df$year[df$year < 2017])),
  n_post = length(unique(df$year[df$year >= 2017])),
  n_obs = nrow(df),
  n_institutions = n_distinct(df$unitid),
  n_within_inst = nrow(df_within),
  beta_publication = coef(m2)["treated:post_pub"],
  beta_rollback = coef(m2)["treated:post_rollback"],
  se_publication = se(m2)["treated:post_pub"],
  se_rollback = se(m2)["treated:post_rollback"]
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Publication effect (beta_1):", round(diag$beta_publication, 2), "\n")
cat("Rollback effect (beta_2):", round(diag$beta_rollback, 2), "\n")
cat("If beta_2 ≈ 0, the scarlet score persists.\n")
cat("If beta_2 > 0, some recovery after rollback (regulatory channel).\n")

# --- 7. Additional: Minority share regression ---
cat("\n=== Minority share regression ===\n")

df_share <- df %>%
  mutate(min_share = minority_completions / pmax(total_completions, 1))

m6 <- feols(min_share ~ treated:post_pub + treated:post_rollback |
              prog_id + year,
            data = df_share, cluster = ~unitid)

cat("Model 6 — Minority share:\n")
print(summary(m6))

results <- readRDS("../data/main_results.rds")
results$m6_min_share <- m6
saveRDS(results, "../data/main_results.rds")
