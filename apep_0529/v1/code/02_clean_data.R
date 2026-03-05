## 02_clean_data.R — Construct analysis panels for apep_0529

source("00_packages.R")

data_dir <- "../data"

sf::sf_use_s2(FALSE)
if (!exists("%||%", mode = "function")) `%||%` <- function(a, b) if (!is.null(a)) a else b

## ============================================================
## A. ELECTION DATA
## ============================================================
cat("=== Processing election data ===\n")

## General results have code_circonscription - use this as primary
gen_all <- as.data.table(arrow::read_parquet(file.path(data_dir, "elections_general.parquet")))
cat("All election IDs:\n")
print(sort(unique(gen_all$id_election)))

## Legislative first round
gen_leg <- gen_all[grepl("_legi_t1$", id_election)]
gen_leg[, year := as.integer(substr(id_election, 1, 4))]
cat("Legislative 1st round general:", nrow(gen_leg), "rows\n")
cat("Years:", paste(sort(unique(gen_leg$year)), collapse = ", "), "\n")

## Build BV-to-constituency mapping from general results
bv_circ <- unique(gen_leg[, .(id_brut_miom, code_departement, code_commune,
                               code_circonscription)])
## Remove duplicates (take first if any)
bv_circ <- bv_circ[!duplicated(id_brut_miom)]
cat("BV-to-constituency mapping:", nrow(bv_circ), "BVs\n")

rm(gen_all); gc(verbose = FALSE)

## Now load candidate data
cand_all <- as.data.table(arrow::read_parquet(file.path(data_dir, "elections_candidats.parquet")))
cand_leg <- cand_all[grepl("_legi_t1$", id_election)]
cand_leg[, year := as.integer(substr(id_election, 1, 4))]
cat("Legislative 1st round candidates:", nrow(cand_leg), "rows\n")

rm(cand_all); gc(verbose = FALSE)

## Merge constituency info from BV mapping
cand_leg <- merge(cand_leg, bv_circ[, .(id_brut_miom, code_circonscription)],
                  by = "id_brut_miom", all.x = TRUE, allow.cartesian = FALSE)
cand_leg[, circ_id := paste0(code_departement, "_", code_circonscription)]

cat("Merged ok. Rows with constituency:", sum(!is.na(cand_leg$code_circonscription)),
    "of", nrow(cand_leg), "\n")

## Drop rows without constituency mapping
cand_leg <- cand_leg[!is.na(code_circonscription)]

## ============================================================
## B. Constituency-level outcomes
## ============================================================
cat("=== Computing constituency-level outcomes ===\n")

## Aggregate votes by candidate at constituency level
circ_cand <- cand_leg[, .(
  votes = sum(voix, na.rm = TRUE)
), by = .(year, circ_id, code_departement, code_circonscription, no_panneau, nuance)]

circ_total <- circ_cand[, .(total_votes = sum(votes)),
                         by = .(year, circ_id)]
circ_cand <- merge(circ_cand, circ_total, by = c("year", "circ_id"))
circ_cand[, vote_share := votes / total_votes]

## ENP at constituency level (by candidate, not nuance)
cand_shares <- circ_cand[, .(
  votes = sum(votes)
), by = .(year, circ_id, code_departement, code_circonscription, no_panneau)]
cand_shares <- merge(cand_shares, circ_total, by = c("year", "circ_id"))
cand_shares[, share := votes / total_votes]

circ_enp <- cand_shares[, .(
  enp = 1 / sum(share^2, na.rm = TRUE),
  n_candidates = .N,
  total_votes = total_votes[1]
), by = .(year, circ_id, code_departement, code_circonscription)]

## Party-specific vote shares by nuance
cat("Nuances:", paste(sort(unique(circ_cand$nuance)), collapse = ", "), "\n")

## Define party blocs
rn_nuances <- c("FN", "RN", "EXD", "REC")
green_nuances <- c("ECO", "VEC", "DVE")

