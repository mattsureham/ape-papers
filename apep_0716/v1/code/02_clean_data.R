# 02_clean_data.R — Clean and prepare data for bunching analysis
# apep_0716: Nonprofit Disclosure Cost Bunching

source("00_packages.R")

data_dir <- "../data"
eo_bmf <- readRDS(file.path(data_dir, "eo_bmf_combined.rds"))

cat(sprintf("Loaded %d organizations\n", nrow(eo_bmf)))

# ----- Convert integer64 columns to numeric -----
# data.table reads large integers as integer64 (bit64 package)
# which fails silently in comparisons with R numeric values
if (!requireNamespace("bit64", quietly = TRUE)) install.packages("bit64")
library(bit64)  # Must be loaded for as.character.integer64 method dispatch

int64_cols <- c("REVENUE_AMT", "ASSET_AMT", "INCOME_AMT")
for (col in int64_cols) {
  if (col %in% names(eo_bmf) && inherits(eo_bmf[[col]], "integer64")) {
    eo_bmf[, (col) := as.numeric(as.character(get(col)))]
  }
}
cat("Converted integer64 columns to numeric.\n")
cat(sprintf("REVENUE_AMT class: %s, range: %s to %s\n",
            class(eo_bmf$REVENUE_AMT),
            min(eo_bmf$REVENUE_AMT, na.rm = TRUE),
            max(eo_bmf$REVENUE_AMT, na.rm = TRUE)))

# ----- Clean and filter -----

# Keep organizations with positive revenue (drop NA)
df <- eo_bmf[!is.na(REVENUE_AMT) & REVENUE_AMT > 0]
cat(sprintf("After filtering to positive revenue: %d\n", nrow(df)))

# Create analysis variables
df[, `:=`(
  revenue = REVENUE_AMT,
  assets = ASSET_AMT,
  state = STATE,
  ntee = NTEE_CD,
  ntee_major = substr(NTEE_CD, 1, 1),  # First letter = major category
  filing_req = FILING_REQ_CD
)]

# Create NTEE major category labels
ntee_labels <- c(
  "A" = "Arts/Culture", "B" = "Education", "C" = "Environment",
  "D" = "Animal", "E" = "Health", "F" = "Mental Health",
  "G" = "Disease/Disorder", "H" = "Medical Research",
  "I" = "Crime/Legal", "J" = "Employment", "K" = "Food/Agriculture",
  "L" = "Housing", "M" = "Public Safety", "N" = "Recreation",
  "O" = "Youth Development", "P" = "Human Services",
  "Q" = "International", "R" = "Civil Rights", "S" = "Community",
  "T" = "Philanthropy", "U" = "Science", "V" = "Social Science",
  "W" = "Public/Society", "X" = "Religion", "Y" = "Mutual/Member",
  "Z" = "Unknown"
)
df[, ntee_label := ntee_labels[ntee_major]]
df[is.na(ntee_label), ntee_label := "Other"]

# ----- Create binned revenue for bunching analysis -----

# Main analysis: $1K bins around $200K threshold
# Window: $100K to $300K for polynomial fitting
df_main <- df[revenue >= 100000 & revenue <= 300000]
df_main[, rev_bin_1k := floor(revenue / 1000) * 1000]

# Create bin counts
bins_main <- df_main[, .(count = .N), by = rev_bin_1k]
bins_main <- bins_main[order(rev_bin_1k)]
bins_main[, bin_center := rev_bin_1k + 500]
bins_main[, bin_id := (rev_bin_1k - 100000) / 1000]  # 0-indexed

cat(sprintf("\nMain analysis window ($100K-$300K): %d organizations in %d bins\n",
            sum(bins_main$count), nrow(bins_main)))

# Placebo analysis: $1K bins around $50K threshold
# Window: $20K to $80K
df_placebo <- df[revenue >= 20000 & revenue <= 80000]
df_placebo[, rev_bin_1k := floor(revenue / 1000) * 1000]

bins_placebo <- df_placebo[, .(count = .N), by = rev_bin_1k]
bins_placebo <- bins_placebo[order(rev_bin_1k)]
bins_placebo[, bin_center := rev_bin_1k + 500]
bins_placebo[, bin_id := (rev_bin_1k - 20000) / 1000]

cat(sprintf("Placebo analysis window ($20K-$80K): %d organizations in %d bins\n",
            sum(bins_placebo$count), nrow(bins_placebo)))

# ----- Print key revenue distribution stats -----
cat("\n--- Revenue distribution around $200K ($5K bins) ---\n")
for (lower in seq(175000, 225000, by = 5000)) {
  n <- sum(df$revenue >= lower & df$revenue < (lower + 5000))
  cat(sprintf("  $%dK-$%dK: %d\n", lower/1000, (lower+5000)/1000, n))
}

cat("\n--- Revenue distribution around $50K ($2K bins) ---\n")
for (lower in seq(40000, 60000, by = 2000)) {
  n <- sum(df$revenue >= lower & df$revenue < (lower + 2000))
  cat(sprintf("  $%dK-$%dK: %d\n", lower/1000, (lower+2000)/1000, n))
}

# ----- Heterogeneity variables -----
# Organization type (subsection code)
df[, org_type := ifelse(ntee_major %in% c("T", "B"), "Foundation/Education",
                 ifelse(ntee_major %in% c("E", "F", "G", "H"), "Health",
                 ifelse(ntee_major %in% c("P", "O", "J", "K", "L"), "Human Services",
                 ifelse(ntee_major %in% c("X"), "Religious",
                 "Other"))))]

# Asset size categories
df[, asset_cat := ifelse(assets < 100000, "Small Assets (<$100K)",
                  ifelse(assets < 500000, "Medium Assets ($100K-$500K)",
                  "Large Assets (>$500K)"))]

# ----- Save cleaned data -----
saveRDS(df, file.path(data_dir, "eo_cleaned.rds"))
saveRDS(bins_main, file.path(data_dir, "bins_main_200k.rds"))
saveRDS(bins_placebo, file.path(data_dir, "bins_placebo_50k.rds"))
saveRDS(df_main, file.path(data_dir, "df_main_window.rds"))

cat("\nCleaned data saved.\n")
