# =============================================================================
# 02_clean_data.R — Variable Construction & Panel Assembly
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. LOAD RAW DATA
# =============================================================================
cat("=== Loading cleaned Land Registry data ===\n")
lr <- fread(file.path(data_dir, "lr_clean.csv"))
lr[, date := as.Date(date)]
lr[, ym := as.Date(ym)]
cat("Loaded:", format(nrow(lr), big.mark = ","), "transactions\n")

# Ensure price is numeric
lr[, price := as.numeric(price)]

prs_share <- fread(file.path(data_dir, "prs_share_by_la.csv"))
cat("Loaded PRS share for", nrow(prs_share), "LAs\n")

# =============================================================================
# 2. CREATE LA-MONTH PANEL (main analysis dataset)
# =============================================================================
cat("\n=== Building LA × month panel ===\n")

# Count transactions by LA × month
panel <- lr[, .(
  n_transactions = .N,
  mean_price = mean(price, na.rm = TRUE),
  median_price = median(price, na.rm = TRUE),
  n_freehold = sum(duration == "F", na.rm = TRUE),
  n_leasehold = sum(duration == "L", na.rm = TRUE),
  n_detached = sum(prop_type == "D", na.rm = TRUE),
  n_semi = sum(prop_type == "S", na.rm = TRUE),
  n_terraced = sum(prop_type == "T", na.rm = TRUE),
  n_flat = sum(prop_type == "F", na.rm = TRUE),
  n_other = sum(prop_type == "O", na.rm = TRUE),
  n_new = sum(old_new == "Y", na.rm = TRUE),
  n_old = sum(old_new == "N", na.rm = TRUE),
  n_cat_a = sum(ppd_cat == "A", na.rm = TRUE),
  n_cat_b = sum(ppd_cat == "B", na.rm = TRUE)
), by = .(la = district_clean, country, ym)]

# Sort
setorder(panel, la, ym)

# Create time variables
panel[, year := year(ym)]
panel[, month := month(ym)]

# Treatment indicators
panel[, wales := as.integer(country == "Wales")]

# Post-treatment: December 2022 onwards (Act implemented 1 Dec 2022)
panel[, post := as.integer(ym >= as.Date("2022-12-01"))]

# Treatment × Post
panel[, treated := wales * post]

# Time period index (relative to December 2022)
panel[, t_rel := as.integer(difftime(ym, as.Date("2022-12-01"), units = "days") / 30.44)]
# More precise: months since Dec 2022
panel[, t_rel := (year - 2022) * 12 + (month - 12)]

# Log transactions (add 1 for zeros)
panel[, log_n := log(n_transactions + 1)]

# Composition shares
panel[, freehold_share := n_freehold / pmax(n_transactions, 1)]
panel[, flat_share := n_flat / pmax(n_transactions, 1)]
panel[, terraced_share := n_terraced / pmax(n_transactions, 1)]
panel[, cat_b_share := n_cat_b / pmax(n_transactions, 1)]
panel[, new_share := n_new / pmax(n_transactions, 1)]

# =============================================================================
# 3. MERGE PRS SHARE
# =============================================================================
cat("\n=== Merging PRS share data ===\n")

# Direct merge by LA name (both from Land Registry, so names match perfectly)
panel <- merge(panel, prs_share[, .(la, prs_share, total_tx, cat_b_tx)],
               by = "la", all.x = TRUE)

n_matched <- panel[!is.na(prs_share), uniqueN(la)]
n_total <- panel[, uniqueN(la)]
cat("PRS share matched:", n_matched, "of", n_total, "LAs\n")

# For any unmatched (shouldn't happen since same source), assign median
median_prs <- median(prs_share$prs_share, na.rm = TRUE)
panel[is.na(prs_share), prs_share := median_prs]

