# =============================================================================
# 02_clean_data.R — Construct treatment classification and analysis panel
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/bfs_commune_panel.rds")
geo_lookup <- readRDS("../data/geo_lookup.rds")

# =============================================================================
# 1. TREATMENT CLASSIFICATION: Ballot vs. Administrative Cantons
# =============================================================================
# The 2003 Federal Court ruling (BGE 129 I 232) banned ballot-vote naturalization.
# This practice was concentrated in German-speaking cantons.
# French-speaking and Italian-speaking cantons already used administrative procedures.
#
# Classification based on:
# - Hainmueller & Hangartner (2013, APSR): documents ballot municipalities in
#   ZH, AG, LU, SG, AR, AI, SO, BL, SZ, OW, NW, GL, TG, GR, ZG cantons
# - Cantonal legislation: GE, VD, NE, TI, JU had administrative-only pre-2003
# - BE is mixed (predominantly administrative in French-speaking part)
# - FR, VS bilingual — treated as mixed
#
# Strategy: Use cantonal language region as primary classification.
# German-speaking cantons = "ballot cantons" (treated)
# French/Italian/Romansh cantons = "administrative cantons" (control)
# This is a conservative approach that aligns with the legal reality.

# BFS canton numbers (first two digits of commune number)
# Map commune BFS number to canton
canton_from_bfs <- function(bfs_nr) {
  # BFS commune numbers encode canton: 1-XXX = ZH, 301-XXX = LU, etc.
  # Use official BFS canton assignment ranges
  case_when(
    bfs_nr >= 1 & bfs_nr <= 296 ~ "ZH",
    bfs_nr >= 301 & bfs_nr <= 995 ~ "BE",
    bfs_nr >= 1001 & bfs_nr <= 1165 ~ "LU",
    bfs_nr >= 1201 & bfs_nr <= 1253 ~ "UR",
    bfs_nr >= 1301 & bfs_nr <= 1373 ~ "SZ",
    bfs_nr >= 1401 & bfs_nr <= 1407 ~ "OW",
    bfs_nr >= 1501 & bfs_nr <= 1511 ~ "NW",
    bfs_nr >= 1601 & bfs_nr <= 1630 ~ "GL",
    bfs_nr >= 1701 & bfs_nr <= 1711 ~ "ZG",
    bfs_nr >= 2001 & bfs_nr <= 2340 ~ "FR",
    bfs_nr >= 2401 & bfs_nr <= 2622 ~ "SO",
    bfs_nr >= 2701 & bfs_nr <= 2786 ~ "BS/BL",
    bfs_nr >= 2831 & bfs_nr <= 2895 ~ "BS/BL",
    bfs_nr >= 2901 & bfs_nr <= 2939 ~ "SH",
    bfs_nr >= 3001 & bfs_nr <= 3428 ~ "AR/AI",
    bfs_nr >= 3501 & bfs_nr <= 3408 ~ "AR/AI",
    bfs_nr >= 3201 & bfs_nr <= 3254 ~ "AR",
    bfs_nr >= 3101 & bfs_nr <= 3113 ~ "AI",
    bfs_nr >= 3401 & bfs_nr <= 3443 ~ "SG",
    bfs_nr >= 3501 & bfs_nr <= 3551 ~ "GR",
    bfs_nr >= 3801 & bfs_nr <= 3987 ~ "AG",
    bfs_nr >= 4001 & bfs_nr <= 4146 ~ "TG",
    bfs_nr >= 4201 & bfs_nr <= 4276 ~ "TI",
    bfs_nr >= 4401 & bfs_nr <= 4651 ~ "VD",
    bfs_nr >= 5001 & bfs_nr <= 5200 ~ "VS",
    bfs_nr >= 5401 & bfs_nr <= 5422 ~ "NE",
    bfs_nr >= 5501 & bfs_nr <= 5564 ~ "GE",
    bfs_nr >= 5701 & bfs_nr <= 5715 ~ "JU",
    bfs_nr >= 6001 & bfs_nr <= 6900 ~ "OTHER",
    TRUE ~ NA_character_
  )
}

# Better approach: extract canton from the BFS geo hierarchy
# The geo_lookup has canton entries marked with "- " prefix
# Let's assign cantons by finding the parent canton for each commune

# Actually, simplest: use the BFS commune number ranges from official BFS documentation
# https://www.bfs.admin.ch/bfs/en/home/basics/institutional-units/number-assignment.html

