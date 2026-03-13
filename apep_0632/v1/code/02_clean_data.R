## 02_clean_data.R — Clean and merge all data sources
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Process ZFE boundaries
## ============================================================
cat("=== 1. Processing ZFE Boundaries ===\n")

sf::sf_use_s2(FALSE)
zfe_raw <- sf::st_read(file.path(data_dir, "zfe_aires.geojson"), quiet = TRUE)
zfe_raw <- sf::st_make_valid(zfe_raw)

## Extract metro identifier from id field (format: "SIREN-ZFE-NNN")
zfe_raw$siren <- sub("-ZFE-.*", "", zfe_raw$id)
zfe_raw$date_debut <- as.Date(zfe_raw$date_debut)

## Only keep ZFEs that were active BEFORE the 2022 presidential election (April 10, 2022)
## These are the treatment group for the main 2017→2022 diff-in-disc
## Metros with ZFE start date before April 2022:
##   200040715: May 2019 (likely Grenoble/Nice area)
##   217500016: June 2021 (Paris/Grand Paris)
##   200067213: January 2022 (Reims area)
##   244200770: January 2022 (Saint-Étienne area)
##   243100518: March 2022 (Toulouse)

cat("  ZFEs active before Presidential 2022 (April 10):\n")
early_zfe <- zfe_raw[zfe_raw$date_debut < as.Date("2022-04-10"), ]
cat(sprintf("  %d ZFE phases from %d metros\n", nrow(early_zfe), length(unique(early_zfe$siren))))

## Create a single polygon per metro (union of all phase polygons)
metros <- unique(zfe_raw$siren)
zfe_metro <- do.call(rbind, lapply(metros, function(s) {
  sub <- zfe_raw[zfe_raw$siren == s, ]
  geom <- sf::st_union(sf::st_geometry(sub))
  data.frame(
    siren = s,
    date_debut = min(sub$date_debut, na.rm = TRUE),
    n_phases = nrow(sub),
    stringsAsFactors = FALSE
  ) |> sf::st_sf(geometry = geom)
}))
sf::st_crs(zfe_metro) <- sf::st_crs(zfe_raw)

## Flag which metros were active before the 2022 election
zfe_metro$active_2022 <- zfe_metro$date_debut < as.Date("2022-04-10")
## Flag for 2024 legislative (June 30, 2024)
zfe_metro$active_2024 <- zfe_metro$date_debut < as.Date("2024-06-30")

cat(sprintf("  Total metro ZFE areas: %d\n", nrow(zfe_metro)))
cat(sprintf("  Active before Pres 2022: %d\n", sum(zfe_metro$active_2022)))
cat(sprintf("  Active before Legis 2024: %d\n", sum(zfe_metro$active_2024)))

## ============================================================
## 2. Compute commune distances to nearest ZFE boundary
## ============================================================
cat("\n=== 2. Computing Commune-ZFE Distances ===\n")

communes <- readRDS(file.path(data_dir, "communes_centroids.rds"))

## Transform to projected CRS (Lambert-93, EPSG:2154) for distance in meters
communes_proj <- sf::st_transform(communes, 2154)
zfe_metro_proj <- sf::st_transform(zfe_metro, 2154)

## Get the boundary lines (not filled polygons)
zfe_boundaries <- sf::st_boundary(zfe_metro_proj)

cat("  Computing distances...\n")

## Inside/outside test for each metro
inside_matrix <- sf::st_within(communes_proj, zfe_metro_proj, sparse = FALSE)

## Distance to boundary for each metro
dist_matrix <- as.matrix(sf::st_distance(communes_proj, zfe_boundaries))

## For each commune, find the nearest metro boundary
nearest_metro_idx <- apply(dist_matrix, 1, which.min)
nearest_dist <- apply(dist_matrix, 1, min)

## Signed distance: positive = inside, negative = outside
is_inside <- sapply(seq_len(nrow(communes_proj)), function(i) {
  inside_matrix[i, nearest_metro_idx[i]]
})
signed_dist <- ifelse(is_inside, as.numeric(nearest_dist), -as.numeric(nearest_dist))

## Build the commune-level dataset
commune_zfe <- data.table(
  code = communes$code,
  nom = communes$nom,
  departement = communes$departement,
  population = communes$population,
  nearest_metro_siren = zfe_metro$siren[nearest_metro_idx],
  nearest_metro_date = zfe_metro$date_debut[nearest_metro_idx],
  metro_active_2022 = zfe_metro$active_2022[nearest_metro_idx],
  metro_active_2024 = zfe_metro$active_2024[nearest_metro_idx],
  dist_to_boundary_m = as.numeric(nearest_dist),
  inside_zfe = is_inside,
  signed_dist_m = signed_dist,
  signed_dist_km = signed_dist / 1000
)

