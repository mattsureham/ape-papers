## 04_robustness.R — Robustness checks for apep_1103

source("00_packages.R")

data_dir <- "../data"
results <- readRDS(file.path(data_dir, "results.rds"))
df <- results$data$df

cat("── Robustness Checks ──\n")

# ══════════════════════════════════════════════════════════════════════════════
# 1) Canton-specific linear time trends
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (1) Canton-specific linear trends\n")
r1 <- feols(okp_total_pc ~ di_rate_2009:post_2008 + di_rate_2009:year |
              canton_id + year,
            data = df, cluster = ~canton_id)
cat("    beta =", round(coef(r1)["di_rate_2009:post_2008"], 3),
    " SE =", round(se(r1)["di_rate_2009:post_2008"], 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2) Placebo reform date (2004 instead of 2008)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (2) Placebo reform: 2004\n")
df_placebo <- df |>
  filter(year <= 2007) |>
  mutate(post_placebo = as.integer(year >= 2004))

r2 <- feols(okp_total_pc ~ di_rate_2009:post_placebo | canton_id + year,
            data = df_placebo, cluster = ~canton_id)
cat("    beta =", round(coef(r2)[1], 3),
    " SE =", round(se(r2)[1], 3),
    " p =", round(pvalue(r2)[1], 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3) Exclude Geneva and Ticino (outlier high-cost cantons)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (3) Exclude GE and TI\n")
r3 <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
            data = df |> filter(!canton %in% c("GE", "TI")), cluster = ~canton_id)
cat("    beta =", round(coef(r3)[1], 3),
    " SE =", round(se(r3)[1], 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 4) Leave-one-canton-out jackknife
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (4) Leave-one-out jackknife\n")
cantons <- unique(df$canton)
jk_betas <- numeric(length(cantons))
for (i in seq_along(cantons)) {
  fit <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
               data = df |> filter(canton != cantons[i]), cluster = ~canton_id)
  jk_betas[i] <- coef(fit)[1]
}
cat("    Jackknife range: [", round(min(jk_betas), 3), ",",
    round(max(jk_betas), 3), "]\n")
cat("    Mean:", round(mean(jk_betas), 3), " SD:", round(sd(jk_betas), 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 5) Shorter pre-period (2004-2022)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (5) Shorter pre-period (2004+)\n")
r5 <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
            data = df |> filter(year >= 2004), cluster = ~canton_id)
cat("    beta =", round(coef(r5)[1], 3),
    " SE =", round(se(r5)[1], 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 6) Per-capita log specification
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  (6) Log(OKP) specification\n")
r6 <- feols(log_okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
            data = df, cluster = ~canton_id)
cat("    beta =", round(coef(r6)[1], 5),
    " SE =", round(se(r6)[1], 5), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# Save robustness results
# ══════════════════════════════════════════════════════════════════════════════
robustness <- list(
  canton_trends = r1,
  placebo = r2,
  excl_outliers = r3,
  jackknife = list(betas = jk_betas, cantons = cantons),
  short_pre = r5,
  log_spec = r6
)

saveRDS(robustness, file.path(data_dir, "robustness.rds"))
cat("\n  Saved robustness.rds\n")
