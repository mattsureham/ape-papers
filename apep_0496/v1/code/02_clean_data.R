## =============================================================================
## 02_clean_data.R — Clean data and construct boundary distance measures
## apep_0496: Education Priority Labels and Housing Markets in France
##
## APPROACH: For each DVF transaction, find the nearest REP and nearest
## non-REP public collège using RANN kd-tree (fast O(N log M)).
## The running variable is:
##   dist_signed = dist_to_nearest_nonREP - dist_to_nearest_REP
## Positive = closer to REP collège (REP side), negative = closer to non-REP collège.
## The "boundary" is at 0 where the transaction is equidistant.
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## ---------------------------------------------------------------------------
## 1. Load and clean DVF
## ---------------------------------------------------------------------------

cat("=== Loading DVF ===\n")

dvf <- fread(file.path(data_dir, "dvf_geolocalisee.csv.gz"),
             encoding = "UTF-8")
cat("Raw rows:", format(nrow(dvf), big.mark = ","), "\n")

# Filter to residential sales
dvf <- dvf[nature_mutation == "Vente" &
             type_local %in% c("Appartement", "Maison") &
             !is.na(valeur_fonciere) & valeur_fonciere > 0 &
             !is.na(surface_reelle_bati) & surface_reelle_bati > 0 &
             !is.na(longitude) & !is.na(latitude) &
             longitude != 0 & latitude != 0]

dvf[, price_m2 := valeur_fonciere / surface_reelle_bati]
dvf <- dvf[price_m2 >= 200 & price_m2 <= 30000]
dvf[, year := as.integer(format(as.Date(date_mutation), "%Y"))]

# Deduplicate by mutation (keep one record per mutation+local type)
dvf <- unique(dvf, by = c("id_mutation", "type_local"))

cat("Cleaned:", format(nrow(dvf), big.mark = ","), "transactions\n")
cat("Years:", paste(sort(unique(dvf$year)), collapse = ", "), "\n")

## ---------------------------------------------------------------------------
## 2. Build collège dataset with REP status
## ---------------------------------------------------------------------------

cat("\n=== Building collège dataset ===\n")

annuaire <- fread(file.path(data_dir, "annuaire_education.csv"),
                  encoding = "UTF-8")

# Public collèges with coordinates
pub_col <- annuaire[
  statut_public_prive == "Public" &
  grepl("Coll.ge", type_etablissement, ignore.case = TRUE) &
  !is.na(latitude) & !is.na(longitude) &
  latitude > 41 & latitude < 52 &  # mainland France bounds
  longitude > -6 & longitude < 10
]
cat("Public collèges:", nrow(pub_col), "\n")

# Merge REP status
rep_etab <- fread(file.path(data_dir, "rep_etablissements.csv"),
                  encoding = "UTF-8")
rep_col <- rep_etab[type_etablissement == "Collège",
                     .(uai = uai, rep_status = ep_2022_2023)]

pub_col[, uai := identifiant_de_l_etablissement]
pub_col <- merge(pub_col, rep_col, by = "uai", all.x = TRUE)
pub_col[is.na(rep_status) | rep_status == "HORS EP", rep_status := "Non-REP"]

cat("REP status:\n")
print(table(pub_col$rep_status))

# Separate into REP and non-REP sets
rep_schools <- pub_col[rep_status %in% c("REP", "REP+")]
nonrep_schools <- pub_col[rep_status == "Non-REP"]
cat("REP/REP+ collèges:", nrow(rep_schools), "\n")
cat("Non-REP collèges:", nrow(nonrep_schools), "\n")

## ---------------------------------------------------------------------------
## 3. Compute distances using RANN kd-tree (FAST)
## ---------------------------------------------------------------------------

cat("\n=== Computing distances to nearest collèges (kd-tree) ===\n")

# Scale coordinates to approximate meters for France
lat_scale <- 111320  # meters per degree latitude
lon_scale <- 111320 * cos(46.5 * pi / 180)  # ~76,600 m/deg lon at 46.5N

# Build scaled coordinate matrices
dvf_scaled <- cbind(dvf$longitude * lon_scale, dvf$latitude * lat_scale)
rep_scaled <- cbind(rep_schools$longitude * lon_scale, rep_schools$latitude * lat_scale)
nonrep_scaled <- cbind(nonrep_schools$longitude * lon_scale, nonrep_schools$latitude * lat_scale)

cat("Finding nearest REP collège (kd-tree)...\n")
nn_rep <- nn2(data = rep_scaled, query = dvf_scaled, k = 1)
cat("  Done.\n")

cat("Finding nearest non-REP collège (kd-tree)...\n")
nn_nonrep <- nn2(data = nonrep_scaled, query = dvf_scaled, k = 1)
cat("  Done.\n")

dvf[, dist_nearest_rep := as.numeric(nn_rep$nn.dists)]
dvf[, dist_nearest_nonrep := as.numeric(nn_nonrep$nn.dists)]

# Signed distance: positive = closer to REP (REP side)
# negative = closer to non-REP (non-REP side)
dvf[, dist_signed := dist_nearest_nonrep - dist_nearest_rep]

# Assignment and indicators
dvf[, assigned_rep := dist_nearest_rep < dist_nearest_nonrep]
dvf[, rep_side := as.integer(assigned_rep)]
dvf[, dist_boundary := pmin(dist_nearest_rep, dist_nearest_nonrep)]

