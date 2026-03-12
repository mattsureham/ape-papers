## 04_robustness.R — Robustness checks
## apep_0608: Japan Women's Participation Disclosure RDD

source("00_packages.R")

data_dir <- "../data"
df_primary <- readRDS(file.path(data_dir, "analysis_primary.rds"))
df_extended <- readRDS(file.path(data_dir, "analysis_extended.rds"))

cat("=== ROBUSTNESS CHECKS ===\n")

## ===========================================================================
## 1. PLACEBO CUTOFFS
## ===========================================================================

cat("\n--- Placebo cutoffs ---\n")

# Test whether outcome jumps at non-policy thresholds
# Placebo 1: 100-employee boundary (no policy change)
# Use firms in 10-100 vs 101-300
df_placebo_100 <- df_extended %>%
  filter(size_cat %in% c("10-100", "101-300")) %>%
  mutate(above_100 = as.integer(size_midpoint >= 101))

p100_wage <- feols(wage_gap ~ above_100 | industry_clean + prefecture,
                   data = df_placebo_100, vcov = "HC1")
p100_mgr <- feols(fem_manager ~ above_100 | industry_clean + prefecture,
                  data = df_placebo_100, vcov = "HC1")

cat("Placebo at 100:\n")
cat("  Wage gap:", round(coef(p100_wage)["above_100"], 2),
    "(SE=", round(se(p100_wage)["above_100"], 2),
    ", p=", format.pval(fixest::pvalue(p100_wage)["above_100"], 3), ")\n")
cat("  Fem manager:", round(coef(p100_mgr)["above_100"], 2),
    "(SE=", round(se(p100_mgr)["above_100"], 2),
    ", p=", format.pval(fixest::pvalue(p100_mgr)["above_100"], 3), ")\n")

# Placebo 2: 500-employee boundary (no policy change there)
# Use firms in 301-500 vs 501-1000
df_placebo_500 <- df_extended %>%
  filter(size_cat %in% c("301-500", "501-1000")) %>%
  mutate(above_500 = as.integer(size_midpoint >= 501))

p500_wage <- feols(wage_gap ~ above_500 | industry_clean + prefecture,
                   data = df_placebo_500, vcov = "HC1")
p500_mgr <- feols(fem_manager ~ above_500 | industry_clean + prefecture,
                  data = df_placebo_500, vcov = "HC1")

cat("\nPlacebo at 500:\n")
cat("  Wage gap:", round(coef(p500_wage)["above_500"], 2),
    "(SE=", round(se(p500_wage)["above_500"], 2),
    ", p=", format.pval(fixest::pvalue(p500_wage)["above_500"], 3), ")\n")
cat("  Fem manager:", round(coef(p500_mgr)["above_500"], 2),
    "(SE=", round(se(p500_mgr)["above_500"], 2),
    ", p=", format.pval(fixest::pvalue(p500_mgr)["above_500"], 3), ")\n")

## ===========================================================================
## 2. BANDWIDTH SENSITIVITY
## ===========================================================================

cat("\n--- Bandwidth sensitivity ---\n")

# Narrow bandwidth: primary only (101-300 vs 301-500)
bw_narrow <- feols(fem_manager ~ above_301 | industry_clean + prefecture,
                   data = df_primary, vcov = "HC1")

# Medium bandwidth: 10-100 through 501-1000
df_medium <- df_extended %>%
  filter(size_cat %in% c("10-100", "101-300", "301-500", "501-1000")) %>%
  mutate(
    size_below = ifelse(above_301 == 0, size_centered, 0),
    size_above = ifelse(above_301 == 1, size_centered, 0)
  )
bw_medium <- feols(fem_manager ~ above_301 + size_below + size_above |
                     industry_clean + prefecture,
                   data = df_medium, vcov = "HC1")

# Wide bandwidth: all bins
df_wide <- df_extended %>%
  mutate(
    size_below = ifelse(above_301 == 0, size_centered, 0),
    size_above = ifelse(above_301 == 1, size_centered, 0)
  )
bw_wide <- feols(fem_manager ~ above_301 + size_below + size_above |
                   industry_clean + prefecture,
                 data = df_wide, vcov = "HC1")

cat("Bandwidth sensitivity (female manager share):\n")
cat("  Narrow (adj bins only):", round(coef(bw_narrow)["above_301"], 2),
    "(SE=", round(se(bw_narrow)["above_301"], 2), ")\n")
cat("  Medium (2 bins each):", round(coef(bw_medium)["above_301"], 2),
    "(SE=", round(se(bw_medium)["above_301"], 2), ")\n")
cat("  Wide (all bins):", round(coef(bw_wide)["above_301"], 2),
    "(SE=", round(se(bw_wide)["above_301"], 2), ")\n")

# Same for wage gap
bw_narrow_w <- feols(wage_gap ~ above_301 | industry_clean + prefecture,
                     data = df_primary, vcov = "HC1")
