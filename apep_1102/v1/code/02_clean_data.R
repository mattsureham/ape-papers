# =============================================================================
# 02_clean_data.R — Clean panel, construct variables, summary statistics
# =============================================================================

source("00_packages.R")

dt <- fread("../data/county_month_panel.csv")
cat("Loaded:", nrow(dt), "rows,", uniqueN(dt$county_id), "counties\n")

# ---------------------------------------------------------------------------
# Drop tiny counties (< 100 pills/month on average) to avoid noisy shares
# ---------------------------------------------------------------------------
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep_counties <- county_avg[avg_pills >= 100]$county_id
cat("Counties with >=100 avg pills/month:", length(keep_counties),
    "of", uniqueN(dt$county_id), "\n")

dt <- dt[county_id %in% keep_counties]
cat("After filter:", nrow(dt), "rows,", uniqueN(dt$county_id), "counties\n")

# ---------------------------------------------------------------------------
# Create state-level aggregates for descriptive plots
# ---------------------------------------------------------------------------
state_month <- dt[, .(
  total_oxy_pills = sum(total_oxy_pills),
  high_dose_pills = sum(high_dose_pills),
  hydro_pills     = sum(hydro_pills),
  avg_mg          = weighted.mean(avg_mg, total_oxy_pills),
  n_counties      = uniqueN(county_id)
), by = .(BUYER_STATE, year, month, ym_date, ym_int)]

state_month[, high_dose_share := high_dose_pills / total_oxy_pills]
state_month[, oxy_hydro_ratio := total_oxy_pills / (total_oxy_pills + hydro_pills)]

fwrite(state_month, "../data/state_month_panel.csv")

# ---------------------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Pre-treatment (before July 2011) by treatment group
pre_fl <- dt[fl == 1 & post == 0]
pre_ctrl <- dt[fl == 0 & post == 0]

summ <- data.table(
  Variable = c("High-dose share (>=30mg)", "Average mg per pill",
               "Oxy/(Oxy+Hydro) ratio", "Monthly oxy pills (thousands)",
               "Number of counties"),
  FL_Mean = c(mean(pre_fl$high_dose_share), mean(pre_fl$avg_mg),
              mean(pre_fl$oxy_hydro_ratio), mean(pre_fl$total_oxy_pills) / 1000,
              uniqueN(pre_fl$county_id)),
  FL_SD = c(sd(pre_fl$high_dose_share), sd(pre_fl$avg_mg),
            sd(pre_fl$oxy_hydro_ratio), sd(pre_fl$total_oxy_pills) / 1000, NA),
  Ctrl_Mean = c(mean(pre_ctrl$high_dose_share), mean(pre_ctrl$avg_mg),
                mean(pre_ctrl$oxy_hydro_ratio), mean(pre_ctrl$total_oxy_pills) / 1000,
                uniqueN(pre_ctrl$county_id)),
  Ctrl_SD = c(sd(pre_ctrl$high_dose_share), sd(pre_ctrl$avg_mg),
              sd(pre_ctrl$oxy_hydro_ratio), sd(pre_ctrl$total_oxy_pills) / 1000, NA)
)

print(summ, digits = 3)

# Save summary stats for the paper
fwrite(summ, "../data/summary_stats.csv")

# ---------------------------------------------------------------------------
# Pre-treatment SDs for SDE calculation
# ---------------------------------------------------------------------------
pre_all <- dt[post == 0]
sds <- list(
  sd_high_dose_share = sd(pre_all$high_dose_share),
  sd_avg_mg = sd(pre_all$avg_mg),
  sd_oxy_hydro_ratio = sd(pre_all$oxy_hydro_ratio)
)
cat("\nPre-treatment SDs:\n")
print(unlist(sds))

write_json(sds, "../data/pre_treatment_sds.json", auto_unbox = TRUE)

cat("\nCleaning complete.\n")