# Create PRS terciles for heterogeneity
panel[, prs_tercile := cut(prs_share,
                            breaks = quantile(prs_share, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                            labels = c("Low PRS", "Mid PRS", "High PRS"),
                            include.lowest = TRUE)]

# High PRS indicator (above median)
panel[, high_prs := as.integer(prs_share > median(prs_share, na.rm = TRUE))]

# =============================================================================
# 4. BORDER COUNTY CLASSIFICATION
# =============================================================================
cat("\n=== Classifying border counties ===\n")

# English LAs that border Wales
border_english_las <- c(
  "HEREFORDSHIRE, COUNTY OF", "HEREFORDSHIRE",
  "SHROPSHIRE", "CHESHIRE WEST AND CHESTER",
  "GLOUCESTERSHIRE", "FOREST OF DEAN",
  "SOUTH GLOUCESTERSHIRE", "WEST BERKSHIRE",
  "CHESHIRE EAST", "OSWESTRY", "SHREWSBURY AND ATCHAM",
  "NORTH SHROPSHIRE", "SOUTH SHROPSHIRE"
)

panel[, border := as.integer(la %in% toupper(border_english_las) | country == "Wales")]

n_border_eng <- panel[border == 1 & country == "England", uniqueN(la)]
cat("Border English LAs identified:", n_border_eng, "\n")

# If few border LAs found, expand to include counties near the border
if (n_border_eng < 5) {
  # Add more border-region LAs
  extra_border <- c(
    "MONMOUTHSHIRE", "TORFAEN", "BLAENAU GWENT",  # These are Welsh
    "SOUTH HEREFORDSHIRE", "NORTH HEREFORDSHIRE",
    "CHELTENHAM", "COTSWOLD", "TEWKESBURY", "STROUD"
  )
  panel[la %in% toupper(extra_border), border := 1L]
  n_border_eng <- panel[border == 1 & country == "England", uniqueN(la)]
  cat("After expansion, border English LAs:", n_border_eng, "\n")
}

# =============================================================================
# 5. SECOND-HOME LAS (for robustness)
# =============================================================================
# Welsh LAs with high second-home rates (targeted by Council Tax Premium)
second_home_las <- c("GWYNEDD", "CEREDIGION", "PEMBROKESHIRE",
                      "ISLE OF ANGLESEY", "CONWY")
panel[, second_home_la := as.integer(la %in% second_home_las)]

# =============================================================================
# 6. CREATE LA-LEVEL FIXED EFFECTS ID
# =============================================================================
panel[, la_id := as.integer(factor(la))]
panel[, ym_id := as.integer(factor(ym))]

# =============================================================================
# 7. SAVE ANALYSIS PANEL
# =============================================================================
cat("\n=== Saving analysis panel ===\n")

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("Panel dimensions:", nrow(panel), "rows ×", ncol(panel), "columns\n")
cat("LAs:", uniqueN(panel$la), "\n")
cat("  Wales:", uniqueN(panel[wales == 1, la]), "\n")
cat("  England:", uniqueN(panel[wales == 0, la]), "\n")
cat("Time periods:", uniqueN(panel$ym), "\n")
cat("Pre-treatment months:", uniqueN(panel[post == 0, ym]), "\n")
cat("Post-treatment months:", uniqueN(panel[post == 1, ym]), "\n")

# Summary statistics
cat("\n=== Summary Statistics ===\n")
sumstats <- panel[, .(
  mean_n = mean(n_transactions),
  sd_n = sd(n_transactions),
  mean_price = mean(mean_price, na.rm = TRUE),
  mean_freehold = mean(freehold_share, na.rm = TRUE),
  mean_flat = mean(flat_share, na.rm = TRUE),
  mean_cat_b = mean(cat_b_share, na.rm = TRUE),
  mean_prs = mean(prs_share, na.rm = TRUE),
  n_la = uniqueN(la),
  n_obs = .N
), by = .(country, period = fifelse(post == 1, "Post", "Pre"))]

print(sumstats)
fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))

cat("\n=== Data cleaning complete ===\n")
