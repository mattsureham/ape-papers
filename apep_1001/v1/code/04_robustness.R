## 04_robustness.R — Robustness checks and placebos
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

source("00_packages.R")

cat("=== Robustness Checks ===\n")

daily <- fread("../data/daily_voivodeship.csv")
daily[, date := as.Date(date)]
daily[, voivodeship_f := as.factor(voivodeship)]
daily[, month_f := as.factor(month)]
daily[, year_f := as.factor(year)]

sundays <- daily[is_sunday == TRUE]
saturdays <- daily[is_saturday == TRUE]

# ============================================================
# 1. SATURDAY PLACEBO
# ============================================================
cat("\n--- Saturday Placebo ---\n")

# Assign Saturday the treatment status of the NEXT day's Sunday
# (i.e., Saturday before a trading Sunday is "trading Saturday")
trading_sundays <- as.Date(c(
  "2020-01-26", "2020-04-05", "2020-04-26", "2020-06-28",
  "2020-08-30", "2020-12-13", "2020-12-20",
  "2021-01-31", "2021-03-28", "2021-04-25", "2021-06-27",
  "2021-08-29", "2021-12-12", "2021-12-19",
  "2022-01-30", "2022-04-10", "2022-04-24", "2022-06-26",
  "2022-08-28", "2022-12-11", "2022-12-18",
  "2023-01-29", "2023-04-02", "2023-04-23", "2023-06-25",
  "2023-08-27", "2023-12-17", "2023-12-24"
))

trading_saturdays <- trading_sundays - 1
saturdays[, non_trading_sat := as.numeric(!(date %in% trading_saturdays))]
saturdays[, accidents := as.numeric(accidents)]

m_sat_placebo <- fepois(accidents ~ non_trading_sat | voivodeship_f + month_f + year_f,
                        data = saturdays, vcov = ~voivodeship_f)

cat(sprintf("Saturday placebo: β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_sat_placebo)["non_trading_sat"],
            se(m_sat_placebo)["non_trading_sat"],
            pvalue(m_sat_placebo)["non_trading_sat"]))
cat(sprintf("  IRR = %.3f\n", exp(coef(m_sat_placebo)["non_trading_sat"])))

# ============================================================
# 2. CLUSTER PERMUTATION TEST (16 clusters — manual RI)
# ============================================================
cat("\n--- Cluster Permutation Test (Randomization Inference) ---\n")

sundays[, non_trading_num := as.numeric(non_trading)]

m_ols <- feols(accidents ~ non_trading_num | voivodeship_f + month_f + year_f,
               data = sundays, vcov = ~voivodeship_f)

# Manual RI: permute treatment across dates within voivodeships
set.seed(42)
n_perms <- 999
obs_coef <- coef(m_ols)["non_trading_num"]
perm_coefs <- numeric(n_perms)

for (b in seq_len(n_perms)) {
  # Permute non_trading indicator across Sundays (same across voivodeships)
  dates_unique <- unique(sundays$date)
  perm_map <- data.table(
    date = dates_unique,
    non_trading_perm = sample(sundays[voivodeship == sundays$voivodeship[1],
                                       non_trading_num, by = date]$non_trading_num)
  )
  sundays_perm <- merge(sundays, perm_map, by = "date", all.x = TRUE)
  m_perm <- tryCatch({
    feols(accidents ~ non_trading_perm | voivodeship_f + month_f + year_f,
          data = sundays_perm, vcov = ~voivodeship_f)
  }, error = function(e) NULL)
  if (!is.null(m_perm)) {
    perm_coefs[b] <- coef(m_perm)["non_trading_perm"]
  }
}

ri_p <- mean(abs(perm_coefs) >= abs(obs_coef))
cat(sprintf("RI p-value (999 permutations): %.4f\n", ri_p))
cat(sprintf("Observed coef: %.4f, permutation range: [%.4f, %.4f]\n",
            obs_coef, min(perm_coefs), max(perm_coefs)))

wcb <- list(p_value = ri_p)

# ============================================================
# 3. NEGATIVE BINOMIAL (alternative to Poisson)
# ============================================================
cat("\n--- Negative Binomial ---\n")

m_nb <- tryCatch({
  MASS::glm.nb(accidents ~ non_trading_num + voivodeship_f + month_f + year_f,
               data = sundays)
}, error = function(e) {
  cat(sprintf("NB error: %s\n", e$message))
  NULL
})

if (!is.null(m_nb)) {
  nb_coef <- coef(m_nb)["non_trading_num"]
  nb_se <- summary(m_nb)$coefficients["non_trading_num", "Std. Error"]
  cat(sprintf("NB: β = %.4f (SE = %.4f), IRR = %.3f\n", nb_coef, nb_se, exp(nb_coef)))
}

