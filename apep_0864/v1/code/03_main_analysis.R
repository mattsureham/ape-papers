## 03_main_analysis.R — Main regressions for apep_0864
## Continuous treatment DiD + event study + RDD

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== MAIN ANALYSIS ===\n")
cat(sprintf("Panel: %d obs, %d municipalities, %d years\n",
            nrow(panel), n_distinct(panel$bfs_nr), n_distinct(panel$year)))

# ============================================================
# 1. CONTINUOUS TREATMENT DiD — Main specification
# ============================================================
cat("\n--- Main DiD Specification ---\n")

# Specification 1: Baseline — municipality FE + year FE
m1 <- feols(foreign_share ~ yes_share_std:post | bfs_nr + year,
            data = panel, cluster = ~bfs_nr)

# Specification 2: + pre-foreign-share × year trends
m2 <- feols(foreign_share ~ yes_share_std:post + pre_foreign_share:factor(year) |
              bfs_nr + year,
            data = panel, cluster = ~bfs_nr)

# Specification 3: + canton × year FE (absorbs canton-level shocks)
m3 <- feols(foreign_share ~ yes_share_std:post + pre_foreign_share:factor(year) |
              bfs_nr + canton_id^year,
            data = panel, cluster = ~bfs_nr)

# Specification 4: + language × year (absorbs language-region trends)
m4 <- feols(foreign_share ~ yes_share_std:post |
              bfs_nr + language^year,
            data = panel, cluster = ~bfs_nr)

cat("Spec 1 (baseline): β =", round(coef(m1)["yes_share_std:post"], 5),
    "SE =", round(se(m1)["yes_share_std:post"], 5), "\n")
cat("Spec 2 (+ pre-FS trend): β =", round(coef(m2)["yes_share_std:post"], 5),
    "SE =", round(se(m2)["yes_share_std:post"], 5), "\n")
cat("Spec 3 (+ canton×year): β =", round(coef(m3)["yes_share_std:post"], 5),
    "SE =", round(se(m3)["yes_share_std:post"], 5), "\n")
cat("Spec 4 (language×year): β =", round(coef(m4)["yes_share_std:post"], 5),
    "SE =", round(se(m4)["yes_share_std:post"], 5), "\n")

# Save main models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
        file.path(data_dir, "main_models.rds"))

# ============================================================
# 2. EVENT STUDY — Dynamic treatment effects
# ============================================================
cat("\n--- Event Study ---\n")

# Create relative-year dummies interacted with treatment intensity
panel <- panel |>
  mutate(rel_year = year - 2015)  # t=0 is 2015, first full post-vote year

# Event study: municipality FE + year FE
es <- feols(foreign_share ~ i(rel_year, yes_share_std, ref = -1) | bfs_nr + year,  # ref: t-1 = 2014
            data = panel, cluster = ~bfs_nr)

cat("Event study coefficients:\n")
es_coefs <- data.frame(
  rel_year = as.numeric(gsub("rel_year::", "", gsub(":yes_share_std", "", names(coef(es))))),
  coef = coef(es),
  se = se(es)
) |>
  arrange(rel_year)
print(es_coefs)

saveRDS(es, file.path(data_dir, "event_study_model.rds"))
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================
# 3. LOG FOREIGN POPULATION — Level effects
# ============================================================
cat("\n--- Log Foreign Population ---\n")

m_log <- feols(log_foreign ~ yes_share_std:post | bfs_nr + year,
               data = panel, cluster = ~bfs_nr)
cat("Log(foreign): β =", round(coef(m_log)[1], 4),
    "SE =", round(se(m_log)[1], 4), "\n")

m_log_canton <- feols(log_foreign ~ yes_share_std:post + pre_foreign_share:factor(year) |
                        bfs_nr + canton_id^year,
                      data = panel, cluster = ~bfs_nr)
cat("Log(foreign) + canton×year: β =", round(coef(m_log_canton)[1], 4),
    "SE =", round(se(m_log_canton)[1], 4), "\n")

saveRDS(list(m_log = m_log, m_log_canton = m_log_canton),
        file.path(data_dir, "log_models.rds"))

# ============================================================
# 4. RDD — Close-vote municipalities
# ============================================================
cat("\n--- RDD within close-vote band ---\n")

rdd_panel <- panel |> filter(post == 1)

# rdrobust on post-period foreign share change
rdd_panel <- rdd_panel |>
  group_by(bfs_nr) |>
  summarize(
    running_var = first(running_var),
    majority_yes = first(majority_yes),
    yes_share = first(yes_share),
    foreign_share_post = mean(foreign_share[year >= 2015]),
    foreign_share_pre = mean(foreign_share[year <= 2013]),
    .groups = "drop"
  ) |>
  mutate(delta_fs = foreign_share_post - foreign_share_pre)

# Need municipalities from the full pre-period too
pre_means <- panel |>
  filter(year <= 2014) |>
  group_by(bfs_nr) |>
  summarize(foreign_share_pre = mean(foreign_share), .groups = "drop")

post_means <- panel |>
  filter(year >= 2016) |>
  group_by(bfs_nr) |>
  summarize(foreign_share_post = mean(foreign_share), .groups = "drop")

rdd_df <- panel |>
  filter(year == 2014) |>
  select(bfs_nr, running_var, majority_yes, yes_share) |>
  left_join(pre_means, by = "bfs_nr") |>
  left_join(post_means, by = "bfs_nr") |>
  mutate(delta_fs = foreign_share_post - foreign_share_pre)

cat(sprintf("RDD sample: %d municipalities\n", nrow(rdd_df)))

# Sharp RDD at 50% threshold
rdd_result <- rdrobust(y = rdd_df$delta_fs, x = rdd_df$running_var, c = 0)
cat("\nRDD estimate:\n")
summary(rdd_result)

# Density test (McCrary)
density_test <- rddensity(X = rdd_df$running_var, c = 0)
cat(sprintf("\nMcCrary density test p-value: %.4f\n", density_test$test$p_jk))

saveRDS(list(rdd_result = rdd_result, density_test = density_test, rdd_df = rdd_df),
        file.path(data_dir, "rdd_results.rds"))

# ============================================================
# 5. DIAGNOSTICS — write diagnostics.json
# ============================================================
cat("\n--- Writing diagnostics ---\n")

diag <- list(
  n_treated = n_distinct(panel$bfs_nr[panel$yes_share > 0.50]),
  n_pre = length(unique(panel$year[panel$year < 2015])),
  n_obs = nrow(panel),
  n_municipalities = n_distinct(panel$bfs_nr),
  n_years = n_distinct(panel$year),
  n_close_vote = n_distinct(panel$bfs_nr[panel$close_vote]),
  main_coef = as.numeric(coef(m3)[1]),
  main_se = as.numeric(se(m3)[1]),
  sd_y = sd(panel$foreign_share),
  sd_treatment = sd(panel$yes_share_std)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics written.\n")

cat("\n=== Main analysis complete ===\n")
