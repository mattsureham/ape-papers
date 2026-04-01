# 02_clean_data.R — Clean and prepare analysis datasets
# Paper: The Growth Ceiling (apep_1264)
source("code/00_packages.R")

data_dir <- "data"

# ===========================================================================
# 1) Load STATENT workplace-level data (Table 109)
# ===========================================================================
cat("=== Loading STATENT workplace data ===\n")
df_ws <- fread(file.path(data_dir, "statent_canton_size.csv"))

# Create clean variable names
df_ws[, year := as.integer(Jahr)]
df_ws[, canton_id := as.integer(Kanton)]
df_ws[, size_class := as.integer(`Grössenklasse`)]
df_ws[, variable := as.integer(Beobachtungseinheit)]

# Size class labels
size_labels <- c("1" = "1-9", "2" = "10-49", "3" = "50-249", "4" = "250+", "999" = "Total")
df_ws[, size_label := size_labels[as.character(size_class)]]

# Variable labels (from metadata)
var_labels <- c(
  "1" = "n_workplaces", "2" = "n_employed", "3" = "n_women",
  "4" = "n_men", "5" = "fte", "6" = "fte_women", "7" = "fte_men"
)
df_ws[, var_name := var_labels[as.character(variable)]]

# Canton labels
canton_map <- c(
  "999" = "Switzerland", "1" = "Zurich", "2" = "Bern", "3" = "Luzern",
  "4" = "Uri", "5" = "Schwyz", "6" = "Obwalden", "7" = "Nidwalden",
  "8" = "Glarus", "9" = "Zug", "10" = "Fribourg", "11" = "Solothurn",
  "12" = "Basel-Stadt", "13" = "Basel-Land", "14" = "Schaffhausen",
  "15" = "AR", "16" = "AI", "17" = "St.Gallen",
  "18" = "Graubuenden", "19" = "Aargau", "20" = "Thurgau",
  "21" = "Ticino", "22" = "Vaud", "23" = "Valais",
  "24" = "Neuchatel", "25" = "Geneva", "26" = "Jura"
)
df_ws[, canton_name := canton_map[as.character(canton_id)]]

# Drop total-Switzerland row for panel analyses (keep for national-level)
df_cantons <- df_ws[canton_id != 999 & size_class != 999]
df_national <- df_ws[canton_id == 999 & size_class != 999]

cat("Canton-level observations:", nrow(df_cantons), "\n")
cat("National-level observations:", nrow(df_national), "\n")
cat("Years:", paste(sort(unique(df_cantons$year)), collapse=", "), "\n")
cat("Cantons:", length(unique(df_cantons$canton_id)), "\n")

# ===========================================================================
# 2) Reshape to wide format: one row per canton-year-size_class
# ===========================================================================
panel <- dcast(df_cantons,
               year + canton_id + canton_name + size_class + size_label ~ var_name,
               value.var = "value")

# Compute derived variables
panel[, avg_emp := n_employed / n_workplaces]  # Average employees per workplace
panel[, female_share := n_women / n_employed]   # Female employment share
panel[, avg_fte := fte / n_workplaces]          # Average FTE per workplace

cat("\nPanel dimensions:", nrow(panel), "rows\n")
cat("Panel structure: canton × year × size_class\n")
cat("  Cantons:", length(unique(panel$canton_id)), "\n")
cat("  Years:", length(unique(panel$year)), "\n")
cat("  Size classes:", length(unique(panel$size_class)), "\n")

# ===========================================================================
# 3) Same for national level
# ===========================================================================
national <- dcast(df_national,
                  year + size_class + size_label ~ var_name,
                  value.var = "value")
national[, avg_emp := n_employed / n_workplaces]
national[, female_share := n_women / n_employed]
national[, avg_fte := fte / n_workplaces]

# ===========================================================================
# 4) Create treatment indicators
# ===========================================================================
# GEA effective July 2020 — affects 100+ employee firms
# In our data: the 50-249 bin contains both treated (100-249) and untreated (50-99)
# The 10-49 bin is fully untreated; the 250+ bin is also treated by GEA

panel[, post_gea := as.integer(year >= 2020)]
panel[, medium := as.integer(size_class == 3)]  # 50-249 bin
panel[, large := as.integer(size_class == 4)]    # 250+ bin

# Bin × post interactions
panel[, medium_post := medium * post_gea]
panel[, large_post := large * post_gea]

national[, post_gea := as.integer(year >= 2020)]
national[, medium := as.integer(size_class == 3)]

# ===========================================================================
# 5) Create ratio variables at the canton-year level
# ===========================================================================
# Ratio of adjacent bins reveals cross-threshold dynamics
ratio_data <- dcast(panel, year + canton_id + canton_name + post_gea ~ size_label,
                    value.var = "n_workplaces")

setnames(ratio_data, c("1-9", "10-49", "50-249", "250+"),
         c("n_micro", "n_small", "n_medium", "n_large"))

