## 01_fetch_data.R — Load SHRUG data from local files
## Paper: The Bureaucrat's Bonus (apep_0821)

source("code/00_packages.R")

shrug_dir <- file.path("..", "..", "..", "data", "india_shrug")

## --- Load district-level datasets ---
cat("Loading SHRUG district-level data...\n")

ec05 <- fread(file.path(shrug_dir, "ec05_pc11dist.tab"))
cat(sprintf("EC 2005 districts: %d rows\n", nrow(ec05)))

dmsp <- fread(file.path(shrug_dir, "dmsp_pc11dist.tab"))
cat(sprintf("DMSP nightlights: %d rows\n", nrow(dmsp)))

ec13 <- fread(file.path(shrug_dir, "ec13_pc11dist.tab"))
cat(sprintf("EC 2013 districts: %d rows\n", nrow(ec13)))

pca11 <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.tab"))
cat(sprintf("PCA 2011 districts: %d rows\n", nrow(pca11)))

td11 <- fread(file.path(shrug_dir, "pc11_td_clean_pc11dist.tab"))
cat(sprintf("TD 2011 districts: %d rows\n", nrow(td11)))

## --- Load SHRID-level keys for concordance ---
cat("\nLoading SHRID key files for concordance...\n")

ec05_key <- fread(file.path(shrug_dir, "ec05r_shrid_key.tab"),
                  select = c("shrid2", "ec05_state_id", "ec05_district_id"))
pc11_key <- fread(file.path(shrug_dir, "pc11r_shrid_key.tab"),
                  select = c("shrid2", "pc11_state_id", "pc11_district_id"))
cat(sprintf("EC05 key: %d SHRIDs, PC11 key: %d SHRIDs\n", nrow(ec05_key), nrow(pc11_key)))

## --- Build district concordance: EC05 codes -> PC11 codes ---
cat("\nBuilding EC05-to-PC11 district concordance...\n")

# Clean EC05 key IDs — they have trailing .0
ec05_key[, ec05_state_id := gsub('\\"', '', ec05_state_id)]
ec05_key[, ec05_district_id := gsub('\\"', '', ec05_district_id)]
ec05_key[, ec05_state_id := as.integer(as.numeric(ec05_state_id))]
ec05_key[, ec05_district_id := as.integer(as.numeric(ec05_district_id))]

# Clean PC11 key IDs
pc11_key[, pc11_state_id := gsub('\\"', '', pc11_state_id)]
pc11_key[, pc11_district_id := gsub('\\"', '', pc11_district_id)]
pc11_key[, pc11_state_id := as.integer(pc11_state_id)]
pc11_key[, pc11_district_id := as.integer(pc11_district_id)]

# Merge on shrid2
concordance <- merge(ec05_key, pc11_key, by = "shrid2", all = FALSE)
cat(sprintf("Matched SHRIDs: %d\n", nrow(concordance)))

# Get unique district-level mapping (many-to-many possible due to splits)
dist_map <- unique(concordance[, .(ec05_state_id, ec05_district_id,
                                    pc11_state_id, pc11_district_id)])
cat(sprintf("Unique district mappings: %d\n", nrow(dist_map)))

## --- Clean EC05 district IDs to match concordance ---
ec05[, pc01_state_id := as.integer(gsub('\\"', '', pc01_state_id))]
ec05[, pc01_district_id := as.integer(gsub('\\"', '', pc01_district_id))]

## --- Map EC05 to PC11 district codes ---
# EC05 uses ec05 codes which correspond to pc01 codes
ec05_mapped <- merge(ec05, dist_map,
                     by.x = c("pc01_state_id", "pc01_district_id"),
                     by.y = c("ec05_state_id", "ec05_district_id"),
                     all.x = TRUE, allow.cartesian = TRUE)

# Some EC05 districts may map to multiple PC11 districts (splits)
# Weight by population if possible, but for now use equal split
split_count <- ec05_mapped[, .N, by = .(pc01_state_id, pc01_district_id)]
ec05_mapped <- merge(ec05_mapped, split_count,
                     by = c("pc01_state_id", "pc01_district_id"))
# Divide employment counts by number of splits
emp_cols <- grep("^ec05_emp_|^ec05_count_", names(ec05_mapped), value = TRUE)
for (col in emp_cols) {
  ec05_mapped[, (col) := get(col) / N]
}

# Aggregate to PC11 district level
ec05_pc11 <- ec05_mapped[!is.na(pc11_state_id),
                          lapply(.SD, sum, na.rm = TRUE),
                          by = .(pc11_state_id, pc11_district_id),
                          .SDcols = c("ec05_emp_all", "ec05_emp_gov",
                                      "ec05_emp_priv", "ec05_emp_hired",
                                      "ec05_count_all", "ec05_count_gov",
                                      "ec05_emp_services", "ec05_emp_manuf")]

cat(sprintf("EC05 mapped to PC11 districts: %d\n", nrow(ec05_pc11)))

## --- Save intermediate files ---
fwrite(ec05_pc11, "data/ec05_pc11_district.csv")
fwrite(dmsp, "data/dmsp_district.csv")
fwrite(ec13, "data/ec13_district.csv")
fwrite(pca11, "data/pca11_district.csv")
fwrite(td11, "data/td11_district.csv")

cat("\n=== Data loading complete ===\n")
cat(sprintf("EC05 PC11 districts: %d\n", nrow(ec05_pc11)))
cat(sprintf("DMSP district-years: %d\n", nrow(dmsp)))
cat(sprintf("Years in DMSP: %s\n", paste(sort(unique(dmsp$year)), collapse = ", ")))

# Validate data loaded correctly from SHRUG
if (nrow(ec05_pc11) == 0) stop("EC05 data is empty")
if (nrow(dmsp) == 0) stop("DMSP data is empty")
