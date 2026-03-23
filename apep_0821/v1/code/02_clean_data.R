## 02_clean_data.R — Construct analysis panel
## Paper: The Bureaucrat's Bonus (apep_0821)

source("code/00_packages.R")

## --- Load processed data ---
ec05 <- fread("data/ec05_pc11_district.csv")
dmsp <- fread("data/dmsp_district.csv")
pca11 <- fread("data/pca11_district.csv")
td11 <- fread("data/td11_district.csv")
ec13 <- fread("data/ec13_district.csv")

## --- Construct treatment variable ---
# GovEmpShare = government employment / total employment (EC 2005)
ec05[, gov_emp_share := ec05_emp_gov / ec05_emp_all]
ec05[is.nan(gov_emp_share) | is.infinite(gov_emp_share), gov_emp_share := NA]

cat(sprintf("Treatment variable (gov_emp_share): mean=%.3f, sd=%.3f, N=%d\n",
            mean(ec05$gov_emp_share, na.rm = TRUE),
            sd(ec05$gov_emp_share, na.rm = TRUE),
            sum(!is.na(ec05$gov_emp_share))))

## --- Restrict DMSP to analysis window 2004-2013, average across satellite versions ---
dmsp_sub <- dmsp[year >= 2003 & year <= 2013]
panel <- dmsp_sub[, .(dmsp_total_light_cal = mean(dmsp_total_light_cal, na.rm = TRUE),
                       dmsp_mean_light_cal = mean(dmsp_mean_light_cal, na.rm = TRUE)),
                   by = .(pc11_state_id, pc11_district_id, year)]
cat(sprintf("DMSP panel (2004-2013, averaged across satellites): %d district-years\n", nrow(panel)))

## --- Merge treatment ---
panel <- merge(panel, ec05[, .(pc11_state_id, pc11_district_id, gov_emp_share,
                                ec05_emp_gov, ec05_emp_all, ec05_emp_priv,
                                ec05_count_all)],
               by = c("pc11_state_id", "pc11_district_id"),
               all.x = FALSE)
cat(sprintf("After merge with EC05: %d district-years\n", nrow(panel)))

## --- Merge controls from Census 2011 ---
pca11_vars <- pca11[, .(pc11_state_id, pc11_district_id,
                         pop = pc11_pca_tot_p,
                         workers = pc11_pca_tot_work_p,
                         literacy = pc11_pca_p_lit)]

# Handle column name variations
if (!"pc11_pca_tot_p" %in% names(pca11)) {
  # Try alternate names
  pop_col <- grep("tot_p$", names(pca11), value = TRUE)[1]
  work_col <- grep("tot_work", names(pca11), value = TRUE)[1]
  lit_col <- grep("p_lit$", names(pca11), value = TRUE)[1]
  pca11_vars <- pca11[, .SD, .SDcols = c("pc11_state_id", "pc11_district_id")]
  if (!is.na(pop_col)) pca11_vars[, pop := pca11[[pop_col]]]
  if (!is.na(work_col)) pca11_vars[, workers := pca11[[work_col]]]
  if (!is.na(lit_col)) pca11_vars[, literacy := pca11[[lit_col]]]
}

panel <- merge(panel, pca11_vars,
               by = c("pc11_state_id", "pc11_district_id"),
               all.x = TRUE)

## --- Construct outcome variables ---
# Inverse hyperbolic sine (handles zeros, approximately log for large values)
panel[, asinh_light := asinh(dmsp_total_light_cal)]
panel[, log_light := log(dmsp_total_light_cal + 1)]

## --- Construct DiD variables ---
panel[, post := as.integer(year >= 2008)]
panel[, treat_x_post := gov_emp_share * post]

## --- Event-study indicators ---
panel[, event_time := year - 2007]  # Base year = 2007
for (k in c(-4:-1, 1:6)) {
  vname <- paste0("et_", ifelse(k < 0, "m", "p"), abs(k))
  panel[, (vname) := gov_emp_share * as.integer(event_time == k)]
}

## --- Quintile treatment groups (for visualization) ---
panel[, treat_q := cut(gov_emp_share,
                        breaks = quantile(gov_emp_share, probs = 0:5/5, na.rm = TRUE),
                        labels = paste0("Q", 1:5),
                        include.lowest = TRUE)]

## --- Private sector placebo treatment ---
panel[, priv_emp_share := ec05_emp_priv / ec05_emp_all]
panel[is.nan(priv_emp_share) | is.infinite(priv_emp_share), priv_emp_share := NA]
panel[, priv_x_post := priv_emp_share * post]

## --- District and state-year FEs ---
panel[, district_id := paste0(pc11_state_id, "_", pc11_district_id)]
panel[, state_year := paste0(pc11_state_id, "_", year)]

## --- Log population control ---
panel[, log_pop := log(pop + 1)]

## --- Drop missing treatment ---
panel <- panel[!is.na(gov_emp_share)]

cat(sprintf("\n=== Final panel ===\n"))
cat(sprintf("Districts: %d\n", uniqueN(panel$district_id)))
cat(sprintf("Years: %d (%d-%d)\n", uniqueN(panel$year), min(panel$year), max(panel$year)))
cat(sprintf("District-years: %d\n", nrow(panel)))
cat(sprintf("Treatment (gov_emp_share): mean=%.3f, sd=%.3f\n",
            mean(panel$gov_emp_share), sd(panel$gov_emp_share)))
cat(sprintf("Outcome (log_light): mean=%.3f, sd=%.3f\n",
            mean(panel$log_light, na.rm = TRUE), sd(panel$log_light, na.rm = TRUE)))

## --- Save analysis panel ---
fwrite(panel, "data/analysis_panel.csv")
cat("Saved: data/analysis_panel.csv\n")
