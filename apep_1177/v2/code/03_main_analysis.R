## 03_main_analysis.R — Main analysis: discretion decoupling
## apep_1177 v2: The Conviction Lottery

source("./code/00_packages.R")

## ---- Load data ----
# Load all three offense datasets (from corrected smoke test)
traff <- as.data.table(arrow::read_parquet("./data/smoke_trafficking.parquet"))
rob <- as.data.table(arrow::read_parquet("./data/smoke_robbery_corrected.parquet"))
theft <- as.data.table(arrow::read_parquet("./data/smoke_theft_corrected.parquet"))

# Add offense type labels
traff[, offense_type := "trafficking"]
rob[, offense_type := "robbery"]
theft[, offense_type := "theft"]

# Filter trafficking to 2015-2019 for consistency
traff[, filing_year := as.integer(substr(filing_date, 1, 4))]
traff <- traff[filing_year >= 2015 & filing_year <= 2019]

# Filter robbery/theft to resolved only
rob <- rob[resolved == TRUE]
theft <- theft[resolved == TRUE]

cat("Sample sizes:\n")
cat("  Trafficking:", nrow(traff), "\n")
cat("  Robbery:", nrow(rob), "\n")
cat("  Theft:", nrow(theft), "\n")

## ---- Vara-level conviction rates by offense ----
vara_traff <- traff[, .(n_traff = .N,
                        conv_traff = sum(convicted, na.rm = TRUE)),
                    by = vara_codigo]
vara_traff[, rate_traff := conv_traff / n_traff]

vara_rob <- rob[, .(n_rob = .N,
                    conv_rob = sum(convicted, na.rm = TRUE)),
                by = vara_codigo]
vara_rob[, rate_rob := conv_rob / n_rob]

vara_theft <- theft[, .(n_theft = .N,
                        conv_theft = sum(convicted, na.rm = TRUE)),
                    by = vara_codigo]
vara_theft[, rate_theft := conv_theft / n_theft]

# Merge all three
vara <- merge(vara_traff, vara_rob, by = "vara_codigo")
vara <- merge(vara, vara_theft, by = "vara_codigo")
# Require ≥20 cases in each offense
vara <- vara[n_traff >= 20 & n_rob >= 20 & n_theft >= 20]
cat("\nCommon varas (≥20 each):", nrow(vara), "\n")

## ---- Core finding: cross-offense correlations ----
cat("\n--- CROSS-OFFENSE CORRELATIONS ---\n")
cor_tr <- cor(vara$rate_traff, vara$rate_rob)
cor_tt <- cor(vara$rate_traff, vara$rate_theft)
cor_rt <- cor(vara$rate_rob, vara$rate_theft)
cat("  Trafficking-Robbery:", round(cor_tr, 3), "\n")
cat("  Trafficking-Theft:", round(cor_tt, 3), "\n")
cat("  Robbery-Theft:", round(cor_rt, 3), "\n")

## ---- Spearman correlations (rank-based, robust to outliers) ----
cat("\n--- SPEARMAN CORRELATIONS ---\n")
sp_tr <- cor(vara$rate_traff, vara$rate_rob, method = "spearman")
sp_tt <- cor(vara$rate_traff, vara$rate_theft, method = "spearman")
sp_rt <- cor(vara$rate_rob, vara$rate_theft, method = "spearman")
cat("  Trafficking-Robbery:", round(sp_tr, 3), "\n")
cat("  Trafficking-Theft:", round(sp_tt, 3), "\n")
cat("  Robbery-Theft:", round(sp_rt, 3), "\n")

## ---- Test: are the correlations significantly different? ----
# Steiger's test for comparing dependent correlations
# We compare cor(traff,theft) vs cor(robbery,theft)
cat("\n--- STEIGER TEST ---\n")
# Using Fisher z-transform
n_v <- nrow(vara)
z_tt <- atanh(cor_tt)
z_rt <- atanh(cor_rt)
z_tr <- atanh(cor_tr)
# Pooled variance
denom <- sqrt(2 * (1 - cor_tr) / (n_v - 3))
z_diff <- (z_rt - z_tt) / denom
p_val <- 2 * (1 - pnorm(abs(z_diff)))
cat("  z-stat for r(rob,theft) - r(traff,theft):", round(z_diff, 3), "\n")
cat("  p-value:", round(p_val, 4), "\n")

