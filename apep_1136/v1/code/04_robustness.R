## 04_robustness.R — apep_1136: Robustness and placebos
## Addresses pre-trend concern and tests alternative specifications

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_wide.rds"))
panel_long <- readRDS(file.path(data_dir, "panel_long.rds"))

## ============================================================
## 1. Pre-trend test: restrict to pre-COVID period
## ============================================================
## Key concern: credit card share was declining before the rule.
## Restricting to Sep 2018 - Feb 2020 isolates the rule from COVID.

df <- panel_long %>%
  filter(date >= "2010-01-01" & date <= "2020-02-29") %>%
  filter(!is.na(ln_outstanding)) %>%
  mutate(pid = factor(product))

m_precovid <- feols(ln_outstanding ~ did + treated + post_rule + trend |
                      month_fe, data = df,
                    panel.id = ~pid + date, vcov = NW(12))
cat("=== Robustness 1: Pre-COVID window only (to Feb 2020) ===\n")
print(summary(m_precovid))

## ============================================================
## 2. Trend-adjusted DiD
## ============================================================
## Include product-specific trends to absorb the pre-existing divergence

df_full <- panel_long %>%
  filter(date >= "2010-01-01" & date <= "2025-03-31") %>%
  filter(!is.na(ln_outstanding)) %>%
  mutate(pid = factor(product))

m_trend <- feols(ln_outstanding ~ did + treated + post_rule + trend +
                   treated:trend | month_fe,
                 data = df_full, panel.id = ~pid + date, vcov = NW(12))
cat("\n=== Robustness 2: Product-specific trend ===\n")
print(summary(m_trend))

## ============================================================
## 3. Placebo test: Student loans vs Dealership finance
## ============================================================
## Neither product is affected by the persistent debt rule.
## If we see a similar "effect" in untreated products, our design is invalid.

pw <- panel %>%
  filter(date >= "2010-01-01" & date <= "2025-03-31") %>%
  filter(!is.na(LPMB3SE) & !is.na(LPMB3SF))

placebo_long <- bind_rows(
  pw %>% transmute(
    date, trend, post_rule, covid_suspend, post_covid,
    month_fe = factor(month),
    product = "Dealership finance", treated = 1L,
    ln_outstanding = log(LPMB3SE)
  ),
  pw %>% transmute(
    date, trend, post_rule, covid_suspend, post_covid,
    month_fe = factor(month),
    product = "Student loans", treated = 0L,
    ln_outstanding = log(LPMB3SF)
  )
) %>%
  mutate(
    pid = factor(product),
    did = treated * post_rule
  )

m_placebo <- feols(ln_outstanding ~ did + treated + post_rule + trend |
                     month_fe, data = placebo_long,
                   panel.id = ~pid + date, vcov = NW(12))
cat("\n=== Robustness 3: Placebo — Dealership finance vs Student loans ===\n")
print(summary(m_placebo))

## ============================================================
## 4. Permutation inference
## ============================================================
## Randomly assign treatment date 1000 times and check if real effect
## is in the tail of the permutation distribution.

set.seed(42)
df_perm <- panel_long %>%
  filter(date >= "2010-01-01" & date <= "2025-03-31") %>%
  filter(!is.na(ln_outstanding)) %>%
  mutate(pid = factor(product))

## Real effect
real_coef <- coef(feols(ln_outstanding ~ did + treated + post_rule + trend |
                          month_fe, data = df_perm,
                        panel.id = ~pid + date))["did"]

n_perms <- 500
perm_coefs <- numeric(n_perms)
possible_dates <- unique(df_perm$date)
possible_dates <- possible_dates[possible_dates >= "2012-01-01" &
                                   possible_dates <= "2023-01-01"]

for (i in seq_len(n_perms)) {
  fake_date <- sample(possible_dates, 1)
  df_perm$fake_post <- as.integer(df_perm$date >= fake_date)
  df_perm$fake_did <- df_perm$treated * df_perm$fake_post

  tryCatch({
    m_fake <- feols(ln_outstanding ~ fake_did + treated + fake_post + trend |
                      month_fe, data = df_perm,
                    panel.id = ~pid + date)
    perm_coefs[i] <- coef(m_fake)["fake_did"]
  }, error = function(e) {
    perm_coefs[i] <<- NA
  })
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_p <- mean(perm_coefs <= real_coef)
cat(sprintf("\n=== Permutation Test ===\n"))
cat(sprintf("Real DiD coef: %.4f\n", real_coef))
cat(sprintf("Permutation p-value (one-sided): %.4f\n", perm_p))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

## ============================================================
## 5. Breakpoint at 18-month mark
## ============================================================
## The rule creates escalating interventions: 18-month contact,
## 27-month repayment plan, 36-month suspend/cancel.
## Test: is there a structural break at month 18 post-treatment?

pw_post <- panel %>%
  filter(date >= "2018-09-01" & date <= "2025-03-31") %>%
  mutate(
    months_post = as.integer(round(difftime(date, as.Date("2018-09-01"),
                                             units = "days") / 30.44)),
    post_18m = as.integer(months_post >= 18),
    post_27m = as.integer(months_post >= 27),
    post_36m = as.integer(months_post >= 36)
  )

m_escalation <- lm(ln_gap ~ post_18m + post_27m + post_36m + months_post +
                      factor(month), data = pw_post)
m_esc_hac <- coeftest(m_escalation, vcov = NeweyWest(m_escalation, lag = 12))
cat("\n=== Robustness 5: Escalation breaks (18/27/36 months) ===\n")
print(m_esc_hac[1:5, ])

## ============================================================
## 6. Save robustness results
## ============================================================
robust_results <- list(
  precovid = m_precovid,
  trend_adjusted = m_trend,
  placebo = m_placebo,
  perm_p = perm_p,
  perm_coefs = perm_coefs,
  real_coef = real_coef,
  escalation = m_escalation,
  escalation_hac = m_esc_hac
)
saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
