## 02_clean_data.R — Clean and prepare hospital bed panel
library(data.table)
library(tidyverse)

cat("=== Cleaning Hospital Bed Panel ===\n")

panel <- fread("data/hospital_bed_panel.csv")
cat(sprintf("Raw panel: %d obs\n", nrow(panel)))

## Remove duplicate reports per provider-year (keep most authoritative)
panel[, status_priority := fcase(
  rpt_stus_cd == "A", 1L, rpt_stus_cd == "S", 2L,
  rpt_stus_cd == "R", 3L, rpt_stus_cd == "F", 4L, default = 5L)]
setorder(panel, prvdr_num, year, status_priority)
panel_clean <- panel[, .SD[1], by = .(prvdr_num, year)]

cat(sprintf("After dedup: %d obs, %d unique hospitals\n",
            nrow(panel_clean), uniqueN(panel_clean$prvdr_num)))

## Analysis variables
panel_clean[, `:=`(
  beds_int = as.integer(beds),
  is_round_5 = (beds %% 5 == 0),
  is_round_10 = (beds %% 10 == 0)
)]

## Summary
cat(sprintf("Mean beds: %.1f, Median: %d, SD: %.1f\n",
            mean(panel_clean$beds), as.integer(median(panel_clean$beds)),
            sd(panel_clean$beds)))
cat(sprintf("CAH: %d (%.1f%%)\n", sum(panel_clean$is_cah), 100*mean(panel_clean$is_cah)))

## Distribution at thresholds by CAH status
cat("\n=== 25-bed threshold (CAH vs non-CAH) ===\n")
for (b in 23:27) {
  n_cah <- sum(panel_clean$beds == b & panel_clean$is_cah)
  n_non <- sum(panel_clean$beds == b & !panel_clean$is_cah)
  cat(sprintf("  %d beds: CAH=%4d, non-CAH=%4d\n", b, n_cah, n_non))
}

## Build pooled bed distribution
bed_dist <- panel_clean[beds >= 1 & beds <= 500, .N, by = beds][order(beds)]
setnames(bed_dist, "N", "count")

fwrite(panel_clean, "data/hospital_panel_clean.csv")
fwrite(bed_dist, "data/bed_distribution_pooled.csv")
cat("\nDone.\n")
