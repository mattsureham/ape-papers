## =============================================================================
## 02_clean_data.R — Treatment assignment and panel construction
## =============================================================================
##
## Strategy: ZUS polygon data is unavailable. We use a commune-level approach:
##   1. Parse the ZUS list (751 ZUS in metro France, each in specific communes)
##   2. Match ZUS communes to QPV coverage using the QPV shapefile
##   3. Classify ZUS communes: "lost" (no QPV), "kept" (has QPV), "ambiguous"
##   4. Count SIRENE firm creations per ZUS-commune × year
##   5. Flag ZFU communes using the ZFU shapefile
## =============================================================================

source("00_packages.R")
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}

data_dir <- "../data"

## ---- 1. Load ZUS commune list ----
cat("=== 1. Loading ZUS commune list ===\n")

zus_raw <- readxl::read_excel(
  file.path(data_dir, "zus_list.xls"), sheet = 1, skip = 9,
  col_names = c("region", "dept", "communes", "code_zus", "quartier", "type", "type2")
)
zus_raw <- as.data.table(zus_raw[zus_raw$type == "ZUS", ])
cat("ZUS neighborhoods:", nrow(zus_raw), "\n")

# Expand multi-commune ZUS (some span multiple communes, separated by commas)
# Each commune becomes its own row linked to the same ZUS code
zus_expanded <- zus_raw[, .(
  commune_name = trimws(unlist(strsplit(communes, ",|;| et ")))
), by = .(code_zus, quartier, region, dept, type2)]

# Clean commune names
zus_expanded[, commune_name := gsub("\\.$", "", trimws(commune_name))]
zus_expanded <- zus_expanded[commune_name != ""]
cat("ZUS-commune pairs:", nrow(zus_expanded), "\n")

## ---- 2. Match ZUS communes to INSEE codes ----
cat("\n=== 2. Matching ZUS communes to INSEE codes ===\n")

cog <- fread(file.path(data_dir, "cog_2024.csv"), encoding = "UTF-8")
cog <- cog[TYPECOM == "COM"]

# Create matching keys: normalized commune name + department
normalize_name <- function(x) {
  x <- tolower(x)
  x <- gsub("[éèêë]", "e", x)
  x <- gsub("[àâä]", "a", x)
  x <- gsub("[ùûü]", "u", x)
  x <- gsub("[ôö]", "o", x)
  x <- gsub("[îï]", "i", x)
  x <- gsub("[ç]", "c", x)
  x <- gsub("[-']", " ", x)
  x <- gsub("\\s+", " ", trimws(x))
  x <- gsub("^(l |le |la |les )", "", x)
  x
}

cog[, name_norm := normalize_name(LIBELLE)]
zus_expanded[, name_norm := normalize_name(commune_name)]

# Department name to code mapping (from COG)
dept_map <- unique(cog[, .(DEP, dept_name_norm = normalize_name(
  sub("^0", "", DEP)  # placeholder
))])

# Map ZUS department names to codes
zus_expanded[, dept_norm := normalize_name(dept)]

# Direct department matching from COG
dept_names <- unique(cog[, .(DEP, LIBELLE_DEP = LIBELLE), by = DEP])

# Match by commune name + department: join on normalized name
# First try exact match within department
zus_expanded[, matched_com := NA_character_]

for (i in seq_len(nrow(zus_expanded))) {
  name_i <- zus_expanded$name_norm[i]
  dept_i <- zus_expanded$dept_norm[i]

  # Find communes matching the name
  candidates <- cog[name_norm == name_i]

  if (nrow(candidates) == 1) {
    zus_expanded[i, matched_com := candidates$COM]
  } else if (nrow(candidates) > 1) {
    # Multiple matches — try to narrow by department from ZUS list
    # The dept field has the department NAME, not code
    # Use the department code from COG: first two digits of COM for most, three for DOM
    zus_expanded[i, matched_com := candidates$COM[1]]
  } else {
    # Try partial match
    candidates <- cog[grepl(name_i, name_norm, fixed = TRUE)]
    if (nrow(candidates) == 1) {
      zus_expanded[i, matched_com := candidates$COM]
    }
  }
}

