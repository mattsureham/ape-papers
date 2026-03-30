## 02_clean_data.R — Extract bed counts from multi-year HCRIS and build panel
## HCRIS Form 2552-10: Worksheet S-3, Part I, Line 14, Col 2 = Total beds

source("00_packages.R")

data_dir <- "../data"

## -----------------------------------------------------------------------
## 1. Read all FY RPT files and stack
## -----------------------------------------------------------------------
cat("Reading HCRIS RPT files...\n")

rpt_files <- list.files(data_dir, pattern = "fy\\d{4}_rpt\\.csv", full.names = TRUE)
rpt_list <- list()

for (f in sort(rpt_files)) {
  yr <- as.integer(sub(".*fy(\\d{4})_rpt.*", "\\1", f))
  dt <- fread(f, header = FALSE, select = c(1, 3, 5, 6, 7),
              colClasses = list(character = c(3, 6, 7)))
  setnames(dt, c("rpt_rec_num", "prvdr_num", "rpt_stus_cd", "fy_bgn_dt", "fy_end_dt"))
  dt[, source_fy := yr]
  rpt_list[[as.character(yr)]] <- dt
  cat(sprintf("  FY%d: %d reports\n", yr, nrow(dt)))
}

rpt <- rbindlist(rpt_list)

# Parse dates and extract fiscal year from end date
rpt[, fy_bgn_dt := as.Date(fy_bgn_dt, format = "%m/%d/%Y")]
rpt[, fy_end_dt := as.Date(fy_end_dt, format = "%m/%d/%Y")]
rpt[, fy := as.integer(format(fy_end_dt, "%Y"))]

# Keep only filed or settled reports
rpt <- rpt[rpt_stus_cd %in% c(1, 2, 4)]

cat(sprintf("\nTotal RPT records: %d\n", nrow(rpt)))
cat(sprintf("Unique providers: %d\n", uniqueN(rpt$prvdr_num)))
cat(sprintf("FY range: %d - %d\n", min(rpt$fy, na.rm = TRUE), max(rpt$fy, na.rm = TRUE)))

## -----------------------------------------------------------------------
## 2. Identify CAH hospitals
## CCN digits 3-6: 1300-1399 = Critical Access Hospital
## -----------------------------------------------------------------------

rpt[, facility_code := as.integer(substr(prvdr_num, 3, 6))]
rpt[, is_cah := facility_code >= 1300 & facility_code <= 1399]
rpt[, state_code := substr(prvdr_num, 1, 2)]

## -----------------------------------------------------------------------
## 3. Extract bed counts from all NMRC files
## Worksheet S-3, Part I (S300001), Line 14 (01400), Column 2 (00200)
## -----------------------------------------------------------------------
cat("\nExtracting bed counts from NMRC files...\n")

nmrc_files <- list.files(data_dir, pattern = "fy\\d{4}_nmrc\\.csv", full.names = TRUE)
beds_list <- list()

for (f in sort(nmrc_files)) {
  yr <- as.integer(sub(".*fy(\\d{4})_nmrc.*", "\\1", f))
  cat(sprintf("  Extracting beds from FY%d...\n", yr))

  # Use grep to extract only bed count rows (S300001, line 01400, col 00200)
  dt <- fread(
    cmd = sprintf("grep ',S300001,01400,00200,' '%s'", f),
    header = FALSE,
    col.names = c("rpt_rec_num", "wksht_cd", "line_num", "clmn_num", "itm_val_num")
  )

  if (nrow(dt) > 0) {
    beds_list[[as.character(yr)]] <- dt[, .(rpt_rec_num,
                                             total_beds = as.integer(round(itm_val_num)))]
    cat(sprintf("    Found %d bed records\n", nrow(dt)))
  }
}

beds <- rbindlist(beds_list)
cat(sprintf("\nTotal bed count records: %d\n", nrow(beds)))

## -----------------------------------------------------------------------
## 4. Merge RPT + beds
## -----------------------------------------------------------------------

panel <- merge(rpt, beds, by = "rpt_rec_num", all.x = FALSE)
panel <- panel[!is.na(total_beds) & total_beds > 0]

# For providers with multiple reports per FY, keep the latest
panel <- panel[order(prvdr_num, fy, -rpt_rec_num)]
panel <- panel[, .SD[1], by = .(prvdr_num, fy)]

cat(sprintf("\nMerged panel: %d provider-year records\n", nrow(panel)))

## -----------------------------------------------------------------------
## 5. Exclude CAH, restrict sample
## -----------------------------------------------------------------------

panel_noncah <- panel[is_cah == FALSE]
panel_noncah <- panel_noncah[fy >= 2012 & fy <= 2023]

cat(sprintf("Non-CAH panel (2012-2023): %d records\n", nrow(panel_noncah)))
cat(sprintf("  Providers: %d\n", uniqueN(panel_noncah$prvdr_num)))

# Year-by-year counts
cat("\n=== Hospitals per year (non-CAH) ===\n")
print(panel_noncah[, .N, by = fy][order(fy)])

## -----------------------------------------------------------------------
## 6. Period indicators
## -----------------------------------------------------------------------

panel_noncah[, period := fifelse(fy <= 2017, "pre_bba", "post_bba")]
panel_noncah[, reh_era := fy >= 2023]

## -----------------------------------------------------------------------
## 7. Bed distribution around 50 beds
## -----------------------------------------------------------------------

cat("\n=== Bed distribution 40-60 beds (all years pooled) ===\n")
near50 <- panel_noncah[total_beds >= 40 & total_beds <= 60]
tab50 <- near50[, .N, by = total_beds][order(total_beds)]
for (i in 1:nrow(tab50)) {
  cat(sprintf("  Beds=%d: N=%d\n", tab50$total_beds[i], tab50$N[i]))
}

# Key ratios
cat("\n=== Bunching by period ===\n")
for (p in c("pre_bba", "post_bba")) {
  sub <- panel_noncah[period == p & total_beds >= 40 & total_beds <= 60]
  n_at_50 <- nrow(sub[total_beds == 50])
  n_at_49 <- nrow(sub[total_beds == 49])
  n_at_51 <- nrow(sub[total_beds == 51])
  n_49_50 <- n_at_49 + n_at_50
  avg_51_55 <- nrow(sub[total_beds >= 51 & total_beds <= 55]) / 5

  cat(sprintf("\n  %s:\n", toupper(p)))
  cat(sprintf("    N at 49: %d\n", n_at_49))
  cat(sprintf("    N at 50: %d\n", n_at_50))
  cat(sprintf("    N at 51: %d\n", n_at_51))
  cat(sprintf("    Drop ratio (50->51): %.1f:1\n",
              ifelse(n_at_51 > 0, n_at_50 / n_at_51, Inf)))
  cat(sprintf("    Bunching ratio (49-50 vs avg 51-55): %.1f:1\n",
              ifelse(avg_51_55 > 0, n_49_50 / avg_51_55, Inf)))
}

## -----------------------------------------------------------------------
## 8. Save analysis datasets
## -----------------------------------------------------------------------

fwrite(panel_noncah, file.path(data_dir, "analysis_panel.csv"))

# Save bed distribution for tables
bed_dist_year <- panel_noncah[total_beds >= 1 & total_beds <= 200,
                               .N, by = .(total_beds, fy, period)]
fwrite(bed_dist_year, file.path(data_dir, "bed_distribution.csv"))

cat(sprintf("\nSaved analysis_panel.csv: %d rows\n", nrow(panel_noncah)))
cat(sprintf("Saved bed_distribution.csv: %d rows\n", nrow(bed_dist_year)))

cat("\n02_clean_data.R complete.\n")
