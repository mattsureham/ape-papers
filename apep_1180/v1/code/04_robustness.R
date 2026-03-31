# 04_robustness.R — Robustness checks for apep_1180
# Korea Mandatory English Disclosure paper

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

weekly  <- fread(file.path(data_dir, "weekly_panel.csv"))
monthly <- fread(file.path(data_dir, "monthly_panel.csv"))
firms   <- fread(file.path(data_dir, "firm_characteristics.csv"))

# ============================================================
# R1. Placebo test: fake treatment date (Jan 2023)
# ============================================================
cat("R1. Placebo test: fake treatment at Jan 2023\n")
cat("=" ,rep("=", 50), "\n")

weekly[, post_placebo := as.integer(week >= "2023-W01")]
# Use only pre-treatment data (before actual treatment Jan 2024)
weekly_pre <- weekly[week < "2024-W01"]

placebo_amihud <- feols(log_amihud_w ~ post_placebo:phase1 | ticker + week,
                        data = weekly_pre, cluster = ~ticker)
summary(placebo_amihud)

placebo_turnover <- feols(log_turnover_w ~ post_placebo:phase1 | ticker + week,
                          data = weekly_pre, cluster = ~ticker)
summary(placebo_turnover)

# ============================================================
# R2. Alternative clustering: sector level
# ============================================================
cat("\nR2. Sector-level clustering\n")
cat("=" ,rep("=", 50), "\n")

did_sector_cluster <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                            data = weekly, cluster = ~sector)
summary(did_sector_cluster)

# ============================================================
# R3. Monthly frequency (instead of weekly)
# ============================================================
cat("\nR3. Monthly frequency\n")
cat("=" ,rep("=", 50), "\n")

did_monthly_amihud <- feols(log_amihud_m ~ post:phase1 | ticker + yearmonth,
                            data = monthly, cluster = ~ticker)
summary(did_monthly_amihud)

did_monthly_turnover <- feols(log_turnover_m ~ post:phase1 | ticker + yearmonth,
                              data = monthly, cluster = ~ticker)
summary(did_monthly_turnover)

# ============================================================
# R4. Excluding top 10 firms (Samsung, SK Hynix, etc.)
# ============================================================
cat("\nR4. Excluding top 10 firms by market cap\n")
cat("=" ,rep("=", 50), "\n")

top10 <- firms[order(-market_cap)][1:10]$ticker
weekly_ex_top10 <- weekly[!ticker %in% top10]

did_ex_top10 <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                      data = weekly_ex_top10, cluster = ~ticker)
summary(did_ex_top10)

# ============================================================
# R5. Donut: exclude 4 weeks around treatment date
# ============================================================
cat("\nR5. Donut: exclude 4 weeks around treatment\n")
cat("=" ,rep("=", 50), "\n")

weekly_donut <- weekly[abs(week_num) > 4 | is.na(week_num)]

did_donut <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                   data = weekly_donut, cluster = ~ticker)
summary(did_donut)

# ============================================================
# R6. Winsorized outcomes (1st/99th percentile)
# ============================================================
cat("\nR6. Winsorized outcomes\n")
cat("=" ,rep("=", 50), "\n")

winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  return(x)
}

weekly[, log_amihud_w_wins := winsorize(log_amihud_w)]
weekly[, log_turnover_w_wins := winsorize(log_turnover_w)]

did_wins_amihud <- feols(log_amihud_w_wins ~ post:phase1 | ticker + week,
                         data = weekly, cluster = ~ticker)
summary(did_wins_amihud)

# ============================================================
# R7. Balanced panel (firms present in all weeks)
# ============================================================
cat("\nR7. Balanced panel\n")
cat("=" ,rep("=", 50), "\n")

n_weeks_total <- uniqueN(weekly$week)
firm_week_counts <- weekly[, .N, by = ticker]
balanced_firms <- firm_week_counts[N >= n_weeks_total * 0.9]$ticker  # >= 90% of weeks

did_balanced <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                      data = weekly[ticker %in% balanced_firms], cluster = ~ticker)
summary(did_balanced)
cat("Balanced panel firms:", length(balanced_firms), "\n")

# ============================================================
# Save robustness results
# ============================================================
robustness <- list(
  placebo_amihud = placebo_amihud,
  placebo_turnover = placebo_turnover,
  did_sector_cluster = did_sector_cluster,
  did_monthly_amihud = did_monthly_amihud,
  did_monthly_turnover = did_monthly_turnover,
  did_ex_top10 = did_ex_top10,
  did_donut = did_donut,
  did_wins_amihud = did_wins_amihud,
  did_balanced = did_balanced
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
