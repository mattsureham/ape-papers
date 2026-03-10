#' 03b_employment_eventstudy.R — Employment event study for main finding
#' The significant DDD result is on employment, so we need its event study

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

# Employment event study
panel[, chem_micro := as.integer(nace_r2 == "C20") * micro_share_pre]

es_emp <- feols(ln_employment ~ i(year, chem_micro, ref = 2017) +
                  i(year, chem, ref = 2017) |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

# Extract employment event study coefficients
es_coefs <- as.data.table(coeftable(es_emp))
es_coefs[, term := rownames(coeftable(es_emp))]
es_ddd <- es_coefs[grepl("chem_micro", term)]
es_ddd[, year := as.integer(gsub("year::(\\d+):chem_micro", "\\1", term))]
es_ddd[, rel_year := year - 2018]
setnames(es_ddd, c("Estimate", "Std. Error"), c("estimate", "se"))
es_ddd[, `:=`(ci_lower = estimate - 1.96 * se, ci_upper = estimate + 1.96 * se)]

# Add reference year
es_ddd <- rbind(es_ddd, data.table(
  estimate = 0, se = 0, ci_lower = 0, ci_upper = 0,
  term = "ref", year = 2017, rel_year = -1
), fill = TRUE)
es_ddd <- es_ddd[order(year)]

fwrite(es_ddd[, .(year, rel_year, estimate, se, ci_lower, ci_upper)],
       paste0(data_dir, "event_study_employment.csv"))

# Also do turnover event study
es_turn <- feols(ln_turnover ~ i(year, chem_micro, ref = 2017) +
                   i(year, chem, ref = 2017) |
                   cs_id + cy_id + sy_id,
                 data = panel, cluster = ~geo)

es_coefs_t <- as.data.table(coeftable(es_turn))
es_coefs_t[, term := rownames(coeftable(es_turn))]
es_ddd_t <- es_coefs_t[grepl("chem_micro", term)]
es_ddd_t[, year := as.integer(gsub("year::(\\d+):chem_micro", "\\1", term))]
es_ddd_t[, rel_year := year - 2018]
setnames(es_ddd_t, c("Estimate", "Std. Error"), c("estimate", "se"))
es_ddd_t[, `:=`(ci_lower = estimate - 1.96 * se, ci_upper = estimate + 1.96 * se)]
es_ddd_t <- rbind(es_ddd_t, data.table(
  estimate = 0, se = 0, ci_lower = 0, ci_upper = 0,
  term = "ref", year = 2017, rel_year = -1
), fill = TRUE)
es_ddd_t <- es_ddd_t[order(year)]

fwrite(es_ddd_t[, .(year, rel_year, estimate, se, ci_lower, ci_upper)],
       paste0(data_dir, "event_study_turnover.csv"))

cat("Employment event study saved.\n")
cat("Employment ES coefficients:\n")
print(es_ddd[, .(year, estimate = round(estimate, 4), se = round(se, 4))])
