# 04_robustness.R — Robustness checks
# apep_1021: Latvia AML Shell-Company Ban

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
det_panel <- readRDS("../data/detail_panel.rds")

# ============================================================
# 1. Placebo tests: false reform dates
# ============================================================

cat("=== PLACEBO TESTS ===\n")

# Restrict to pre-treatment period only (Jan 2015 - Jan 2018)
pre_only <- panel[ym < as.Date("2018-02-01")]
pre_only[, treated := shell_likely & riga]
pre_only[, group_id := paste0(as.numeric(shell_likely), "_", as.numeric(riga))]

# Placebo 1: False reform in Jan 2016
pre_only[, placebo_2016 := ym >= as.Date("2016-01-01")]
p1 <- feols(dissolution_rate ~ treated:placebo_2016 | group_id + ym,
            data = pre_only, vcov = "hetero")
cat("Placebo 2016:\n")
print(coeftable(p1))

# Placebo 2: False reform in Jan 2017
pre_only[, placebo_2017 := ym >= as.Date("2017-01-01")]
p2 <- feols(dissolution_rate ~ treated:placebo_2017 | group_id + ym,
            data = pre_only, vcov = "hetero")
cat("\nPlacebo 2017:\n")
print(coeftable(p2))

# ============================================================
# 2. Riga vs non-Riga: geographic heterogeneity
# ============================================================

cat("\n=== GEOGRAPHIC HETEROGENEITY ===\n")

# SIA firms only — compare Riga vs non-Riga
sia_only <- panel[shell_likely == TRUE]
sia_only[, group_id := paste0(as.numeric(riga))]

m_geo <- feols(dissolution_rate ~ riga * post | group_id + ym,
               data = sia_only, vcov = "hetero")
cat("SIA firms: Riga vs non-Riga, dissolution rate:\n")
summary(m_geo)

m_geo_reg <- feols(registration_rate ~ riga * post | group_id + ym,
                   data = sia_only, vcov = "hetero")
cat("\nSIA firms: Riga vs non-Riga, registration rate:\n")
summary(m_geo_reg)

# ============================================================
# 3. Firm-type heterogeneity using detailed panel
# ============================================================

cat("\n=== FIRM TYPE HETEROGENEITY ===\n")

# Focus on main categories with enough observations
main_cats <- c("SIA", "AS", "foreign_rep", "IK", "farm", "sole_prop")
det_sub <- det_panel[firm_category %in% main_cats & active_firms > 0]
det_sub[, post := ym >= as.Date("2018-02-01")]
det_sub[, group_id := paste0(firm_category, "_", as.numeric(riga))]

# Run DiD for each firm type in Riga vs non-Riga
for (cat_name in main_cats) {
  cat_data <- det_sub[firm_category == cat_name]
  if (nrow(cat_data) >= 20) {
    m_cat <- feols(dissolution_rate ~ riga * post | group_id + ym,
                   data = cat_data, vcov = "hetero")
    cat(sprintf("\n%s (Riga vs non-Riga):\n", cat_name))
    cat(sprintf("  DiD coef: %.2f (SE: %.2f, p: %.4f)\n",
                coef(m_cat)[grep("riga.*post", names(coef(m_cat)))],
                se(m_cat)[grep("riga.*post", names(se(m_cat)))],
                pvalue(m_cat)[grep("riga.*post", names(pvalue(m_cat)))]))
  }
}

# ============================================================
# 4. Firm age heterogeneity
# ============================================================

cat("\n=== FIRM AGE HETEROGENEITY ===\n")

# Rebuild dissolution counts by firm age cohort
reg <- readRDS("../data/register_parsed.rds")
reg[, firm_category := fcase(
  grepl("Sabiedrība ar ierobežotu", type_text), "SIA",
  grepl("Akciju sabiedrība", type_text), "AS",
  grepl("Ārvalsts komersanta", type_text), "foreign_rep",
  default = "other"
)]
reg[, shell_likely := firm_category %in% c("SIA", "AS", "foreign_rep")]
reg[, riga := (atvk == 10000)]
reg[is.na(riga), riga := FALSE]

