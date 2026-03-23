# 02_clean_data.R — Construct analysis panel
source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. LSE: Compute gender wage gap by NOGA division x year
# ============================================================

cat("=== Cleaning LSE wage data ===\n")
lse <- fread(file.path(data_dir, "lse_wages.csv"))
cat(sprintf("LSE raw: %d rows\n", nrow(lse)))

setnames(lse, c("year", "region", "noga_div", "position", "gender", "percentile", "wage"))

# Filter: national level, total position, median
lse <- lse[region == "Schweiz" & position == "Berufliche Stellung - Total" &
             percentile == "Zentralwert"]

# Create gender indicator
lse[, gender_code := fifelse(grepl("Frauen|Frau", gender), "female",
                     fifelse(grepl("Männer|Mann", gender), "male", "total"))]

lse[, year := as.integer(year)]

# Pivot wider
lse_wide <- data.table::dcast(lse, noga_div + year ~ gender_code, value.var = "wage")
setDT(lse_wide)

# Compute gender wage gap
lse_wide[, gender_gap := (male - female) / male]
lse_wide[, log_gap := log(male) - log(female)]

# Drop total economy row
lse_wide <- lse_wide[noga_div != "Wirtschaftsabteilung - Total"]

cat(sprintf("LSE cleaned: %d NOGA divisions, years %d-%d\n",
            uniqueN(lse_wide$noga_div), min(lse_wide$year), max(lse_wide$year)))

# Show sample gender gaps
cat("\nSample gender gaps (2018):\n")
print(lse_wide[year == 2018][order(-gender_gap)][1:10, .(noga_div, male, female, gender_gap)])

# Pre-treatment gender gap (2018)
pre_gap <- lse_wide[year == 2018, .(noga_div, pre_gender_gap = gender_gap, pre_log_gap = log_gap)]
cat(sprintf("\nPre-treatment gap (2018): %d industries\n", nrow(pre_gap)))
cat(sprintf("  Mean gap: %.3f, SD: %.3f, Min: %.3f, Max: %.3f\n",
            mean(pre_gap$pre_gender_gap, na.rm = TRUE),
            sd(pre_gap$pre_gender_gap, na.rm = TRUE),
            min(pre_gap$pre_gender_gap, na.rm = TRUE),
            max(pre_gap$pre_gender_gap, na.rm = TRUE)))

fwrite(lse_wide, file.path(data_dir, "lse_clean.csv"))
fwrite(pre_gap, file.path(data_dir, "pre_treatment_gap.csv"))

# ============================================================
# 2. STATENT: Construct canton x NOGA x year panel
# ============================================================

cat("\n=== Cleaning STATENT data ===\n")
statent <- fread(file.path(data_dir, "statent_canton_noga.csv"))
cat(sprintf("STATENT raw: %d rows\n", nrow(statent)))

setnames(statent, c("year", "canton", "noga_div", "obs_unit", "value"))
statent[, year := as.integer(year)]

cat("Observation units:\n")
print(unique(statent$obs_unit))

# Pivot wider
statent_wide <- data.table::dcast(statent, canton + noga_div + year ~ obs_unit, value.var = "value")
setDT(statent_wide)

cat("Columns after pivot:\n")
print(names(statent_wide))

# Rename columns to short names
cn <- names(statent_wide)
name_map <- c(
  "Arbeitsstätten" = "establishments",
  "Beschäftigte" = "employees",
  "Beschäftigte Frauen" = "employees_f",
  "Beschäftigte Männer" = "employees_m",
  "Vollzeitäquivalente" = "fte",
  "Vollzeitäquivalente Frauen" = "fte_f",
  "Vollzeitäquivalente Männer" = "fte_m"
)
for (old in names(name_map)) {
  if (old %in% cn) setnames(statent_wide, old, name_map[old])
}

# Drop total rows
statent_wide <- statent_wide[canton != "Schweiz" & !grepl("Total", noga_div)]

# Compute derived variables
statent_wide[, female_share := employees_f / employees]
statent_wide[, avg_size := employees / establishments]
statent_wide[, log_emp := log(employees + 1)]
statent_wide[, log_est := log(establishments + 1)]
statent_wide[, log_fte := log(fte + 1)]

cat(sprintf("STATENT cleaned: %d cantons, %d NOGA divisions, years %d-%d\n",
            uniqueN(statent_wide$canton), uniqueN(statent_wide$noga_div),
            min(statent_wide$year), max(statent_wide$year)))
