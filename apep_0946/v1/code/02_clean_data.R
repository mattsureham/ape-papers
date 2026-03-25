# 02_clean_data.R — Construct analysis panel
# apep_0946: EECC transposition and consumer telecom prices

source("00_packages.R")

# ===========================================================================
# 1. Load raw data
# ===========================================================================

hicp <- fread("../data/hicp_raw.csv")
eecc <- fread("../data/eecc_transposition.csv")
broadband <- fread("../data/broadband_raw.csv")

# ===========================================================================
# 2. Construct main analysis panel (CP08 — communications)
# ===========================================================================

# Keep CP08 (main outcome)
cp08 <- hicp[coicop_cat == "CP08", .(geo, year, cp08 = values)]

# Merge with treatment
panel <- merge(cp08, eecc, by = "geo", all.x = TRUE)

# Create treatment indicators
# first_treat: year of treatment (for CS-DiD); 0 = never-treated
panel[, first_treat := fifelse(is.na(transposition_year), 0L, as.integer(transposition_year))]
panel[, post := fifelse(first_treat > 0 & year >= first_treat, 1L, 0L)]

# Create numeric country ID for did package
panel[, country_id := as.integer(factor(geo))]

# Log outcome for elasticity interpretation
panel[, ln_cp08 := log(cp08)]

cat("Main panel:\n")
cat("  Countries:", uniqueN(panel$geo), "\n")
cat("  Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("  Observations:", nrow(panel), "\n")
cat("  Treated countries:", uniqueN(panel[first_treat > 0]$geo), "\n")
cat("  Never-treated countries:", uniqueN(panel[first_treat == 0]$geo), "\n")
cat("\nCohort sizes:\n")
print(panel[, .(n_countries = uniqueN(geo)), by = first_treat][order(first_treat)])

# ===========================================================================
# 3. Construct placebo panels
# ===========================================================================

placebo_panels <- list()
for (coicop_code in c("CP011", "CP07", "CP04")) {
  label <- switch(coicop_code,
    "CP011" = "food",
    "CP07" = "transport",
    "CP04" = "housing"
  )

  dt <- hicp[coicop_cat == coicop_code, .(geo, year, values)]
  setnames(dt, "values", paste0("cp_", label))
  dt <- merge(dt, eecc, by = "geo", all.x = TRUE)
  dt[, first_treat := fifelse(is.na(transposition_year), 0L, as.integer(transposition_year))]
  dt[, country_id := as.integer(factor(geo))]

  placebo_panels[[label]] <- dt
  cat("Placebo panel (", label, "):", nrow(dt), "obs,",
      uniqueN(dt$geo), "countries\n")
}

# ===========================================================================
# 4. Construct broadband panel (secondary outcome)
# ===========================================================================

bb_panel <- broadband[, .(geo, year, broadband = IT.NET.BBND.P2)]
bb_panel <- merge(bb_panel, eecc, by = "geo", all.x = TRUE)
bb_panel[, first_treat := fifelse(is.na(transposition_year), 0L, as.integer(transposition_year))]
bb_panel[, country_id := as.integer(factor(geo))]

cat("\nBroadband panel:", nrow(bb_panel), "obs,",
    uniqueN(bb_panel$geo), "countries\n")

# ===========================================================================
# 5. Summary statistics
# ===========================================================================

cat("\n=== Summary Statistics ===\n")
cat("\nCP08 (Communications CPI) by treatment status:\n")
panel[, .(mean = mean(cp08, na.rm = TRUE),
          sd = sd(cp08, na.rm = TRUE),
          min = min(cp08, na.rm = TRUE),
          max = max(cp08, na.rm = TRUE),
          n = .N),
      by = .(treated = first_treat > 0)] |> print()

cat("\nCP08 pre-treatment (2014-2019) standard deviation:\n")
pre_sd <- panel[year <= 2019, sd(cp08, na.rm = TRUE)]
cat("  SD(Y) =", round(pre_sd, 2), "\n")

# ===========================================================================
# 6. Save analysis panels
# ===========================================================================

fwrite(panel, "../data/panel_main.csv")
fwrite(placebo_panels$food, "../data/panel_placebo_food.csv")
fwrite(placebo_panels$transport, "../data/panel_placebo_transport.csv")
fwrite(placebo_panels$housing, "../data/panel_placebo_housing.csv")
fwrite(bb_panel, "../data/panel_broadband.csv")

cat("\nAll panels saved to data/\n")
