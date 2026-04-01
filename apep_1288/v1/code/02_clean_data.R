## 02_clean_data.R — Variable construction and panel preparation
## Child Labor Law Relaxations and Teen Employment

source("00_packages.R")

# --- Load data ---
qwi <- readRDS("../data/qwi_state_panel.rds")
setDT(qwi)

# --- Create time variable ---
# Quarterly time index: 2019Q1 = 1, 2019Q2 = 2, etc.
qwi[, time := (year - 2019) * 4 + quarter]

# --- Treatment assignment ---
# Cohort 1 (Q3 2022): NJ (34), NH (33)
# Cohort 2 (Q3 2023): AR (5), IA (19), FL (12), IN (18)
# Treatment time: Q3 2022 = time 15, Q3 2023 = time 19

cohort1_fips <- c(34, 33)
cohort2_fips <- c(5, 19, 12, 18)
treated_fips <- c(cohort1_fips, cohort2_fips)

qwi[, treated := fifelse(statefip %in% treated_fips, 1L, 0L)]
qwi[, cohort := fcase(
  statefip %in% cohort1_fips, 1L,
  statefip %in% cohort2_fips, 2L,
  default = 0L
)]

# Treatment timing for CS estimator (first_treat = 0 for never-treated)
qwi[, first_treat := fcase(
  cohort == 1L, 15L,  # Q3 2022
  cohort == 2L, 19L,  # Q3 2023
  default = 0L        # never-treated
)]

# Post indicator
qwi[, post := fifelse(
  cohort == 1L & time >= 15, 1L,
  fifelse(cohort == 2L & time >= 19, 1L, 0L)
)]

# --- Age group indicators ---
qwi[, teen := fifelse(agegrp == "A01", 1L, 0L)]

# Clean age labels
qwi[, age_label := fcase(
  agegrp == "A01", "14-18",
  agegrp == "A02", "19-21",
  agegrp == "A03", "25-34",
  agegrp == "A04", "35-44"
)]

# --- Industry classification ---
# High-teen industries based on smoke test: food service (72), retail (44-45),
# arts/entertainment (71), other services (81)
high_teen_ind <- c("72", "44-45", "71", "81")
qwi[, high_teen_industry := fifelse(industry %in% high_teen_ind, 1L, 0L)]

# Industry labels for tables
ind_labels <- c(
  "00" = "All Industries", "11" = "Agriculture", "21" = "Mining",
  "22" = "Utilities", "23" = "Construction", "31-33" = "Manufacturing",
  "42" = "Wholesale", "44-45" = "Retail", "48-49" = "Transportation",
  "51" = "Information", "52" = "Finance", "53" = "Real Estate",
  "54" = "Professional Svcs", "55" = "Management", "56" = "Admin/Waste",
  "61" = "Education", "62" = "Health Care", "71" = "Arts/Entertainment",
  "72" = "Food Service", "81" = "Other Services", "92" = "Public Admin"
)
qwi[, industry_label := ind_labels[industry]]

# --- State labels ---
state_labels <- c(
  `1`="AL", `2`="AK", `4`="AZ", `5`="AR", `6`="CA", `8`="CO", `9`="CT",
  `10`="DE", `11`="DC", `12`="FL", `13`="GA", `15`="HI", `16`="ID",
  `17`="IL", `18`="IN", `19`="IA", `20`="KS", `21`="KY", `22`="LA",
  `23`="ME", `24`="MD", `25`="MA", `26`="MI", `27`="MN", `28`="MS",
  `29`="MO", `30`="MT", `31`="NE", `32`="NV", `33`="NH", `34`="NJ",
  `35`="NM", `36`="NY", `37`="NC", `38`="ND", `39`="OH", `40`="OK",
  `41`="OR", `42`="PA", `44`="RI", `45`="SC", `46`="SD", `47`="TN",
  `48`="TX", `49`="UT", `50`="VT", `51`="VA", `53`="WA", `54`="WV",
  `55`="WI", `56`="WY"
)
qwi[, state_abbr := state_labels[as.character(statefip)]]

# --- Create analysis datasets ---

# 1. All-industry panel (industry = "00"): state × quarter × age
all_ind <- qwi[industry == "00"]
cat(sprintf("All-industry panel: %d rows\n", nrow(all_ind)))
cat(sprintf("  States: %d, Quarters: %d, Age groups: %d\n",
            uniqueN(all_ind$statefip), uniqueN(all_ind$time),
            uniqueN(all_ind$agegrp)))

# 2. Industry-level panel: state × quarter × age × industry
ind_panel <- qwi[industry != "00"]
cat(sprintf("Industry panel: %d rows\n", nrow(ind_panel)))

# --- Compute teen employment share by industry (pre-treatment) ---
pre_teen_share <- qwi[time < 15 & agegrp %in% c("A01", "A03"),
                      .(emp_total = sum(Emp, na.rm = TRUE)),
                      by = .(industry, teen)]
pre_teen_share <- dcast(pre_teen_share, industry ~ teen,
                        value.var = "emp_total")
setnames(pre_teen_share, c("0", "1"), c("adult_emp", "teen_emp"))
pre_teen_share[, teen_share := teen_emp / (teen_emp + adult_emp)]
pre_teen_share <- pre_teen_share[order(-teen_share)]

cat("\nPre-treatment teen employment share by industry:\n")
for (i in 1:min(10, nrow(pre_teen_share))) {
  row <- pre_teen_share[i]
  lab <- ind_labels[row$industry]
  if (is.na(lab)) lab <- row$industry
  cat(sprintf("  %s (%s): %.1f%%\n", lab, row$industry,
              row$teen_share * 100))
}

# --- Log-transform outcomes ---
all_ind[, log_emp := log(Emp + 1)]
all_ind[, log_hires := log(HirA + 1)]
all_ind[, log_sep := log(Sep + 1)]
all_ind[, log_earns := log(EarnS + 1)]

ind_panel[, log_emp := log(Emp + 1)]
ind_panel[, log_hires := log(HirA + 1)]

# --- Summary stats ---
cat("\n--- Summary Statistics (All-Industry, Pre-Treatment) ---\n")
pre <- all_ind[time < 15 & agegrp %in% c("A01", "A03")]
pre_summary <- pre[, .(
  mean_emp = mean(Emp, na.rm = TRUE),
  sd_emp = sd(Emp, na.rm = TRUE),
  mean_earns = mean(EarnS, na.rm = TRUE),
  mean_hires = mean(HirA, na.rm = TRUE),
  n = .N
), by = .(teen, treated)]
print(pre_summary)

# --- Save ---
saveRDS(all_ind, "../data/all_industry_panel.rds")
saveRDS(ind_panel, "../data/industry_panel.rds")
saveRDS(pre_teen_share, "../data/teen_share_by_industry.rds")
cat("\nSaved analysis datasets.\n")