bw_medium_w <- feols(wage_gap ~ above_301 + size_below + size_above |
                       industry_clean + prefecture,
                     data = df_medium, vcov = "HC1")
bw_wide_w <- feols(wage_gap ~ above_301 + size_below + size_above |
                     industry_clean + prefecture,
                   data = df_wide, vcov = "HC1")

cat("\nBandwidth sensitivity (wage gap):\n")
cat("  Narrow:", round(coef(bw_narrow_w)["above_301"], 2),
    "(SE=", round(se(bw_narrow_w)["above_301"], 2), ")\n")
cat("  Medium:", round(coef(bw_medium_w)["above_301"], 2),
    "(SE=", round(se(bw_medium_w)["above_301"], 2), ")\n")
cat("  Wide:", round(coef(bw_wide_w)["above_301"], 2),
    "(SE=", round(se(bw_wide_w)["above_301"], 2), ")\n")

## ===========================================================================
## 3. INDUSTRY HETEROGENEITY
## ===========================================================================

cat("\n--- Industry heterogeneity ---\n")

# Top 5 industries by sample size
top_ind <- df_primary %>%
  count(industry_clean) %>%
  arrange(desc(n)) %>%
  head(5) %>%
  pull(industry_clean)

for (ind in top_ind) {
  subdf <- df_primary %>% filter(industry_clean == ind)
  n_above <- sum(subdf$above_301 == 1)
  n_below <- sum(subdf$above_301 == 0)

  if (sum(!is.na(subdf$fem_manager)) > 50) {
    m <- feols(fem_manager ~ above_301 | prefecture, data = subdf, vcov = "HC1")
    cat(sprintf("  %-30s (n=%d/%d): %5.2f (SE=%5.2f, p=%s)\n",
                ind, n_below, n_above,
                coef(m)["above_301"], se(m)["above_301"],
                format.pval(fixest::pvalue(m)["above_301"], 3)))
  }
}

## ===========================================================================
## 4. DENSITY TEST (binned running variable)
## ===========================================================================

cat("\n--- Density check ---\n")

# With binned data, formal McCrary test is not possible
# Instead, compare observed bin sizes to expected (Zipf/power law)
bin_counts <- df_extended %>%
  filter(!is.na(size_cat)) %>%
  count(size_cat, size_midpoint) %>%
  arrange(size_midpoint)

cat("Bin sizes:\n")
print(bin_counts)

# Check ratio of adjacent bins
cat("\nRatio 101-300 / 301-500:",
    round(bin_counts$n[bin_counts$size_cat == "101-300"] /
            bin_counts$n[bin_counts$size_cat == "301-500"], 2), "\n")
cat("Ratio 301-500 / 501-1000:",
    round(bin_counts$n[bin_counts$size_cat == "301-500"] /
            bin_counts$n[bin_counts$size_cat == "501-1000"], 2), "\n")

# If firms bunch below 301, we'd expect excess mass in 101-300
# Ratio ~3.3:1 for 101-300/301-500 vs ~1.4:1 for 301-500/501-1000
# But the bins differ in width (200 vs 200 vs 500), so density comparison:
cat("\nDensity (firms per unit width):\n")
cat("  101-300: ", round(bin_counts$n[3] / 200, 1), " per employee\n")
cat("  301-500: ", round(bin_counts$n[4] / 200, 1), " per employee\n")
cat("  501-1000:", round(bin_counts$n[5] / 500, 1), " per employee\n")

## ===========================================================================
## 5. LISTED vs NON-LISTED firms
## ===========================================================================

cat("\n--- Listed vs non-listed ---\n")

# Listed firms face market pressure for disclosure regardless of size
listed <- df_primary %>% filter(is_listed == 1)
unlisted <- df_primary %>% filter(is_listed == 0)

cat("Listed firms (n=", nrow(listed), "):\n")
if (sum(!is.na(listed$fem_manager)) > 30) {
  m_listed <- feols(fem_manager ~ above_301, data = listed, vcov = "HC1")
  cat("  Fem manager:", round(coef(m_listed)["above_301"], 2),
      "(SE=", round(se(m_listed)["above_301"], 2), ")\n")
}

cat("Non-listed firms (n=", nrow(unlisted), "):\n")
m_unlisted <- feols(fem_manager ~ above_301 | industry_clean + prefecture,
                    data = unlisted, vcov = "HC1")
cat("  Fem manager:", round(coef(m_unlisted)["above_301"], 2),
    "(SE=", round(se(m_unlisted)["above_301"], 2), ")\n")

## ===========================================================================
## 6. SAVE ROBUSTNESS RESULTS
## ===========================================================================

save(
  p100_wage, p100_mgr, p500_wage, p500_mgr,
  bw_narrow, bw_medium, bw_wide,
  bw_narrow_w, bw_medium_w, bw_wide_w,
  bin_counts,
  file = file.path(data_dir, "robustness_results.RData")
)
cat("\nRobustness results saved.\n")
