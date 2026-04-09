# 02_clean_data.R — Construct analysis dataset from CQC ratings
source("00_packages.R")

# === 1. Load raw data ===
dt <- fread("../data/cqc_ratings_raw.csv")
cat(sprintf("Raw data: %d rows\n", nrow(dt)))

# Standardize column names
setnames(dt, c("Location ID", "Location Name", "Care Home?", "Location Post Code",
               "Location Local Authority", "Location Region", "Domain", "Latest Rating",
               "Publication Date", "Report Type", "Inherited Rating (Y/N)",
               "Location Primary Inspection Category", "Provider ID", "Brand Name"),
         c("location_id", "name", "care_home", "postcode", "local_authority",
           "region", "domain", "rating", "pub_date", "report_type", "inherited",
           "category", "provider_id", "brand_name"))

# === 2. Filter to care homes only ===
dt <- dt[care_home == "Y"]
cat(sprintf("Care homes only: %d rows\n", nrow(dt)))

# Filter to location-level reports (not provider-level)
dt <- dt[report_type == "Location"]
cat(sprintf("Location reports: %d rows\n", nrow(dt)))

# Exclude inherited ratings (these are carried forward, not from inspection)
dt <- dt[inherited != "Y" | is.na(inherited)]
cat(sprintf("Non-inherited: %d rows\n", nrow(dt)))

# === 3. Pivot to wide format (one row per location) ===
# Keep only the 5 key domains + Overall
domains <- c("Safe", "Effective", "Caring", "Responsive", "Well-led", "Overall")
dt <- dt[domain %in% domains]

# Encode ratings numerically
rating_map <- c("Outstanding" = 1, "Good" = 2, "Requires improvement" = 3, "Inadequate" = 4)
dt[, rating_num := rating_map[rating]]

# Pivot wide
dt_wide <- dcast(dt, location_id + name + postcode + local_authority + region +
                   category + provider_id + brand_name + pub_date ~ domain,
                 value.var = c("rating", "rating_num"), fun.aggregate = first)

# Clean column names
old_names <- names(dt_wide)
new_names <- gsub("rating_num_", "num_", old_names)
new_names <- gsub("rating_", "rat_", new_names)
new_names <- tolower(new_names)
new_names <- gsub(" ", "_", new_names)
new_names <- gsub("-", "", new_names)
setnames(dt_wide, new_names)

cat(sprintf("Wide format: %d locations\n", nrow(dt_wide)))

# === 4. Construct running variable ===
# Composite score = sum of 5 domain numeric ratings (range 5-20, higher = worse)
domain_num_cols <- c("num_safe", "num_effective", "num_caring", "num_responsive", "num_wellled")
dt_wide[, composite_score := rowSums(.SD, na.rm = FALSE), .SDcols = domain_num_cols]

# Overall rating
dt_wide[, overall_inadequate := as.integer(rat_overall == "Inadequate")]
dt_wide[, overall_ri := as.integer(rat_overall == "Requires improvement")]

# === 5. Determine the threshold empirically ===
cat("\n=== Composite Score vs Overall Rating ===\n")
threshold_table <- dt_wide[!is.na(composite_score) & !is.na(rat_overall),
                           .(n = .N, pct_inadequate = mean(overall_inadequate, na.rm = TRUE)),
                           by = composite_score][order(composite_score)]
print(threshold_table)

# The threshold should be visible as a sharp jump in P(Inadequate)
# Based on CQC rules: Inadequate overall requires Inadequate in at least one "key question"
# This means the running variable isn't purely the sum — it also depends on WHICH domains
# Let's look at a more refined running variable

cat("\n=== Alternative: Count of Inadequate domains ===\n")
dt_wide[, n_inadequate := rowSums(.SD == 4, na.rm = TRUE), .SDcols = domain_num_cols]
dt_wide[, n_ri := rowSums(.SD == 3, na.rm = TRUE), .SDcols = domain_num_cols]

inad_table <- dt_wide[!is.na(n_inadequate) & !is.na(rat_overall),
                      .(n = .N, pct_inadequate = mean(overall_inadequate, na.rm = TRUE)),
                      by = n_inadequate][order(n_inadequate)]