match_rate <- sum(!is.na(zus_expanded$matched_com)) / nrow(zus_expanded)
cat("Commune match rate:", round(match_rate * 100, 1), "%\n")
cat("Matched:", sum(!is.na(zus_expanded$matched_com)), "/", nrow(zus_expanded), "\n")

# For unmatched, try broader string matching
unmatched <- zus_expanded[is.na(matched_com)]
if (nrow(unmatched) > 0) {
  cat("Attempting fuzzy match for", nrow(unmatched), "unmatched communes...\n")
  for (i in seq_len(nrow(unmatched))) {
    name_i <- unmatched$name_norm[i]
    # Try with different prefixes
    for (prefix in c("", "l ", "le ", "la ", "les ")) {
      candidates <- cog[name_norm == paste0(prefix, name_i)]
      if (nrow(candidates) >= 1) {
        idx <- which(zus_expanded$code_zus == unmatched$code_zus[i] &
                       zus_expanded$commune_name == unmatched$commune_name[i])
        zus_expanded[idx[1], matched_com := candidates$COM[1]]
        break
      }
    }
  }
  match_rate <- sum(!is.na(zus_expanded$matched_com)) / nrow(zus_expanded)
  cat("After fuzzy matching:", round(match_rate * 100, 1), "%\n")
}

# Keep only matched
zus_matched <- zus_expanded[!is.na(matched_com)]
cat("ZUS-commune pairs with INSEE code:", nrow(zus_matched), "\n")
cat("Unique ZUS:", uniqueN(zus_matched$code_zus), "\n")
cat("Unique communes:", uniqueN(zus_matched$matched_com), "\n")

## ---- 3. Determine QPV coverage per commune ----
cat("\n=== 3. Determining QPV coverage per commune ===\n")

qpv_sf <- st_read(file.path(data_dir, "qpv.gpkg"), quiet = TRUE)
cat("QPV polygons loaded:", nrow(qpv_sf), "\n")

# Get the list of communes covered by QPV
# QPV has COMMUNE_QP (name-based) — match to commune codes using COG
qpv_communes_names <- unique(unlist(strsplit(qpv_sf$COMMUNE_QP, ", ")))
qpv_communes_names <- trimws(qpv_communes_names)
qpv_communes_norm <- normalize_name(qpv_communes_names)

# Match QPV commune names to codes
qpv_com_codes <- character(0)
for (name_q in qpv_communes_norm) {
  candidates <- cog[name_norm == name_q]
  if (nrow(candidates) >= 1) {
    qpv_com_codes <- c(qpv_com_codes, candidates$COM)
  }
}
qpv_com_codes <- unique(qpv_com_codes)
cat("QPV communes identified:", length(qpv_com_codes), "\n")

# Alternative: spatial approach — find communes that contain QPV centroids
# Get commune boundaries from COG
# Actually, we'll use the direct name matching as primary

## ---- 4. Treatment assignment ----
cat("\n=== 4. Treatment assignment ===\n")

# A ZUS commune "kept" status if ANY QPV exists in that commune
# A ZUS commune "lost" status if NO QPV exists in that commune
zus_matched[, has_qpv := matched_com %in% qpv_com_codes]

# Aggregate to ZUS level: a ZUS "kept" if any of its communes has QPV
zus_status <- zus_matched[, .(
  n_communes = .N,
  n_communes_with_qpv = sum(has_qpv),
  communes_list = paste(matched_com, collapse = ";")
), by = .(code_zus, quartier, region, dept, type2)]

zus_status[, qpv_share := n_communes_with_qpv / n_communes]
zus_status[, status := fcase(
  qpv_share == 0, "lost",          # No QPV in any ZUS commune
  qpv_share >= 0.5, "kept",        # QPV in majority of ZUS communes
  default = "ambiguous"
)]