# Let me use a cleaner approach: parse canton from the hierarchical geo_lookup
# In the API, cantons are coded as "- Zürich", districts as ">> Bezirk X",
# communes as "......XXXX Name"

# Read the full geo hierarchy to map communes to cantons
cat("Mapping communes to cantons from BFS hierarchy...\n")

# Parse the full geo hierarchy
full_geo <- data.frame(
  geo_code = geo_lookup$geo_code,
  geo_text = geo_lookup$geo_text,
  bfs_nr = geo_lookup$bfs_nr,
  stringsAsFactors = FALSE
)

# Reload from API metadata to get the full hierarchy including cantons
api_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_201/px-x-0102020000_201.px"
meta <- GET(api_url) |> content(as = "text", encoding = "UTF-8") |> fromJSON()
vars <- meta$variables

all_geo_texts <- vars$valueTexts[[2]]
all_geo_codes <- vars$values[[2]]

# Build hierarchy: canton → district → commune
current_canton <- NA_character_
current_canton_code <- NA_character_
canton_map <- data.frame(
  geo_code = character(),
  geo_text = character(),
  canton = character(),
  canton_abbr = character(),
  stringsAsFactors = FALSE
)

# Swiss canton abbreviation from name
canton_abbr_map <- c(
  "Zürich" = "ZH", "Bern / Berne" = "BE", "Luzern" = "LU",
  "Uri" = "UR", "Schwyz" = "SZ", "Obwalden" = "OW",
  "Nidwalden" = "NW", "Glarus" = "GL", "Zug" = "ZG",
  "Fribourg / Freiburg" = "FR", "Solothurn" = "SO",
  "Basel-Stadt" = "BS", "Basel-Landschaft" = "BL",
  "Schaffhausen" = "SH", "Appenzell Ausserrhoden" = "AR",
  "Appenzell Innerrhoden" = "AI", "St. Gallen" = "SG",
  "Graubünden / Grigioni / Grischun" = "GR",
  "Aargau" = "AG", "Thurgau" = "TG", "Ticino" = "TI",
  "Vaud" = "VD", "Valais / Wallis" = "VS", "Neuchâtel" = "NE",
  "Genève" = "GE", "Jura" = "JU"
)

results <- list()
current_canton_name <- NA
current_canton_abbr <- NA

for (i in seq_along(all_geo_texts)) {
  txt <- all_geo_texts[i]
  code <- all_geo_codes[i]

  if (grepl("^- ", txt)) {
    # Canton
    cname <- gsub("^- ", "", txt)
    current_canton_name <- cname
    # Match to abbreviation
    matched <- FALSE
    for (k in names(canton_abbr_map)) {
      if (grepl(k, cname, fixed = TRUE) || grepl(cname, k, fixed = TRUE)) {
        current_canton_abbr <- canton_abbr_map[k]
        matched <- TRUE
        break
      }
    }
    if (!matched) {
      # Try partial match
      for (k in names(canton_abbr_map)) {
        if (grepl(substr(cname, 1, 4), k, ignore.case = TRUE)) {
          current_canton_abbr <- canton_abbr_map[k]
          matched <- TRUE
          break
        }
      }
    }
    if (!matched) current_canton_abbr <- cname
  } else if (grepl("^\\.\\.\\.\\.\\.\\.", txt)) {
    # Commune — assign to current canton
    bfs <- as.integer(gsub("^\\.*([0-9]+)\\s.*", "\\1", txt))
    results[[length(results) + 1]] <- data.frame(
      geo_code = code,
      bfs_nr = bfs,
      canton = current_canton_name,
      canton_abbr = current_canton_abbr,
      stringsAsFactors = FALSE
    )
  }
}

canton_assignment <- bind_rows(results)
cat(sprintf("Communes with canton assignment: %d\n", nrow(canton_assignment)))
cat("\nCommunes per canton:\n")
print(canton_assignment |> count(canton_abbr) |> arrange(desc(n)))