print(inad_table)

# === 6. Look at the actual CQC aggregation rule ===
# CQC rule: Overall = Inadequate if:
#   (a) Inadequate in EITHER Safe or Well-led, OR
#   (b) Inadequate in ANY 2+ domains
# This creates a sharp, deterministic rule.

# Better running variable: distance to the Inadequate threshold
# inadequate_safe_or_wellled = 1 if Safe=4 or WellLed=4
dt_wide[, inad_safe := as.integer(num_safe == 4)]
dt_wide[, inad_wellled := as.integer(num_wellled == 4)]
dt_wide[, inad_key_domain := as.integer(inad_safe == 1 | inad_wellled == 1)]
dt_wide[, n_inad_other := rowSums(.SD == 4, na.rm = TRUE),
        .SDcols = c("num_effective", "num_caring", "num_responsive")]

# The MECHANICAL rule for Overall = Inadequate:
# inadequate_trigger = inad_key_domain == 1 OR n_inadequate >= 2
dt_wide[, predicted_inadequate := as.integer(inad_key_domain == 1 | n_inadequate >= 2)]

cat("\n=== Predicted vs Actual Inadequate ===\n")
pred_table <- dt_wide[!is.na(predicted_inadequate) & !is.na(overall_inadequate),
                      .(n = .N), by = .(predicted_inadequate, overall_inadequate)]
print(pred_table)
# Should be high concordance — the rule is mechanical

# === 7. Construct the Sharp RDD running variable ===
# For the sharp RDD: the treatment is crossing the Inadequate threshold
# Running variable = worst domain rating among Safe and Well-led (the "key" domains)
# Or: min distance to any rule that triggers Inadequate

# Simplest approach: use the WORST rating among Safe and Well-led
# Since the rule is: if Safe=4 or WellLed=4 → likely Inadequate overall
dt_wide[, worst_key_domain := pmax(num_safe, num_wellled, na.rm = TRUE)]

cat("\n=== Worst Key Domain vs Overall Inadequate ===\n")
wkd_table <- dt_wide[!is.na(worst_key_domain) & !is.na(overall_inadequate),
                     .(n = .N, pct_inadequate = mean(overall_inadequate, na.rm = TRUE)),
                     by = worst_key_domain][order(worst_key_domain)]
print(wkd_table)

# === 8. Parse publication date ===
dt_wide[, pub_date_parsed := as.Date(pub_date, format = "%d/%m/%Y")]
dt_wide[, pub_year := year(pub_date_parsed)]
dt_wide[, pub_quarter := quarter(pub_date_parsed)]

# === 9. Create analysis variables ===
# Ownership type (chain vs independent)
dt_wide[, chain := as.integer(!is.na(brand_name) & brand_name != "")]

