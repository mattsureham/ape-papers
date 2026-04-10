source("code/00_packages.R")

enoe <- readRDS("data/enoe_combined.rds")
cat(sprintf("Loaded %d observations\n", nrow(enoe)))

if ("clase1" %in% names(enoe)) {
  enoe <- enoe[clase1 == 1]
  cat(sprintf("After restricting to employed (clase1==1): %d\n", nrow(enoe)))
} else if ("clase2" %in% names(enoe)) {
  enoe <- enoe[clase2 == 1]
  cat(sprintf("After restricting to employed (clase2==1): %d\n", nrow(enoe)))
}

enoe[, formal := 0L]
if ("seg_soc" %in% names(enoe)) {
  enoe[seg_soc == 1, formal := 1L]
}

enoe[, post := as.integer(year >= 2023 | (year == 2022 & quarter == 4 & FALSE))]
enoe[, post := as.integer(year > 2022 | (year == 2022 & quarter > 4))]

enoe[, treat_post := formal * post]

if ("hrsocup" %in% names(enoe)) {
  enoe[hrsocup >= 998, hrsocup := NA_real_]
}

if ("ingocup" %in% names(enoe)) {
  enoe[ingocup >= 999998, ingocup := NA_real_]
  enoe[, log_wage := log(ingocup + 1)]
}

if ("eda" %in% names(enoe)) {
  enoe <- enoe[eda >= 15 & eda <= 65]
  cat(sprintf("After age restriction (15-65): %d\n", nrow(enoe)))
}

if ("niv_ins" %in% names(enoe)) {
  enoe[, educ_group := fcase(
    niv_ins %in% c(0, 1, 2), "primary_or_less",
    niv_ins %in% c(3, 4, 5), "secondary",
    niv_ins %in% c(6, 7, 8, 9), "higher",
    default = "other"
  )]
}

if ("rama_est1" %in% names(enoe)) {
  high_inf_sectors <- c(1, 6, 7, 8, 9)
  enoe[, high_inf_sector := as.integer(rama_est1 %in% high_inf_sectors)]
} else if ("rama_est2" %in% names(enoe)) {
  enoe[, high_inf_sector := as.integer(rama_est2 %in% c(1, 6, 7, 8, 9))]
}

if ("dur9c" %in% names(enoe)) {
  enoe[, tenure_years := fcase(
    dur9c == 0, 0,
    dur9c == 1, 0.5,
    dur9c == 2, 1,
    dur9c == 3, 2,
    dur9c == 4, 4,
    dur9c == 5, 8,
    dur9c == 6, 15,
    dur9c == 7, 25,
    dur9c == 8, 35,
    default = NA_real_
  )]
  enoe[, high_dose := as.integer(tenure_years <= 2)]
}

enoe[, state := as.integer(ent)]
enoe[, period := year * 10 + quarter]

enoe[, person_id := paste(cd_a, ent, con, v_sel, n_hog, h_mud, n_ren, sep = "_")]

cat(sprintf("\nFinal analysis sample: %d observations\n", nrow(enoe)))
cat(sprintf("Formal workers: %d (%.1f%%)\n", sum(enoe$formal == 1), 100 * mean(enoe$formal == 1)))
cat(sprintf("Informal workers: %d (%.1f%%)\n", sum(enoe$formal == 0), 100 * mean(enoe$formal == 0)))
cat(sprintf("Pre-reform periods: %d quarters\n", length(unique(enoe[post == 0, period]))))
cat(sprintf("Post-reform periods: %d quarters\n", length(unique(enoe[post == 1, period]))))
cat(sprintf("States: %d\n", length(unique(enoe$state))))

saveRDS(enoe, "data/enoe_analysis.rds")
cat("Saved analysis dataset to data/enoe_analysis.rds\n")
