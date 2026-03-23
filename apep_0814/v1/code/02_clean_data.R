## 02_clean_data.R — Build municipality-year panel
## APEP paper apep_0814: El Salvador gang removal and homicide geography

source("00_packages.R")

data_dir <- "../data"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Load raw data
# ─────────────────────────────────────────────────────────────────────────────
hom_df <- fread(file.path(data_dir, "homicide_rates.csv"), encoding = "Latin-1")
gang_df <- fread(file.path(data_dir, "gang_detentions.csv"), encoding = "Latin-1")
pop_df <- fread(file.path(data_dir, "population.csv"), encoding = "Latin-1")

# Fix encoding: convert Latin-1 strings to UTF-8
fix_encoding <- function(dt) {
  char_cols <- names(dt)[sapply(dt, is.character)]
  for (col in char_cols) {
    dt[[col]] <- iconv(dt[[col]], from = "latin1", to = "UTF-8")
  }
  dt
}
hom_df <- fix_encoding(hom_df)
gang_df <- fix_encoding(gang_df)
pop_df <- fix_encoding(pop_df)

setnames(hom_df, c("time", "hom_rate"), c("year", "hom_rate_10k"))

message("Homicide data: ", nrow(hom_df), " rows, years: ",
        min(hom_df$year), "-", max(hom_df$year))
message("Gang detentions: ", nrow(gang_df), " rows")
message("Population: ", nrow(pop_df), " rows")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Compute gang intensity per municipality
# ─────────────────────────────────────────────────────────────────────────────
g_cols <- grep("^G", names(gang_df), value = TRUE)
gang_df[, total_detentions := rowSums(.SD, na.rm = TRUE), .SDcols = g_cols]
gang_df[, mean_annual_detentions := total_detentions / length(g_cols)]

# Get population from pop_df (use POB2018 as baseline)
pop_df[, pop_2018 := POB2018]

# Fuzzy merge: normalize municipality names for matching
normalize_name <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[áà]", "a", x)
  x <- gsub("[éè]", "e", x)
  x <- gsub("[íì]", "i", x)
  x <- gsub("[óò]", "o", x)
  x <- gsub("[úùü]", "u", x)
  x <- gsub("[ñ]", "n", x)
  x
}

gang_df[, name_norm := normalize_name(NAME_2)]
pop_df[, name_norm := normalize_name(NAME_2)]

# Merge population into gang data
gang_pop <- merge(gang_df, pop_df[, .(name_norm, pop_2018)],
                  by = "name_norm", all.x = TRUE)

# For remaining NAs, try matching by department + municipality
if (any(is.na(gang_pop$pop_2018))) {
  n_missing <- sum(is.na(gang_pop$pop_2018))
  message("Population missing for ", n_missing, " municipalities after name merge")
  # Use median population as fallback for missing
  median_pop <- median(gang_pop$pop_2018, na.rm = TRUE)
  gang_pop[is.na(pop_2018), pop_2018 := median_pop]
  message("  Filled with median population: ", round(median_pop))
}

# Gang detention rate per 100K population
gang_pop[, gang_rate := (mean_annual_detentions) / (pop_2018 / 1e5)]
gang_pop[is.infinite(gang_rate) | is.nan(gang_rate), gang_rate := 0]

# Quintiles
gang_pop[, gang_quintile := cut(gang_rate,
                                 breaks = quantile(gang_rate, probs = 0:5/5,
                                                   na.rm = TRUE),
                                 labels = 1:5, include.lowest = TRUE)]
gang_pop[, gang_quintile := as.integer(gang_quintile)]

message("\n=== Gang detention rate per 100K ===")
message("  N: ", sum(!is.na(gang_pop$gang_rate)))
message("  Mean: ", round(mean(gang_pop$gang_rate, na.rm = TRUE), 1))
message("  Median: ", round(median(gang_pop$gang_rate, na.rm = TRUE), 1))
message("  SD: ", round(sd(gang_pop$gang_rate, na.rm = TRUE), 1))
message("  P10: ", round(quantile(gang_pop$gang_rate, 0.1, na.rm = TRUE), 1))
message("  P90: ", round(quantile(gang_pop$gang_rate, 0.9, na.rm = TRUE), 1))