# ============================================================
# 4. EXCLUDE HOLIDAY-ADJACENT SUNDAYS
# ============================================================
cat("\n--- Excluding Holiday-Adjacent Sundays ---\n")

# Christmas/Easter windows: remove 2 weeks around major holidays
holiday_windows <- as.Date(c(
  # Christmas 2020-2023 (Dec 20 - Jan 5)
  seq(as.Date("2020-12-20"), as.Date("2021-01-05"), by = 1),
  seq(as.Date("2021-12-20"), as.Date("2022-01-05"), by = 1),
  seq(as.Date("2022-12-20"), as.Date("2023-01-05"), by = 1),
  seq(as.Date("2023-12-20"), as.Date("2024-01-05"), by = 1),
  # Easter windows (week before and after)
  seq(as.Date("2020-04-05"), as.Date("2020-04-19"), by = 1),
  seq(as.Date("2021-03-28"), as.Date("2021-04-11"), by = 1),
  seq(as.Date("2022-04-10"), as.Date("2022-04-24"), by = 1),
  seq(as.Date("2023-04-02"), as.Date("2023-04-16"), by = 1)
))

sundays_noholiday <- sundays[!(date %in% holiday_windows)]
cat(sprintf("After excluding holidays: %d obs (dropped %d)\n",
            nrow(sundays_noholiday), nrow(sundays) - nrow(sundays_noholiday)))

sundays_noholiday[, non_trading_num := as.numeric(non_trading)]
sundays_noholiday[, accidents := as.numeric(accidents)]

m_noholiday <- fepois(accidents ~ non_trading_num | voivodeship_f + month_f + year_f,
                      data = sundays_noholiday, vcov = ~voivodeship_f)

cat(sprintf("No holidays: β = %.4f (SE = %.4f), IRR = %.3f\n",
            coef(m_noholiday)["non_trading_num"],
            se(m_noholiday)["non_trading_num"],
            exp(coef(m_noholiday)["non_trading_num"])))

# ============================================================
# 5. LEAVE-ONE-VOIVODESHIP-OUT
# ============================================================
cat("\n--- Leave-One-Out ---\n")

sundays[, non_trading_num := as.numeric(non_trading)]
sundays[, accidents := as.numeric(accidents)]

loo_results <- data.table()
for (v in unique(sundays$voivodeship)) {
  sub <- sundays[voivodeship != v]
  m_loo <- fepois(accidents ~ non_trading_num | voivodeship_f + month_f + year_f,
                  data = sub, vcov = ~voivodeship_f)
  loo_results <- rbind(loo_results, data.table(
    excluded = v,
    coef = coef(m_loo)["non_trading_num"],
    se = se(m_loo)["non_trading_num"],
    irr = exp(coef(m_loo)["non_trading_num"])
  ))
}

cat(sprintf("LOO range: IRR [%.3f, %.3f]\n",
            min(loo_results$irr), max(loo_results$irr)))

# ============================================================
# 6. FRIDAY PLACEBO (no ban on any day)
# ============================================================
cat("\n--- Friday Placebo ---\n")

# Reload full incidents to get Fridays
incidents_full <- fread("../data/incidents.csv", encoding = "UTF-8")
incidents_full[, datetime_parsed := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
incidents_full[, date := as.Date(datetime_parsed)]
incidents_full[, dow := wday(date, week_start = 1)]
incidents_full[, year := year(date)]
incidents_full[, month := month(date)]
incidents_full[, voivodeship_f := as.factor(voivodeship)]

fridays <- incidents_full[dow == 5, .(accidents = as.numeric(.N)),
                          by = .(voivodeship = voivodeship, date, year, month)]
fridays[, voivodeship_f := as.factor(voivodeship)]
fridays[, month_f := as.factor(month)]
fridays[, year_f := as.factor(year)]
fridays[, non_trading_fri := as.numeric(!(date %in% (trading_sundays - 2)))]

m_fri <- fepois(accidents ~ non_trading_fri | voivodeship_f + month_f + year_f,
                data = fridays, vcov = ~voivodeship_f)

cat(sprintf("Friday placebo: β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_fri)["non_trading_fri"],
            se(m_fri)["non_trading_fri"],
            pvalue(m_fri)["non_trading_fri"]))

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  sat_placebo = m_sat_placebo,
  wcb = wcb,
  nb = m_nb,
  noholiday = m_noholiday,
  loo = loo_results,
  fri_placebo = m_fri
)
saveRDS(robustness, "../data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
