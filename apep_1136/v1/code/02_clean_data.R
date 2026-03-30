## 02_clean_data.R — apep_1136: Construct analysis panel
## Builds cross-product DiD panel: credit cards (treated) vs personal loans (control)

source("00_packages.R")

data_dir <- "../data"
boe <- readRDS(file.path(data_dir, "boe_consumer_credit.rds"))

## ============================================================
## 1. Reshape to wide panel: one row per month
## ============================================================
panel <- boe %>%
  select(date, series, value) %>%
  pivot_wider(names_from = series, values_from = value) %>%
  arrange(date) %>%
  mutate(
    year  = year(date),
    month = month(date),
    ym    = as.yearmon(date)
  )

cat(sprintf("Panel: %d months, %s to %s\n", nrow(panel), min(panel$date), max(panel$date)))

## ============================================================
## 2. Define treatment events
## ============================================================
## Event 1: Sep 2018 — FCA persistent debt rule takes effect
## (18-month clock starts — first contacts March 2020)
## Event 2: Feb 2020 — FCA Dear CEO letter warning against blanket suspensions
## Event 3: Mar 2020 — COVID emergency suspends persistent debt letters
## Event 4: Oct 2021 — COVID measures end, persistent debt letters resume

event_1 <- as.Date("2018-09-01")  # Rule effective
event_2 <- as.Date("2020-02-01")  # FCA warning
event_3 <- as.Date("2020-03-01")  # COVID suspension
event_4 <- as.Date("2021-10-01")  # COVID measures end

panel <- panel %>%
  mutate(
    ## Period indicators
    post_rule     = as.integer(date >= event_1),
    post_warning  = as.integer(date >= event_2),
    covid_suspend = as.integer(date >= event_3 & date < event_4),
    post_covid    = as.integer(date >= event_4),

    ## Time relative to main treatment (months since Sep 2018)
    t_rel = as.integer(round(difftime(date, event_1, units = "days") / 30.44)),

    ## Treatment phases
    phase = case_when(
      date < event_1                    ~ "Pre-rule",
      date >= event_1 & date < event_3  ~ "Rule active",
      date >= event_3 & date < event_4  ~ "COVID suspension",
      date >= event_4                   ~ "Post-COVID"
    ),
    phase = factor(phase, levels = c("Pre-rule", "Rule active",
                                      "COVID suspension", "Post-COVID"))
  )

## ============================================================
## 3. Construct cross-product gap variables
## ============================================================
## The DiD outcome: CC - PL (or ratios/log ratios)
## CC = credit card, PL = other consumer credit (personal loans, etc.)

panel <- panel %>%
  mutate(
    ## Rename for clarity
    cc_outstanding = LPMVZRJ,       # Credit card outstanding (£m)
    pl_outstanding = LPMVZRI,       # Other consumer credit outstanding (£m)
    cc_net_lending = LPMVZQX,       # Credit card net lending (£m, flow)
    cc_gross_lending = LPMVZQO,     # Credit card gross lending (£m)
    cc_interest_rate = IUMCCTL,     # Credit card effective rate (%)
    pl_interest_rate = IUMTLMV,     # Personal loan effective rate (%)
    cc_writeoffs  = LPMB3QE,        # Credit card write-offs (£m)
    pl_writeoffs  = LPMB3QG,        # Other consumer credit write-offs (£m)
    cc_repayments = LPMB3SG,        # Credit card repayments (£m)
    cc_new_business = LPMB3SB,      # Credit card new business

    ## Log levels
    ln_cc = log(cc_outstanding),
    ln_pl = log(pl_outstanding),

    ## Cross-product gap: log(CC) - log(PL)
    ln_gap = ln_cc - ln_pl,

    ## CC share of total consumer credit
    cc_share = cc_outstanding / (cc_outstanding + pl_outstanding),

    ## Normalized indices (Jan 2015 = 100)
    cc_idx = cc_outstanding / cc_outstanding[date == as.Date("2015-01-31")] * 100,
    pl_idx = pl_outstanding / pl_outstanding[date == as.Date("2015-01-31")] * 100,

    ## Gap in index points
    idx_gap = cc_idx - pl_idx,

    ## Net lending ratio
    nl_ratio = ifelse(!is.na(cc_net_lending) & !is.na(LPMVZQW),
                      cc_net_lending / pmax(abs(LPMVZQW), 1), NA),

    ## Write-off ratio
    wo_ratio = ifelse(!is.na(cc_writeoffs) & !is.na(pl_writeoffs) & pl_writeoffs > 0,
                      cc_writeoffs / pl_writeoffs, NA),

    ## Interest rate spread
    rate_spread = cc_interest_rate - pl_interest_rate,

    ## Time trend (months from start)
    trend = as.integer(difftime(date, min(date), units = "days") / 30.44)
  )