# === 10. Read the October 2024 snapshot for panel construction ===
if (file.exists("../data/cqc_ratings_2024_10.ods")) {
  cat("\nReading October 2024 snapshot...\n")
  dt_2024_raw <- as.data.table(readODS::read_ods("../data/cqc_ratings_2024_10.ods", sheet = "Locations"))
  cat(sprintf("2024 snapshot columns: %s\n", paste(names(dt_2024_raw), collapse = ", ")))

  # Use column positions since names may differ
  # Identify key columns by content
  id_col <- names(dt_2024_raw)[1]  # Location ID
  ch_col <- names(dt_2024_raw)[grep("[Cc]are [Hh]ome", names(dt_2024_raw))[1]]
  dom_col <- names(dt_2024_raw)[grep("[Dd]omain", names(dt_2024_raw))[1]]
  rat_col <- names(dt_2024_raw)[grep("[Rr]ating", names(dt_2024_raw))[1]]
  rt_col <- names(dt_2024_raw)[grep("[Rr]eport.?[Tt]ype", names(dt_2024_raw))[1]]

  if (!is.na(id_col) && !is.na(dom_col) && !is.na(rat_col)) {
    setnames(dt_2024_raw, c(id_col, dom_col, rat_col), c("location_id", "domain", "rating"))
    if (!is.na(ch_col)) setnames(dt_2024_raw, ch_col, "care_home")
    if (!is.na(rt_col)) setnames(dt_2024_raw, rt_col, "report_type")

    dt_2024 <- dt_2024_raw
    if ("care_home" %in% names(dt_2024)) dt_2024 <- dt_2024[care_home == "Y"]
    if ("report_type" %in% names(dt_2024)) dt_2024 <- dt_2024[report_type == "Location"]

    # Get overall ratings
    dt_2024_ov <- dt_2024[domain == "Overall"]
    locs_2024 <- unique(dt_2024_ov$location_id)
    locs_2026 <- unique(dt_wide$location_id)
    closed_locs <- setdiff(locs_2024, locs_2026)

    cat(sprintf("Locations in Oct 2024: %d\n", length(locs_2024)))
    cat(sprintf("Locations in Mar 2026: %d\n", length(locs_2026)))
    cat(sprintf("Disappeared (closures): %d\n", length(closed_locs)))

    dt_closed <- dt_2024_ov[location_id %in% closed_locs]
    cat("\nRatings of closed locations:\n")
    print(table(dt_closed$rating))

    # Build panel: 2024 locations with domain ratings + closure indicator
    dt_2024_ov[, closed_by_2026 := as.integer(location_id %in% closed_locs)]
    dt_2024_ov[, inadequate_2024 := as.integer(rating == "Inadequate")]

    # Domain ratings for running variable
    dt_dom24 <- dt_2024[domain %in% c("Safe", "Effective", "Caring", "Responsive", "Well-led")]
    dt_dom24[, rating_num := rating_map[rating]]
    dt_dom24_w <- dcast(dt_dom24, location_id ~ domain, value.var = "rating_num", fun.aggregate = first)

    dt_panel <- merge(dt_2024_ov[, .(location_id, rating_2024 = rating, closed_by_2026, inadequate_2024)],
                      dt_dom24_w, by = "location_id", all.x = TRUE)

    # Standardize domain column names
    for (cn in intersect(c("Safe", "Effective", "Caring", "Responsive", "Well-led"), names(dt_panel))) {
      setnames(dt_panel, cn, paste0("num_", tolower(gsub("-", "", cn)), "_24"))
    }
    num24_cols <- grep("^num_.*_24$", names(dt_panel), value = TRUE)
    if (length(num24_cols) >= 5) {
      dt_panel[, composite_2024 := rowSums(.SD, na.rm = FALSE), .SDcols = num24_cols]
      safe_col <- grep("safe", num24_cols, value = TRUE)
      wellled_col <- grep("wellled", num24_cols, value = TRUE)
      if (length(safe_col) && length(wellled_col)) {
        dt_panel[, worst_key_24 := pmax(get(safe_col), get(wellled_col), na.rm = TRUE)]
      }
      dt_panel[, n_inad_24 := rowSums(.SD == 4, na.rm = TRUE), .SDcols = num24_cols]
    }

    fwrite(dt_panel, "../data/cqc_panel_closures.csv")
    cat(sprintf("Panel dataset saved: %d locations\n", nrow(dt_panel)))
  } else {
    cat("Could not identify required columns in 2024 snapshot. Skipping panel.\n")
  }
}

# === 11. Save analysis dataset ===
fwrite(dt_wide, "../data/cqc_analysis.csv")
cat(sprintf("\nAnalysis dataset saved: %d locations\n", nrow(dt_wide)))

# Summary stats
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Unique locations: %d\n", uniqueN(dt_wide$location_id)))
cat(sprintf("Date range: %s to %s\n",
            min(dt_wide$pub_date_parsed, na.rm = TRUE),
            max(dt_wide$pub_date_parsed, na.rm = TRUE)))
cat(sprintf("Regions: %d\n", uniqueN(dt_wide$region)))
cat(sprintf("Local authorities: %d\n", uniqueN(dt_wide$local_authority)))
cat("\nOverall rating distribution:\n")
print(table(dt_wide$rat_overall, useNA = "ifany"))
cat("\nComposite score distribution:\n")
print(summary(dt_wide$composite_score))
