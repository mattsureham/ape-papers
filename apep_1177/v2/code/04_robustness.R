## 04_robustness.R — Robustness checks
## apep_1177 v2: The Conviction Lottery

source("./code/00_packages.R")

vara <- fread("./data/vara_three_way.csv")

cat("Loaded vara data:", nrow(vara), "varas\n")

## ---- R1: Minimum-case threshold sensitivity ----
cat("\n--- R1: Minimum-case threshold sensitivity ---\n")
for (min_n in c(20, 50, 100)) {
  sub <- vara[n_traff >= min_n & n_rob >= min_n & n_theft >= min_n]
  if (nrow(sub) > 5) {
    ct <- cor(sub$rate_traff, sub$rate_theft)
    cr <- cor(sub$rate_rob, sub$rate_theft)
    cat(sprintf("  Min N=%d: %d varas, r(traff,theft)=%.3f, r(rob,theft)=%.3f\n",
                min_n, nrow(sub), ct, cr))
  }
}

## ---- R2: Year-by-year correlation stability ----
cat("\n--- R2: Year-by-year correlation stability ---\n")
traff <- as.data.table(arrow::read_parquet("./data/smoke_trafficking.parquet"))
traff[, filing_year := as.integer(substr(filing_date, 1, 4))]
traff <- traff[filing_year >= 2015 & filing_year <= 2019]
traff[, convicted := as.integer(convicted)]
traff[, filing_month := as.integer(substr(filing_date, 6, 7))]

rob <- as.data.table(arrow::read_parquet("./data/smoke_robbery_corrected.parquet"))
rob <- rob[resolved == TRUE]
rob[, filing_year := as.integer(substr(filing_date, 1, 4))]

theft <- as.data.table(arrow::read_parquet("./data/smoke_theft_corrected.parquet"))
theft <- theft[resolved == TRUE]
theft[, filing_year := as.integer(substr(filing_date, 1, 4))]

for (yr in 2015:2019) {
  t_yr <- traff[filing_year == yr, .(rate_traff = mean(convicted, na.rm=TRUE), .N), by=vara_codigo]
  r_yr <- rob[filing_year == yr, .(rate_rob = mean(convicted, na.rm=TRUE), .N), by=vara_codigo]
  th_yr <- theft[filing_year == yr, .(rate_theft = mean(convicted, na.rm=TRUE), .N), by=vara_codigo]
  merged_yr <- merge(t_yr[N >= 5], merge(r_yr[N >= 5], th_yr[N >= 5], by="vara_codigo"), by="vara_codigo")
  if (nrow(merged_yr) >= 10) {
    ct <- cor(merged_yr$rate_traff, merged_yr$rate_theft)
    cr <- cor(merged_yr$rate_rob, merged_yr$rate_theft)
    cat(sprintf("  %d: %d varas, r(traff,theft)=%.3f, r(rob,theft)=%.3f\n",
                yr, nrow(merged_yr), ct, cr))
  }
}

## ---- R3: Leniency time stability ----
cat("\n--- R3: Leniency time stability ---\n")
traff_early <- traff[filing_year <= 2017, .(rate_early=mean(convicted,na.rm=TRUE)), by=vara_codigo]
traff_late <- traff[filing_year >= 2018, .(rate_late=mean(convicted,na.rm=TRUE)), by=vara_codigo]
mt <- merge(traff_early, traff_late, by="vara_codigo")
if (nrow(mt) > 5) cat("  Trafficking early-late r =", round(cor(mt$rate_early, mt$rate_late), 3), "\n")

rob_early <- rob[filing_year <= 2017, .(rate_early=mean(convicted,na.rm=TRUE)), by=vara_codigo]
rob_late <- rob[filing_year >= 2018, .(rate_late=mean(convicted,na.rm=TRUE)), by=vara_codigo]
mr <- merge(rob_early, rob_late, by="vara_codigo")
if (nrow(mr) > 5) cat("  Robbery early-late r =", round(cor(mr$rate_early, mr$rate_late), 3), "\n")

## ---- R4: Permutation test ----
cat("\n--- R4: Permutation test ---\n")
set.seed(42)
n_perm <- 10000
observed_diff <- cor(vara$rate_rob, vara$rate_theft) - cor(vara$rate_traff, vara$rate_theft)
perm_diffs <- numeric(n_perm)
for (i in seq_len(n_perm)) {
  perm_traff <- sample(vara$rate_traff)
  perm_diffs[i] <- cor(vara$rate_rob, vara$rate_theft) - cor(perm_traff, vara$rate_theft)
}
perm_p <- mean(perm_diffs >= observed_diff)
cat("  Observed diff:", round(observed_diff, 3), ", Permutation p:", perm_p, "\n")

## ---- R5: Balance tests ----
cat("\n--- R5: Balance tests ---\n")
traff[, filing_dow := wday(as.Date(filing_date))]
traff[, vara_total_conv := sum(convicted, na.rm=TRUE), by=vara_codigo]
traff[, vara_total_n := .N, by=vara_codigo]
traff[, vara_leniency := (vara_total_conv - convicted) / (vara_total_n - 1)]

bal_dow <- feols(filing_dow ~ vara_leniency | filing_year, data=traff, cluster=~vara_codigo)
cat("  Day-of-week: coef=", round(coef(bal_dow), 4), "SE=", round(sqrt(vcov(bal_dow)[1,1]), 4), "\n")

bal_month <- feols(filing_month ~ vara_leniency | filing_year, data=traff, cluster=~vara_codigo)
cat("  Filing month: coef=", round(coef(bal_month), 4), "SE=", round(sqrt(vcov(bal_month)[1,1]), 4), "\n")

cat("\n  Sorteio coverage:\n")
cat("    Trafficking:", round(100*mean(traff$has_sorteio, na.rm=TRUE), 1), "%\n")
cat("    Robbery:", round(100*mean(rob$has_sorteio, na.rm=TRUE), 1), "%\n")
cat("    Theft:", round(100*mean(theft$has_sorteio, na.rm=TRUE), 1), "%\n")

## ---- Save ----
rob_results <- list(balance_dow=bal_dow, balance_month=bal_month,
                    perm_p=perm_p, observed_diff=observed_diff)
saveRDS(rob_results, "./data/robustness_results_v2.rds")
cat("\nRobustness complete.\n")
