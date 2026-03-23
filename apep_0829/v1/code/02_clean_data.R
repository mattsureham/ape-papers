## 02_clean_data.R — Construct analysis variables
## APEP Paper apep_0829: The Goldilocks Examiner

source("00_packages.R")

df <- as.data.table(readRDS("../data/analysis_raw.rds"))
cat(sprintf("Loaded %s patents\n", format(nrow(df), big.mark = ",")))

## ---- Step 1: Construct examiner leave-one-out (LOO) measures ----
## For each patent i assigned to examiner e in Art Unit × Year cell j,
## compute the LOO mean of num_claims (excluding patent i)
cat("\nComputing LOO examiner averages...\n")

## Examiner × art_unit_year cell totals
df[, cell_n := .N, by = .(examiner_id, art_unit_year)]
df[, cell_sum_claims := sum(num_claims), by = .(examiner_id, art_unit_year)]

## LOO examiner average claims (excluding own patent)
df[, loo_examiner_claims := (cell_sum_claims - num_claims) / pmax(cell_n - 1, 1)]

## ---- Step 2: Filter to cells with sufficient observations ----
## Need at least 10 patents per examiner × art_unit_year cell for LOO to be meaningful
df_filtered <- df[cell_n >= 10]
cat(sprintf("After cell_n >= 10 filter: %s patents\n",
            format(nrow(df_filtered), big.mark = ",")))

## Also check how many examiner cells we have
n_cells <- uniqueN(df_filtered[, .(examiner_id, art_unit_year)])
cat(sprintf("Examiner × Art Unit × Year cells: %s\n", format(n_cells, big.mark = ",")))

## ---- Step 3: Winsorize extreme values ----
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmax(pmin(x, q[2]), q[1])
}

df_filtered[, `:=`(
  num_claims_w = winsorize(num_claims),
  loo_examiner_claims_w = winsorize(loo_examiner_claims),
  total_forward_cites_5yr_w = winsorize(total_forward_cites_5yr),
  other_forward_cites_5yr_w = winsorize(other_forward_cites_5yr),
  self_forward_cites_5yr_w = winsorize(self_forward_cites_5yr),
  ## Log citations (adding 1 for zeros)
  ln_total_cites = log(1 + total_forward_cites_5yr),
  ln_other_cites = log(1 + other_forward_cites_5yr),
  ln_self_cites = log(1 + self_forward_cites_5yr),
  ## Binary: any forward citation
  has_citation = as.integer(total_forward_cites_5yr > 0),
  has_other_citation = as.integer(other_forward_cites_5yr > 0),
  ## Log claims
  ln_claims = log(num_claims)
)]

## ---- Step 4: Summary statistics ----
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Patents: %s\n", format(nrow(df_filtered), big.mark = ",")))
cat(sprintf("Unique examiners: %s\n",
            format(uniqueN(df_filtered$examiner_id), big.mark = ",")))
cat(sprintf("Unique Art Unit × Year cells: %s\n",
            format(uniqueN(df_filtered$art_unit_year), big.mark = ",")))

cat("\nNumber of claims at grant:\n")
cat(sprintf("  Mean: %.1f  SD: %.1f  P10: %.0f  P90: %.0f\n",
            mean(df_filtered$num_claims), sd(df_filtered$num_claims),
            quantile(df_filtered$num_claims, 0.10),
            quantile(df_filtered$num_claims, 0.90)))

cat("\nLOO examiner claims:\n")
cat(sprintf("  Mean: %.1f  SD: %.1f  P10: %.1f  P90: %.1f\n",
            mean(df_filtered$loo_examiner_claims), sd(df_filtered$loo_examiner_claims),
            quantile(df_filtered$loo_examiner_claims, 0.10),
            quantile(df_filtered$loo_examiner_claims, 0.90)))

cat("\nForward citations (5-year, total):\n")
cat(sprintf("  Mean: %.1f  SD: %.1f  Median: %.0f  P90: %.0f\n",
            mean(df_filtered$total_forward_cites_5yr),
            sd(df_filtered$total_forward_cites_5yr),
            median(df_filtered$total_forward_cites_5yr),
            quantile(df_filtered$total_forward_cites_5yr, 0.90)))

cat("\nForward citations (5-year, other):\n")
cat(sprintf("  Mean: %.1f  SD: %.1f\n",
            mean(df_filtered$other_forward_cites_5yr),
            sd(df_filtered$other_forward_cites_5yr)))

## ---- Step 5: Save cleaned data ----
saveRDS(df_filtered, "../data/analysis_clean.rds")
cat("\nSaved data/analysis_clean.rds\n")
