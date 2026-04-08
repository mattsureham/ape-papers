# 02_clean_data.R — Construct analysis panel
# BVG Conversion Rate and Capital Withdrawal Choice

source("00_packages.R")

cat("=== Constructing analysis panel ===\n")

# ---------------------------------------------------------------
# Load raw data
# ---------------------------------------------------------------
dt_101 <- readRDS("../data/bfs_101_overview.rds")
dt_141 <- readRDS("../data/bfs_141_annuities.rds")
dt_142 <- readRDS("../data/bfs_142_capital_retirement.rds")
dt_101_risk <- readRDS("../data/bfs_101_by_risk_type.rds")

# ---------------------------------------------------------------
# BVG Conversion Rate Schedule (federal law SR 831.40)
# ---------------------------------------------------------------
conversion_schedule <- data.table(
  year = 2004:2024,
  conversion_rate = c(
    7.2,                       # 2004
    7.1, 7.1,                 # 2005-2006
    7.0, 7.0, 7.0,           # 2007-2009
    6.9, 6.9, 6.9, 6.9,     # 2010-2013
    rep(6.8, 11)              # 2014-2024
  )
)
conversion_schedule[, rate_cut := 7.2 - conversion_rate]
conversion_schedule[, rate_cut_pct := rate_cut / 7.2 * 100]

# Reform period indicator
conversion_schedule[, period := fcase(
  year <= 2004, "Pre-reform",
  year <= 2006, "Step 1 (7.1%)",
  year <= 2009, "Step 2 (7.0%)",
  year <= 2013, "Step 3 (6.9%)",
  default = "Step 4 (6.8%)"
)]

cat("Conversion rate schedule:\n")
print(conversion_schedule)

# ---------------------------------------------------------------
# Panel A: Aggregate annuity vs capital (from _101)
# ---------------------------------------------------------------
cat("\nBuilding aggregate panel from _101...\n")

# Reshape: one row per year with annuity and capital counts
agg <- dt_101[, .(Beobachtungseinheit, Beobachtungseinheit_label, Jahr, value)]
agg[, year := as.integer(Jahr)]

# Create wide panel
panel_agg <- dcast(agg, year ~ Beobachtungseinheit,
                   value.var = "value")
setnames(panel_agg, c("year", "active_insured", "annuity_beneficiaries",
                       "annuity_amount_1000chf", "capital_beneficiaries",
                       "capital_amount_1000chf"))

# Capital withdrawal share
panel_agg[, total_retirees := annuity_beneficiaries + capital_beneficiaries]
panel_agg[, capital_share := capital_beneficiaries / total_retirees]
panel_agg[, capital_amount_share := capital_amount_1000chf /
            (annuity_amount_1000chf + capital_amount_1000chf)]

# Average capital per beneficiary (1000 CHF)
panel_agg[, avg_capital_per_ben := capital_amount_1000chf / capital_beneficiaries]
panel_agg[, avg_annuity_per_ben := annuity_amount_1000chf / annuity_beneficiaries]

# Merge conversion rate schedule
panel_agg <- merge(panel_agg, conversion_schedule, by = "year")

cat("Aggregate panel:\n")
print(panel_agg[, .(year, conversion_rate, rate_cut,
                     annuity_beneficiaries, capital_beneficiaries,
                     capital_share)])

# ---------------------------------------------------------------
# Panel B: Retirement capital by gender (from _142)
# ---------------------------------------------------------------
cat("\nBuilding gender panel from _142...\n")

cap_ret <- dt_142[, .(Beobachtungseinheit, Beobachtungseinheit_label, Jahr, value)]
cap_ret[, year := as.integer(Jahr)]

# Codes: 1=all beneficiaries, 2=women, 3=total amount, 4=women amount
# 9=disability all, 10=disability women, 11=disability total amount, 12=disability women amount
cap_wide <- dcast(cap_ret, year ~ Beobachtungseinheit, value.var = "value")
setnames(cap_wide, c("year",
                      "cap_ret_all", "cap_ret_women",
                      "cap_ret_amt_total", "cap_ret_amt_women",
                      "cap_disab_all", "cap_disab_women",
                      "cap_disab_amt_total", "cap_disab_amt_women"))

# Derive men counts
cap_wide[, cap_ret_men := cap_ret_all - cap_ret_women]
cap_wide[, cap_ret_amt_men := cap_ret_amt_total - cap_ret_amt_women]
cap_wide[, cap_disab_men := cap_disab_all - cap_disab_women]

# Average capital at retirement per beneficiary
cap_wide[, avg_cap_ret_all := cap_ret_amt_total / cap_ret_all * 1000]  # in CHF
cap_wide[, avg_cap_ret_women := cap_ret_amt_women / cap_ret_women * 1000]
cap_wide[, avg_cap_ret_men := cap_ret_amt_men / cap_ret_men * 1000]

cap_wide <- merge(cap_wide, conversion_schedule, by = "year")

# ---------------------------------------------------------------
# Panel C: Annuity benefits by gender (from _141)
# ---------------------------------------------------------------
cat("\nBuilding annuity gender panel from _141...\n")

ann <- dt_141[, .(Beobachtungseinheit, Beobachtungseinheit_label, Jahr, value)]
ann[, year := as.integer(Jahr)]

