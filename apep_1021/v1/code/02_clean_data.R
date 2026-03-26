# 02_clean_data.R — Construct analysis panel
# apep_1021: Latvia AML Shell-Company Ban

source("00_packages.R")

reg <- readRDS("../data/register_parsed.rds")

# ============================================================
# 1. Classify firm types
# ============================================================

reg[, firm_category := fcase(
  grepl("Sabiedrība ar ierobežotu", type_text), "SIA",
  grepl("Akciju sabiedrība", type_text), "AS",
  grepl("Ārvalsts komersanta", type_text), "foreign_rep",
  grepl("Individuālais komersants", type_text), "IK",
  grepl("Zemnieku", type_text), "farm",
  grepl("Biedrība|Sabiedriskā org", type_text), "association",
  grepl("Individuālais uzņēmums", type_text), "sole_prop",
  grepl("Kooperatīvā", type_text), "coop",
  grepl("Masu informācijas", type_text), "media",
  default = "other"
)]

# Shell-likely: SIA, AS, foreign representative offices
reg[, shell_likely := firm_category %in% c("SIA", "AS", "foreign_rep")]

cat("Firm categories:\n")
print(reg[, .(N = .N, shell_likely = first(shell_likely)),
          by = firm_category][order(-N)])

# ============================================================
# 2. Identify Riga (ATVK code 10000)
# ============================================================

reg[, riga := (atvk == 10000)]
# Handle NAs in atvk
reg[is.na(atvk), riga := FALSE]

cat(sprintf("\nRiga firms: %d (%.1f%%)\n", sum(reg$riga), 100 * mean(reg$riga)))
cat(sprintf("Non-Riga firms: %d (%.1f%%)\n", sum(!reg$riga), 100 * mean(!reg$riga)))

# Verify Riga is the financial center
cat("\nShell-likely share by location:\n")
print(reg[, .(N = .N, shell_pct = 100 * mean(shell_likely)), by = riga])

# ============================================================
# 3. Create monthly panel of firm events
# ============================================================

start_date <- as.Date("2015-01-01")
end_date   <- as.Date("2021-12-31")
months <- seq(start_date, end_date, by = "month")

# Filter to relevant firms
reg_study <- reg[registered <= end_date]

# Registration and termination months
reg_study[, reg_month := floor_date(registered, "month")]
reg_study[, term_month := floor_date(terminated, "month")]

# ---- New registrations per group-month ----
new_regs <- reg_study[reg_month >= start_date & reg_month <= end_date,
                      .(new_firms = .N),
                      by = .(ym = reg_month, shell_likely, riga)]

# ---- Dissolutions per group-month ----
dissolutions <- reg_study[!is.na(term_month) & term_month >= start_date & term_month <= end_date,
                          .(dissolved = .N),
                          by = .(ym = term_month, shell_likely, riga)]

# ---- Active firms (stock) per group-month ----
cat("Computing monthly active firm counts (84 months)...\n")
active_counts <- rbindlist(lapply(months, function(m) {
  m_end <- ceiling_date(m, "month") - days(1)
  active <- reg_study[registered <= m_end & (is.na(terminated) | terminated > m_end)]
  active[, .(active_firms = .N), by = .(shell_likely, riga)][, ym := m]
}))

# ============================================================
# 4. Build analysis panel
# ============================================================

groups <- CJ(
  ym = months,
  shell_likely = c(TRUE, FALSE),
  riga = c(TRUE, FALSE)
)

panel <- merge(groups, new_regs, by = c("ym", "shell_likely", "riga"), all.x = TRUE)
panel <- merge(panel, dissolutions, by = c("ym", "shell_likely", "riga"), all.x = TRUE)
panel <- merge(panel, active_counts, by = c("ym", "shell_likely", "riga"), all.x = TRUE)

panel[is.na(new_firms), new_firms := 0]
panel[is.na(dissolved), dissolved := 0]

# Rates per 1000 active firms
panel[, dissolution_rate := (dissolved / active_firms) * 1000]
panel[, registration_rate := (new_firms / active_firms) * 1000]

