## 01_fetch_data.R — Build hospital bed panel from HCRIS cost reports
## Data already downloaded via bash to /tmp/hcris/
## This script combines all years into a single panel

library(data.table)
library(tidyverse)

cat("=== Building Hospital Bed Panel from HCRIS ===\n")

## Read bed count files for all years
years <- 2010:2023
bed_list <- list()
rpt_list <- list()

for (yr in years) {
  bedfile <- sprintf("/tmp/hcris/beds_%d.csv", yr)
  rptfile <- sprintf("/tmp/hcris/rpt_%d.csv", yr)

  if (file.exists(bedfile)) {
    beds <- fread(bedfile, header = FALSE,
                  col.names = c("rpt_rec_num", "wksht_cd", "line_num", "clmn_num", "beds"))
    beds[, year := yr]
    bed_list[[as.character(yr)]] <- beds
  }

  if (file.exists(rptfile)) {
    ## RPT file columns (from HCRIS documentation):
    ## RPT_REC_NUM, PRVDR_CTRL_TYPE_CD, PRVDR_NUM, NPI,
    ## RPT_STUS_CD, FY_BGN_DT, FY_END_DT, PROC_DT,
    ## INITL_RPT_SW, LAST_RPT_SW, TRNSMTL_NUM, FI_NUM,
    ## ADR_VNDR_CD, FI_CREAT_DT, UTIL_CD, NPR_DT,
    ## SPEC_IND, FI_RCPT_DT
    rpt <- fread(rptfile, header = FALSE,
                 col.names = c("rpt_rec_num", "prvdr_ctrl_type", "prvdr_num", "npi",
                               "rpt_stus_cd", "fy_bgn_dt", "fy_end_dt", "proc_dt",
                               "initl_rpt_sw", "last_rpt_sw", "trnsmtl_num", "fi_num",
                               "adr_vndr_cd", "fi_creat_dt", "util_cd", "npr_dt",
                               "spec_ind", "fi_rcpt_dt"),
                 fill = TRUE)
    rpt[, year := yr]
    rpt_list[[as.character(yr)]] <- rpt
  }
}

beds_panel <- rbindlist(bed_list, fill = TRUE)
rpt_panel <- rbindlist(rpt_list, fill = TRUE)

cat(sprintf("Bed panel: %d obs across %d years\n", nrow(beds_panel), length(unique(beds_panel$year))))
cat(sprintf("Report panel: %d obs\n", nrow(rpt_panel)))

## Merge beds with provider info
panel <- merge(beds_panel[, .(rpt_rec_num, year, beds)],
               rpt_panel[, .(rpt_rec_num, year, prvdr_num, rpt_stus_cd,
                              fy_bgn_dt, fy_end_dt, prvdr_ctrl_type)],
               by = c("rpt_rec_num", "year"),
               all.x = TRUE)

cat(sprintf("Merged panel: %d obs\n", nrow(panel)))

## Clean
panel <- panel[!is.na(beds) & beds > 0 & beds < 2000]  # Remove zeros and outliers
panel[, beds := as.integer(beds)]

## Identify CAH hospitals (provider number format: 6-digit, CAH starts with specific codes)
## CAH Medicare provider numbers have form XX1300-XX1399
panel[, is_cah := grepl("13[0-9]{2}$", prvdr_num)]

## Extract state from provider number (first 2 digits)
panel[, state_code := substr(prvdr_num, 1, 2)]

## Urban vs rural: CAH is inherently rural, but we can also check provider number patterns
## General acute care hospitals: XX0001-XX0879 (some are urban, some rural)
## CAH: XX1300-XX1399

cat(sprintf("\nFinal panel: %d hospital-years\n", nrow(panel)))
cat(sprintf("Unique hospitals: %d\n", uniqueN(panel$prvdr_num)))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("CAH hospitals: %d (%.1f%%)\n",
            sum(panel$is_cah), 100 * mean(panel$is_cah)))

## Quick bed distribution check
cat("\n=== Bed Distribution at Key Thresholds (all years pooled) ===\n")
for (b in c(24, 25, 26, 49, 50, 51, 99, 100, 101)) {
  n <- sum(panel$beds == b)
  cat(sprintf("  %3d beds: %5d\n", b, n))
}

## Save
fwrite(panel, "data/hospital_bed_panel.csv")
cat("\nSaved to data/hospital_bed_panel.csv\n")

## Also save yearly distribution for diagnostics
yearly_dist <- panel[, .N, by = .(year, beds)][order(year, beds)]
fwrite(yearly_dist, "data/bed_distribution_by_year.csv")

cat("Done.\n")