## Filter to communes within 50 km of any ZFE boundary
commune_zfe <- commune_zfe[dist_to_boundary_m <= 50000]
cat(sprintf("  Communes within 50 km: %d\n", nrow(commune_zfe)))
cat(sprintf("  Inside ZFE: %d | Outside: %d\n",
            sum(commune_zfe$inside_zfe), sum(!commune_zfe$inside_zfe)))

## ============================================================
## 3. Parse Election Results
## ============================================================
cat("\n=== 3. Parsing Election Results ===\n")

## --- Presidential 2012 ---
cat("  Presidential 2012...\n")
pres2012 <- fread(file.path(data_dir, "pres_2012_t1.csv"), encoding = "UTF-8")
## Columns: CodeInsee, Inscrits, ..., LePen, ..., Hollande
pres2012[, `:=`(
  code = sprintf("%05s", as.character(CodeInsee)),
  rn_share_2012 = LePen / `Exprimés`,
  turnout_2012 = Votants / Inscrits,
  registered_2012 = Inscrits,
  expressed_2012 = `Exprimés`
)]
pres2012_clean <- pres2012[, .(code, rn_share_2012, turnout_2012, registered_2012, expressed_2012)]
cat(sprintf("    N=%d, mean FN share=%.1f%%\n", nrow(pres2012_clean),
            100 * mean(pres2012_clean$rn_share_2012, na.rm = TRUE)))

## --- Presidential 2017 ---
cat("  Presidential 2017...\n")
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org", quiet = TRUE)
}
pres2017_raw <- as.data.table(readxl::read_xls(
  file.path(data_dir, "pres_2017_t1.xls"), skip = 3
))

## Build commune code (dept + commune)
pres2017_raw[, code := paste0(
  sprintf("%02s", `Code du département`),
  sprintf("%03s", `Code de la commune`)
)]

## Le Pen is candidate 1 (columns: Nom...21 = "LE PEN", Voix...23)
## Verify
stopifnot("LE PEN not in expected column" =
  pres2017_raw[1, `Nom...21`] == "LE PEN" ||
  any(grepl("LE PEN", pres2017_raw[1:5, `Nom...21`])))

pres2017_raw[, `:=`(
  rn_share_2017 = as.numeric(`Voix...23`) / as.numeric(`Exprimés`),
  turnout_2017 = as.numeric(Votants) / as.numeric(Inscrits),
  registered_2017 = as.numeric(Inscrits),
  expressed_2017 = as.numeric(`Exprimés`)
)]
pres2017_clean <- pres2017_raw[, .(code, rn_share_2017, turnout_2017, registered_2017, expressed_2017)]
cat(sprintf("    N=%d, mean FN share=%.1f%%\n", nrow(pres2017_clean),
            100 * mean(pres2017_clean$rn_share_2017, na.rm = TRUE)))

## --- Presidential 2022 ---
cat("  Presidential 2022...\n")
pres2022 <- fread(file.path(data_dir, "pres_2022_t1.txt"), encoding = "Latin-1",
                  sep = ";", header = TRUE, fill = TRUE)

## Build commune code
pres2022[, code := paste0(
  sprintf("%02s", `Code du département`),
  sprintf("%03s", `Code de la commune`)
)]

## Le Pen is candidate 5: Nom in col 50, Voix in col 52
## The auto-named columns are V50 and V52
## Also get Zemmour (candidate 6, col 59) for far-right total
lepen_col <- names(pres2022)[52]   # V52
zemmour_col <- names(pres2022)[59] # V59

pres2022[, `:=`(
  lepen_v = as.numeric(get(lepen_col)),
  zemmour_v = as.numeric(get(zemmour_col)),
  expressed = as.numeric(`Exprimés`),
  inscrits = as.numeric(Inscrits),
  votants = as.numeric(Votants)
)]

## Aggregate subcom to commune level
pres2022_agg <- pres2022[, .(
  lepen_v = sum(lepen_v, na.rm = TRUE),
  zemmour_v = sum(zemmour_v, na.rm = TRUE),
  expressed_2022 = sum(expressed, na.rm = TRUE),
  registered_2022 = sum(inscrits, na.rm = TRUE),
  votants_2022 = sum(votants, na.rm = TRUE)
), by = code]

pres2022_agg[, `:=`(
  rn_share_2022 = lepen_v / expressed_2022,
  farright_share_2022 = (lepen_v + zemmour_v) / expressed_2022,
  turnout_2022 = votants_2022 / registered_2022
)]
pres2022_clean <- pres2022_agg[, .(code, rn_share_2022, farright_share_2022,
                                    turnout_2022, registered_2022, expressed_2022)]
cat(sprintf("    N=%d, mean RN share=%.1f%%, mean far-right=%.1f%%\n",
            nrow(pres2022_clean),
            100 * mean(pres2022_clean$rn_share_2022, na.rm = TRUE),
            100 * mean(pres2022_clean$farright_share_2022, na.rm = TRUE)))

## --- Legislative 2024 ---
cat("  Legislative 2024...\n")
legis2024 <- fread(file.path(data_dir, "legis_2024_t1.csv"), encoding = "UTF-8",
                   sep = ";", header = TRUE)