# Key ratios
ratio_data[, ratio_small_medium := n_small / n_medium]    # 10-49 / 50-249
ratio_data[, ratio_medium_large := n_medium / n_large]    # 50-249 / 250+
ratio_data[, share_medium := n_medium / (n_micro + n_small + n_medium + n_large)]
ratio_data[, log_n_medium := log(n_medium)]
ratio_data[, log_n_small := log(n_small)]

# Also get avg employment in each size bin (canton-year)
avg_data <- dcast(panel, year + canton_id + canton_name + post_gea ~ size_label,
                  value.var = "avg_emp")
setnames(avg_data, c("1-9", "10-49", "50-249", "250+"),
         c("avg_micro", "avg_small", "avg_medium", "avg_large"))

# Female share by bin
fem_data <- dcast(panel, year + canton_id + canton_name + post_gea ~ size_label,
                  value.var = "female_share")
setnames(fem_data, c("1-9", "10-49", "50-249", "250+"),
         c("fem_micro", "fem_small", "fem_medium", "fem_large"))

# Merge
canton_year <- merge(ratio_data, avg_data[, .(year, canton_id, avg_micro, avg_small, avg_medium, avg_large)],
                     by = c("year", "canton_id"))
canton_year <- merge(canton_year, fem_data[, .(year, canton_id, fem_micro, fem_small, fem_medium, fem_large)],
                     by = c("year", "canton_id"))

cat("\nCanton-year panel:", nrow(canton_year), "observations\n")
cat("  (26 cantons × 13 years =", 26*13, "expected)\n")

# ===========================================================================
# 6) Load enterprise-level data (Table 107) for robustness
# ===========================================================================
cat("\n=== Loading enterprise data (Table 107) ===\n")
df_ent <- fread(file.path(data_dir, "statent_enterprises_size.csv"))
df_ent[, year := as.integer(Jahr)]
df_ent[, canton_id := as.integer(Kanton)]
df_ent[, size_class := as.integer(`Grössenklasse`)]
df_ent[, variable := as.integer(Beobachtungseinheit)]
df_ent[, var_name := var_labels[as.character(variable)]]
df_ent[, size_label := size_labels[as.character(size_class)]]

# Enterprise counts and employment by size class
ent_panel <- dcast(df_ent[canton_id != 999 & size_class != 999],
                   year + canton_id + size_class + size_label ~ var_name,
                   value.var = "value")
ent_panel[, avg_emp := n_employed / n_workplaces]
ent_panel[, female_share := n_women / n_employed]

# ===========================================================================
# 7) Load UDEMO data for entry dynamics
# ===========================================================================
cat("=== Loading UDEMO data ===\n")
df_udemo <- fread(file.path(data_dir, "udemo_industry_size.csv"))
df_udemo[, year := as.integer(Jahr)]
df_udemo[, industry := as.character(Wirtschaftsabteilung)]
df_udemo[, size_class := as.integer(`Grössenklasse`)]
df_udemo[, variable := as.integer(Beobachtungseinheit)]

udemo_labels <- c(
  "1" = "stock", "2" = "births", "3" = "closures",
  "4" = "stock_emp", "5" = "birth_emp", "6" = "closure_emp"
)
df_udemo[, var_name := udemo_labels[as.character(variable)]]

cat("UDEMO observations:", nrow(df_udemo), "\n")

# ===========================================================================
# 8) Validation checks
# ===========================================================================
cat("\n=== Validation ===\n")

# Check national totals are reasonable
nat_2023 <- national[year == 2023]
cat("Switzerland 2023:\n")
for (sc in c("1-9", "10-49", "50-249", "250+")) {
  row <- nat_2023[size_label == sc]
  cat(sprintf("  %6s: %6.0f workplaces, %8.0f employed, avg %.1f emp/firm\n",
              sc, row$n_workplaces, row$n_employed, row$avg_emp))
}

# Smoke test: medium firms should be ~9,000-10,000 (from idea manifest)
n_med_2023 <- nat_2023[size_label == "50-249", n_workplaces]
cat("\nMedium firms (50-249) in 2023:", n_med_2023, "\n")
stopifnot(n_med_2023 > 5000 & n_med_2023 < 20000)  # Sanity check

# ===========================================================================
# 9) Save analysis-ready datasets
# ===========================================================================
fwrite(panel, file.path(data_dir, "panel_canton_size_year.csv"))
fwrite(canton_year, file.path(data_dir, "panel_canton_year.csv"))
fwrite(national, file.path(data_dir, "national_size_year.csv"))
fwrite(ent_panel, file.path(data_dir, "enterprise_panel.csv"))

cat("\n=== Saved analysis datasets ===\n")
cat("  panel_canton_size_year.csv:", nrow(panel), "rows (canton × year × size)\n")
cat("  panel_canton_year.csv:", nrow(canton_year), "rows (canton × year)\n")
cat("  national_size_year.csv:", nrow(national), "rows (year × size)\n")
cat("  enterprise_panel.csv:", nrow(ent_panel), "rows (canton × year × size)\n")
