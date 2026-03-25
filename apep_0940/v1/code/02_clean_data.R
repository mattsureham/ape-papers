## 02_clean_data.R — Construct municipality-year panel
## Denmark Parallel Society Designation and Displacement (apep_0940)

library(data.table)

cat("=== Cleaning data for apep_0940 ===\n")

# -------------------------------------------------------------------
# 1. Load raw data
# -------------------------------------------------------------------
folk1e <- fread("data/folk1e_raw.csv")
ras200 <- fread("data/ras200_raw.csv")
mun_treatment <- fread("data/mun_treatment.csv")

# -------------------------------------------------------------------
# 2. Clean FOLK1E: population by municipality x ancestry x Q1
# -------------------------------------------------------------------
# Rename columns for clarity
setnames(folk1e, c("OMRÅDE", "KØN", "ALDER", "HERKOMST", "TID", "INDHOLD"),
         c("mun_name", "sex", "age", "ancestry", "time", "pop"))

# Remove aggregate rows ("All Denmark", region rows)
# Keep only 3-digit municipality codes in mun_name
# Actually mun_name is the text label. We need to get the code.
# Since we fetched by mun_code, the OMRÅDE column has municipality names.
# We need to re-fetch with codes or map names to codes.

# Get municipality code mapping
cat("Building municipality code mapping...\n")
library(httr)
library(jsonlite)
resp_info <- GET("https://api.statbank.dk/v1/tableinfo/FOLK1E?lang=en")
mun_info <- fromJSON(content(resp_info, "text", encoding = "UTF-8"))
omraade_vals <- mun_info$variables$values[[1]]
mun_map <- data.table(mun_name = omraade_vals$text, mun_code = omraade_vals$id)
mun_map <- mun_map[nchar(mun_code) == 3]  # only municipalities

# Merge to get codes
folk1e <- merge(folk1e, mun_map, by = "mun_name", all.x = FALSE)
cat(sprintf("  After merge with municipality codes: %d rows\n", nrow(folk1e)))

# Parse year from time "2008Q1" -> 2008
folk1e[, year := as.integer(sub("Q.*", "", time))]

# Create ancestry categories
folk1e[, ancestry_cat := fcase(
  ancestry == "Total", "total",
  ancestry == "Persons of Danish origin", "danish",
  ancestry == "Immigrants from non-western countries", "nw_immigrant",
  ancestry == "Descendants from non-western countries", "nw_descendant"
)]

# Reshape wide: one row per municipality-year
pop_wide <- dcast(folk1e, mun_code + year ~ ancestry_cat, value.var = "pop",
                  fun.aggregate = sum)

# Construct outcomes
pop_wide[, `:=`(
  nw_total = nw_immigrant + nw_descendant,
  nw_share = (nw_immigrant + nw_descendant) / total,
  nw_imm_share = nw_immigrant / total,
  log_total = log(total),
  log_nw = log(pmax(nw_immigrant + nw_descendant, 1))
)]

cat(sprintf("Population panel: %d municipality-years\n", nrow(pop_wide)))
cat(sprintf("  Years: %d to %d\n", min(pop_wide$year), max(pop_wide$year)))
cat(sprintf("  Municipalities: %d\n", uniqueN(pop_wide$mun_code)))

# -------------------------------------------------------------------
# 3. Clean RAS200: employment rate by municipality x ancestry x year
# -------------------------------------------------------------------
setnames(ras200, c("OMRÅDE", "HERKOMST", "ALDER", "KØN", "BEREGNING", "TID", "INDHOLD"),
         c("mun_name", "ancestry", "age", "sex", "measure", "year", "value"))

# Merge with municipality codes
ras200 <- merge(ras200, mun_map, by = "mun_name", all.x = FALSE)

ras200[, ancestry_cat := fcase(
  ancestry == "Total", "emp_total",
  ancestry == "Persons of Danish origin", "emp_danish",
  ancestry == "Immigrants from non-western countries", "emp_nw_imm",
  ancestry == "Descendants from non-western countries", "emp_nw_desc"
)]

emp_wide <- dcast(ras200, mun_code + year ~ ancestry_cat, value.var = "value",
                  fun.aggregate = mean, na.rm = TRUE)

cat(sprintf("Employment panel: %d municipality-years\n", nrow(emp_wide)))

# -------------------------------------------------------------------
# 4. Merge into analysis panel
# -------------------------------------------------------------------
panel <- merge(pop_wide, emp_wide, by = c("mun_code", "year"), all.x = TRUE)

# Ensure mun_code is character everywhere
panel[, mun_code := as.character(mun_code)]
mun_treatment[, mun_code := as.character(mun_code)]

# Add treatment indicator
panel[, treated := as.integer(mun_code %in% mun_treatment$mun_code)]

# Add treatment intensity (number of designated estates)
panel <- merge(panel, mun_treatment, by = "mun_code", all.x = TRUE)
panel[is.na(n_estates), n_estates := 0L]

# Post-treatment indicator (Ghetto Package enacted June 2018, lists from Dec 2018)
# Use 2019 as first fully treated year
panel[, post := as.integer(year >= 2019)]
panel[, treat_post := treated * post]

# Treatment intensity x post
panel[, intensity_post := n_estates * post]

# Event time relative to 2019
panel[, event_time := year - 2019]

cat(sprintf("\nFinal panel: %d obs, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$mun_code), uniqueN(panel$year)))
cat(sprintf("  Treated municipalities: %d\n", uniqueN(panel$mun_code[panel$treated == 1])))
cat(sprintf("  Control municipalities: %d\n", uniqueN(panel$mun_code[panel$treated == 0])))
cat(sprintf("  Pre-treatment years: %d (2008-%d)\n",
            sum(sort(unique(panel$year)) < 2019),
            max(panel$year[panel$year < 2019])))
cat(sprintf("  Post-treatment years: %d (2019-%d)\n",
            sum(sort(unique(panel$year)) >= 2019),
            max(panel$year)))

# Summary statistics
cat("\n--- Pre-treatment means (2008-2018) ---\n")
pre <- panel[year <= 2018]
cat(sprintf("  NW share, treated:  %.4f\n", mean(pre[treated == 1]$nw_share, na.rm = TRUE)))
cat(sprintf("  NW share, control:  %.4f\n", mean(pre[treated == 0]$nw_share, na.rm = TRUE)))
cat(sprintf("  Population, treated: %.0f\n", mean(pre[treated == 1]$total, na.rm = TRUE)))
cat(sprintf("  Population, control: %.0f\n", mean(pre[treated == 0]$total, na.rm = TRUE)))

# -------------------------------------------------------------------
# 5. Save analysis panel
# -------------------------------------------------------------------
fwrite(panel, "data/panel.csv")
cat(sprintf("\nPanel saved: data/panel.csv (%d rows)\n", nrow(panel)))
