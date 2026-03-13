## 04_robustness.R — Robustness checks and placebos
library(data.table)
library(fixest)

panel <- fread("data/panel.csv.gz")

## ---- 1. Temporal placebo: fake reform at January 2013 ----
panel_placebo <- panel[ym < 201412]  # only pre-reform data
panel_placebo[, post_placebo := as.integer(ym >= 201301)]

m_placebo_time <- feols(ln_txn_200_350 ~ post_placebo:excess_mass | la_id + ym,
                        data = panel_placebo, cluster = ~la_id)

cat("\n=== TEMPORAL PLACEBO (Jan 2013) ===\n")
summary(m_placebo_time)

## ---- 2. Price band replication: £125k notch ----
## The £125k notch (1% → 3%) was also abolished in December 2014
## Constructing bunching at £125k and testing for same pattern validates the design

ppd <- fread("data/ppd_2010_2019.csv.gz")
ppd_125 <- ppd[price >= 100000 & price <= 200000]
pre_125 <- ppd_125[ym < 201412]

la_bunching_125 <- pre_125[, {
  below_far <- sum(price >= 100000 & price < 115000)
  below_notch <- sum(price >= 115000 & price < 125000)
  dead_zone <- sum(price >= 125000 & price < 135000)
  above_far <- sum(price >= 135000 & price <= 200000)

  counterfactual_per_10k <- (below_far + above_far) / (1.5 + 6.5)
  excess_mass_125 <- below_notch / counterfactual_per_10k - 1

  list(excess_mass_125 = excess_mass_125, n_pre_100_200 = .N)
}, by = district]

la_bunching_125 <- la_bunching_125[n_pre_100_200 >= 50]

la_month_125 <- ppd_125[, .(n_txn_100_200 = .N), by = .(district, ym, year, month)]

panel_125 <- merge(la_month_125, la_bunching_125[, .(district, excess_mass_125)],
                   by = "district", all.x = FALSE)
panel_125[, post := as.integer(ym >= 201412)]
panel_125[, la_id := as.integer(as.factor(district))]
panel_125[, ln_txn_100_200 := log(n_txn_100_200 + 1)]

m_125 <- feols(ln_txn_100_200 ~ post:excess_mass_125 | la_id + ym,
               data = panel_125, cluster = ~la_id)

cat("\n=== £125K NOTCH REPLICATION ===\n")
summary(m_125)
rm(ppd, ppd_125, pre_125)

## ---- 3. Exclude London ----
london_districts <- c("CITY OF LONDON", "BARKING AND DAGENHAM", "BARNET",
  "BEXLEY", "BRENT", "BROMLEY", "CAMDEN", "CROYDON", "EALING", "ENFIELD",
  "GREENWICH", "HACKNEY", "HAMMERSMITH AND FULHAM", "HARINGEY", "HARROW",
  "HAVERING", "HILLINGDON", "HOUNSLOW", "ISLINGTON", "KENSINGTON AND CHELSEA",
  "KINGSTON UPON THAMES", "LAMBETH", "LEWISHAM", "MERTON", "NEWHAM",
  "REDBRIDGE", "RICHMOND UPON THAMES", "SOUTHWARK", "SUTTON",
  "TOWER HAMLETS", "WALTHAM FOREST", "WANDSWORTH", "WESTMINSTER")

m_no_london <- feols(ln_txn_200_350 ~ post:excess_mass | la_id + ym,
                     data = panel[!district %in% london_districts], cluster = ~la_id)

cat("\n=== EXCLUDING LONDON ===\n")
summary(m_no_london)

## ---- 4. Alternative treatment measure: dead zone depth ----
m_dz <- feols(ln_txn_200_350 ~ post:dead_zone_depth | la_id + ym,
              data = panel, cluster = ~la_id)

cat("\n=== DEAD ZONE DEPTH AS TREATMENT ===\n")
summary(m_dz)

## ---- 5. LA-specific linear trends ----
## Address pre-trend concern by allowing each LA its own linear time trend
panel[, time_idx := as.integer(as.factor(ym))]

m_trends <- feols(ln_txn_200_350 ~ post:excess_mass | la_id[time_idx] + ym,
                  data = panel, cluster = ~la_id)

cat("\n=== WITH LA-SPECIFIC LINEAR TRENDS ===\n")
summary(m_trends)

## ---- 6. Quarterly panel ----
panel[, quarter := ceiling(month / 3)]
panel[, yq := year * 10L + quarter]

panel_q <- panel[, .(
  n_txn_200_350 = sum(n_txn_200_350),
  excess_mass = first(excess_mass),
  dead_zone_depth = first(dead_zone_depth),
  post = max(post)
), by = .(district, yq, la_id)]

panel_q[, ln_txn_200_350 := log(n_txn_200_350 + 1)]

m_quarterly <- feols(ln_txn_200_350 ~ post:excess_mass | la_id + yq,
                     data = panel_q, cluster = ~la_id)

cat("\n=== QUARTERLY PANEL ===\n")
summary(m_quarterly)

## ---- Save robustness results ----
robust <- list(
  placebo_time = list(coef = coef(m_placebo_time)[[1]], se = se(m_placebo_time)[[1]],
                      pval = pvalue(m_placebo_time)[[1]]),
  notch_125 = list(coef = coef(m_125)[[1]], se = se(m_125)[[1]],
                   pval = pvalue(m_125)[[1]]),
  no_london = list(coef = coef(m_no_london)[[1]], se = se(m_no_london)[[1]],
                   pval = pvalue(m_no_london)[[1]]),
  dead_zone_treatment = list(coef = coef(m_dz)[[1]], se = se(m_dz)[[1]],
                             pval = pvalue(m_dz)[[1]]),
  la_trends = list(coef = coef(m_trends)[[1]], se = se(m_trends)[[1]],
                   pval = pvalue(m_trends)[[1]]),
  quarterly = list(coef = coef(m_quarterly)[[1]], se = se(m_quarterly)[[1]],
                   pval = pvalue(m_quarterly)[[1]])
)
saveRDS(robust, "data/robustness_results.rds")
cat("\nRobustness results saved.\n")
