# 04_robustness.R — Robustness checks

library(tidyverse)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")
panel$province[panel$province == "Fryslân"] <- "Friesland"

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. Pre-COVID subsample (exclude March 2020+)
# ============================================================
cat("--- R1: Pre-COVID subsample ---\n")
panel_precovid <- panel %>% filter(date < as.Date("2020-03-01"))

r1 <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel_precovid, cluster = "region"
)
summary(r1)

# ============================================================
# 2. Province × year-month trends
# ============================================================
cat("\n--- R2: Province-specific trends ---\n")
r2 <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor + province^ym,
  data = panel, cluster = "region"
)
summary(r2)

# ============================================================
# 3. Alternative treatment: closest provinces only
# ============================================================
cat("\n--- R3: Treatment = Zuid-Holland only ---\n")
panel$treat_zh <- panel$province == "Zuid-Holland"
panel$treat_zh_freeze <- as.integer(panel$treat_zh) * as.integer(panel$freeze_period)
panel$treat_zh_postrelax <- as.integer(panel$treat_zh) * as.integer(panel$post_relax)

r3 <- feols(
  new_construction ~ treat_zh_freeze + treat_zh_postrelax | region + ym_factor,
  data = panel, cluster = "region"
)
summary(r3)

# ============================================================
# 4. Placebo test: 2017 fake freeze
# ============================================================
cat("\n--- R4: Placebo test (fake freeze July 2017) ---\n")
panel$placebo_freeze <- panel$date >= as.Date("2017-07-01") & panel$date < as.Date("2017-12-01")
panel$placebo_post <- panel$date >= as.Date("2017-12-01") & panel$date < as.Date("2019-07-01")
panel$treat_placebo_freeze <- as.integer(panel$high_pfas) * as.integer(panel$placebo_freeze)
panel$treat_placebo_post <- as.integer(panel$high_pfas) * as.integer(panel$placebo_post)

r4 <- feols(
  new_construction ~ treat_placebo_freeze + treat_placebo_post | region + ym_factor,
  data = panel %>% filter(date < as.Date("2019-07-01")),
  cluster = "region"
)
summary(r4)

# ============================================================
# 5. Winsorized outcome (top 1%)
# ============================================================
cat("\n--- R5: Winsorized outcome (top 1%) ---\n")
p99 <- quantile(panel$new_construction, 0.99, na.rm = TRUE)
panel$new_win <- pmin(panel$new_construction, p99)

r5 <- feols(
  new_win ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel, cluster = "region"
)
summary(r5)

# ============================================================
# 6. Annual aggregation (reduce noise)
# ============================================================
cat("\n--- R6: Annual aggregation ---\n")
annual <- panel %>%
  group_by(region, year, high_pfas, province) %>%
  summarise(
    new_construction = sum(new_construction, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    post = year >= 2020,  # Full years after freeze
    treat_post = as.integer(high_pfas) * as.integer(post)
  )

r6 <- feols(
  new_construction ~ treat_post | region + year,
  data = annual, cluster = "region"
)
summary(r6)

# ============================================================
# 7. Excluding nitrogen-affected municipalities
# ============================================================
cat("\n--- R7: Exclude Natura 2000 buffer (nitrogen crisis control) ---\n")
# Gelderland (Veluwe = major Natura 2000 area) as nitrogen-exposed
# Drop Gelderland to avoid nitrogen crisis confound
panel_no_gel <- panel %>% filter(province != "Gelderland")

r7 <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel_no_gel, cluster = "region"
)
summary(r7)

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  r1_precovid = r1,
  r2_prov_trends = r2,
  r3_zh_only = r3,
  r4_placebo = r4,
  r5_winsorized = r5,
  r6_annual = r6,
  r7_no_gelderland = r7
)
saveRDS(rob_results, "data/robustness_results.rds")

cat("\n=== Robustness summary ===\n")
cat("R1 (pre-COVID): freeze=", coef(r1)["treat_freeze"],
    "postrelax=", coef(r1)["treat_postrelax"], "\n")
cat("R2 (prov trends): freeze=", coef(r2)["treat_freeze"],
    "postrelax=", coef(r2)["treat_postrelax"], "\n")
cat("R3 (ZH only): freeze=", coef(r3)["treat_zh_freeze"],
    "postrelax=", coef(r3)["treat_zh_postrelax"], "\n")
cat("R4 (placebo 2017): freeze=", coef(r4)["treat_placebo_freeze"],
    "post=", coef(r4)["treat_placebo_post"], "\n")
cat("R5 (winsorized): freeze=", coef(r5)["treat_freeze"],
    "postrelax=", coef(r5)["treat_postrelax"], "\n")
cat("R6 (annual): post=", coef(r6)["treat_post"], "\n")
cat("R7 (no Gelderland): freeze=", coef(r7)["treat_freeze"],
    "postrelax=", coef(r7)["treat_postrelax"], "\n")
