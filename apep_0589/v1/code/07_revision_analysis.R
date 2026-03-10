## 07_revision_analysis.R — Stage C Revision Analyses
## Addresses referee concerns: first stage, EU-only sample, non-overlapping outcome

library(data.table)
library(rdrobust)

# Load analysis data
df <- fread("data/analysis.csv")

cat("=== REVISION ANALYSES ===\n")
cat("Total regions:", nrow(df), "\n")

# ---------------------------------------------------------------
# 1. EU-ONLY SAMPLE: Exclude candidate/EFTA countries
# ---------------------------------------------------------------
candidate_countries <- c("TR", "ME", "MK", "AL", "RS", "IS", "NO", "CH", "LI")
df_eu <- df[!country %in% candidate_countries]
cat("\nEU-only sample:", nrow(df_eu), "regions\n")
cat("Excluded countries:", paste(candidate_countries[candidate_countries %in% df$country], collapse=", "), "\n")
cat("Regions excluded:", nrow(df) - nrow(df_eu), "\n")

# Main RDD on EU-only sample
rdd_eu <- rdrobust(y = df_eu$delta_gdp, x = df_eu$rv_centered, kernel = "triangular")
cat("\n--- EU-Only RDD (GDP Change) ---\n")
cat("Coefficient:", round(rdd_eu$coef[1], 3), "\n")
cat("SE (robust):", round(rdd_eu$se[3], 3), "\n")
cat("p-value (bc):", round(rdd_eu$pv[3], 3), "\n")
cat("Bandwidth:", round(rdd_eu$bws[1,1], 2), "\n")
cat("N (estimation):", sum(rdd_eu$N), "\n")

# ---------------------------------------------------------------
# 2. FIRST STAGE: RDD on ERDF payment change at cutoff
# ---------------------------------------------------------------
# Use delta_erdf_pc as outcome
df_fs <- df_eu[!is.na(delta_erdf_pc)]
cat("\n--- First Stage: ERDF Payment Change ---\n")
cat("Regions with ERDF data:", nrow(df_fs), "\n")

if (nrow(df_fs) > 30) {
  rdd_fs <- tryCatch({
    rdrobust(y = df_fs$delta_erdf_pc, x = df_fs$rv_centered, kernel = "triangular")
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rdd_fs)) {
    cat("Coefficient:", round(rdd_fs$coef[1], 3), "\n")
    cat("SE (robust):", round(rdd_fs$se[3], 3), "\n")
    cat("p-value (bc):", round(rdd_fs$pv[3], 3), "\n")
    cat("Bandwidth:", round(rdd_fs$bws[1,1], 2), "\n")
    cat("N (estimation):", sum(rdd_fs$N), "\n")
  }
} else {
  cat("Too few observations for ERDF first stage\n")
  rdd_fs <- NULL
}

# ---------------------------------------------------------------
# 3. NON-OVERLAPPING OUTCOME: Post-2014 GDP level
# ---------------------------------------------------------------
# Use gdp_pct_post (2014-2020 avg) as outcome, controlling for pre via RV
# This avoids the 2008-2010 overlap concern
cat("\n--- Non-Overlapping: Post-2014 GDP Level ---\n")
rdd_post <- rdrobust(y = df_eu$gdp_pct_post, x = df_eu$rv_centered, kernel = "triangular")
cat("Coefficient:", round(rdd_post$coef[1], 3), "\n")
cat("SE (robust):", round(rdd_post$se[3], 3), "\n")
cat("p-value (bc):", round(rdd_post$pv[3], 3), "\n")
cat("Bandwidth:", round(rdd_post$bws[1,1], 2), "\n")

