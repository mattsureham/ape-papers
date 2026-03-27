# =============================================================================
# 04_robustness.R — Robustness for BRAC base closures
# =============================================================================
source("00_packages.R")

panel <- fread("../data/panel_annual.csv",
               colClasses = list(character = "county_fips"))
panel[, post := as.integer(year >= g & g > 0)]
panel[, cohort_sa := fifelse(g %in% c(1995, 2005), g,
                              fifelse(g == 0, 10000L, NA_integer_))]

# =============================================================================
# 1. Leave-one-cohort-out (TWFE)
# =============================================================================
cat("=== Leave-one-cohort-out ===\n")
cohorts <- sort(unique(panel[g > 0]$g))
loco <- data.table()
for (drop_g in cohorts) {
  sub <- panel[g != drop_g & !is.na(ln_emp)]
  mod <- feols(ln_emp ~ post | county_id + year, data = sub, cluster = ~county_id)
  loco <- rbind(loco, data.table(
    dropped = drop_g,
    att = round(coef(mod)["post"], 4),
    se = round(se(mod)["post"], 4),
    pval = round(pvalue(mod)["post"], 3)
  ))
}
cat("LOCO results (TWFE, log employment):\n")
print(loco)
fwrite(loco, "../data/loco_results.csv")

# =============================================================================
# 2. Sun-Abraham event study for EARNINGS (key outcome)
# =============================================================================
cat("\n=== SA event study: earnings ===\n")
panel_main <- panel[g %in% c(0, 1995, 2005)]
panel_main[, cohort_sa := fifelse(g == 0, 10000L, g)]

sa_earn <- feols(ln_earn ~ sunab(cohort_sa, year) | county_id + year,
                 data = panel_main[!is.na(ln_earn)], cluster = ~county_id)
saveRDS(sa_earn, "../data/sa_earn.rds")

earn_coefs <- data.table(
  rel_year = as.integer(gsub("year::", "", names(coef(sa_earn)))),
  coef = as.numeric(coef(sa_earn)),
  se = as.numeric(se(sa_earn)),
  pval = as.numeric(pvalue(sa_earn))
)
fwrite(earn_coefs, "../data/sa_earn_coefs.csv")
cat("Earnings pre-trends:\n")
print(earn_coefs[rel_year >= -5 & rel_year <= -2])
cat("Earnings post (years 0-5):\n")
print(earn_coefs[rel_year >= 0 & rel_year <= 5])

# =============================================================================
# 3. SA event study for accommodation share (clean identification?)
# =============================================================================
cat("\n=== SA event study: accommodation share ===\n")
sa_accom <- feols(share_accom ~ sunab(cohort_sa, year) | county_id + year,
                  data = panel_main[!is.na(share_accom)], cluster = ~county_id)
saveRDS(sa_accom, "../data/sa_accom.rds")

accom_coefs <- data.table(
  rel_year = as.integer(gsub("year::", "", names(coef(sa_accom)))),
  coef = as.numeric(coef(sa_accom)),
  se = as.numeric(se(sa_accom)),
  pval = as.numeric(pvalue(sa_accom))
)
fwrite(accom_coefs, "../data/sa_accom_coefs.csv")
cat("Accommodation share pre-trends:\n")
print(accom_coefs[rel_year >= -5 & rel_year <= -2])

# =============================================================================
# 4. Earnings TWFE with controls for county size
# =============================================================================
cat("\n=== Earnings with baseline controls ===\n")
# Use 1993 (baseline) employment as control
baseline <- panel[year == 1993, .(county_fips, base_emp = emp)]
panel_ctrl <- merge(panel, baseline, by = "county_fips", all.x = TRUE)
panel_ctrl[, ln_base_emp := log(base_emp + 1)]
panel_ctrl[, post_x_size := post * ln_base_emp]

twfe_earn_ctrl <- feols(ln_earn ~ post + post_x_size | county_id + year,
                        data = panel_ctrl[!is.na(ln_earn)], cluster = ~county_id)
cat("Earnings with size interaction:\n")
print(summary(twfe_earn_ctrl))

# =============================================================================
# 5. Placebo: Same-state non-BRAC counties
# =============================================================================
cat("\n=== Placebo: BRAC-state spillovers ===\n")
brac <- fread("../data/brac_treatment.csv", colClasses = list(character = "county_fips"))
brac_states <- unique(substr(brac$county_fips, 1, 2))
panel[, state_fips := substr(county_fips, 1, 2)]

# Among never-treated: those in BRAC states vs non-BRAC states
panel_nt <- panel[g == 0 & !is.na(ln_emp)]
panel_nt[, brac_state := as.integer(state_fips %in% brac_states)]

# Time-varying: do BRAC-state counties diverge after BRAC rounds?
panel_nt[, post_any_brac := as.integer(year >= 1995)]
panel_nt[, brac_state_post := brac_state * post_any_brac]
placebo_tv <- feols(ln_emp ~ brac_state_post | county_id + year,
                    data = panel_nt, cluster = ~county_id)
cat("Placebo (BRAC-state x post-1995):\n")
print(summary(placebo_tv))

cat("\n=== Robustness complete ===\n")
