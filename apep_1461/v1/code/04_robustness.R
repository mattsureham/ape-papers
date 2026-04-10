source("code/00_packages.R")

enoe <- readRDS("data/enoe_analysis.rds")
results <- readRDS("data/results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

cat("--- 1. Exclude COVID quarters (2020Q1-2021Q2) ---\n")
enoe_nocovid <- enoe[!(year == 2020 | (year == 2021 & quarter <= 2))]
r1 <- feols(hrsocup ~ formal + treat_post | state + period,
            data = enoe_nocovid, cluster = ~state)
summary(r1)

cat("\n--- 2. State-specific linear trends ---\n")
enoe[, time_trend := year + (quarter - 1) / 4 - 2019]
r2 <- feols(hrsocup ~ formal + treat_post | state + period + state[time_trend],
            data = enoe, cluster = ~state)
summary(r2)

cat("\n--- 3. Placebo test: 2021 pseudo-reform ---\n")
enoe_placebo <- enoe[post == 0]
enoe_placebo[, pseudo_post := as.integer(year >= 2021)]
enoe_placebo[, pseudo_treat := formal * pseudo_post]
r3 <- feols(hrsocup ~ formal + pseudo_treat | state + period,
            data = enoe_placebo, cluster = ~state)
cat("Placebo (2021 pseudo-reform on pre-period data):\n")
summary(r3)

cat("\n--- 4. Age subgroups ---\n")
r4_young <- feols(hrsocup ~ formal + treat_post | state + period,
                  data = enoe[eda >= 15 & eda <= 30], cluster = ~state)
r4_old <- feols(hrsocup ~ formal + treat_post | state + period,
                data = enoe[eda > 30 & eda <= 65], cluster = ~state)
cat("Young (15-30):\n")
summary(r4_young)
cat("Older (31-65):\n")
summary(r4_old)

cat("\n--- 5. Male vs Female ---\n")
r5_male <- feols(hrsocup ~ formal + treat_post | state + period,
                 data = enoe[sex == 1], cluster = ~state)
r5_female <- feols(hrsocup ~ formal + treat_post | state + period,
                   data = enoe[sex == 2], cluster = ~state)
cat("Male:\n")
summary(r5_male)
cat("Female:\n")
summary(r5_female)

cat("\n--- 6. Formality transition (alternative measure) ---\n")
if ("seg_soc" %in% names(enoe)) {
  enoe[, formal_strict := as.integer(tip_con %in% c(2))]
  enoe[, treat_post_strict := formal_strict * post]
  r6 <- feols(hrsocup ~ formal_strict + treat_post_strict | state + period,
              data = enoe, cluster = ~state)
  cat("Strict formality (social security only):\n")
  summary(r6)
}

robustness <- list(
  no_covid = r1,
  state_trends = r2,
  placebo_2021 = r3,
  young = r4_young,
  older = r4_old,
  male = r5_male,
  female = r5_female,
  strict_formal = if (exists("r6")) r6 else NULL
)

saveRDS(robustness, "data/robustness.rds")
cat("\nRobustness results saved to data/robustness.rds\n")