ann_wide <- dcast(ann, year ~ Beobachtungseinheit, value.var = "value")
setnames(ann_wide, c("year",
                      "annuity_ret_all", "annuity_ret_women",
                      "annuity_ret_amt_total", "annuity_ret_amt_women",
                      "annuity_disab_all", "annuity_disab_women",
                      "annuity_disab_amt_total", "annuity_disab_amt_women"))

ann_wide[, annuity_ret_men := annuity_ret_all - annuity_ret_women]

# ---------------------------------------------------------------
# Panel D: Gender-specific capital share
# ---------------------------------------------------------------
cat("\nBuilding gender-specific capital share panel...\n")

gender_panel <- merge(cap_wide[, .(year, conversion_rate, rate_cut, rate_cut_pct, period,
                                    cap_ret_all, cap_ret_women, cap_ret_men,
                                    cap_ret_amt_total, cap_ret_amt_women, cap_ret_amt_men,
                                    avg_cap_ret_all, avg_cap_ret_women, avg_cap_ret_men,
                                    cap_disab_all, cap_disab_women, cap_disab_men)],
                      ann_wide[, .(year, annuity_ret_all, annuity_ret_women, annuity_ret_men,
                                   annuity_ret_amt_total, annuity_ret_amt_women,
                                   annuity_disab_all, annuity_disab_women)],
                      by = "year")

# Capital share = capital beneficiaries / (capital + annuity new retirees)
# NOTE: annuity_ret is stock (end of year), capital is flow (during year)
# For a cleaner flow measure, compute year-on-year changes in annuity stock
gender_panel[, annuity_new_all := annuity_ret_all - shift(annuity_ret_all, 1)]
gender_panel[, annuity_new_women := annuity_ret_women - shift(annuity_ret_women, 1)]
gender_panel[, annuity_new_men := annuity_ret_men - shift(annuity_ret_men, 1)]

# Capital share using new annuitants (flow-based)
gender_panel[year > 2004, capital_share_flow_all :=
               cap_ret_all / (cap_ret_all + pmax(annuity_new_all, 0))]
gender_panel[year > 2004, capital_share_flow_women :=
               cap_ret_women / (cap_ret_women + pmax(annuity_new_women, 0))]
gender_panel[year > 2004, capital_share_flow_men :=
               cap_ret_men / (cap_ret_men + pmax(annuity_new_men, 0))]

# Also compute stock-based capital share (using _101 totals)
gender_panel <- merge(gender_panel,
                      panel_agg[, .(year, capital_share, capital_amount_share,
                                    active_insured)],
                      by = "year", all.x = TRUE)

# Disability pension capital share (placebo)
gender_panel[, disab_capital_share := cap_disab_all / (cap_disab_all + annuity_disab_all)]

cat("Gender panel constructed: ", nrow(gender_panel), " rows\n")
print(gender_panel[, .(year, conversion_rate, rate_cut,
                        cap_ret_all, annuity_new_all,
                        capital_share_flow_all, disab_capital_share)])

# ---------------------------------------------------------------
# Panel E: By risk coverage type (mechanism)
# ---------------------------------------------------------------
cat("\nBuilding risk-type panel from _101...\n")

risk <- dt_101_risk[, .(Beobachtungseinheit, `Art der Risikodeckung`,
                         `Art der Risikodeckung_label`, Jahr, value)]
risk[, year := as.integer(Jahr)]

risk_wide <- dcast(risk, year + `Art der Risikodeckung` + `Art der Risikodeckung_label` ~ Beobachtungseinheit,
                   value.var = "value")

risk_names <- c("year", "risk_code", "risk_label",
                "active_insured", "annuity_ben", "annuity_amt",
                "capital_ben", "capital_amt")
if (ncol(risk_wide) == length(risk_names)) {
  setnames(risk_wide, risk_names)
} else {
  cat("WARNING: risk panel has ", ncol(risk_wide), " cols, expected ", length(risk_names), "\n")
  print(names(risk_wide))
}

risk_wide[, capital_share := capital_ben / (annuity_ben + capital_ben)]
risk_wide <- merge(risk_wide, conversion_schedule, by = "year")

# Classify risk types by degree of autonomy
# Autonomous VE: more control over conversion rate → less affected by BVG minimum
# Collective VE: directly apply insurance company rates → more affected
risk_wide[, autonomy := fcase(
  risk_code %in% c("1", "2"), "Autonomous",
  risk_code %in% c("3", "4"), "Semi-autonomous",
  risk_code %in% c("5"), "Collective",
  default = "Savings only"
)]

cat("Risk-type panel:\n")
print(risk_wide[year %in% c(2004, 2014, 2024),
                .(year, risk_label, capital_share, autonomy)])

# ---------------------------------------------------------------
# Save analysis panels
# ---------------------------------------------------------------
saveRDS(panel_agg, "../data/panel_aggregate.rds")
saveRDS(gender_panel, "../data/panel_gender.rds")
saveRDS(risk_wide, "../data/panel_risk_type.rds")
saveRDS(conversion_schedule, "../data/conversion_schedule.rds")

cat("\n=== Analysis panels saved ===\n")
