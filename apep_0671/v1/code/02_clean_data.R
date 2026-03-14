# =============================================================================
# 02_clean_data.R — Clean data and construct analysis variables
# =============================================================================

source("00_packages.R")

main <- fread("../data/main_panel_1920_1930.csv")
placebo <- fread("../data/placebo_panel_1910_1920.csv")
exposure <- fread("../data/county_exposure_1920.csv")

cat(sprintf("Main panel: %s obs\n", format(nrow(main), big.mark=",")))
cat(sprintf("Placebo panel: %s obs\n", format(nrow(placebo), big.mark=",")))
cat(sprintf("Exposure data: %d counties\n", nrow(exposure)))

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Merge exposure to main panel (1920 county location)
# ─────────────────────────────────────────────────────────────────────────────
main <- merge(main, exposure[, .(statefip, countyicp, restricted_share, fb_share, total_pop)],
              by.x = c("statefip_1920", "countyicp_1920"),
              by.y = c("statefip", "countyicp"),
              all.x = FALSE)

cat(sprintf("After exposure merge: %s obs (%d counties)\n",
            format(nrow(main), big.mark=","),
            uniqueN(main[, .(statefip_1920, countyicp_1920)])))

# For placebo: match on 1920 county (the _1920 columns in 1910-1920 panel)
placebo <- merge(placebo, exposure[, .(statefip, countyicp, restricted_share, fb_share, total_pop)],
                 by.x = c("statefip_1920", "countyicp_1920"),
                 by.y = c("statefip", "countyicp"),
                 all.x = FALSE)

cat(sprintf("Placebo after exposure merge: %s obs\n", format(nrow(placebo), big.mark=",")))

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Construct outcome variables — Main panel
# ─────────────────────────────────────────────────────────────────────────────

main[, `:=`(
  d_occscore = occscore_1930 - occscore_1920,
  upgraded = as.integer(occscore_1930 - occscore_1920 > 5),
  downgraded = as.integer(occscore_1920 - occscore_1930 > 5),
  moved = as.integer(statefip_1920 != statefip_1930 | countyicp_1920 != countyicp_1930),
  left_farm = as.integer(farm_1920 == 2 & farm_1930 != 2),
  switched_industry = as.integer(ind1950_1920 != ind1950_1930),
  skill_group = fcase(
    occscore_1920 <= 15, "low_skill",
    occscore_1920 <= 25, "mid_skill",
    default = "high_skill"
  ),
  white = as.integer(race_1920 == 1),
  literate = as.integer(lit_1920 == 4)
)]

main[, high_exposure := as.integer(restricted_share > median(restricted_share, na.rm = TRUE))]
main[, county_id := paste(statefip_1920, countyicp_1920, sep = "_")]

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Construct outcome variables — Placebo panel
# ─────────────────────────────────────────────────────────────────────────────

placebo[, `:=`(
  d_occscore = occscore_1920 - occscore_1910,
  upgraded = as.integer(occscore_1920 - occscore_1910 > 5),
  downgraded = as.integer(occscore_1910 - occscore_1920 > 5),
  moved = as.integer(statefip_1910 != statefip_1920 | countyicp_1910 != countyicp_1920),
  skill_group = fcase(
    occscore_1910 <= 15, "low_skill",
    occscore_1910 <= 25, "mid_skill",
    default = "high_skill"
  ),
  white = as.integer(race_1910 == 1),
  literate = as.integer(lit_1910 == 4)
)]

placebo[, high_exposure := as.integer(restricted_share > median(restricted_share, na.rm = TRUE))]
placebo[, county_id := paste(statefip_1920, countyicp_1920, sep = "_")]

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Summary statistics
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MAIN PANEL SUMMARY ===\n")
cat(sprintf("N: %s\n", format(nrow(main), big.mark=",")))
cat(sprintf("Counties: %d\n", uniqueN(main$county_id)))
cat(sprintf("Mean OCCSCORE 1920: %.2f (SD: %.2f)\n", mean(main$occscore_1920), sd(main$occscore_1920)))
cat(sprintf("Mean OCCSCORE 1930: %.2f (SD: %.2f)\n", mean(main$occscore_1930), sd(main$occscore_1930)))
cat(sprintf("Mean OCCSCORE change: %.3f (SD: %.3f)\n", mean(main$d_occscore), sd(main$d_occscore)))
cat(sprintf("Upgrade rate: %.1f%%\n", 100 * mean(main$upgraded)))
cat(sprintf("Downgrade rate: %.1f%%\n", 100 * mean(main$downgraded)))
cat(sprintf("Mobility rate: %.1f%%\n", 100 * mean(main$moved)))
cat(sprintf("Mean restricted share: %.3f (SD: %.3f)\n",
            mean(main$restricted_share), sd(main$restricted_share)))
cat(sprintf("White: %.1f%%, Literate: %.1f%%\n",
            100 * mean(main$white), 100 * mean(main$literate)))

cat("\nBy skill group:\n")
print(main[, .(N = .N,
               mean_d_occscore = mean(d_occscore),
               upgrade_rate = mean(upgraded),
               mean_exposure = mean(restricted_share)),
           by = skill_group])

cat("\n=== PLACEBO PANEL SUMMARY ===\n")
cat(sprintf("N: %s\n", format(nrow(placebo), big.mark=",")))
cat(sprintf("Mean OCCSCORE change (1910-1920): %.3f\n", mean(placebo$d_occscore)))

fwrite(main, "../data/analysis_main.csv")
fwrite(placebo, "../data/analysis_placebo.csv")

cat("\nCleaned data saved.\n")