# =============================================================================
# 2. CLASSIFY BALLOT vs. ADMINISTRATIVE CANTONS
# =============================================================================
# Based on Hainmueller & Hangartner (2013) and legal literature:
#
# BALLOT CANTONS (used Gemeindeversammlung/ballot for naturalization pre-2003):
# German-speaking interior cantons where popular assembly decided naturalizations
# ZH, LU, SZ, OW, NW, GL, ZG, SO, BL, SH, AR, AI, SG, AG, TG
# Also parts of GR, BE (German-speaking municipalities)
#
# ADMINISTRATIVE CANTONS (already used commission/executive for naturalization):
# GE, VD, NE, TI, JU, FR (predominantly), BS (city-canton, different system)
#
# MIXED/AMBIGUOUS: BE (bilingual), FR (bilingual), VS (bilingual), GR (trilingual)
#
# Conservative design: Use PURE German-speaking vs. PURE French/Italian cantons

ballot_cantons <- c("ZH", "LU", "SZ", "OW", "NW", "GL", "ZG",
                     "SO", "BL", "SH", "AR", "AI", "SG", "AG", "TG")

admin_cantons <- c("GE", "VD", "NE", "TI", "JU", "BS")

# Mixed cantons (excluded from primary specification, used in robustness):
# BE, FR, VS, GR, UR

canton_assignment <- canton_assignment |>
  mutate(
    treatment_group = case_when(
      canton_abbr %in% ballot_cantons ~ "ballot",
      canton_abbr %in% admin_cantons ~ "admin",
      TRUE ~ "mixed"
    )
  )

cat("\nTreatment classification:\n")
print(canton_assignment |> count(treatment_group, canton_abbr) |>
        arrange(treatment_group, desc(n)))

cat(sprintf("\nBallot communes: %d\n", sum(canton_assignment$treatment_group == "ballot")))
cat(sprintf("Admin communes: %d\n", sum(canton_assignment$treatment_group == "admin")))
cat(sprintf("Mixed communes: %d\n", sum(canton_assignment$treatment_group == "mixed")))

# =============================================================================
# 3. BUILD ANALYSIS PANEL
# =============================================================================

# Merge treatment assignment to panel
panel <- panel |>
  left_join(canton_assignment |> select(bfs_nr, canton_abbr, treatment_group),
            by = "bfs_nr")

# Compute naturalization rate
panel <- panel |>
  mutate(
    nat_rate = ifelse(foreign_pop > 0, naturalizations / foreign_pop * 1000, NA_real_),
    nat_rate_pop = naturalizations / total_pop * 1000,
    log_nat = log1p(naturalizations),
    foreign_share = foreign_pop / total_pop * 100,
    post = as.integer(year >= 2004),  # Allow 1 year for implementation
    ballot = as.integer(treatment_group == "ballot")
  )

# Filter to ballot and admin cantons only (drop mixed for primary spec)
panel_main <- panel |>
  filter(treatment_group %in% c("ballot", "admin"))

cat(sprintf("\n=== ANALYSIS PANEL ===\n"))
cat(sprintf("Total obs: %d\n", nrow(panel_main)))
cat(sprintf("Communes: %d (ballot: %d, admin: %d)\n",
            n_distinct(panel_main$bfs_nr),
            n_distinct(panel_main$bfs_nr[panel_main$ballot == 1]),
            n_distinct(panel_main$bfs_nr[panel_main$ballot == 0])))
cat(sprintf("Years: %d to %d\n", min(panel_main$year), max(panel_main$year)))

# Summary stats
cat("\nSummary stats — Naturalization rate (per 1000 foreign pop):\n")
panel_main |>
  filter(!is.na(nat_rate), is.finite(nat_rate)) |>
  group_by(treatment_group) |>
  summarize(
    mean = mean(nat_rate),
    sd = sd(nat_rate),
    median = median(nat_rate),
    n = n()
  ) |>
  print()

# Pre vs post comparison
cat("\nPre/Post naturalization rate by group:\n")
panel_main |>
  filter(!is.na(nat_rate), is.finite(nat_rate)) |>
  group_by(treatment_group, post) |>
  summarize(
    mean_nat_rate = mean(nat_rate),
    mean_nat = mean(naturalizations),
    .groups = "drop"
  ) |>
  print()

# =============================================================================
# 4. SAVE
# =============================================================================

saveRDS(panel_main, "../data/analysis_panel.rds")
saveRDS(panel, "../data/full_panel.rds")  # Including mixed cantons
saveRDS(canton_assignment, "../data/canton_assignment.rds")

cat("\nData saved to data/analysis_panel.rds\n")
cat("02_clean_data.R complete.\n")