# Pre-2008 placebo: Use gdp_pct_2007 as outcome (year before any overlap)
if ("gdp_pct_2007" %in% names(df_eu)) {
  df_placebo <- df_eu[!is.na(gdp_pct_2007)]
  cat("\n--- Pre-2008 Placebo: 2007 GDP Level ---\n")
  rdd_placebo <- tryCatch({
    rdrobust(y = df_placebo$gdp_pct_2007, x = df_placebo$rv_centered, kernel = "triangular")
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })
  if (!is.null(rdd_placebo)) {
    cat("Coefficient:", round(rdd_placebo$coef[1], 3), "\n")
    cat("SE (robust):", round(rdd_placebo$se[3], 3), "\n")
    cat("p-value (bc):", round(rdd_placebo$pv[3], 3), "\n")
  }
}

# ---------------------------------------------------------------
# 4. ALTERNATIVE OUTCOME: Exclude 2008-2010 from pre-period
# Use only 2007 and 2011-2013 average for "pre", 2014-2020 for "post"
# ---------------------------------------------------------------
cat("\n--- Alternative: Pre = 2007+2011-2013, Post = 2014-2020 ---\n")
# Load annual panel for this
panel <- fread("data/annual_panel.csv")
if ("gdp_pct" %in% names(panel)) {
  pre_alt <- panel[year %in% c(2007, 2011, 2012, 2013), .(gdp_pre_alt = mean(gdp_pct, na.rm=TRUE)), by=geo]
  post_alt <- panel[year %in% 2014:2020, .(gdp_post_alt = mean(gdp_pct, na.rm=TRUE)), by=geo]
  alt_df <- merge(pre_alt, post_alt, by="geo")
  alt_df[, delta_gdp_alt := gdp_post_alt - gdp_pre_alt]
  alt_df <- merge(alt_df, df_eu[, .(geo, rv_centered, country)], by="geo")

  rdd_alt <- tryCatch({
    rdrobust(y = alt_df$delta_gdp_alt, x = alt_df$rv_centered, kernel = "triangular")
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })
  if (!is.null(rdd_alt)) {
    cat("Coefficient:", round(rdd_alt$coef[1], 3), "\n")
    cat("SE (robust):", round(rdd_alt$se[3], 3), "\n")
    cat("p-value (bc):", round(rdd_alt$pv[3], 3), "\n")
    cat("Bandwidth:", round(rdd_alt$bws[1,1], 2), "\n")
  }
}

# ---------------------------------------------------------------
# 5. Save revision results
# ---------------------------------------------------------------
results <- data.table(
  specification = c("Main (EU-only)", "First stage (ERDF)", "Post-2014 level", "Non-overlapping change"),
  coef = c(
    round(rdd_eu$coef[1], 3),
    if (!is.null(rdd_fs)) round(rdd_fs$coef[1], 3) else NA,
    round(rdd_post$coef[1], 3),
    if (exists("rdd_alt") && !is.null(rdd_alt)) round(rdd_alt$coef[1], 3) else NA
  ),
  se_robust = c(
    round(rdd_eu$se[3], 3),
    if (!is.null(rdd_fs)) round(rdd_fs$se[3], 3) else NA,
    round(rdd_post$se[3], 3),
    if (exists("rdd_alt") && !is.null(rdd_alt)) round(rdd_alt$se[3], 3) else NA
  ),
  p_value = c(
    round(rdd_eu$pv[3], 3),
    if (!is.null(rdd_fs)) round(rdd_fs$pv[3], 3) else NA,
    round(rdd_post$pv[3], 3),
    if (exists("rdd_alt") && !is.null(rdd_alt)) round(rdd_alt$pv[3], 3) else NA
  ),
  bw = c(
    round(rdd_eu$bws[1,1], 2),
    if (!is.null(rdd_fs)) round(rdd_fs$bws[1,1], 2) else NA,
    round(rdd_post$bws[1,1], 2),
    if (exists("rdd_alt") && !is.null(rdd_alt)) round(rdd_alt$bws[1,1], 2) else NA
  )
)

fwrite(results, "data/revision_results.csv")
cat("\n=== REVISION RESULTS SAVED ===\n")
print(results)