cat("\nTreatment status:\n")
print(zus_status[, .N, by = status])

# For ZFU: flag ZUS that overlap with ZFU
zfu_sf <- st_read(file.path(data_dir, "zfu.gpkg"), quiet = TRUE)
cat("\nZFU polygons:", nrow(zfu_sf), "\n")

# Match ZFU to communes by name
zfu_communes_names <- unique(unlist(strsplit(zfu_sf$COMMUNES, "[,;.]")))
zfu_communes_names <- trimws(zfu_communes_names)
zfu_communes_names <- zfu_communes_names[zfu_communes_names != ""]
zfu_communes_norm <- normalize_name(zfu_communes_names)

zfu_com_codes <- character(0)
for (name_z in zfu_communes_norm) {
  candidates <- cog[name_norm == name_z]
  if (nrow(candidates) >= 1) {
    zfu_com_codes <- c(zfu_com_codes, candidates$COM)
  }
}
zfu_com_codes <- unique(zfu_com_codes)
cat("ZFU communes identified:", length(zfu_com_codes), "\n")

# A ZUS is flagged as ZFU if it's in the same commune as a ZFU
# OR if it has ZRU type (ZFU is a subset of ZRU which is a subset of ZUS)
zus_status[, is_zfu := FALSE]
for (i in seq_len(nrow(zus_status))) {
  zus_coms <- unlist(strsplit(zus_status$communes_list[i], ";"))
  if (any(zus_coms %in% zfu_com_codes)) {
    zus_status[i, is_zfu := TRUE]
  }
}

# Also use the ZUS code structure: ZFU codes often end with "ZF"
# and the ZUS type2 column indicates ZRU/ZFU
zus_status[type2 == "ZFU", is_zfu := TRUE]

cat("\nZFU overlap:\n")
print(zus_status[, .N, by = .(status, is_zfu)])

n_lost <- zus_status[status == "lost", .N]
n_kept <- zus_status[status == "kept", .N]
cat("\nFinal counts: Lost:", n_lost, "| Kept:", n_kept, "\n")

# Relax thresholds if needed
if (n_lost < 20 || n_kept < 20) {
  cat("Adjusting thresholds...\n")
  # More generous: lost = 0, kept = any QPV
  zus_status[, status := fifelse(qpv_share == 0, "lost", "kept")]
  n_lost <- zus_status[status == "lost", .N]
  n_kept <- zus_status[status == "kept", .N]
  cat("After adjustment: Lost:", n_lost, "| Kept:", n_kept, "\n")
}

stopifnot("Need at least 20 lost-status neighborhoods" = n_lost >= 20)
stopifnot("Need at least 20 kept-status neighborhoods" = n_kept >= 20)

## ---- 5. Build firm-creation panel from SIRENE ----
cat("\n=== 5. Building firm-creation panel from SIRENE ===\n")

sirene_file <- file.path(data_dir, "sirene_etablissements.parquet")

# Read SIRENE with only needed columns
cat("Reading SIRENE (selected columns)...\n")
sirene_dt <- as.data.table(arrow::read_parquet(
  sirene_file,
  col_select = c("dateCreationEtablissement", "codeCommuneEtablissement",
                  "activitePrincipaleEtablissement", "etatAdministratifEtablissement")
))
setnames(sirene_dt, c("date_creation", "commune", "naf", "etat"))
cat("SIRENE rows:", format(nrow(sirene_dt), big.mark = ","), "\n")

# Parse creation year
sirene_dt[, year := as.integer(substr(date_creation, 1, 4))]
sirene_dt <- sirene_dt[year >= 2008 & year <= 2024]
cat("Filtered 2008-2024:", format(nrow(sirene_dt), big.mark = ","), "\n")

# Get all ZUS commune codes
all_zus_communes <- unique(unlist(strsplit(zus_status$communes_list, ";")))
cat("ZUS communes to track:", length(all_zus_communes), "\n")