# Classify by registration era
reg[, reg_era := fcase(
  registered >= as.Date("2010-01-01"), "post_2010",
  registered >= as.Date("2000-01-01") & registered < as.Date("2010-01-01"), "2000s",
  default = "pre_2000"
)]

# Shell-likely firms only, dissolutions by era
start_date <- as.Date("2015-01-01")
end_date <- as.Date("2021-12-31")
months <- seq(start_date, end_date, by = "month")

shells <- reg[shell_likely == TRUE & registered <= end_date]
shells[, term_month := floor_date(terminated, "month")]

# Dissolution counts by era × riga × month
diss_era <- shells[!is.na(term_month) & term_month >= start_date & term_month <= end_date,
                   .(dissolved = .N),
                   by = .(ym = term_month, reg_era, riga)]

# Active counts by era
active_era <- rbindlist(lapply(months, function(m) {
  m_end <- ceiling_date(m, "month") - days(1)
  act <- shells[registered <= m_end & (is.na(terminated) | terminated > m_end)]
  act[, .(active_firms = .N), by = .(reg_era, riga)][, ym := m]
}))

era_grid <- CJ(ym = months, reg_era = unique(shells$reg_era), riga = c(TRUE, FALSE))
era_panel <- merge(era_grid, diss_era, by = c("ym", "reg_era", "riga"), all.x = TRUE)
era_panel <- merge(era_panel, active_era, by = c("ym", "reg_era", "riga"), all.x = TRUE)
era_panel[is.na(dissolved), dissolved := 0]
era_panel[active_firms > 0, dissolution_rate := (dissolved / active_firms) * 1000]
era_panel[, post := ym >= as.Date("2018-02-01")]
era_panel[, group_id := paste0(reg_era, "_", as.numeric(riga))]

# DiD by era
for (era in c("post_2010", "2000s", "pre_2000")) {
  era_data <- era_panel[reg_era == era & active_firms > 0]
  if (nrow(era_data) >= 20) {
    m_era <- feols(dissolution_rate ~ riga * post | group_id + ym,
                   data = era_data, vcov = "hetero")
    cat(sprintf("\n%s shell firms (Riga vs non-Riga):\n", era))
    rid <- grep("riga.*post", names(coef(m_era)))
    if (length(rid) > 0) {
      cat(sprintf("  DiD coef: %.2f (SE: %.2f, p: %.4f)\n",
                  coef(m_era)[rid], se(m_era)[rid], pvalue(m_era)[rid]))
    }
  }
}

# ============================================================
# 5. Linear trends robustness
# ============================================================

cat("\n=== LINEAR TRENDS ROBUSTNESS ===\n")

panel[, ym_num := as.numeric(ym) / 30]  # Months since origin
panel[, group_id := paste0(as.numeric(shell_likely), "_", as.numeric(riga))]

# With group-specific linear trends
m_trend <- feols(dissolution_rate ~ treated:post + group_id:ym_num | group_id + ym,
                 data = panel, vcov = "hetero")
cat("With group-specific linear trends:\n")
print(coeftable(m_trend))

# ============================================================
# 6. Update diagnostics
# ============================================================

# Proper diagnostics
diag <- list(
  n_treated = 47L,   # 47 post-treatment months for treated group
  n_pre = 37L,       # 37 pre-treatment months
  n_obs = as.integer(nrow(panel)),
  n_active_firms_pre_treated = round(mean(panel[shell_likely == TRUE & riga == TRUE & !post, active_firms])),
  n_active_firms_post_treated = round(mean(panel[shell_likely == TRUE & riga == TRUE & post, active_firms])),
  treatment_date = "2018-02-01",
  outcome = "dissolution_rate_per_1000",
  design = "firm_type_x_geography_DiD"
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# Save robustness models
save(p1, p2, m_geo, m_geo_reg, m_trend,
     file = "../data/robustness_models.RData")

cat("\nRobustness models saved.\n")
cat("Diagnostics updated.\n")