compute_bloc_share <- function(dt, tot_dt, nuance_list, col_name) {
  bloc <- dt[nuance %in% nuance_list, .(
    bloc_votes = sum(votes, na.rm = TRUE)
  ), by = .(year, circ_id)]
  bloc <- merge(bloc, tot_dt, by = c("year", "circ_id"), all.y = TRUE)
  bloc[is.na(bloc_votes), bloc_votes := 0]
  bloc[, (col_name) := bloc_votes / total_votes]
  bloc[, .(year, circ_id, get(col_name))]
}

rn_dt <- circ_cand[nuance %in% rn_nuances, .(rn_votes = sum(votes)),
                    by = .(year, circ_id)]
green_dt <- circ_cand[nuance %in% green_nuances, .(green_votes = sum(votes)),
                      by = .(year, circ_id)]

circ_panel <- copy(circ_enp)
circ_panel <- merge(circ_panel, rn_dt, by = c("year", "circ_id"), all.x = TRUE)
circ_panel <- merge(circ_panel, green_dt, by = c("year", "circ_id"), all.x = TRUE)
circ_panel[is.na(rn_votes), rn_votes := 0]
circ_panel[is.na(green_votes), green_votes := 0]
circ_panel[, rn_share := rn_votes / total_votes]
circ_panel[, green_share := green_votes / total_votes]

## Turnout from general results
turnout <- gen_leg[, .(
  inscrits = sum(as.numeric(inscrits), na.rm = TRUE),
  votants = sum(as.numeric(votants), na.rm = TRUE)
), by = .(year, code_departement, code_circonscription)]
turnout[, circ_id := paste0(code_departement, "_", code_circonscription)]
turnout[, turnout_rate := votants / inscrits]

circ_panel <- merge(circ_panel, turnout[, .(year, circ_id, turnout_rate, inscrits)],
                    by = c("year", "circ_id"), all.x = TRUE)

cat("Panel:", nrow(circ_panel), "rows,",
    uniqueN(circ_panel$circ_id), "constituencies,",
    uniqueN(circ_panel$year), "years\n")
cat("Mean ENP:", round(mean(circ_panel$enp, na.rm = TRUE), 2), "\n")
cat("Mean RN share:", round(mean(circ_panel$rn_share, na.rm = TRUE), 3), "\n")
cat("Mean Green share:", round(mean(circ_panel$green_share, na.rm = TRUE), 3), "\n")

## ============================================================
## C. ZFE-Constituency Crosswalk
## ============================================================
cat("=== ZFE-constituency overlaps ===\n")

circ_sf <- sf::st_read(file.path(data_dir, "circonscriptions.geojson"), quiet = TRUE)
zfe_sf <- sf::st_read(file.path(data_dir, "zfe_aires.geojson"), quiet = TRUE)

circ_sf <- sf::st_transform(circ_sf, 2154)
zfe_sf <- sf::st_transform(zfe_sf, 2154)
circ_sf <- sf::st_make_valid(circ_sf)
zfe_sf <- sf::st_make_valid(zfe_sf)

zfe_union <- sf::st_union(zfe_sf)

## Normalize circ IDs: GeoJSON codeCirconscription = dept+circ (e.g., "0104" = dept 01, circ 04)
## Election data uses code_departement + code_circonscription (e.g., "01" + "04")
## Strip department prefix from GeoJSON's codeCirconscription
circ_sf$circ_num <- mapply(function(dept, circ) sub(paste0("^", dept), "", circ),
  circ_sf$codeDepartement, circ_sf$codeCirconscription)
circ_sf$circ_id <- paste0(circ_sf$codeDepartement, "_", circ_sf$circ_num)
circ_sf$total_area_m2 <- as.numeric(sf::st_area(circ_sf))

