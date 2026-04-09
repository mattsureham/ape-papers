library(data.table)

data_dir <- file.path(dirname(getwd()), "data")
files <- list.files(data_dir, pattern = "^sobcov.*\\.txt$", full.names = TRUE)

col_names <- c("year","state_fips","state_abbr","county_code","county_name",
               "crop_code","crop_name","plan_code","plan_abbr",
               "cov_category","delivery_type","coverage_level",
               "policies_sold","policies_earning","policies_indemnified",
               "units_earning","units_indemnified","quantity_type",
               "net_quantity","endorsed_companion_acres",
               "liability","total_premium","subsidy","state_private_subsidy",
               "additional_subsidy","efa_discount","indemnity","loss_ratio")

col_classes <- c("integer","character","character","character","character",
                 "character","character","character","character",
                 "character","character","numeric",
                 "integer","integer","integer",
                 "integer","integer","character",
                 "numeric","numeric",
                 "numeric","numeric","numeric","numeric",
                 "numeric","numeric","numeric","numeric")

major_crops <- c("0041","0081","0011","0021")
standard_levels <- c(0.50,0.55,0.60,0.65,0.70,0.75,0.80,0.85)

dt_list <- lapply(files, function(f) {
  tryCatch(fread(f, sep="|", header=FALSE, col.names=col_names,
                 colClasses=col_classes, strip.white=TRUE),
           error=function(e) NULL)
})
sob <- rbindlist(dt_list[!sapply(dt_list, is.null)], fill=TRUE)

d <- sob[crop_code %in% major_crops & grepl("A", cov_category) &
         coverage_level %in% standard_levels & year >= 2000 & year <= 2023]
d[, cov_pct := as.integer(coverage_level * 100)]

# 1. DIFFERENCE-IN-SHARES (simple, no polynomial)
agg <- d[, .(policies = sum(policies_earning, na.rm=TRUE)), by=.(year, cov_pct)]
agg[, total := sum(policies), by=year]
agg[, share := policies / total]

shares <- dcast(agg, year ~ cov_pct, value.var="share")
shares[, period := ifelse(year < 2014, "Pre", "Post")]

cat("=== SHARE AT 75% BY PERIOD ===\n")
cat("Pre-2014 mean share at 75%:", mean(shares[period=="Pre"]$`75`, na.rm=TRUE), "\n")
cat("Post-2014 mean share at 75%:", mean(shares[period=="Post"]$`75`, na.rm=TRUE), "\n")
cat("Difference:", mean(shares[period=="Post"]$`75`, na.rm=TRUE) - mean(shares[period=="Pre"]$`75`, na.rm=TRUE), "\n")

# t-test
tt <- t.test(shares[period=="Post"]$`75`, shares[period=="Pre"]$`75`)
cat("t-stat:", tt$statistic, "  p-value:", tt$p.value, "\n")

# 2. MISSING MASS: shares at 80% and 85%
cat("\n=== SHARES BY PERIOD (looking for missing mass at 80-85%) ===\n")
for (lev in c(65, 70, 75, 80, 85)) {
  col <- as.character(lev)
  pre_mean <- mean(shares[period=="Pre"][[col]], na.rm=TRUE)
  post_mean <- mean(shares[period=="Post"][[col]], na.rm=TRUE)
  cat(sprintf("  %d%%: Pre=%.4f  Post=%.4f  Diff=%+.4f\n", lev, pre_mean, post_mean, post_mean - pre_mean))
}

# 3. TRIPLE DIFFERENCE: share at 75% for corn/soy vs wheat/cotton
d[, crop_group := ifelse(crop_code %in% c("0041","0081"), "CornSoy", "WheatCotton")]
agg_crop <- d[, .(policies = sum(policies_earning, na.rm=TRUE)), by=.(year, cov_pct, crop_group)]
agg_crop[, total := sum(policies), by=.(year, crop_group)]
agg_crop[, share := policies / total]

triple <- agg_crop[cov_pct == 75, .(year, crop_group, share)]
triple[, period := ifelse(year < 2014, "Pre", "Post")]
triple_wide <- dcast(triple, year + period ~ crop_group, value.var="share")
triple_wide[, diff := CornSoy - WheatCotton]

cat("\n=== TRIPLE DIFFERENCE (Corn/Soy vs Wheat/Cotton share at 75%) ===\n")
cat("Pre diff:", mean(triple_wide[period=="Pre"]$diff, na.rm=TRUE), "\n")
cat("Post diff:", mean(triple_wide[period=="Post"]$diff, na.rm=TRUE), "\n")
cat("DDD:", mean(triple_wide[period=="Post"]$diff, na.rm=TRUE) - mean(triple_wide[period=="Pre"]$diff, na.rm=TRUE), "\n")

# 4. ELASTICITY WITH STATUTORY RATES
# Enterprise unit statutory rates (dominant unit type)
# 75% -> 77% subsidy -> farmer share = 23%
# 80% -> 68% subsidy -> farmer share = 32%
statutory_75 <- 0.23
statutory_80 <- 0.32
delta_log_statutory <- log(statutory_80) - log(statutory_75)
b_post <- 0.150
elasticity_statutory <- b_post / delta_log_statutory
cat("\n=== STATUTORY RATE ELASTICITY ===\n")
cat("Enterprise farmer share at 75%:", statutory_75, "\n")
cat("Enterprise farmer share at 80%:", statutory_80, "\n")
cat("Delta log:", round(delta_log_statutory, 4), "\n")
cat("Elasticity (using post-2014 b):", round(elasticity_statutory, 3), "\n")

# 5. FISCAL IMPACT
# Excess policies at 75% post-2014
post_75 <- d[year >= 2014 & cov_pct == 75, sum(policies_earning, na.rm=TRUE)]
# Counterfactual: if share at 75% stayed at pre-2014 level
pre_share_75 <- mean(shares[period=="Pre"]$`75`, na.rm=TRUE)
post_total <- d[year >= 2014, sum(policies_earning, na.rm=TRUE)]
counterfactual_75 <- post_total * pre_share_75
excess_policies <- post_75 - counterfactual_75

# Average subsidy per policy at 75% post-2014
avg_subsidy_75 <- d[year >= 2014 & cov_pct == 75, sum(subsidy, na.rm=TRUE)] / post_75
# Average subsidy at 70% (where they'd likely come from)
avg_subsidy_70 <- d[year >= 2014 & cov_pct == 70, sum(subsidy, na.rm=TRUE)] / d[year >= 2014 & cov_pct == 70, sum(policies_earning, na.rm=TRUE)]

fiscal_cost <- excess_policies * (avg_subsidy_75 - avg_subsidy_70)
cat("\n=== FISCAL IMPACT ===\n")
cat("Excess policies at 75% post-2014:", round(excess_policies), "\n")
cat("Avg subsidy per policy at 75%: $", round(avg_subsidy_75), "\n")
cat("Avg subsidy per policy at 70%: $", round(avg_subsidy_70), "\n")
cat("Incremental subsidy per excess policy: $", round(avg_subsidy_75 - avg_subsidy_70), "\n")
cat("Total fiscal cost of bunching: $", round(fiscal_cost / 1e6), "M\n")
