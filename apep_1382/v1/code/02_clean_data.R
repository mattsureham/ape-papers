#!/usr/bin/env Rscript
# Clean and construct analysis dataset

source("code/00_packages.R")

cat("Cleaning and preparing analysis data...\n")

# Load raw panel data
df_full <- fread("data/czech_registrations_panel.csv")

# ============================================================
# PART 1: Create long-form dataset for DID estimation
# ============================================================

# Create two rows per district-date (one for sole prop, one for LLC)
sole_prop_df <- df_full[, .(
  district = district,
  date = date,
  year = year,
  month = month,
  post = post_shock,
  entity = "sole_proprietor",
  registrations = sole_prop_reg
)]

llc_df <- df_full[, .(
  district = district,
  date = date,
  year = year,
  month = month,
  post = post_shock,
  entity = "llc",
  registrations = llc_reg
)]

df_long <- rbind(sole_prop_df, llc_df)
df_long[, treated_entity := entity == "sole_proprietor"]
df_long[, post_numeric := as.integer(post)]

# Aggregate to district-month level
df_long_agg <- df_long[, .(
  registrations = sum(registrations)
), by = .(district, date, year, month, entity, treated_entity, post, post_numeric)]

cat("✓ Constructed long-form dataset: ", nrow(df_long_agg), " rows\n", sep="")

# ============================================================
# PART 2: Create DDD dataset with sector variation
# ============================================================

# DDD requires sector × entity × time variation
# We'll use the full panel as-is for DDD estimation
df_ddd <- df_full[, .(
  year = year,
  month = month,
  date = date,
  district = district,
  sector = sector,
  cash_intensive = cash_intensive,
  post_shock = post_shock,
  period = period,
  registrations_sole = sole_prop_reg,
  registrations_llc = llc_reg
)]

df_ddd[, cash_int := as.integer(cash_intensive)]
df_ddd[, time_period := as.integer(post_shock)]

cat("✓ Constructed DDD dataset with sector variation: ", nrow(df_ddd), " rows\n", sep="")

# ============================================================
# PART 3: Summary statistics
# ============================================================

cat("\nSummary statistics:\n")
cat("  Total district-sector-month observations: ", nrow(df_ddd), "\n", sep="")
cat("  Total sole prop registrations: ", sum(df_ddd$registrations_sole), "\n", sep="")
cat("  Total LLC registrations: ", sum(df_ddd$registrations_llc), "\n", sep="")
cat("  Districts: ", n_distinct(df_ddd$district), "\n", sep="")
cat("  Date range: ", min(df_ddd$date), " to ", max(df_ddd$date), "\n", sep="")

# Pre-treatment summary
pre_sole <- df_ddd[period == "pre", mean(registrations_sole, na.rm=TRUE)]
post_sole <- df_ddd[period == "post", mean(registrations_sole, na.rm=TRUE)]
pre_llc <- df_ddd[period == "pre", mean(registrations_llc, na.rm=TRUE)]
post_llc <- df_ddd[period == "post", mean(registrations_llc, na.rm=TRUE)]

cat("\nBy period and entity:\n")
cat("  Sole prop (pre): ", round(pre_sole, 2), " per sector-district-month\n", sep="")
cat("  Sole prop (post): ", round(post_sole, 2), " per sector-district-month\n", sep="")
cat("  LLC (pre): ", round(pre_llc, 2), " per sector-district-month\n", sep="")
cat("  LLC (post): ", round(post_llc, 2), " per sector-district-month\n", sep="")

# Cash-intensive vs non-cash
cash_pre_sole <- df_ddd[period == "pre" & cash_intensive == TRUE, mean(registrations_sole)]
cash_post_sole <- df_ddd[period == "post" & cash_intensive == TRUE, mean(registrations_sole)]
noncash_pre_sole <- df_ddd[period == "pre" & cash_intensive == FALSE, mean(registrations_sole)]
noncash_post_sole <- df_ddd[period == "post" & cash_intensive == FALSE, mean(registrations_sole)]

cat("\nBy sector type:\n")
cat("  Cash-intensive sole prop (pre): ", round(cash_pre_sole, 2), "\n", sep="")
cat("  Cash-intensive sole prop (post): ", round(cash_post_sole, 2), " [Δ=", round(cash_post_sole - cash_pre_sole, 2), "]\n", sep="")
cat("  Non-cash sole prop (pre): ", round(noncash_pre_sole, 2), "\n", sep="")
cat("  Non-cash sole prop (post): ", round(noncash_post_sole, 2), " [Δ=", round(noncash_post_sole - noncash_pre_sole, 2), "]\n", sep="")

# ============================================================
# PART 4: Save cleaned datasets
# ============================================================

fwrite(df_ddd, "data/czech_analysis_ddd_sector.csv")
fwrite(df_long_agg, "data/czech_analysis_long.csv")

cat("\n✓ Cleaned datasets saved:\n")
cat("  - data/czech_analysis_ddd_sector.csv\n")
cat("  - data/czech_analysis_long.csv\n")

cat("\n✓ Data cleaning complete\n")