# ─────────────────────────────────────────────────────────────────────────────
# 3. Build panel: merge homicide + gang intensity
# ─────────────────────────────────────────────────────────────────────────────
hom_df[, name_norm := normalize_name(NAME_2)]

# Gang intensity is time-invariant: merge by municipality name
gang_vars <- gang_pop[, .(name_norm, gang_rate, gang_quintile,
                           total_detentions, pop_2018, NAME_1)]
# Deduplicate (in case of name collisions)
gang_vars <- gang_vars[!duplicated(name_norm)]

panel <- merge(hom_df, gang_vars, by = "name_norm", all.x = TRUE,
               suffixes = c("", ".gang"))

# Use NAME_1 from gang data for department
if ("NAME_1.gang" %in% names(panel)) {
  panel[is.na(NAME_1), NAME_1 := NAME_1.gang]
  panel[, NAME_1.gang := NULL]
}

message("\n=== Merge result ===")
message("Panel rows: ", nrow(panel))
message("Gang rate non-missing: ", sum(!is.na(panel$gang_rate)),
        " / ", nrow(panel))

# ─────────────────────────────────────────────────────────────────────────────
# 4. Construct variables
# ─────────────────────────────────────────────────────────────────────────────
# Treatment
panel[, post := as.integer(year >= 2019)]

# Log outcome
panel[, ln_hom := log(hom_rate_10k + 1)]

# Event time
panel[, rel_year := year - 2019]

# Standardized gang rate (for one-SD interpretation)
panel[, gang_rate_std := (gang_rate - mean(gang_rate, na.rm = TRUE)) /
        sd(gang_rate, na.rm = TRUE)]

# Municipality numeric ID
panel[, muni_id := as.integer(as.factor(name_norm))]

# Department factor
panel[, dept := as.factor(NAME_1)]

# Alternative intensity: 2015 homicide rate (peak year)
peak_2015 <- panel[year == 2015, .(name_norm, hom_2015 = hom_rate_10k)]
panel <- merge(panel, peak_2015, by = "name_norm", all.x = TRUE)

# High gang dummy (above median)
panel[, high_gang := as.integer(gang_rate > median(gang_rate, na.rm = TRUE))]

# ─────────────────────────────────────────────────────────────────────────────
# 5. Summary statistics
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Panel summary ===")
message("Observations: ", nrow(panel))
message("Municipalities: ", length(unique(panel$muni_id)))
message("Years: ", min(panel$year), " - ", max(panel$year))
message("Departments: ", length(unique(panel$dept)))

message("\n--- Homicide rate per 10K ---")
message("  Overall mean: ", round(mean(panel$hom_rate_10k, na.rm = TRUE), 2))
message("  Pre-2019 mean: ", round(mean(panel[post == 0]$hom_rate_10k, na.rm = TRUE), 2))
message("  Post-2019 mean: ", round(mean(panel[post == 1]$hom_rate_10k, na.rm = TRUE), 2))
message("  SD: ", round(sd(panel$hom_rate_10k, na.rm = TRUE), 2))

message("\n--- By gang quintile (post-2019 homicide rate) ---")
for (q in 1:5) {
  msg <- round(mean(panel[gang_quintile == q & post == 1]$hom_rate_10k,
                     na.rm = TRUE), 2)
  message("  Q", q, ": ", msg)
}

# Validate
stopifnot("Panel has data" = nrow(panel) > 4000)
stopifnot("Gang rate matched" = sum(!is.na(panel$gang_rate)) > 4000)
stopifnot("Multiple years" = length(unique(panel$year)) == 20)

fwrite(panel, file.path(data_dir, "panel.csv"))
message("\nPanel saved: ", nrow(panel), " rows")