cat(sprintf("  Total rows: %d\n", nrow(statent_wide)))

fwrite(statent_wide, file.path(data_dir, "statent_clean.csv"))

# ============================================================
# 3. Match NOGA codes between LSE and STATENT
# ============================================================

cat("\n=== Matching NOGA codes ===\n")

# Extract 2-digit NOGA code from labels
# LSE format: "> 10 Herstellung von..." — number after "> "
# STATENT format: "10 Herstellung von..." — number at start
pre_gap[, noga_code := str_extract(noga_div, "[0-9]+")]
statent_wide[, noga_code := str_extract(noga_div, "^[0-9]+")]

# Check overlap
lse_codes <- unique(pre_gap$noga_code[!is.na(pre_gap$noga_code)])
st_codes <- unique(statent_wide$noga_code[!is.na(statent_wide$noga_code)])
matched <- intersect(lse_codes, st_codes)
cat(sprintf("LSE codes: %d, STATENT codes: %d, Matched: %d\n",
            length(lse_codes), length(st_codes), length(matched)))

# Deduplicate pre_gap on noga_code (some composite codes like "4.99" → "4")
pre_gap_unique <- pre_gap[, .(pre_gender_gap = mean(pre_gender_gap, na.rm = TRUE),
                               pre_log_gap = mean(pre_log_gap, na.rm = TRUE)),
                           by = noga_code]

# Merge
panel <- merge(statent_wide, pre_gap_unique,
               by = "noga_code", all.x = TRUE)
setDT(panel)

cat(sprintf("Merged panel: %d rows (%d with gap data, %.0f%%)\n",
            nrow(panel), sum(!is.na(panel$pre_gender_gap)),
            100 * mean(!is.na(panel$pre_gender_gap))))

# Treatment variables
panel[, post := as.integer(year >= 2020)]
panel[, treat_intensity := pre_gender_gap * post]

# Fixed effect IDs
panel[, canton_noga := paste(canton, noga_code, sep = "_")]

# Median split for binary treatment
med_gap <- median(pre_gap$pre_gender_gap, na.rm = TRUE)
panel[, high_gap := as.integer(pre_gender_gap > med_gap)]
panel[, high_gap_post := high_gap * post]

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# 4. Clean STATENT size class data
# ============================================================

cat("\n=== Cleaning size class data ===\n")
size <- fread(file.path(data_dir, "statent_sizeclass.csv"))
setnames(size, c("year", "canton", "size_class", "obs_unit", "value"))
size[, year := as.integer(year)]

cat("Size classes:\n")
print(unique(size$size_class))

size_est <- size[obs_unit == "Arbeitsstätten" & canton != "Schweiz" &
                   size_class != "Grössenklasse - Total"]

size_wide <- data.table::dcast(size_est, canton + year ~ size_class, value.var = "value")
setDT(size_wide)
cat(sprintf("Size class panel: %d rows\n", nrow(size_wide)))

fwrite(size_wide, file.path(data_dir, "sizeclass_panel.csv"))

# ============================================================
# 5. Summary statistics
# ============================================================

cat("\n=== ANALYSIS SAMPLE SUMMARY ===\n")
p <- panel[!is.na(pre_gender_gap)]

cat(sprintf("Cantons: %d\n", uniqueN(p$canton)))
cat(sprintf("NOGA divisions: %d\n", uniqueN(p$noga_code)))
cat(sprintf("Years: %d-%d (%d years)\n", min(p$year), max(p$year), uniqueN(p$year)))
cat(sprintf("Canton x NOGA cells: %d\n", uniqueN(p$canton_noga)))
cat(sprintf("Total observations: %d\n", nrow(p)))
cat(sprintf("Pre-treatment gap: mean=%.3f, sd=%.3f\n",
            mean(p$pre_gender_gap), sd(p$pre_gender_gap)))
cat(sprintf("Female share: mean=%.3f, sd=%.3f\n",
            mean(p$female_share, na.rm = TRUE), sd(p$female_share, na.rm = TRUE)))
cat(sprintf("Avg establishment size: mean=%.1f, sd=%.1f\n",
            mean(p$avg_size, na.rm = TRUE), sd(p$avg_size, na.rm = TRUE)))

cat("\nData cleaning complete.\n")
