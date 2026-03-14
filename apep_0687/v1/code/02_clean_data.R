## 02_clean_data.R — Clean PS1 and LT122 data, merge with treatment assignment
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply

source("00_packages.R")

# ============================================================
# 1. CLEAN PS1 PLANNING APPLICATION STATISTICS (Quarterly)
# ============================================================
ps1 <- fread("data/ps1_decisions.csv", header = FALSE, skip = 3)

# Set header from first row
hdr <- fread("data/ps1_decisions.csv", header = FALSE, skip = 3, nrows = 1)
col_names <- as.character(hdr[1,])
ps1 <- ps1[-1, ]  # Remove header row from data
setnames(ps1, names(ps1), col_names)

cat("PS1 columns available:\n")
cat(paste(col_names[1:15], collapse = "\n"), "\n")

# Key columns: Region, LPANM, LPACD, Quarter, Applications decided, received
ps1_clean <- ps1 |>
  as_tibble() |>
  select(
    region = Region,
    lpa_name = LPANM,
    lpa_code = LPACD,
    quarter = Quarter,
    apps_received = `Applications received`,
    apps_decided = `Applications decided`,
    apps_withdrawn = `Applications withdrawn`,
    apps_start = `Applications at beginning of the quarter`,
    apps_end = `Applications at end of the quarter`
  ) |>
  mutate(across(c(apps_received, apps_decided, apps_withdrawn, apps_start, apps_end),
                ~as.numeric(gsub("[^0-9.-]", "", .x)))) |>
  # Fix encoding issues in LPA names (Windows-1252 right single quote)
  mutate(lpa_name = iconv(lpa_name, from = "latin1", to = "UTF-8", sub = "'")) |>
  mutate(lpa_name = gsub("\u2019|\u0092", "'", lpa_name, useBytes = FALSE)) |>
  # Parse quarter: "1996 Q2" -> year, qtr
  mutate(
    year = as.integer(str_extract(quarter, "^\\d{4}")),
    qtr = as.integer(str_extract(quarter, "\\d$")),
    # Create numeric time variable (year + quarter fraction)
    time_q = year + (qtr - 1) / 4
  ) |>
  # Exclude National Parks and sub-areas (keep only standard LPAs)
  filter(!grepl("National Park|within National Park", lpa_name)) |>
  filter(!is.na(year), !is.na(apps_decided)) |>
  # Filter to England only (should already be, but verify)
  filter(nchar(lpa_code) > 0)

cat("PS1 cleaned:", nrow(ps1_clean), "observations\n")
cat("  LPAs:", n_distinct(ps1_clean$lpa_name), "\n")
cat("  Quarters:", min(ps1_clean$quarter), "to", max(ps1_clean$quarter), "\n")
cat("  Years:", min(ps1_clean$year), "to", max(ps1_clean$year), "\n")

# ============================================================
# 2. CLEAN LT122 NET ADDITIONAL DWELLINGS (Annual)
# ============================================================
lt122 <- readODS::read_ods("data/lt122_dwellings.ods", sheet = "LT_122", col_names = FALSE, skip = 4)

# Row 1 is header (year columns), data starts from row 2
hdr122 <- as.character(lt122[1, ])
lt122 <- lt122[-1, ]  # Remove header

# Clean year headers: "2001-02" -> "2001", remove notes
year_cols <- hdr122[5:length(hdr122)]
year_nums <- as.integer(str_extract(year_cols, "^\\d{4}"))
clean_years <- year_nums[!is.na(year_nums)]

cat("LT122 years:", min(clean_years, na.rm=T), "to", max(clean_years, na.rm=T), "\n")

# Set column names
n_year_cols <- sum(!is.na(year_nums))
names(lt122)[1:4] <- c("dclg_code", "old_ons_code", "ons_code", "la_name")

# Reshape to long format
lt122_long <- lt122 |>
  as_tibble() |>
  # Select ID cols + year cols
  select(1:4, 5:(4 + n_year_cols)) |>
  # Name the year columns
  setNames(c("dclg_code", "old_ons_code", "ons_code", "la_name",
             paste0("y_", clean_years))) |>
  # Filter to individual LAs (not regions/England totals)
  filter(!is.na(ons_code), grepl("^E0[6-9]", ons_code)) |>
  pivot_longer(
    cols = starts_with("y_"),
    names_to = "year_str",
    values_to = "net_additions"
  ) |>
  mutate(
    year = as.integer(str_extract(year_str, "\\d{4}")),
    net_additions = as.numeric(gsub("[^0-9.-]", "", net_additions))
  ) |>
  select(ons_code, la_name, year, net_additions)

cat("LT122 cleaned:", nrow(lt122_long), "observations\n")
cat("  LAs:", n_distinct(lt122_long$la_name), "\n")

# ============================================================
# 3. MERGE WITH TREATMENT ASSIGNMENT
# ============================================================
treatment_df <- readRDS("data/treatment_assignment.rds")

# Fuzzy match treatment LPA names to PS1 LPA names
ps1_names <- sort(unique(ps1_clean$lpa_name))
cat("\nMatching treatment LPAs to PS1 data...\n")

# Direct match first
treatment_df <- treatment_df |>
  mutate(
    matched = lpa_name %in% ps1_names,
    ps1_name = ifelse(matched, lpa_name, NA_character_)
  )

