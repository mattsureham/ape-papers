# 04_robustness.R — Robustness checks for apep_0811

source("00_packages.R")

load("../data/main_results.RData")
panel[, inc_month := as.Date(inc_month)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ---------------------------------------------------------------
# 1. Exclude COVID lockdown months (Mar 2020 - Jun 2021)
# ---------------------------------------------------------------
cat("--- 1. Excluding COVID months (Mar 2020 - Jun 2021) ---\n")

covid_start <- as.Date("2020-03-01")
covid_end   <- as.Date("2021-06-01")
panel_nocov <- panel[inc_month < covid_start | inc_month > covid_end]

m_nocov <- feols(log_inc ~ treat_ddd | cs + ct + st,
                 data = panel_nocov, vcov = "hetero")
cat(sprintf("  β = %.4f (SE = %.4f), N = %d\n",
            coef(m_nocov)["treat_ddd"], se(m_nocov)["treat_ddd"],
            nobs(m_nocov)))

# ---------------------------------------------------------------
# 2. Post-2021 only (avoid all COVID disruption)
# ---------------------------------------------------------------
cat("\n--- 2. Post-2021 sample (Jul 2021 - Dec 2025) ---\n")

panel_post21 <- panel[inc_month >= as.Date("2021-07-01")]
m_post21 <- feols(log_inc ~ treat_ddd | cs + ct + st,
                  data = panel_post21, vcov = "hetero")
cat(sprintf("  β = %.4f (SE = %.4f), N = %d\n",
            coef(m_post21)["treat_ddd"], se(m_post21)["treat_ddd"],
            nobs(m_post21)))

# ---------------------------------------------------------------
# 3. Quarterly aggregation (smoother, addresses monthly noise)
# ---------------------------------------------------------------
cat("\n--- 3. Quarterly aggregation ---\n")

panel[, qtr := floor_date(inc_month, "quarter")]
panel_q <- panel[, .(
  incorporations = sum(incorporations),
  log_inc = log(sum(incorporations) + 1),
  england = first(england),
  food = first(food),
  post = max(post),
  treat_ddd = first(england) * first(food) * max(post)
), by = .(country, sector, qtr)]

panel_q[, cs := paste0(country, "_", sector)]
panel_q[, ct := paste0(country, "_", qtr)]
panel_q[, st := paste0(sector, "_", qtr)]

m_qtr <- feols(log_inc ~ treat_ddd | cs + ct + st,
               data = panel_q, vcov = "hetero")
cat(sprintf("  β = %.4f (SE = %.4f), N = %d\n",
            coef(m_qtr)["treat_ddd"], se(m_qtr)["treat_ddd"],
            nobs(m_qtr)))

# ---------------------------------------------------------------
# 4. Placebo treatment date: April 2020 (pre-actual-treatment)
# ---------------------------------------------------------------
cat("\n--- 4. Placebo treatment date (April 2020) ---\n")

panel_pre <- panel[inc_month < as.Date("2022-04-01")]
panel_pre[, post_placebo := as.integer(inc_month >= as.Date("2020-04-01"))]
panel_pre[, treat_placebo := england * food * post_placebo]

m_placebo <- feols(log_inc ~ treat_placebo | cs + ct + st,
                   data = panel_pre, vcov = "hetero")
cat(sprintf("  β = %.4f (SE = %.4f), N = %d\n",
            coef(m_placebo)["treat_placebo"], se(m_placebo)["treat_placebo"],
            nobs(m_placebo)))

# ---------------------------------------------------------------
# 5. Placebo sector: Real Estate as "treated" sector
# ---------------------------------------------------------------
cat("\n--- 5. Placebo sector (Real Estate as pseudo-treated) ---\n")

panel[, re := as.integer(sector == "RealEstate")]
panel[, treat_re := england * re * post]

m_re_placebo <- feols(log_inc ~ treat_re | cs + ct + st,
                      data = panel, vcov = "hetero")
cat(sprintf("  β = %.4f (SE = %.4f)\n",
            coef(m_re_placebo)["treat_re"], se(m_re_placebo)["treat_re"]))

# ---------------------------------------------------------------
# 6. Subsector analysis: different SIC 56 divisions
# ---------------------------------------------------------------
cat("\n--- 6. Subsector heterogeneity ---\n")

# Reload raw data for subsector analysis
dt_raw <- fread("../data/companies_house.csv", select = c(
  "CompanyNumber", "IncorporationDate", "SICCode.SicText_1"
), na.strings = "")

dt_raw[, sic_code := str_extract(SICCode.SicText_1, "^\\d+")]
dt_raw[, sic4 := substr(sic_code, 1, 4)]
dt_raw[, country := fifelse(grepl("^SC", CompanyNumber), "Scotland", "EnglandWales")]
dt_raw[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
dt_raw[is.na(inc_date), inc_date := as.Date(IncorporationDate)]
dt_raw[, inc_month := floor_date(inc_date, "month")]

# Filter to food service subsectors
food_subs <- dt_raw[substr(sic_code, 1, 2) == "56" &
                      country %in% c("EnglandWales", "Scotland") &
                      inc_month >= as.Date("2019-01-01") &
                      inc_month <= as.Date("2025-12-01")]

food_subs[, subsector := fcase(
  sic4 == "5610", "Restaurants",
  sic4 == "5621", "EventCatering",
  sic4 == "5629", "OtherCatering",
  sic4 == "5630", "Bars",
  default = "Other56"
)]

sub_counts <- food_subs[, .N, by = .(country, subsector, inc_month)]
cat("Subsector counts:\n")
print(sub_counts[, .(total = sum(N)), by = subsector][order(-total)])

# ---------------------------------------------------------------
# 7. Summary robustness table
# ---------------------------------------------------------------
cat("\n\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("%-35s  %8s  %8s  %5s\n", "Specification", "β", "SE", "N"))
cat(paste(rep("-", 62), collapse = ""), "\n")
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Main (all sectors)", coef(m1)["treat_ddd"], se(m1)["treat_ddd"], nobs(m1)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Poisson", coef(m2)["treat_ddd"], se(m2)["treat_ddd"], nobs(m2)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Drop COVID months", coef(m_nocov)["treat_ddd"], se(m_nocov)["treat_ddd"], nobs(m_nocov)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Post-2021 only", coef(m_post21)["treat_ddd"], se(m_post21)["treat_ddd"], nobs(m_post21)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Quarterly aggregation", coef(m_qtr)["treat_ddd"], se(m_qtr)["treat_ddd"], nobs(m_qtr)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Placebo date (Apr 2020)", coef(m_placebo)["treat_placebo"],
            se(m_placebo)["treat_placebo"], nobs(m_placebo)))
cat(sprintf("%-35s  %8.4f  %8.4f  %5d\n",
            "Placebo sector (Real Estate)", coef(m_re_placebo)["treat_re"],
            se(m_re_placebo)["treat_re"], nobs(m_re_placebo)))

# Save robustness results
save(m_nocov, m_post21, m_qtr, m_placebo, m_re_placebo,
     file = "../data/robustness_results.RData")

cat("\nRobustness checks complete.\n")
