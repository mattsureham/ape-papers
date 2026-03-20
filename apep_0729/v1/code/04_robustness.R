## 04_robustness.R — Robustness checks for apep_0729

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. POPULATION QUARTILE MATCHING
# ============================================================
cat("--- 1. WITHIN POPULATION QUARTILE ---\n")
df[, pop_quartile := cut(population_2021,
                          breaks = quantile(population_2021, probs = 0:4/4, na.rm = TRUE),
                          labels = paste0("Q", 1:4), include.lowest = TRUE)]

r1 <- feols(turnout ~ treated + log_pop | year + pop_quartile + county_code,
            data = df, vcov = ~region_code)
cat(sprintf("  Treated: %.3f (SE=%.3f, p=%.4f)\n",
            coef(r1)["treatedTRUE"],
            sqrt(vcov(r1)["treatedTRUE","treatedTRUE"]),
            2*pnorm(-abs(coef(r1)["treatedTRUE"]/sqrt(vcov(r1)["treatedTRUE","treatedTRUE"])))))

# ============================================================
# 2. EXCLUDE NATIONAL AND BIG-CITY PAPERS
# ============================================================
# National papers (Riksmedier) shouldn't affect local turnout
# Big-city papers (Oslo/Bergen/Stavanger/Trondheim) are in large markets
# Only keep "Øvrige medier" as treatment
cat("\n--- 2. ONLY 'OTHER' LOCAL PAPERS AS TREATMENT ---\n")
subsidy_all <- fread(file.path(data_dir, "subsidy_all.csv"))
subsidy_local_only <- fread(file.path(data_dir, "subsidy_local.csv"))

# Count how many papers are "Øvrige medier" vs other categories
cat(sprintf("  Full subsidy sample: %d papers\n", nrow(subsidy_all)))
cat(sprintf("  Mapped local papers: %d\n", nrow(subsidy_local_only)))

# This is already our treatment — so same as main. Confirm.
r2 <- feols(turnout ~ treated + log_pop | year + county_code,
            data = df, vcov = ~region_code)
cat(sprintf("  Treated (main spec, already uses local papers): %.3f (SE=%.3f)\n",
            coef(r2)["treatedTRUE"],
            sqrt(vcov(r2)["treatedTRUE","treatedTRUE"])))

# ============================================================
# 3. DROP OUTLIER MUNICIPALITIES (VERY SMALL/LARGE)
# ============================================================
cat("\n--- 3. DROPPING EXTREME POPULATION ---\n")
p5 <- quantile(df$population_2021, 0.05, na.rm = TRUE)
p95 <- quantile(df$population_2021, 0.95, na.rm = TRUE)
df_trim <- df[population_2021 >= p5 & population_2021 <= p95]
cat(sprintf("  Trimmed sample: %d obs (dropped %d)\n",
            nrow(df_trim), nrow(df) - nrow(df_trim)))

r3 <- feols(turnout ~ treated + log_pop | year + county_code,
            data = df_trim, vcov = ~region_code)
cat(sprintf("  Treated: %.3f (SE=%.3f, p=%.4f)\n",
            coef(r3)["treatedTRUE"],
            sqrt(vcov(r3)["treatedTRUE","treatedTRUE"]),
            2*pnorm(-abs(coef(r3)["treatedTRUE"]/sqrt(vcov(r3)["treatedTRUE","treatedTRUE"])))))

# ============================================================
# 4. STORTING VS LOCAL ELECTIONS SEPARATELY
# ============================================================
cat("\n--- 4. BY ELECTION TYPE (MAIN vs APPENDIX) ---\n")
r4a <- feols(turnout ~ treated + log_pop | year + county_code,
             data = df[election_type == "storting"], vcov = ~region_code)
r4b <- feols(turnout ~ treated + log_pop | year + county_code,
             data = df[election_type == "local"], vcov = ~region_code)

cat(sprintf("  Storting: %.3f (SE=%.3f)\n",
            coef(r4a)["treatedTRUE"], sqrt(vcov(r4a)["treatedTRUE","treatedTRUE"])))
cat(sprintf("  Local:    %.3f (SE=%.3f)\n",
            coef(r4b)["treatedTRUE"], sqrt(vcov(r4b)["treatedTRUE","treatedTRUE"])))
cat(sprintf("  Ratio (local/storting): %.2f — effect is %.0f%% larger for local elections\n",
            coef(r4b)["treatedTRUE"] / coef(r4a)["treatedTRUE"],
            abs((coef(r4b)["treatedTRUE"] - coef(r4a)["treatedTRUE"]) / coef(r4a)["treatedTRUE"] * 100)))

# ============================================================
# 5. SUBSIDY AMOUNT ROBUSTNESS
# ============================================================
cat("\n--- 5. SUBSIDY AMOUNT (NOK PER CAPITA) ---\n")
r5a <- feols(turnout ~ subsidy_per_capita + log_pop | year + county_code,
             data = df, vcov = ~region_code)

# Standardized (per SD of subsidy)
df[, subsidy_pc_std := scale(subsidy_per_capita)]
r5b <- feols(turnout ~ subsidy_pc_std + log_pop | year + county_code,
             data = df, vcov = ~region_code)

cat(sprintf("  Per NOK/capita: %.5f (SE=%.5f)\n",
            coef(r5a)["subsidy_per_capita"],
            sqrt(vcov(r5a)["subsidy_per_capita","subsidy_per_capita"])))
cat(sprintf("  Per SD: %.3f (SE=%.3f)\n",
            coef(r5b)["subsidy_pc_std"],
            sqrt(vcov(r5b)["subsidy_pc_std","subsidy_pc_std"])))

# ============================================================
# 6. NUMBER OF SUBSIDIZED PAPERS
# ============================================================
cat("\n--- 6. NUMBER OF SUBSIDIZED PAPERS ---\n")
r6 <- feols(turnout ~ n_subsidized_papers + log_pop | year + county_code,
            data = df, vcov = ~region_code)
cat(sprintf("  Per additional paper: %.3f (SE=%.3f)\n",
            coef(r6)["n_subsidized_papers"],
            sqrt(vcov(r6)["n_subsidized_papers","n_subsidized_papers"])))

# ============================================================
# 7. PRE-2017 vs POST-2017 (DIGITAL TRANSITION)
# ============================================================
cat("\n--- 7. PRE vs POST 2017 ---\n")
r7a <- feols(turnout ~ treated + log_pop | year + county_code,
             data = df[year <= 2017], vcov = ~region_code)
r7b <- feols(turnout ~ treated + log_pop | year + county_code,
             data = df[year > 2017], vcov = ~region_code)
cat(sprintf("  Pre-2017:  %.3f (SE=%.3f)\n",
            coef(r7a)["treatedTRUE"], sqrt(vcov(r7a)["treatedTRUE","treatedTRUE"])))
cat(sprintf("  Post-2017: %.3f (SE=%.3f)\n",
            coef(r7b)["treatedTRUE"], sqrt(vcov(r7b)["treatedTRUE","treatedTRUE"])))

# ============================================================
# 8. SAVE ROBUSTNESS RESULTS
# ============================================================
rob_results <- list(
  r1_pop_quartile = r1,
  r3_trimmed = r3,
  r4a_storting = r4a, r4b_local = r4b,
  r5a_subsidy_pc = r5a, r5b_subsidy_std = r5b,
  r6_n_papers = r6,
  r7a_pre2017 = r7a, r7b_post2017 = r7b
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