## ============================================================
## 4. Create long-format panel for product-level DiD
## ============================================================
## Stack CC and PL as two "products" per month

panel_long <- bind_rows(
  panel %>%
    transmute(
      date, year, month, ym, t_rel, phase, trend,
      post_rule, post_warning, covid_suspend, post_covid,
      product = "Credit card",
      treated = 1L,
      outstanding = cc_outstanding,
      ln_outstanding = ln_cc,
      idx = cc_idx,
      interest_rate = cc_interest_rate,
      writeoffs = cc_writeoffs
    ),
  panel %>%
    transmute(
      date, year, month, ym, t_rel, phase, trend,
      post_rule, post_warning, covid_suspend, post_covid,
      product = "Personal loan",
      treated = 0L,
      outstanding = pl_outstanding,
      ln_outstanding = ln_pl,
      idx = pl_idx,
      interest_rate = pl_interest_rate,
      writeoffs = pl_writeoffs
    )
) %>%
  filter(!is.na(outstanding)) %>%
  mutate(
    ## DiD interaction
    did = treated * post_rule,
    did_covid = treated * covid_suspend,
    did_postcovid = treated * post_covid,

    ## Month FE (seasonality)
    month_fe = factor(month)
  ) %>%
  arrange(date, product)

cat(sprintf("Long panel: %d product-month observations\n", nrow(panel_long)))
cat(sprintf("  Credit card: %d months\n", sum(panel_long$treated == 1)))
cat(sprintf("  Personal loan: %d months\n", sum(panel_long$treated == 0)))

## ============================================================
## 5. Summary statistics
## ============================================================
cat("\n=== PRE-TREATMENT SUMMARY (Jan 2010 - Aug 2018) ===\n")
pre <- panel %>% filter(date >= "2010-01-01" & date < event_1)

cat(sprintf("CC outstanding: mean=%.0f, sd=%.0f £m\n",
            mean(pre$cc_outstanding, na.rm = TRUE),
            sd(pre$cc_outstanding, na.rm = TRUE)))
cat(sprintf("PL outstanding: mean=%.0f, sd=%.0f £m\n",
            mean(pre$pl_outstanding, na.rm = TRUE),
            sd(pre$pl_outstanding, na.rm = TRUE)))
cat(sprintf("CC share: mean=%.3f, sd=%.3f\n",
            mean(pre$cc_share, na.rm = TRUE),
            sd(pre$cc_share, na.rm = TRUE)))
cat(sprintf("Log gap (ln CC - ln PL): mean=%.3f, sd=%.3f\n",
            mean(pre$ln_gap, na.rm = TRUE),
            sd(pre$ln_gap, na.rm = TRUE)))
cat(sprintf("CC interest rate: mean=%.1f%%\n",
            mean(pre$cc_interest_rate, na.rm = TRUE)))
cat(sprintf("PL interest rate: mean=%.1f%%\n",
            mean(pre$pl_interest_rate, na.rm = TRUE)))

## ============================================================
## 6. Save
## ============================================================
saveRDS(panel, file.path(data_dir, "panel_wide.rds"))
saveRDS(panel_long, file.path(data_dir, "panel_long.rds"))

cat("\nSaved: panel_wide.rds, panel_long.rds\n")
cat("Clean data complete.\n")
