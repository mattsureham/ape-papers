## 02_clean_data.R — Construct agency-month panel with treatment intensity
source("00_packages.R")

## ---- Load raw data ----
nprms <- fread("../data/nprms_2010_2024.csv")
rules <- fread("../data/rules_2010_2024.csv")
agency_prio <- fread("../data/agency_priority.csv")
eo_desig <- fread("../data/eo13771_designations.csv")

cat("NPRMs:", nrow(nprms), "| Final Rules:", nrow(rules), "\n")

## ---- Parse dates ----
nprms[, posted_date := as.Date(substr(posted_date, 1, 10))]
nprms[, year := year(posted_date)]
nprms[, month := month(posted_date)]
nprms[, ym := year + (month - 1) / 12]

rules[, posted_date := as.Date(substr(posted_date, 1, 10))]
rules[, year := year(posted_date)]
rules[, month := month(posted_date)]
rules[, ym := year + (month - 1) / 12]

## ---- Construct treatment intensity ----
prio_wide <- dcast(agency_prio, agency ~ category, value.var = "count", fill = 0)
prio_wide[, total := rowSums(.SD, na.rm = TRUE),
          .SDcols = setdiff(names(prio_wide), "agency")]
prio_wide[, share_econ_sig := `Economically Significant` / total]
prio_wide[is.nan(share_econ_sig), share_econ_sig := 0]

treatment <- prio_wide[, .(agency, share_econ_sig, total_dockets = total,
                            n_econ_sig = `Economically Significant`)]

# Filter to agencies with meaningful rulemaking (>= 50 total dockets)
treatment <- treatment[total_dockets >= 50]
cat("\nTreatment intensity (agencies with >= 50 dockets):\n")
print(treatment[order(-share_econ_sig)])
cat("N agencies:", nrow(treatment), "\n")

## ---- Build agency-MONTH panel ----
agencies <- treatment$agency

# NPRM counts per agency-month
nprm_panel <- nprms[agency_id %in% agencies,
                     .(n_nprm = .N), by = .(agency_id, year, month)]

# Final Rule counts per agency-month
rule_panel <- rules[agency_id %in% agencies,
                     .(n_rule = .N), by = .(agency_id, year, month)]

# Create balanced grid
grid <- CJ(agency_id = agencies, year = 2010:2024, month = 1:12)
# Remove future months (2024 may be incomplete but keep for now)
grid[, ym := year + (month - 1) / 12]

panel <- merge(grid, nprm_panel, by = c("agency_id", "year", "month"), all.x = TRUE)
panel <- merge(panel, rule_panel, by = c("agency_id", "year", "month"), all.x = TRUE)
panel[is.na(n_nprm), n_nprm := 0]
panel[is.na(n_rule), n_rule := 0]

# Add treatment intensity
panel <- merge(panel, treatment[, .(agency, share_econ_sig, n_econ_sig)],
               by.x = "agency_id", by.y = "agency", all.x = TRUE)

# Create policy period indicators
# EO 13771 signed Jan 30, 2017 — effective Feb 2017
# Biden rescission Jan 20, 2021 — effective Feb 2021
panel[, post_eo := as.integer(year > 2017 | (year == 2017 & month >= 2))]
panel[, post_rescission := as.integer(year > 2021 | (year == 2021 & month >= 2))]
panel[, post_eo_x_intensity := post_eo * share_econ_sig]
panel[, post_rescission_x_intensity := post_rescission * share_econ_sig]

# Log transforms
panel[, log_nprm := log(n_nprm + 1)]
panel[, log_rule := log(n_rule + 1)]
panel[, n_total := n_nprm + n_rule]
panel[, log_total := log(n_total + 1)]

# Composition: ratio of rules to NPRMs (measure of deregulatory shift)
panel[, rule_nprm_ratio := n_rule / pmax(n_nprm, 1)]

# Create yearmonth factor for FE
panel[, yearmonth := factor(paste0(year, "-", sprintf("%02d", month)))]

## ---- NPRM-to-Rule matching for duration ----
nprm_by_docket <- nprms[agency_id %in% agencies,
                         .(nprm_date = min(posted_date)), by = .(docket_id, agency_id)]
rule_by_docket <- rules[, .(rule_date = min(posted_date)), by = docket_id]

matched <- merge(nprm_by_docket, rule_by_docket, by = "docket_id")
matched[, duration_days := as.numeric(rule_date - nprm_date)]
matched <- matched[duration_days > 0 & duration_days < 3650]
matched[, nprm_year := year(nprm_date)]
matched[, nprm_month := month(nprm_date)]

cat("\nMatched NPRM-Rule pairs:", nrow(matched), "\n")
cat("Median duration:", median(matched$duration_days), "days\n")

# Duration panel by agency-quarter for more power
matched[, nprm_quarter := ceiling(nprm_month / 3)]
matched <- merge(matched, treatment[, .(agency, share_econ_sig)],
                 by.x = "agency_id", by.y = "agency")
matched[, post_eo := as.integer(nprm_year > 2017 | (nprm_year == 2017 & nprm_month >= 2))]
matched[, post_rescission := as.integer(nprm_year > 2021 | (nprm_year == 2021 & nprm_month >= 2))]
matched[, post_eo_x_intensity := post_eo * share_econ_sig]
matched[, post_rescission_x_intensity := post_rescission * share_econ_sig]

cat("\nPanel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Agencies:", uniqueN(panel$agency_id), "\n")
cat("Year-months:", uniqueN(panel$yearmonth), "\n")

fwrite(panel, "../data/panel.csv")
fwrite(matched, "../data/matched_durations.csv")
cat("Saved panel.csv and matched_durations.csv\n")