# Add nearest school info
dvf[, nearest_rep_uai := rep_schools$uai[nn_rep$nn.idx]]
dvf[, nearest_nonrep_uai := nonrep_schools$uai[nn_nonrep$nn.idx]]
dvf[, nearest_rep_status := rep_schools$rep_status[nn_rep$nn.idx]]

cat("Distance summary (meters):\n")
cat("  To nearest REP:\n")
print(summary(dvf$dist_nearest_rep))
cat("  To nearest non-REP:\n")
print(summary(dvf$dist_nearest_nonrep))
cat("  Signed distance (running variable):\n")
print(summary(dvf$dist_signed))

cat("\nAssignment:\n")
cat("  Closer to REP:", sum(dvf$assigned_rep), "\n")
cat("  Closer to non-REP:", sum(!dvf$assigned_rep), "\n")

## ---------------------------------------------------------------------------
## 4. Restrict to competitive boundary zone
## ---------------------------------------------------------------------------

cat("\n=== Restricting to boundary zone ===\n")

# Keep only transactions where both nearest REP and nearest non-REP
# are within reasonable distance (< 5km each)
dvf_boundary <- dvf[dist_nearest_rep < 5000 & dist_nearest_nonrep < 5000]

cat("In boundary zone (both < 5km):", format(nrow(dvf_boundary), big.mark = ","), "\n")

# Tighter restriction for main analysis: within 2km of implicit boundary
dvf_near <- dvf_boundary[abs(dist_signed) <= 2000]
cat("Within 2km of boundary:", format(nrow(dvf_near), big.mark = ","), "\n")

## ---------------------------------------------------------------------------
## 5. Private school density (mechanism variable)
## ---------------------------------------------------------------------------

cat("\n=== Computing private school density ===\n")

priv_col <- annuaire[
  statut_public_prive == "Privé" &
  grepl("Coll.ge", type_etablissement, ignore.case = TRUE) &
  !is.na(latitude) & !is.na(longitude) &
  latitude > 41 & latitude < 52
]
cat("Private collèges:", nrow(priv_col), "\n")

priv_scaled <- cbind(priv_col$longitude * lon_scale, priv_col$latitude * lat_scale)

# For boundary zone transactions, count private collèges within 5km
# Use nn2 with k=20 (find 20 nearest private schools) and count those within 5km
cat("Counting nearby private schools...\n")
k_max <- min(20, nrow(priv_col))
bnd_scaled <- cbind(dvf_boundary$longitude * lon_scale, dvf_boundary$latitude * lat_scale)
nn_priv <- nn2(data = priv_scaled, query = bnd_scaled, k = k_max)

dvf_boundary[, n_private_5km := rowSums(nn_priv$nn.dists <= 5000)]

cat("Private school density summary:\n")
print(summary(dvf_boundary$n_private_5km))

# High/low private density indicator
dvf_boundary[, high_private := as.integer(n_private_5km >= median(n_private_5km))]

## ---------------------------------------------------------------------------
## 6. Brevet results for school quality
## ---------------------------------------------------------------------------

cat("\n=== Loading brevet results ===\n")

brevet <- fread(file.path(data_dir, "brevet_par_etablissement.csv"),
                encoding = "UTF-8")
cat("Brevet rows:", format(nrow(brevet), big.mark = ","), "\n")

brev_names <- tolower(names(brevet))
names(brevet) <- brev_names
cat("Brevet columns:", paste(head(brev_names, 15), collapse = ", "), "\n")

## ---------------------------------------------------------------------------
## 7. Save analysis-ready datasets
## ---------------------------------------------------------------------------

cat("\n=== Saving ===\n")

# Key columns for analysis
keep_cols <- c("id_mutation", "date_mutation", "year",
               "valeur_fonciere", "surface_reelle_bati", "price_m2",
               "type_local", "nombre_pieces_principales",
               "code_commune", "nom_commune", "code_departement",
               "longitude", "latitude",
               "dist_nearest_rep", "dist_nearest_nonrep",
               "dist_signed", "assigned_rep", "rep_side",
               "dist_boundary", "nearest_rep_uai", "nearest_nonrep_uai",
               "nearest_rep_status")

# Add private density for boundary zone transactions
dvf_boundary_save <- dvf_boundary[, .SD,
  .SDcols = intersect(c(keep_cols, "n_private_5km", "high_private"),
                       names(dvf_boundary))]

saveRDS(dvf_boundary_save, file.path(data_dir, "analysis_data.rds"))
saveRDS(dvf[, .SD, .SDcols = intersect(keep_cols, names(dvf))],
        file.path(data_dir, "dvf_all.rds"))
saveRDS(pub_col, file.path(data_dir, "colleges.rds"))
saveRDS(brevet, file.path(data_dir, "brevet.rds"))

cat("\n=== Summary ===\n")
cat("Total DVF transactions:", format(nrow(dvf), big.mark = ","), "\n")
cat("Boundary zone (both < 5km):", format(nrow(dvf_boundary), big.mark = ","), "\n")
cat("Years:", paste(sort(unique(dvf_boundary$year)), collapse = ", "), "\n")
cat("Assignment: REP side =", sum(dvf_boundary$rep_side),
    ", non-REP side =", sum(!dvf_boundary$rep_side), "\n")
cat("Private collèges:", nrow(priv_col), "\n")
