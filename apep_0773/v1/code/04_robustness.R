# 04_robustness.R — apep_0773
source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# 1. Exclude early EA states
cat("=== Excluding early EA states ===\n")
late_ea <- panel[ea_end_month >= as.Date("2023-01-01")]
did_late <- feols(snap_rate_pct ~ integrated:post_unwinding | state + time_id,
                  data = late_ea, cluster = ~state)
cat("  Late EA only:\n")
print(coef(did_late))
cat("  SE:", sqrt(vcov(did_late)["integrated:post_unwinding", "integrated:post_unwinding"]), "\n")

# 2. Pre-2023 placebo
cat("\n=== Placebo: pre-2023 ===\n")
pre2023 <- panel[year <= 2022]
pre2023[, fake_post := as.integer(year >= 2022)]
did_placebo <- feols(snap_rate_pct ~ integrated:fake_post | state + time_id,
                     data = pre2023, cluster = ~state)
cat("  Placebo:\n")
print(coef(did_placebo))
cat("  SE:", sqrt(vcov(did_placebo)["integrated:fake_post", "integrated:fake_post"]), "\n")

# 3. Level outcome
cat("\n=== Level: SNAP HH ===\n")
did_level <- feols(snap_hh ~ integrated:post_unwinding + post_ea | state + time_id,
                   data = panel, cluster = ~state)
cat("  SNAP HH (level):\n")
print(summary(did_level))

saveRDS(list(late = did_late, placebo = did_placebo, level = did_level),
        file.path(data_dir, "robustness_results.rds"))

cat("=== Robustness complete ===\n")