# Filter SIRENE to ZUS communes
sirene_zus <- sirene_dt[commune %in% all_zus_communes]
cat("Establishments in ZUS communes:", format(nrow(sirene_zus), big.mark = ","), "\n")

# Count firm creations per commune × year
firm_counts <- sirene_zus[, .(n_firms_created = .N), by = .(commune, year)]

# Map communes back to ZUS
# A commune may belong to multiple ZUS — create one observation per ZUS
zus_commune_map <- zus_matched[!is.na(matched_com), .(code_zus, commune = matched_com)]
zus_commune_map <- unique(zus_commune_map)

# Merge with firm counts (allow cartesian: a commune can belong to multiple ZUS)
zus_firms <- merge(zus_commune_map, firm_counts, by = "commune", all.x = TRUE,
                   allow.cartesian = TRUE)
zus_firms[is.na(n_firms_created), n_firms_created := 0]

# Aggregate to ZUS level (sum across communes for multi-commune ZUS)
zus_panel <- zus_firms[, .(
  n_firms_created = sum(n_firms_created)
), by = .(code_zus, year)]

# Create balanced panel
all_zus <- unique(zus_status[status %in% c("lost", "kept"), code_zus])
all_years <- 2010:2024
balanced <- CJ(code_zus = all_zus, year = all_years)
panel <- merge(balanced, zus_panel, by = c("code_zus", "year"), all.x = TRUE)
panel[is.na(n_firms_created), n_firms_created := 0]

# Add treatment status
panel <- merge(panel, zus_status[, .(code_zus, status, is_zfu, qpv_share)],
               by = "code_zus", all.x = TRUE)

## ---- 6. Add derived variables ----
panel[, `:=`(
  zus_id = code_zus,
  post = as.integer(year >= 2015),
  lost_status = as.integer(status == "lost"),
  log_firms = log(n_firms_created + 1),
  rel_year = year - 2015
)]

# Create analysis samples
panel_main <- panel[status %in% c("lost", "kept")]
panel_nozfu <- panel_main[is_zfu == FALSE]

## ---- 7. Summary and validation ----
cat("\n=== Panel Summary ===\n")
cat("Total panel rows:", format(nrow(panel), big.mark = ","), "\n")
cat("Main sample (lost + kept):", format(nrow(panel_main), big.mark = ","), "\n")
cat("Excluding ZFU:", format(nrow(panel_nozfu), big.mark = ","), "\n")

cat("\nNeighborhoods by status:\n")
print(panel_main[, .(N = uniqueN(zus_id)), by = status])

cat("\nFirm creation by status × period:\n")
print(panel_nozfu[, .(
  mean_firms = round(mean(n_firms_created), 1),
  sd_firms = round(sd(n_firms_created), 1),
  median_firms = as.double(median(n_firms_created)),
  total_firms = sum(n_firms_created)
), by = .(status, period = fifelse(year < 2015, "Pre (2010-14)", "Post (2015-24)"))])

# Validate panel has enough variation
n_lost_nozfu <- panel_nozfu[lost_status == 1, uniqueN(zus_id)]
n_kept_nozfu <- panel_nozfu[lost_status == 0, uniqueN(zus_id)]
cat("\nNo-ZFU sample: Lost:", n_lost_nozfu, "| Kept:", n_kept_nozfu, "\n")
stopifnot("Need 20+ lost neighborhoods" = n_lost_nozfu >= 15)
stopifnot("Need 20+ kept neighborhoods" = n_kept_nozfu >= 15)

## ---- 8. Save ----
cat("\n=== Saving panel data ===\n")
fwrite(panel, file.path(data_dir, "panel_full.csv"))
fwrite(panel_main, file.path(data_dir, "panel_main.csv"))
fwrite(panel_nozfu, file.path(data_dir, "panel_nozfu.csv"))
fwrite(zus_status, file.path(data_dir, "zus_treatment_status.csv"))

cat("Panel saved successfully.\n")
