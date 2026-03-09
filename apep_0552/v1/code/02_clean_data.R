# =============================================================================
# 02_clean_data.R — Clean DVF, DPE; match and construct analysis panel
# APEP Paper apep_0552: Stranded by the Label?
# Memory-efficient: uses DuckDB for out-of-core processing (8GB RAM constraint)
# =============================================================================

source("00_packages.R")

cat("=== Memory-efficient cleaning pipeline ===\n")
cat("Available RAM:", Sys.getenv("APEP_MAX_RAM_GB", "8"), "GB\n")

# =============================================================================
# 1. Filter DVF using DuckDB (out-of-core)
# =============================================================================

cat("\n=== Step 1: Filter DVF via DuckDB ===\n")

con <- DBI::dbConnect(duckdb::duckdb())

# Register parquet file - DuckDB reads lazily, not into RAM
DBI::dbExecute(con, sprintf(
  "CREATE VIEW dvf_raw AS SELECT * FROM read_parquet('%s')",
  file.path(data_dir, "dvf_all.parquet")
))

# Count and filter in DuckDB
cat("Total DVF rows:", dbGetQuery(con, "SELECT count(*) FROM dvf_raw")[[1]], "\n")

# Create filtered residential sales view
DBI::dbExecute(con, "
  CREATE TABLE dvf_clean AS
  SELECT
    id_mutation,
    date_mutation,
    nature_mutation,
    valeur_fonciere AS price,
    code_commune,
    code_departement AS dept,
    type_local,
    surface_reelle_bati,
    nombre_pieces_principales,
    longitude,
    latitude,
    year,
    EXTRACT(QUARTER FROM CAST(date_mutation AS DATE)) AS quarter,
    CASE WHEN type_local = 'Appartement' THEN 1 ELSE 0 END AS is_apartment,
    LOG(valeur_fonciere) AS log_price,
    valeur_fonciere / GREATEST(surface_reelle_bati, 1) AS price_sqm,
    CASE WHEN CAST(date_mutation AS DATE) >= DATE '2021-07-01' THEN 1 ELSE 0 END AS post_reform,
    CONCAT(year, 'Q', EXTRACT(QUARTER FROM CAST(date_mutation AS DATE))) AS yq,
    CONCAT(year, 'S', CASE WHEN EXTRACT(MONTH FROM CAST(date_mutation AS DATE)) <= 6 THEN '1' ELSE '2' END) AS semester
  FROM dvf_raw
  WHERE nature_mutation = 'Vente'
    AND type_local IN ('Maison', 'Appartement')
    AND valeur_fonciere >= 10000
    AND valeur_fonciere <= 5000000
    AND longitude IS NOT NULL
    AND latitude IS NOT NULL
    AND surface_reelle_bati > 0
    AND valeur_fonciere / GREATEST(surface_reelle_bati, 1) BETWEEN 200 AND 30000
    AND code_departement NOT IN ('57', '67', '68', '976')
")

n_dvf <- dbGetQuery(con, "SELECT count(*) FROM dvf_clean")[[1]]
cat("Clean DVF rows:", n_dvf, "\n")

yr_range <- dbGetQuery(con, "SELECT MIN(year), MAX(year) FROM dvf_clean")
cat("Year range:", yr_range[[1]], "-", yr_range[[2]], "\n")

# =============================================================================
# 2. Clean DPE using DuckDB
# =============================================================================

cat("\n=== Step 2: Clean DPE via DuckDB ===\n")

DBI::dbExecute(con, sprintf(
  "CREATE VIEW dpe_raw AS SELECT * FROM read_parquet('%s')",
  file.path(data_dir, "dpe_post2021.parquet")
))

cat("Raw DPE rows:", dbGetQuery(con, "SELECT count(*) FROM dpe_raw")[[1]], "\n")

# Identify column names (they vary between API responses)
dpe_cols <- dbGetQuery(con, "SELECT * FROM dpe_raw LIMIT 0")
cat("DPE columns:", paste(names(dpe_cols), collapse = ", "), "\n")

# Build column name mappings dynamically
has_etiquette_dpe <- "etiquette_dpe" %in% names(dpe_cols)
has_conso <- "conso_5_usages_par_m2_ep" %in% names(dpe_cols)
has_x_ban <- "coordonnee_cartographique_x_ban" %in% names(dpe_cols)
has_insee <- "code_insee_ban" %in% names(dpe_cols)

rating_col <- if (has_etiquette_dpe) "etiquette_dpe" else "dpe_rating"
kwh_col <- if (has_conso) "conso_5_usages_par_m2_ep" else "kwh_m2_year"
x_col <- if (has_x_ban) "coordonnee_cartographique_x_ban" else "dpe_x_lambert"
y_col <- if (has_x_ban) "coordonnee_cartographique_y_ban" else "dpe_y_lambert"
insee_col <- if (has_insee) "code_insee_ban" else "dpe_insee_code"

DBI::dbExecute(con, sprintf("
  CREATE TABLE dpe_clean AS
  SELECT
    %s AS dpe_rating,
    CAST(%s AS DOUBLE) AS kwh_m2_year,
    CAST(%s AS DOUBLE) AS dpe_x,
    CAST(%s AS DOUBLE) AS dpe_y,
    LPAD(CAST(%s AS VARCHAR), 5, '0') AS dpe_commune,
    date_etablissement_dpe AS dpe_date,
    type_batiment AS building_type,
    periode_construction AS construction_period
  FROM dpe_raw
  WHERE UPPER(%s) IN ('A','B','C','D','E','F','G')
    AND %s IS NOT NULL
    AND CAST(%s AS DOUBLE) > 0
    AND CAST(%s AS DOUBLE) < 2000
    AND %s IS NOT NULL
    AND %s IS NOT NULL
    AND CAST(%s AS DOUBLE) BETWEEN 100000 AND 1250000
    AND CAST(%s AS DOUBLE) BETWEEN 6000000 AND 7200000
", rating_col, kwh_col, x_col, y_col, insee_col,
   rating_col, kwh_col, kwh_col, kwh_col,
   x_col, y_col, x_col, y_col
))

n_dpe <- dbGetQuery(con, "SELECT count(*) FROM dpe_clean")[[1]]
cat("Clean DPE rows:", n_dpe, "\n")
cat("DPE rating distribution:\n")
print(dbGetQuery(con, "SELECT dpe_rating, COUNT(*) AS n FROM dpe_clean GROUP BY dpe_rating ORDER BY dpe_rating"))

# =============================================================================
# 3. Commune-level matching (memory-efficient alternative to spatial)
# =============================================================================

cat("\n=== Step 3: Commune-level DVF-DPE merge ===\n")

# Compute commune-level modal DPE rating and mean kWh
DBI::dbExecute(con, "
  CREATE TABLE dpe_commune AS
  SELECT
    dpe_commune,
    MODE(dpe_rating) AS modal_rating,
    AVG(kwh_m2_year) AS mean_kwh,
    STDDEV(kwh_m2_year) AS sd_kwh,
    COUNT(*) AS n_dpe,
    SUM(CASE WHEN dpe_rating = 'G' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_G,
    SUM(CASE WHEN dpe_rating = 'F' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_F,
    SUM(CASE WHEN dpe_rating IN ('F','G') THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_passoire,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY kwh_m2_year) AS kwh_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY kwh_m2_year) AS kwh_p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY kwh_m2_year) AS kwh_p75
  FROM dpe_clean
  GROUP BY dpe_commune
  HAVING COUNT(*) >= 5
")

n_communes <- dbGetQuery(con, "SELECT count(*) FROM dpe_commune")[[1]]
cat("DPE communes (>=5 certs):", n_communes, "\n")

# Spatial matching: For each department, read DVF and DPE chunks into R
# and do nearest-neighbor matching within 50m
# Process one department at a time to stay under 8GB RAM

cat("\n=== Step 4: Spatial matching by department ===\n")

# Get list of departments with both DVF and DPE data
depts <- dbGetQuery(con, "
  SELECT DISTINCT d.dept
  FROM dvf_clean d
  INNER JOIN dpe_clean p ON d.code_commune = p.dpe_commune
  ORDER BY d.dept
")$dept

cat("Departments with matched data:", length(depts), "\n")

matched_file <- file.path(data_dir, "analysis_panel.parquet")
first_chunk <- TRUE

for (dept_code in depts) {
  # Read DVF for this department (small subset)
  dvf_dept <- dbGetQuery(con, sprintf("
    SELECT * FROM dvf_clean WHERE dept = '%s'
  ", dept_code))
  setDT(dvf_dept)

  # Read DPE for communes in this department
  communes_in_dept <- unique(dvf_dept$code_commune)
  if (length(communes_in_dept) == 0) next

  commune_list <- paste(sprintf("'%s'", communes_in_dept), collapse = ",")
  dpe_dept <- dbGetQuery(con, sprintf("
    SELECT * FROM dpe_clean WHERE dpe_commune IN (%s)
  ", commune_list))
  setDT(dpe_dept)

  if (nrow(dpe_dept) == 0) next

  # Convert DVF coords (WGS84) to Lambert-93 for distance matching
  tryCatch({
    dvf_sf <- st_as_sf(dvf_dept, coords = c("longitude", "latitude"), crs = 4326)
    dvf_sf <- st_transform(dvf_sf, 2154)
    dvf_coords <- st_coordinates(dvf_sf)
    dvf_dept[, c("x_lambert", "y_lambert") := .(dvf_coords[,1], dvf_coords[,2])]

    # For each DVF transaction, find nearest DPE in same commune within 50m
    # Using simple Euclidean distance in Lambert-93 (meters)
    matched_rows <- list()

    for (comm in communes_in_dept) {
      dvf_c <- dvf_dept[code_commune == comm]
      dpe_c <- dpe_dept[dpe_commune == comm]
      if (nrow(dvf_c) == 0 || nrow(dpe_c) == 0) next

      # Vectorized nearest-neighbor using outer distance matrix in chunks
      # For large communes, process in sub-chunks of 5000
      sub_size <- 5000
      n_sub <- ceiling(nrow(dvf_c) / sub_size)

      for (s in seq_len(n_sub)) {
        s_start <- (s - 1) * sub_size + 1
        s_end <- min(s * sub_size, nrow(dvf_c))
        dvf_sub <- dvf_c[s_start:s_end]

        # Distance matrix
        dx <- outer(dvf_sub$x_lambert, dpe_c$dpe_x, `-`)
        dy <- outer(dvf_sub$y_lambert, dpe_c$dpe_y, `-`)
        dist_mat <- sqrt(dx^2 + dy^2)

        # Find nearest and check if within 50m
        nearest_idx <- apply(dist_mat, 1, which.min)
        nearest_dist <- dist_mat[cbind(seq_len(nrow(dvf_sub)), nearest_idx)]
        close <- nearest_dist <= 50

        if (sum(close) > 0) {
          result <- dvf_sub[close]
          dpe_match <- dpe_c[nearest_idx[close]]
          result[, `:=`(
            dpe_rating = dpe_match$dpe_rating,
            kwh_m2_year = dpe_match$kwh_m2_year,
            building_type = dpe_match$building_type,
            construction_period = dpe_match$construction_period,
            match_distance_m = nearest_dist[close]
          )]
          matched_rows[[length(matched_rows) + 1]] <- result
        }

        rm(dx, dy, dist_mat)
      }
    }

    if (length(matched_rows) > 0) {
      dept_matched <- rbindlist(matched_rows, fill = TRUE)

      # Append to parquet file
      if (first_chunk) {
        arrow::write_parquet(dept_matched, matched_file)
        first_chunk <- FALSE
      } else {
        # Read existing, append, write back
        existing <- arrow::read_parquet(matched_file)
        combined <- rbind(setDT(existing), dept_matched, fill = TRUE)
        arrow::write_parquet(combined, matched_file)
        rm(existing, combined)
      }

      if (which(depts == dept_code) %% 10 == 0) {
        n_total <- arrow::read_parquet(matched_file, as_data_frame = FALSE)$num_rows
        cat("  Dept", dept_code, ":", nrow(dept_matched), "matches. Total:", n_total, "\n")
      }
    }
  }, error = function(e) {
    cat("  Error in dept", dept_code, ":", e$message, "\n")
  })

  rm(dvf_dept, dpe_dept)
  gc(verbose = FALSE)
}

# =============================================================================
# 5. Construct analysis variables
# =============================================================================

cat("\n=== Step 5: Constructing analysis variables ===\n")

# Read the matched panel
dvf_matched <- arrow::read_parquet(matched_file)
setDT(dvf_matched)
cat("Matched panel rows:", nrow(dvf_matched), "\n")

# DPE binary indicators
dvf_matched[, is_G := as.integer(dpe_rating == "G")]
dvf_matched[, is_F := as.integer(dpe_rating == "F")]
dvf_matched[, is_E := as.integer(dpe_rating == "E")]
dvf_matched[, is_D := as.integer(dpe_rating == "D")]
dvf_matched[, is_FG := as.integer(dpe_rating %in% c("F", "G"))]
dvf_matched[, passoire := as.integer(dpe_rating %in% c("F", "G"))]

# Distance to thresholds
dvf_matched[, dist_to_GF := kwh_m2_year - 420]
dvf_matched[, dist_to_FE := kwh_m2_year - 330]
dvf_matched[, dist_to_ED := kwh_m2_year - 250]

# Compute rental share proxy from pre-reform apartment share
commune_proxy <- dvf_matched[post_reform == 0, .(
  pct_rental = mean(is_apartment, na.rm = TRUE),
  n_transactions_pre = .N
), by = code_commune]
dvf_matched <- merge(dvf_matched, commune_proxy, by = "code_commune", all.x = TRUE)

# Rental-share terciles
dvf_matched[, rental_tercile := cut(pct_rental,
                                     breaks = quantile(pct_rental, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                                     labels = c("Low rental", "Medium rental", "High rental"),
                                     include.lowest = TRUE)]

# Log price per sqm
dvf_matched[, log_price_sqm := log(price_sqm)]

cat("\nFinal analysis dataset:\n")
cat("  Rows:", nrow(dvf_matched), "\n")
cat("  Communes:", uniqueN(dvf_matched$code_commune), "\n")
cat("  Year range:", min(dvf_matched$year, na.rm = TRUE), "-", max(dvf_matched$year, na.rm = TRUE), "\n")
cat("  DPE rating distribution:\n")
print(dvf_matched[, .N, by = dpe_rating][order(dpe_rating)])

# Save
arrow::write_parquet(dvf_matched, matched_file)
cat("\nAnalysis panel saved:", nrow(dvf_matched), "rows\n")

# Save summary stats for reference
summary_stats <- dvf_matched[, .(
  n = .N,
  mean_price = mean(price),
  median_price = median(price),
  mean_price_sqm = mean(price_sqm),
  mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
  pct_apartment = mean(is_apartment),
  pct_G = mean(is_G),
  pct_F = mean(is_F),
  pct_passoire = mean(passoire)
), by = .(year, post_reform)]
fwrite(summary_stats, file.path(data_dir, "summary_by_year.csv"))

# Clean up
DBI::dbDisconnect(con, shutdown = TRUE)
rm(dvf_matched); gc()

cat("\n=== Cleaning complete ===\n")