## ---- Common severity factor (from robbery + theft) ----
cat("\n--- COMMON SEVERITY FACTOR ---\n")
# Principal component from robbery and theft rates
rates_rt <- cbind(vara$rate_rob, vara$rate_theft)
pca <- prcomp(rates_rt, scale. = TRUE)
vara[, common_severity := pca$x[, 1]]

# How much does trafficking load on this factor?
loading_traff <- cor(vara$rate_traff, vara$common_severity)
cat("  Trafficking loading on robbery-theft PC1:", round(loading_traff, 3), "\n")
cat("  Robbery loading:", round(cor(vara$rate_rob, vara$common_severity), 3), "\n")
cat("  Theft loading:", round(cor(vara$rate_theft, vara$common_severity), 3), "\n")

# Trafficking residual after projecting onto common severity
reg_traff <- lm(rate_traff ~ common_severity, data = vara)
vara[, traff_residual := residuals(reg_traff)]
cat("\n  Trafficking residual SD:", round(sd(vara$traff_residual), 4), "\n")
cat("  R-squared (common severity explains trafficking):",
    round(summary(reg_traff)$r.squared, 3), "\n")

## ---- Distribution of trafficking residuals ----
cat("\n--- TRAFFICKING RESIDUALS (drug-specific discretion) ---\n")
cat("  Mean:", round(mean(vara$traff_residual), 4), "\n")
cat("  Skewness:", round(moments::skewness(vara$traff_residual), 3), "\n")
cat("  N below -0.10:", sum(vara$traff_residual < -0.10), "\n")
cat("  N below -0.15:", sum(vara$traff_residual < -0.15), "\n")
cat("  N above +0.10:", sum(vara$traff_residual > 0.10), "\n")
cat("  N above +0.15:", sum(vara$traff_residual > 0.15), "\n")

## ---- Leave-one-out correlation stability ----
cat("\n--- LEAVE-ONE-OUT CORRELATION STABILITY ---\n")
loo_cors <- numeric(nrow(vara))
for (i in seq_len(nrow(vara))) {
  loo_cors[i] <- cor(vara$rate_traff[-i], vara$rate_theft[-i])
}
cat("  Trafficking-Theft LOO range:", round(min(loo_cors), 3),
    "to", round(max(loo_cors), 3), "\n")
cat("  Most influential vara (biggest change):",
    vara$vara_codigo[which.max(abs(loo_cors - cor_tt))], "\n")

## ---- First stage: LOO leniency → conviction (trafficking only) ----
cat("\n--- FIRST STAGE (trafficking) ---\n")
# Combine all trafficking cases and compute LOO leniency
traff[, vara_total_conv := sum(convicted, na.rm = TRUE), by = vara_codigo]
traff[, vara_total_n := .N, by = vara_codigo]
traff[, vara_leniency := (vara_total_conv - convicted) / (vara_total_n - 1)]
traff[, filing_month := as.integer(substr(filing_date, 6, 7))]

fs <- feols(convicted ~ vara_leniency | filing_year, data = traff,
            cluster = ~vara_codigo)
cat("First stage coefficient:", round(coef(fs)["vara_leniency"], 4), "\n")
cat("N obs:", nobs(fs), "\n")
cat("N clusters:", length(unique(traff$vara_codigo)), "\n")
print(summary(fs))

## ---- Balance tests (trafficking) ----
cat("\n--- BALANCE TESTS (trafficking) ---\n")
bal_month <- feols(filing_month ~ vara_leniency | filing_year,
                   data = traff, cluster = ~vara_codigo)
bal_coef <- coef(bal_month)["vara_leniency"]
bal_se <- sqrt(vcov(bal_month)["vara_leniency", "vara_leniency"])
bal_t <- bal_coef / bal_se
bal_p <- 2 * pt(-abs(bal_t), df = nobs(bal_month) - 2)
cat("Filing month on leniency: coef =", round(bal_coef, 4),
    "t =", round(bal_t, 4), "p =", round(bal_p, 4), "\n")

## ---- Save all results ----
results <- list(
  vara_data = vara,
  correlations = list(
    pearson = list(tr = cor_tr, tt = cor_tt, rt = cor_rt),
    spearman = list(tr = sp_tr, tt = sp_tt, rt = sp_rt)
  ),
  steiger = list(z = z_diff, p = p_val),
  common_severity_loading = loading_traff,
  traff_residual_sd = sd(vara$traff_residual),
  first_stage = fs,
  balance = bal_month
)
saveRDS(results, "./data/main_results_v2.rds")
fwrite(vara, "./data/vara_three_way.csv")

cat("\nMain analysis complete. Results saved.\n")
