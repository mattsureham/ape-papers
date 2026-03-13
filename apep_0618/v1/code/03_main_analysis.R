## 03_main_analysis.R — Main DiD estimation
library(data.table)
library(fixest)
library(jsonlite)

panel <- fread("data/panel.csv.gz")
cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$district), "LAs,",
    uniqueN(panel$ym), "months\n")

## ---- Table 1: Summary Statistics ----
pre <- panel[post == 0]
post_df <- panel[post == 1]

sumstats <- data.frame(
  Variable = c("Monthly transactions per LA",
               "Transactions near notch (£240k-£260k)",
               "Dead zone transactions (£250k-£260k)",
               "Below-notch transactions (£240k-£250k)",
               "Median price (£)",
               "Pre-reform excess mass ratio",
               "Pre-reform dead zone depth"),
  Pre_Mean = c(mean(pre$n_txn), mean(pre$n_txn_near_notch),
               mean(pre$n_txn_dead_zone), mean(pre$n_txn_below_notch),
               mean(pre$median_price), mean(pre$excess_mass),
               mean(pre$dead_zone_depth)),
  Pre_SD = c(sd(pre$n_txn), sd(pre$n_txn_near_notch),
             sd(pre$n_txn_dead_zone), sd(pre$n_txn_below_notch),
             sd(pre$median_price), sd(pre$excess_mass),
             sd(pre$dead_zone_depth)),
  Post_Mean = c(mean(post_df$n_txn), mean(post_df$n_txn_near_notch),
                mean(post_df$n_txn_dead_zone), mean(post_df$n_txn_below_notch),
                mean(post_df$median_price), NA, NA),
  Post_SD = c(sd(post_df$n_txn), sd(post_df$n_txn_near_notch),
              sd(post_df$n_txn_dead_zone), sd(post_df$n_txn_below_notch),
              sd(post_df$median_price), NA, NA),
  N_pre = rep(nrow(pre), 7),
  N_post = rep(nrow(post_df), 7)
)

cat("\n=== SUMMARY STATISTICS ===\n")
print(sumstats, digits = 2)

## ---- Main specification: DiD with continuous treatment intensity ----
## Y_it = α_i + γ_t + β × (Post_t × ExcessMass_i) + ε_it
## Cluster at LA level

## Specification 1: log total transactions
m1 <- feols(ln_txn ~ post:excess_mass | la_id + ym,
            data = panel, cluster = ~la_id)

## Specification 2: log transactions in £200k-£350k range
m2 <- feols(ln_txn_200_350 ~ post:excess_mass | la_id + ym,
            data = panel, cluster = ~la_id)

## Specification 3: dead zone share (share of near-notch in dead zone)
m3 <- feols(dead_zone_share ~ post:excess_mass | la_id + ym,
            data = panel, cluster = ~la_id)

## Specification 4: log dead zone count
m4 <- feols(log(n_txn_dead_zone + 1) ~ post:excess_mass | la_id + ym,
            data = panel, cluster = ~la_id)

## Specification 5: log below-notch count (bunching should decrease post-reform)
m5 <- feols(log(n_txn_below_notch + 1) ~ post:excess_mass | la_id + ym,
            data = panel, cluster = ~la_id)

cat("\n=== MAIN RESULTS ===\n")
cat("\n--- Spec 1: Log total transactions ---\n")
summary(m1)
cat("\n--- Spec 2: Log transactions £200k-£350k ---\n")
summary(m2)
cat("\n--- Spec 3: Dead zone share ---\n")
summary(m3)
cat("\n--- Spec 4: Log dead zone count ---\n")
summary(m4)
cat("\n--- Spec 5: Log below-notch count ---\n")
summary(m5)

## ---- Event study: dynamic effects ----
## Create relative-time indicators (semi-annual to reduce noise)
panel[, half := ifelse(month <= 6, 1L, 2L)]
panel[, yh_idx := (year - 2010L) * 2L + half]  # sequential index: 2010H1=1, 2010H2=2, ...

## Reform = 2014H2 = index 10
reform_idx <- (2014 - 2010) * 2 + 2  # = 10
panel[, rel_half := yh_idx - reform_idx]

## Create event-time indicators
## Pre: -9 to -1 (2010H1 to 2014H1), Post: 0 to 10 (2014H2 to 2019H2)
panel[, rel_half_f := factor(rel_half)]

## Event study
es <- feols(ln_txn_200_350 ~ i(rel_half_f, excess_mass, ref = -1) | la_id + rel_half_f,
            data = panel, cluster = ~la_id)

cat("\n=== EVENT STUDY (semi-annual) ===\n")
summary(es)

## ---- Save results for tables ----
results <- list(
  m1 = list(coef = coef(m1), se = se(m1), nobs = m1$nobs),
  m2 = list(coef = coef(m2), se = se(m2), nobs = m2$nobs),
  m3 = list(coef = coef(m3), se = se(m3), nobs = m3$nobs),
  m4 = list(coef = coef(m4), se = se(m4), nobs = m4$nobs),
  m5 = list(coef = coef(m5), se = se(m5), nobs = m5$nobs)
)
saveRDS(results, "data/main_results.rds")

## Event study coefficients
es_coefs <- data.frame(
  rel_half = as.integer(gsub("rel_half_f::(-?[0-9]+):excess_mass", "\\1",
                             names(coef(es)))),
  coef = coef(es),
  se = se(es)
)
es_coefs$ci_lo <- es_coefs$coef - 1.96 * es_coefs$se
es_coefs$ci_hi <- es_coefs$coef + 1.96 * es_coefs$se
fwrite(es_coefs, "data/event_study_coefs.csv")

## ---- Diagnostics for validator ----
diag <- list(
  n_treated = uniqueN(panel$district),
  n_pre = uniqueN(panel[post == 0]$ym),
  n_obs = nrow(panel),
  n_post = uniqueN(panel[post == 1]$ym),
  n_las = uniqueN(panel$district),
  reform_date = "2014-12-04",
  main_coef = coef(m2)[[1]],
  main_se = se(m2)[[1]],
  main_pval = pvalue(m2)[[1]]
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat("Main result (log txn £200k-£350k):", round(diag$main_coef, 4),
    "(SE:", round(diag$main_se, 4), ", p:", round(diag$main_pval, 4), ")\n")
