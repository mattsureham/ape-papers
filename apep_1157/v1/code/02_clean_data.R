## 02_clean_data.R — Clean panel and prepare for analysis
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

source("00_packages.R")

panel <- fread("../data/panel.csv")
cat(sprintf("Loaded panel: %d obs, %d municipalities\n", nrow(panel), length(unique(panel$mun_id))))

# Drop municipalities with missing SP enrollment
panel <- panel[!is.na(first_treat)]
cat(sprintf("After dropping NA enrollment: %d obs, %d municipalities\n",
            nrow(panel), length(unique(panel$mun_id))))

# Winsorize extreme mortality rates at 99th percentile
# (small municipalities can have very high rates from few births)
for (v in c("imr", "nmr", "amenable_mr", "non_amenable_mr")) {
  p99 <- quantile(panel[[v]], 0.99, na.rm = TRUE)
  panel[get(v) > p99, (v) := p99]
}

# Create balanced panel indicator
mun_counts <- panel[, .N, by = mun_id]
balanced_muns <- mun_counts[N == 15, mun_id]  # full 1998-2012
panel[, balanced := mun_id %in% balanced_muns]
cat(sprintf("Balanced panel municipalities: %d of %d\n",
            length(balanced_muns), length(unique(panel$mun_id))))

# Create pre-treatment outcome means for heterogeneity analysis
pre_means <- panel[year < 2002, .(
  pre_imr = mean(imr, na.rm = TRUE),
  pre_amenable = mean(amenable_mr, na.rm = TRUE),
  pre_total_deaths = mean(total_deaths, na.rm = TRUE),
  pre_infant_deaths = mean(infant_deaths, na.rm = TRUE)
), by = mun_id]

panel <- merge(panel, pre_means, by = "mun_id", all.x = TRUE)

# High vs low baseline mortality (median split)
med_imr <- median(pre_means$pre_imr, na.rm = TRUE)
panel[, high_baseline_imr := as.integer(pre_imr > med_imr)]

# Population size terciles (based on pre-treatment total deaths as proxy)
panel[, pop_tercile := cut(pre_total_deaths,
                           breaks = quantile(pre_total_deaths, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                           labels = c("Small", "Medium", "Large"),
                           include.lowest = TRUE)]

# State-level fixed effects
panel[, state_num := as.integer(factor(state_code))]

# Summary statistics for paper
cat("\n=== SUMMARY STATISTICS ===\n")

vars <- c("imr", "nmr", "amenable_mr", "non_amenable_mr",
          "infant_deaths", "amenable_deaths", "non_amenable_deaths",
          "total_deaths", "est_pop")
summ_list <- lapply(vars, function(v) {
  data.table(
    Variable = v,
    Mean = mean(panel[[v]], na.rm = TRUE),
    SD = sd(panel[[v]], na.rm = TRUE),
    Min = min(panel[[v]], na.rm = TRUE),
    P25 = quantile(panel[[v]], 0.25, na.rm = TRUE),
    Median = median(panel[[v]], na.rm = TRUE),
    P75 = quantile(panel[[v]], 0.75, na.rm = TRUE),
    Max = max(panel[[v]], na.rm = TRUE)
  )
})
summ <- rbindlist(summ_list)
print(summ, digits = 2)

# Save cleaned panel
fwrite(panel, "../data/panel_clean.csv")
cat(sprintf("\nCleaned panel saved: %d obs, %d municipalities\n",
            nrow(panel), length(unique(panel$mun_id))))
