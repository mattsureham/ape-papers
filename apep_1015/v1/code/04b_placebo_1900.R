# =============================================================================
# 04b_placebo_1900.R — 1900-1910 placebo (pre-treatment period)
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

# Read Azure connection string directly
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

key_cols <- paste(c(
  "statefip_1900", "age_1900", "sex_1900", "race_1900",
  "nativity_1900", "marst_1900", "occ1950_1900", "ind1950_1900",
  "occscore_1900", "lit_1900", "perwt_1900",
  "statefip_1910", "age_1910", "occ1950_1910", "ind1950_1910",
  "occscore_1910", "marst_1910"
), collapse = ", ")

cat("=== Fetching 1900-1910 women placebo sample ===\n")
women_pre <- dbGetQuery(con, sprintf("
  SELECT %s
  FROM 'az://derived/mlp_panel/linked_1900_1910.parquet'
  WHERE sex_1900 = 2
    AND occ1950_1900 > 0
    AND occ1950_1900 < 979
", key_cols))
cat(sprintf("Women in LF 1900: %s\n", format(nrow(women_pre), big.mark = ",")))

apep_azure_disconnect(con)

dt <- as.data.table(women_pre)

# Same treatment coding as main analysis
mw_states <- c(4, 5, 6, 8, 20, 25, 27, 31, 38, 41, 48, 49, 53, 55)
dt[, mw_state := as.integer(statefip_1900 %in% mw_states)]

dt[, covered_ind := as.integer(
  (ind1950_1900 >= 306 & ind1950_1900 <= 499) |
  (ind1950_1900 >= 606 & ind1950_1900 <= 699) |
  (ind1950_1900 >= 806 & ind1950_1900 <= 829)
)]
dt[, exempt_ind := as.integer(
  (ind1950_1900 >= 100 & ind1950_1900 <= 126) |
  (ind1950_1900 == 856)
)]

# Keep covered or exempt
dt <- dt[covered_ind == 1 | exempt_ind == 1]
cat(sprintf("Placebo sample (1900 LF, covered/exempt): %s\n",
            format(nrow(dt), big.mark = ",")))

# Outcomes measured in 1910
dt[, retention := as.integer(occ1950_1910 > 0 & occ1950_1910 < 979)]
dt[, same_industry := as.integer(ind1950_1900 == ind1950_1910)]
dt[, occ_change := occscore_1910 - occscore_1900]

# Variables
dt[, mw_x_covered := mw_state * covered_ind]
dt[, age_sq := age_1900^2]
dt[, native := as.integer(nativity_1900 <= 1)]
dt[, literate := as.integer(lit_1900 == 4)]
dt[, married := as.integer(marst_1900 <= 2)]
dt[, white := as.integer(race_1900 == 1)]
dt[, ind_group := fcase(
  ind1950_1900 >= 100 & ind1950_1900 <= 126, 1L,
  ind1950_1900 >= 306 & ind1950_1900 <= 399, 2L,
  ind1950_1900 >= 400 & ind1950_1900 <= 499, 3L,
  ind1950_1900 >= 606 & ind1950_1900 <= 699, 4L,
  ind1950_1900 >= 806 & ind1950_1900 <= 829, 5L,
  ind1950_1900 == 856, 6L,
  default = 7L
)]

# Remove singletons
cell_counts <- dt[, .N, by = .(statefip_1900, ind_group)]
dt <- dt[!cell_counts[N == 1], on = .(statefip_1900, ind_group)]

# Placebo DDD
cat("\n=== 1900-1910 PLACEBO (no treatment in this period) ===\n")
p1 <- feols(retention ~ mw_x_covered +
              age_1900 + age_sq + native + literate + married + white |
              statefip_1900 + ind_group,
            data = dt, cluster = ~statefip_1900)
cat("Retention:\n"); print(coeftable(p1))

p2 <- feols(same_industry ~ mw_x_covered +
              age_1900 + age_sq + native + literate + married + white |
              statefip_1900 + ind_group,
            data = dt, cluster = ~statefip_1900)
cat("Industry persistence:\n"); print(coeftable(p2))

# Enforcement heterogeneity on main sample
cat("\n=== ENFORCEMENT: Advisory vs Mandatory (on 1910-1920 data) ===\n")
main_dt <- as.data.table(arrow::read_parquet("../data/est_sample_women.parquet"))
main_dt[, age_sq := age_1910^2]
main_dt[, native := as.integer(nativity_1910 <= 1)]
main_dt[, literate := as.integer(lit_1910 == 4)]
main_dt[, married := as.integer(marst_1910 <= 2)]
main_dt[, white := as.integer(race_1910 == 1)]
main_dt[, ind_group := fcase(
  ind1950_1910 >= 100 & ind1950_1910 <= 126, 1L,
  ind1950_1910 >= 306 & ind1950_1910 <= 399, 2L,
  ind1950_1910 >= 400 & ind1950_1910 <= 499, 3L,
  ind1950_1910 >= 606 & ind1950_1910 <= 699, 4L,
  ind1950_1910 >= 806 & ind1950_1910 <= 829, 5L,
  ind1950_1910 == 856, 6L,
  default = 7L
)]
main_dt[, in_lf_1920 := as.integer(occ1950_1920 > 0 & occ1950_1920 < 979)]
main_dt[, retention := in_lf_1920]

# Advisory-only: Massachusetts (25)
# Mandatory with penalties: CA(6), CO(8), OR(41), WA(53), MN(27), WI(55),
#   UT(49), NE(31), AR(5), KS(20), AZ(4), ND(38), TX(48)
advisory_states <- c(25)
mandatory_states <- c(4, 5, 6, 8, 20, 27, 31, 38, 41, 48, 49, 53, 55)

main_dt[, advisory := as.integer(statefip_1910 %in% advisory_states)]
main_dt[, mandatory := as.integer(statefip_1910 %in% mandatory_states)]
main_dt[, advisory_x_covered := advisory * covered_ind]
main_dt[, mandatory_x_covered := mandatory * covered_ind]

cell_counts_m <- main_dt[, .N, by = .(statefip_1910, ind_group)]
main_dt <- main_dt[!cell_counts_m[N == 1], on = .(statefip_1910, ind_group)]

m_enforce <- feols(retention ~ advisory_x_covered + mandatory_x_covered +
                     age_1910 + age_sq + native + literate + married + white |
                     statefip_1910 + ind_group,
                   data = main_dt, cluster = ~statefip_1910)
cat("Advisory vs Mandatory:\n"); print(coeftable(m_enforce))

# Save results
placebo_results <- list(
  placebo_ret = p1,
  placebo_ind = p2,
  enforce = m_enforce,
  n_placebo = nrow(dt)
)
saveRDS(placebo_results, "../data/placebo_results.rds")

cat("\n04b_placebo_1900.R complete.\n")
