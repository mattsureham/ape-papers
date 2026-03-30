## 04_robustness.R — Robustness checks
## APEP-1123: The Registration Effect

source("00_packages.R")

cat("=== Robustness Checks ===\n")

df <- read_csv("data/trials_analysis.csv", show_col_types = FALSE)
df_comp <- read_csv("data/trials_completed.csv", show_col_types = FALSE)

# ============================================================
# 1. PLACEBO TEST: Pre-period only (2003-2007), fake treatment at 2006
# ============================================================
cat("\n--- Placebo: Fake treatment at 2006 ---\n")

df_pre <- df_comp |>
  filter(start_year >= 2003, start_year <= 2007) |>
  mutate(
    fake_post = as.integer(start_year >= 2006),
    fake_treat_post = treated * fake_post
  )

m_placebo <- feols(has_results_posted ~ fake_treat_post + treated | start_year,
                   data = df_pre,
                   cluster = ~start_year)

cat(sprintf("  Placebo DiD: %.4f (SE: %.4f, p=%.3f)\n",
            coef(m_placebo)["fake_treat_post"],
            se(m_placebo)["fake_treat_post"],
            pvalue(m_placebo)["fake_treat_post"]))

# ============================================================
# 2. DONUT: Drop 2007-2008 (anticipation / transition)
# ============================================================
cat("\n--- Donut: Exclude 2007-2008 ---\n")

df_donut <- df_comp |>
  filter(!start_year %in% c(2007, 2008))

m_donut <- feols(has_results_posted ~ treat_post + treated +
                   is_industry + log_enrollment | start_year,
                 data = df_donut,
                 cluster = ~start_year)

cat(sprintf("  Donut DiD: %.4f (SE: %.4f)\n",
            coef(m_donut)["treat_post"], se(m_donut)["treat_post"]))

# ============================================================
# 3. ALTERNATIVE WINDOW: Narrower (2005-2010) and wider (2003-2015)
# ============================================================
cat("\n--- Alternative windows ---\n")

df_narrow <- df_comp |> filter(start_year >= 2005, start_year <= 2010)
m_narrow <- feols(has_results_posted ~ treat_post + treated +
                    is_industry + log_enrollment | start_year,
                  data = df_narrow,
                  cluster = ~start_year)

cat(sprintf("  Narrow (2005-2010): %.4f (SE: %.4f)\n",
            coef(m_narrow)["treat_post"], se(m_narrow)["treat_post"]))

# Wide window is the baseline (2003-2015)

# ============================================================
# 4. ALTERNATIVE CONTROL: Phase 1/2 trials as treatment
# ============================================================
cat("\n--- Phase 2 only vs Phase 3 only ---\n")

df_full <- read_csv("data/trials_raw.csv", show_col_types = FALSE) |>
  mutate(start_year = as.integer(substr(start_date, 1, 4)))

# Phase 2 only
df_p2 <- df_comp |> filter(phase %in% c("PHASE1", "PHASE2"))
df_p2 <- df_p2 |>
  mutate(treated_p2 = as.integer(phase == "PHASE2"),
         treat_post_p2 = treated_p2 * post)

m_p2 <- feols(has_results_posted ~ treat_post_p2 + treated_p2 +
                is_industry + log_enrollment | start_year,
              data = df_p2,
              cluster = ~start_year)

# Phase 3 only
df_p3 <- df_comp |> filter(phase %in% c("PHASE1", "PHASE3"))
df_p3 <- df_p3 |>
  mutate(treated_p3 = as.integer(phase == "PHASE3"),
         treat_post_p3 = treated_p3 * post)

m_p3 <- feols(has_results_posted ~ treat_post_p3 + treated_p3 +
                is_industry + log_enrollment | start_year,
              data = df_p3,
              cluster = ~start_year)

cat(sprintf("  Phase 2 vs 1: %.4f (SE: %.4f)\n",
            coef(m_p2)["treat_post_p2"], se(m_p2)["treat_post_p2"]))
cat(sprintf("  Phase 3 vs 1: %.4f (SE: %.4f)\n",
            coef(m_p3)["treat_post_p3"], se(m_p3)["treat_post_p3"]))

# ============================================================
# 5. OUTCOME: PRIMARY OUTCOME COUNT ROBUSTNESS
# ============================================================
cat("\n--- Primary outcome count robustness ---\n")

# Restrict to trials with at least 1 primary outcome registered
df_with_po <- df |> filter(n_primary >= 1)

m_po_restrict <- feols(n_primary ~ treat_post + treated +
                         is_industry + log_enrollment | start_year,
                       data = df_with_po,
                       cluster = ~start_year)

cat(sprintf("  Primary outcomes (conditional on >0): %.4f (SE: %.4f)\n",
            coef(m_po_restrict)["treat_post"], se(m_po_restrict)["treat_post"]))

# Has any primary outcome (extensive margin)
df <- df |> mutate(has_primary = as.integer(n_primary >= 1))
m_has_po <- feols(has_primary ~ treat_post + treated +
                    is_industry + log_enrollment | start_year,
                  data = df,
                  cluster = ~start_year)

cat(sprintf("  Has primary outcome (extensive): %.4f (SE: %.4f)\n",
            coef(m_has_po)["treat_post"], se(m_has_po)["treat_post"]))

# ============================================================
# SAVE
# ============================================================
save(m_placebo, m_donut, m_narrow,
     m_p2, m_p3,
     m_po_restrict, m_has_po,
     file = "data/robustness_models.RData")

cat("\n=== Robustness checks complete ===\n")