overlap <- tryCatch(
  suppressWarnings(sf::st_intersection(circ_sf, zfe_union)),
  error = function(e) {
    cat("  Intersection error, buffering geometries...\n")
    circ_buf <- sf::st_buffer(circ_sf, 0)
    zfe_buf <- sf::st_buffer(zfe_union, 0)
    sf::st_intersection(circ_buf, zfe_buf)
  }
)
overlap$overlap_area_m2 <- as.numeric(sf::st_area(overlap))

overlap$circ_id <- mapply(function(dept, circ) paste0(dept, "_", sub(paste0("^", dept), "", circ)),
  overlap$codeDepartement, overlap$codeCirconscription)
overlap_dt <- data.table(
  circ_id = overlap$circ_id,
  overlap_area_m2 = overlap$overlap_area_m2
)
## Some constituencies might intersect multiple ZFE fragments; sum areas
overlap_dt <- overlap_dt[, .(overlap_area_m2 = sum(overlap_area_m2)), by = circ_id]

circ_area_dt <- data.table(
  circ_id = circ_sf$circ_id,
  total_area_m2 = circ_sf$total_area_m2
)

zfe_exposure <- merge(circ_area_dt, overlap_dt, by = "circ_id", all.x = TRUE)
zfe_exposure[is.na(overlap_area_m2), overlap_area_m2 := 0]
zfe_exposure[, zfe_area_share := overlap_area_m2 / total_area_m2]
zfe_exposure[, zfe_treated := as.integer(zfe_area_share > 0.01)]

cat("ZFE constituencies:", sum(zfe_exposure$zfe_treated), "of", nrow(zfe_exposure), "\n")

## ============================================================
## D. Treatment assignment
## ============================================================
cat("=== Treatment assignment ===\n")

zfe_timeline <- fread(file.path(data_dir, "zfe_timeline.csv"))

## Map departments to treatment year (earliest ZFE in department)
zfe_timeline[, departement := as.character(departement)]
dept_treatment <- zfe_timeline[, .(
  zfe_start = min(as.Date(zfe_start)),
  wave = min(wave)
), by = departement]

## Treatment turns on at the first election after ZFE start
## Legislative elections: 2002, 2007, 2012, 2017, 2022, 2024
dept_treatment[, treatment_year := fifelse(
  zfe_start < as.Date("2022-06-01"), 2022L,
  fifelse(zfe_start < as.Date("2024-06-01"), 2024L, NA_integer_)
)]

## Merge treatment into panel
circ_panel <- merge(circ_panel, zfe_exposure[, .(circ_id, zfe_area_share, zfe_treated)],
                    by = "circ_id", all.x = TRUE)
circ_panel[is.na(zfe_treated), zfe_treated := 0L]
circ_panel[is.na(zfe_area_share), zfe_area_share := 0]

circ_panel <- merge(circ_panel,
                    dept_treatment[, .(departement, treatment_year, wave)],
                    by.x = "code_departement", by.y = "departement",
                    all.x = TRUE)

## Event time and post indicator
circ_panel[, treated_group := as.integer(zfe_treated == 1 & !is.na(treatment_year))]
circ_panel[, post := as.integer(treated_group == 1 & year >= treatment_year)]
circ_panel[treated_group == 0, post := 0L]

## Cohort variable for CS-DiD
circ_panel[, cohort := fifelse(treated_group == 1, treatment_year, 0L)]

cat("Treated group:", sum(circ_panel$treated_group == 1) / uniqueN(circ_panel$year),
    "constituencies per year\n")
cat("Control group:", sum(circ_panel$treated_group == 0) / uniqueN(circ_panel$year),
    "constituencies per year\n")

## Summary stats
cat("\n--- Summary by treatment group ---\n")
print(circ_panel[, .(
  mean_enp = round(mean(enp, na.rm = TRUE), 2),
  mean_rn = round(mean(rn_share, na.rm = TRUE), 3),
  mean_green = round(mean(green_share, na.rm = TRUE), 3),
  mean_turnout = round(mean(turnout_rate, na.rm = TRUE), 3),
  N = .N
), by = .(treated_group, post)])