## Build commune code
legis2024[, code := paste0(
  sprintf("%02s", `Code département`),
  sprintf("%03s", `Code commune`)
)]

## Find RN votes: candidates with nuance "RN"
## Nuance columns repeat per candidate slot
nuance_cols <- grep("^Nuance candidat", names(legis2024), value = TRUE)
voix_cols <- grep("^Voix ", names(legis2024), value = TRUE)

legis2024[, rn_votes_raw := 0]
for (i in seq_along(nuance_cols)) {
  nc <- nuance_cols[i]
  vc <- voix_cols[i]
  if (nc %in% names(legis2024) && vc %in% names(legis2024)) {
    legis2024[get(nc) == "RN", rn_votes_raw := rn_votes_raw + as.numeric(get(vc))]
  }
}

legis2024_agg <- legis2024[, .(
  rn_votes_2024l = sum(rn_votes_raw, na.rm = TRUE),
  expressed_2024l = sum(as.numeric(`Exprimés`), na.rm = TRUE),
  registered_2024l = sum(as.numeric(Inscrits), na.rm = TRUE),
  votants_2024l = sum(as.numeric(Votants), na.rm = TRUE)
), by = code]
legis2024_agg[, `:=`(
  rn_share_2024l = rn_votes_2024l / expressed_2024l,
  turnout_2024l = votants_2024l / registered_2024l
)]
legis2024_clean <- legis2024_agg[, .(code, rn_share_2024l, turnout_2024l,
                                      registered_2024l, expressed_2024l)]
cat(sprintf("    N=%d, mean RN share=%.1f%%\n", nrow(legis2024_clean),
            100 * mean(legis2024_clean$rn_share_2024l, na.rm = TRUE)))

## ============================================================
## 4. Merge everything
## ============================================================
cat("\n=== 4. Merging Datasets ===\n")

panel <- copy(commune_zfe)
panel <- merge(panel, pres2012_clean, by = "code", all.x = TRUE)
panel <- merge(panel, pres2017_clean, by = "code", all.x = TRUE)
panel <- merge(panel, pres2022_clean, by = "code", all.x = TRUE)
panel <- merge(panel, legis2024_clean, by = "code", all.x = TRUE)

## Compute changes in RN share (key outcome variables)
panel[, `:=`(
  ## Main outcome: diff-in-disc uses change from pre to post ZFE
  delta_rn_1722 = rn_share_2022 - rn_share_2017,
  delta_rn_1222 = rn_share_2022 - rn_share_2012,
  ## Placebo: change between two pre-ZFE elections (no ZFE existed before 2019)
  delta_rn_1217 = rn_share_2017 - rn_share_2012,
  ## Turnout change
  delta_turnout_1722 = turnout_2022 - turnout_2017,
  ## Far-right total (Le Pen + Zemmour 2022)
  delta_farright_1722 = farright_share_2022 - rn_share_2017
)]

## Treatment indicator for the diff-in-disc:
## inside_zfe AND the nearest metro had an active ZFE before the election
panel[, treated_2022 := inside_zfe & metro_active_2022]
panel[, treated_2024 := inside_zfe & metro_active_2024]

## Drop communes with missing key election data
panel <- panel[!is.na(rn_share_2017) & !is.na(rn_share_2022)]

cat(sprintf("  Final panel: %d communes\n", nrow(panel)))
cat(sprintf("  Treated (inside active ZFE, 2022): %d\n", sum(panel$treated_2022)))
cat(sprintf("  Control (outside or inactive ZFE): %d\n", sum(!panel$treated_2022)))

## ============================================================
## 5. Save cleaned panel
## ============================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

cat("\n=== Panel Summary Statistics ===\n")
cat(sprintf("  N communes: %d\n", nrow(panel)))
cat(sprintf("  RN share 2012: %.1f%% (sd=%.1f)\n",
            100 * mean(panel$rn_share_2012, na.rm = TRUE),
            100 * sd(panel$rn_share_2012, na.rm = TRUE)))
cat(sprintf("  RN share 2017: %.1f%% (sd=%.1f)\n",
            100 * mean(panel$rn_share_2017, na.rm = TRUE),
            100 * sd(panel$rn_share_2017, na.rm = TRUE)))
cat(sprintf("  RN share 2022: %.1f%% (sd=%.1f)\n",
            100 * mean(panel$rn_share_2022, na.rm = TRUE),
            100 * sd(panel$rn_share_2022, na.rm = TRUE)))
cat(sprintf("  Mean ΔRN 2017→2022: %.2f pp\n", 100 * mean(panel$delta_rn_1722, na.rm = TRUE)))
cat(sprintf("  Metros: %s\n", paste(unique(panel$nearest_metro_siren), collapse = ", ")))
cat(sprintf("  Distance range: %.1f to %.1f km\n",
            min(panel$dist_to_boundary_m) / 1000, max(panel$dist_to_boundary_m) / 1000))

cat("\nDone.\n")