# Treatment indicators
panel[, post := ym >= as.Date("2018-02-01")]
panel[, post_law := ym >= as.Date("2018-05-01")]
panel[, treated := shell_likely & riga]

# Relative time (months from Feb 2018)
panel[, rel_month := interval(as.Date("2018-02-01"), ym) %/% months(1)]

# Numeric time
panel[, year := year(ym)]
panel[, month_of_year := month(ym)]

# Group labels
panel[, group := fcase(
  shell_likely & riga, "SIA/Riga",
  shell_likely & !riga, "SIA/non-Riga",
  !shell_likely & riga, "non-SIA/Riga",
  !shell_likely & !riga, "non-SIA/non-Riga"
)]

# ============================================================
# 5. Also build a more granular panel: firm_category x riga x month
# ============================================================

# Detailed category panel for heterogeneity analysis
new_regs_det <- reg_study[reg_month >= start_date & reg_month <= end_date,
                          .(new_firms = .N),
                          by = .(ym = reg_month, firm_category, riga)]

diss_det <- reg_study[!is.na(term_month) & term_month >= start_date & term_month <= end_date,
                      .(dissolved = .N),
                      by = .(ym = term_month, firm_category, riga)]

active_det <- rbindlist(lapply(months, function(m) {
  m_end <- ceiling_date(m, "month") - days(1)
  active <- reg_study[registered <= m_end & (is.na(terminated) | terminated > m_end)]
  active[, .(active_firms = .N), by = .(firm_category, riga)][, ym := m]
}))

cats <- unique(reg_study$firm_category)
det_grid <- CJ(ym = months, firm_category = cats, riga = c(TRUE, FALSE))
det_panel <- merge(det_grid, new_regs_det, by = c("ym", "firm_category", "riga"), all.x = TRUE)
det_panel <- merge(det_panel, diss_det, by = c("ym", "firm_category", "riga"), all.x = TRUE)
det_panel <- merge(det_panel, active_det, by = c("ym", "firm_category", "riga"), all.x = TRUE)
det_panel[is.na(new_firms), new_firms := 0]
det_panel[is.na(dissolved), dissolved := 0]
det_panel[active_firms > 0, dissolution_rate := (dissolved / active_firms) * 1000]
det_panel[active_firms > 0, registration_rate := (new_firms / active_firms) * 1000]
det_panel[, post := ym >= as.Date("2018-02-01")]
det_panel[, rel_month := interval(as.Date("2018-02-01"), ym) %/% months(1)]
det_panel[, shell_likely := firm_category %in% c("SIA", "AS", "foreign_rep")]

saveRDS(det_panel, "../data/detail_panel.rds")

# ============================================================
# 6. Summary statistics
# ============================================================

cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Months: %d (%s to %s)\n",
            length(months),
            format(min(panel$ym), "%Y-%m"),
            format(max(panel$ym), "%Y-%m")))

cat("\nPre-treatment averages (Jan 2015 - Jan 2018):\n")
pre <- panel[ym < as.Date("2018-02-01")]
print(pre[, .(
  mean_active = round(mean(active_firms)),
  mean_dissolved = round(mean(dissolved), 1),
  mean_diss_rate = round(mean(dissolution_rate, na.rm = TRUE), 2),
  mean_new = round(mean(new_firms), 1),
  mean_reg_rate = round(mean(registration_rate, na.rm = TRUE), 2)
), by = group][order(-mean_active)])

cat("\nPost-treatment averages (Feb 2018 - Dec 2021):\n")
post_d <- panel[ym >= as.Date("2018-02-01")]
print(post_d[, .(
  mean_active = round(mean(active_firms)),
  mean_dissolved = round(mean(dissolved), 1),
  mean_diss_rate = round(mean(dissolution_rate, na.rm = TRUE), 2),
  mean_new = round(mean(new_firms), 1),
  mean_reg_rate = round(mean(registration_rate, na.rm = TRUE), 2)
), by = group][order(-mean_active)])

saveRDS(panel, "../data/panel.rds")
cat("\nPanel saved to data/panel.rds\n")
cat("Detail panel saved to data/detail_panel.rds\n")
