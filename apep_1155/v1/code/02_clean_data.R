## 02_clean_data.R — Construct analysis panel for apep_1155
## Merges homicide rates, gang detentions, and population using numeric ID keys

source("00_packages.R")
data_dir <- "../data/"

plos <- readRDS(file.path(data_dir, "plos_raw.rds"))

# ============================================================
# 1. Homicide panel (S1) — already in long format
# ============================================================
cat("=== Processing homicide data ===\n")
hom <- as.data.table(plos$homicides)
setnames(hom, c("id_map", "muni_id", "year", "hom_rate", "dept_name", "muni_name"))
hom[, muni_id := as.integer(muni_id)]
cat(sprintf("  Observations: %d\n", nrow(hom)))
cat(sprintf("  Municipalities: %d\n", uniqueN(hom$muni_id)))
cat(sprintf("  Years: %d to %d\n", min(hom$year), max(hom$year)))

# ============================================================
# 2. Gang detentions (S2) — merge by mun_dep = muni_id
# ============================================================
cat("\n=== Processing gang detention data ===\n")
det <- as.data.table(plos$detentions)
det[, muni_id := as.integer(mun_dep)]

# 2011 detentions (last full pre-truce year)
det[, det_2011 := as.numeric(G2011)]
det[, det_total := G2011 + G2012 + G2013 + G2014 + G2015 + G2016 + G2017 + G2018]

cat(sprintf("  Municipalities with G2011 > 0: %d / %d\n",
            sum(det$det_2011 > 0), nrow(det)))

# ============================================================
# 3. Population (S3) — merge by id = muni_id
# ============================================================
cat("\n=== Processing population data ===\n")
pop <- as.data.table(plos$population)
pop[, muni_id := as.integer(id)]

# Reshape to long
pop_cols <- grep("^POB20", names(pop), value = TRUE)  # Only 2002-2022
pop_long <- melt(pop, id.vars = c("muni_id", "NAME_2"),
                 measure.vars = pop_cols,
                 variable.name = "year_var", value.name = "population")
pop_long[, year := as.integer(gsub("POB", "", year_var))]

# 2011 population for treatment normalization
pop_2011 <- pop[, .(muni_id, pop_2011 = POB2011)]

# ============================================================
# 4. Construct treatment variable
# ============================================================
cat("\n=== Constructing treatment variable ===\n")

# Merge detentions with 2011 population
muni_data <- merge(det[, .(muni_id, det_2011, det_total, dept_name = NAME_1, muni_name = NAME_2)],
                   pop_2011, by = "muni_id", all.x = TRUE)

# Gang intensity = 2011 detentions per 10,000 population
muni_data[, gang_intensity := (det_2011 / pop_2011) * 10000]
muni_data[is.na(gang_intensity) | is.infinite(gang_intensity), gang_intensity := 0]

# Standardize (mean 0, sd 1)
muni_data[, gang_intensity_std := (gang_intensity - mean(gang_intensity)) / sd(gang_intensity)]
# Binary: above median
muni_data[, high_gang := as.integer(gang_intensity > median(gang_intensity))]

cat(sprintf("  Mean gang intensity: %.2f per 10,000\n", mean(muni_data$gang_intensity)))
cat(sprintf("  SD gang intensity: %.2f\n", sd(muni_data$gang_intensity)))
cat(sprintf("  Municipalities with det_2011 > 0: %d\n", sum(muni_data$det_2011 > 0)))
cat(sprintf("  High-gang municipalities: %d\n", sum(muni_data$high_gang)))

# ============================================================
# 5. Build analysis panel
# ============================================================
cat("\n=== Building analysis panel ===\n")

# Merge treatment into homicide panel by muni_id
panel <- merge(hom, muni_data[, .(muni_id, gang_intensity, gang_intensity_std,
                                   high_gang, det_2011, pop_2011)],
               by = "muni_id", all.x = TRUE)

# Merge annual population
panel <- merge(panel, pop_long[, .(muni_id, year, population)],
               by = c("muni_id", "year"), all.x = TRUE)

# Fill missing treatment with 0 (unmatched municipality)
panel[is.na(gang_intensity), gang_intensity := 0]
panel[is.na(gang_intensity_std), gang_intensity_std := 0]
panel[is.na(high_gang), high_gang := 0L]

# Create period indicators
panel[, truce := as.integer(year %in% c(2012, 2013))]
panel[, post_collapse := as.integer(year >= 2014)]
panel[, post_2012 := as.integer(year >= 2012)]

# Relative year (0 = 2012, the truce year)
panel[, rel_year := year - 2012]

# Log outcome
panel[, log_hom := log(hom_rate + 0.1)]

# Homicide count (approximate)
panel[!is.na(population), hom_count := round(hom_rate * population / 10000)]

# Department ID for FE
panel[, dept_id := as.integer(factor(dept_name))]

cat(sprintf("  Panel: %d municipality-years\n", nrow(panel)))
cat(sprintf("  Municipalities: %d\n", uniqueN(panel$muni_id)))
cat(sprintf("  Years: %d\n", uniqueN(panel$year)))

# Pre-truce period stats
pre <- panel[year < 2012]
cat(sprintf("  Pre-truce mean hom_rate: %.2f per 10,000\n", mean(pre$hom_rate, na.rm = TRUE)))
cat(sprintf("  Pre-truce SD hom_rate: %.2f\n", sd(pre$hom_rate, na.rm = TRUE)))

# ============================================================
# 6. Save
# ============================================================
saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(muni_data, file.path(data_dir, "muni_data.rds"))

cat("\n=== Panel Construction Complete ===\n")