# Report matches
cat("  Direct matches:", sum(treatment_df$matched), "of", nrow(treatment_df), "\n")
unmatched <- treatment_df |> filter(!matched)
if (nrow(unmatched) > 0) {
  cat("  Unmatched LPAs:\n")
  for (nm in unmatched$lpa_name) {
    # Try partial matching
    candidates <- ps1_names[agrep(nm, ps1_names, max.distance = 0.2)]
    cat(sprintf("    %s -> candidates: %s\n", nm, paste(candidates, collapse = ", ")))
  }
}

# Apply manual fixes for unmatched names
name_fixes <- c(
  "Hull" = "Kingston upon Hull, City of",
  "South Downs" = NA_character_,  # National Park authority, excluded from PS1
  "Herefordshire" = "Herefordshire, County of",
  "Monmouthshire" = NA_character_  # Wales, not in England PS1 data
)

# Check for LPA name changes due to mergers (post-2023: Cumberland, Somerset, etc.)
# Somerset merged from: Mendip, Sedgemoor, Somerset West and Taunton, South Somerset (April 2023)
# Cumberland merged from: Allerdale, Carlisle, Copeland (April 2023)
# Westmorland and Furness merged from: Barrow-in-Furness, Eden, South Lakeland (April 2023)

# For the pre-merger analysis, we use the names as they appeared in PS1
# Post-April 2023, we need to handle merged authorities

# Apply name fixes: replace lpa_name with the PS1-matched version
for (i in seq_len(nrow(treatment_df))) {
  nm <- treatment_df$lpa_name[i]
  if (!treatment_df$matched[i] && nm %in% names(name_fixes)) {
    fix <- name_fixes[nm]
    if (!is.na(fix)) {
      treatment_df$lpa_name[i] <- fix
      treatment_df$ps1_name[i] <- fix
      treatment_df$matched[i] <- fix %in% ps1_names
    }
  }
}

# Drop excluded LPAs (Wales, National Parks)
treatment_df <- treatment_df |>
  filter(matched | !(lpa_name %in% c("Monmouthshire", "South Downs")))

# Create the panel: merge PS1 with treatment status
panel <- ps1_clean |>
  left_join(
    treatment_df |> select(lpa_name, wave, treat_year, treat_quarter),
    by = "lpa_name"
  ) |>
  mutate(
    # Treatment indicators
    treated_ever = !is.na(wave),
    treated = case_when(
      is.na(wave) ~ 0L,
      wave == 1 & time_q >= 2019.25 ~ 1L,  # 2019 Q2
      wave == 2 & time_q >= 2022.0 ~ 1L,    # 2022 Q1
      TRUE ~ 0L
    ),
    # Cohort variable for CS-DiD (first treatment period)
    first_treat = case_when(
      is.na(wave) ~ 0L,  # Never treated
      wave == 1 ~ 93L,   # 2019Q2 = quarter 93 (from 1996Q1)
      wave == 2 ~ 104L   # 2022Q1 = quarter 104
    ),
    # Numeric quarter ID for CS-DiD
    qid = (year - 1996) * 4 + qtr
  )

cat("\nPanel constructed:\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  Treated LPAs matched:", sum(panel$treated_ever & !duplicated(panel$lpa_name)), "\n")
cat("  Control LPAs:", sum(!panel$treated_ever & !duplicated(panel$lpa_name)), "\n")
cat("  Ever-treated in Wave 1:", sum(panel$wave == 1 & !duplicated(panel$lpa_name), na.rm=T), "\n")
cat("  Ever-treated in Wave 2:", sum(panel$wave == 2 & !duplicated(panel$lpa_name), na.rm=T), "\n")

# ============================================================
# 4. CONSTRUCT ANNUAL PANEL (for LT122 analysis)
# ============================================================
# Aggregate PS1 quarterly to annual for LT122 merge
annual_panel <- panel |>
  # Use financial year (April-March) to match LT122
  mutate(fy = ifelse(qtr >= 2, year, year - 1L)) |>
  group_by(lpa_name, lpa_code, region, fy, treated_ever, wave) |>
  summarise(
    apps_received = sum(apps_received, na.rm = TRUE),
    apps_decided = sum(apps_decided, na.rm = TRUE),
    apps_withdrawn = sum(apps_withdrawn, na.rm = TRUE),
    .groups = "drop"
  ) |>
  rename(year = fy) |>
  mutate(
    treated = case_when(
      is.na(wave) ~ 0L,
      wave == 1 & year >= 2019 ~ 1L,
      wave == 2 & year >= 2022 ~ 1L,
      TRUE ~ 0L
    )
  )

# Merge with LT122
# LT122 uses ONS codes, PS1 uses ONS codes too (lpa_code)
annual_panel <- annual_panel |>
  left_join(
    lt122_long |> select(ons_code, year, net_additions),
    by = c("lpa_code" = "ons_code", "year")
  )

cat("\nAnnual panel:", nrow(annual_panel), "obs\n")
cat("  With LT122 data:", sum(!is.na(annual_panel$net_additions)), "\n")

# ============================================================
# 5. SAVE CLEANED DATA
# ============================================================
saveRDS(panel, "data/panel_quarterly.rds")
saveRDS(annual_panel, "data/panel_annual.rds")
saveRDS(treatment_df, "data/treatment_matched.rds")

cat("\nData cleaning complete.\n")