## ============================================================
## E. Roll-call vote panel
## ============================================================
cat("=== Roll-call votes ===\n")

scrutins <- readRDS(file.path(data_dir, "scrutins_all.rds"))

parse_scrutins <- function(scrutins_list) {
  all_rows <- list()
  for (leg_name in names(scrutins_list)) {
    leg_data <- scrutins_list[[leg_name]]
    if (is.null(leg_data)) next
    items <- if ("scrutins" %in% names(leg_data)) leg_data$scrutins else leg_data
    if (!is.list(items)) next
    for (item in items) {
      s <- if ("scrutin" %in% names(item)) item$scrutin else item
      if (is.null(s)) next
      sid <- if (!is.null(s$numero)) as.character(s$numero) else
             if (!is.null(s$id)) as.character(s$id) else NA_character_
      sdate <- if (!is.null(s$date)) as.character(s$date) else NA_character_
      stitle <- if (!is.null(s$titre)) as.character(s$titre) else
                if (!is.null(s$demandeur)) as.character(s$demandeur) else ""
      ssort <- if (!is.null(s$sort)) as.character(s$sort) else NA_character_
      all_rows[[length(all_rows) + 1]] <- data.table(
        legislature = as.integer(leg_name),
        scrutin_id = sid, date = sdate,
        title = stitle, sort = ssort
      )
    }
  }
  rbindlist(all_rows, fill = TRUE)
}

scrutins_dt <- parse_scrutins(scrutins)
scrutins_dt[, date := as.Date(date)]

climate_kw <- c("emission", "climat", "pollution", "environnement",
                "mobilite", "transport", "ZFE", "vignette", "Crit.Air",
                "carbone", "ecologique", "energie", "vehicule",
                "faibles emissions", "qualite de l.air")
scrutins_dt[, is_climate := as.integer(
  grepl(paste(climate_kw, collapse = "|"), title, ignore.case = TRUE)
)]

cat("Scrutins:", nrow(scrutins_dt), "total,", sum(scrutins_dt$is_climate), "climate-related\n")

## ============================================================
## F. Deputy panel
## ============================================================
cat("=== Deputies ===\n")

deputes_raw <- readRDS(file.path(data_dir, "deputes_current.rds"))

parse_deputes <- function(dep_data) {
  items <- dep_data$deputes
  if (is.null(items) || length(items) == 0) return(data.table())
  all_rows <- lapply(items, function(item) {
    d <- item$depute
    if (is.null(d)) return(NULL)
    data.table(
      slug = as.character(d$slug %||% NA),
      nom = as.character(d$nom %||% NA),
      groupe_sigle = as.character(d$groupe_sigle %||% NA),
      num_deptmt = as.character(d$num_deptmt %||% NA),
      num_circo = as.character(d$num_circo %||% NA)
    )
  })
  rbindlist(all_rows, fill = TRUE)
}

deputes_dt <- parse_deputes(deputes_raw)
deputes_dt[, circ_id := paste0(num_deptmt, "_", num_circo)]

cat("Deputies:", nrow(deputes_dt), "\n")
cat("Groups:", paste(sort(unique(deputes_dt$groupe_sigle)), collapse = ", "), "\n")

## ============================================================
## G. Save
## ============================================================
cat("=== Saving ===\n")

fwrite(circ_panel, file.path(data_dir, "circ_election_panel.csv"))
fwrite(scrutins_dt, file.path(data_dir, "scrutins_panel.csv"))
fwrite(deputes_dt, file.path(data_dir, "deputes_panel.csv"))
fwrite(zfe_exposure, file.path(data_dir, "zfe_constituency_exposure.csv"))

cat("\n=== CLEAN COMPLETE ===\n")
cat("circ_election_panel.csv:", nrow(circ_panel), "rows\n")
cat("scrutins_panel.csv:", nrow(scrutins_dt), "rows\n")
cat("deputes_panel.csv:", nrow(deputes_dt), "rows\n")
