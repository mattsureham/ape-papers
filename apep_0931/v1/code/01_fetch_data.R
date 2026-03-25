## 01_fetch_data.R — apep_0931: IAP and Economic Development
## Load SHRUG data and construct IAP treatment indicator

source("code/00_packages.R")

shrug_dir <- "../../../data/india_shrug"

# ── Load district-level nightlights ─────────────────────────────────
cat("Loading DMSP nightlights (district level)...\n")
dmsp <- fread(file.path(shrug_dir, "dmsp_pc11dist.csv"))
stopifnot(nrow(dmsp) > 0)
cat(sprintf("  DMSP: %d rows, years %d-%d\n", nrow(dmsp), min(dmsp$year), max(dmsp$year)))

cat("Loading VIIRS nightlights (district level)...\n")
viirs <- fread(file.path(shrug_dir, "viirs_annual_pc11dist.csv"))
stopifnot(nrow(viirs) > 0)
cat(sprintf("  VIIRS: %d rows, years %d-%d\n", nrow(viirs), min(viirs$year), max(viirs$year)))

# ── Load Census PCA for covariates ──────────────────────────────────
cat("Loading Census 2001 and 2011 district PCA...\n")
pca01 <- fread(file.path(shrug_dir, "pc01_pca_clean_pc01dist.csv"))
pca11 <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.csv"))
stopifnot(nrow(pca01) > 0 && nrow(pca11) > 0)

# ── Load geographic crosswalk (Town Directory) ──────────────────────
cat("Loading district-level Town Directory...\n")
td <- fread(file.path(shrug_dir, "pc11_td_clean_pc11dist.csv"))
stopifnot(nrow(td) > 0)

# ── Load Census 2011 district names (from external directory) ───────
cat("Loading Census 2011 district directory...\n")
census_dir <- fread("data/census_2011_districts.csv", select = c(1:3))
names(census_dir) <- c("pc11_district_id", "state_name", "district_name")
census_dir[, pc11_district_id := as.integer(pc11_district_id)]
census_dir[, district_name := trimws(district_name)]

# ── Define IAP treatment districts (original 60) ────────────────────
# Source: Government of India, CCEA approval November 2010.
# The 60 districts were selected from MHA's list of LWE-affected districts (48)
# plus tribal concentration criteria (12 additional).
# State distribution: CG(10), JH(14), OD(15), MP(8), BR(7), AP(2), MH(2), UP(1), WB(1)

# SHRUG uses Census 2011 national sequential district IDs.
# Mapping verified against Census 2011 district directory.

iap_ids <- c(
  # Andhra Pradesh (2): Khammam (541), East Godavari (545)
  541, 545,
  # Bihar (7): Kaimur (233), Rohtas (234), Aurangabad (235), Gaya (236),
  #            Nawada (237), Jamui (238), Jehanabad (239)
  233, 234, 235, 236, 237, 238, 239,
  # Chhattisgarh (10): Koriya (400), Surguja (401), Jashpur (402),
  #                     Rajnandgaon (408), Dhamtari (412), Kanker (413),
  #                     Bastar (414), Narayanpur (415), Dantewada (416), Bijapur (417)
  400, 401, 402, 408, 412, 413, 414, 415, 416, 417,
  # Jharkhand (14): Garhwa (346), Chatra (347), Giridih (349),
  #                  Bokaro (355), Lohardaga (356), E. Singhbhum (357),
  #                  Palamu (358), Latehar (359), Hazaribagh (360),
  #                  Ranchi (364), Gumla (366), Simdega (367),
  #                  W. Singhbhum (368), Saraikela-Kharsawan (369)
  346, 347, 349, 355, 356, 357, 358, 359, 360, 364, 366, 367, 368, 369,
  # Madhya Pradesh (8): Umaria (431), Dindori (453), Mandla (454),
  #                      Balaghat (457), Shahdol (460), Anuppur (461),
  #                      Sidhi (462), Singrauli (463)
  431, 453, 454, 457, 460, 461, 462, 463,
  # Maharashtra (2): Gondiya (507), Gadchiroli (508)
  507, 508,
  # Odisha (15): Sundargarh (374), Kendujhar/Keonjhar (375), Mayurbhanj (376),
  #              Nayagarh (385), Ganjam (388), Gajapati (389), Kandhamal (390),
  #              Subarnapur/Sonepur (392), Balangir (393), Nuapada (394),
  #              Kalahandi (395), Rayagada (396), Nabarangapur (397),
  #              Koraput (398), Malkangiri (399)
  374, 375, 376, 385, 388, 389, 390, 392, 393, 394, 395, 396, 397, 398, 399,
  # Uttar Pradesh (1): Sonbhadra (200)
  200,
  # West Bengal (1): Paschim Medinipur (344)
  344
)

stopifnot(length(iap_ids) == 60)

# Create IAP indicator table with names
iap_districts <- data.table(pc11_district_id = iap_ids, iap = 1L)
iap_districts <- merge(iap_districts, census_dir[, .(pc11_district_id, district_name)],
                       by = "pc11_district_id", all.x = TRUE)

cat(sprintf("IAP districts defined: %d\n", nrow(iap_districts)))
cat("Districts with names:\n")
print(iap_districts[order(pc11_district_id)])

# ── Merge IAP indicator onto DMSP panel ─────────────────────────────
dmsp[, iap := as.integer(pc11_district_id %in% iap_ids)]

# Treatment timing: IAP approved November 2010, funds disbursed 2010-11
# First full fiscal year with funds: 2011-12 (April 2011)
# Use 2011 as first treated year (conservative)
dmsp[, post := as.integer(year >= 2011)]
dmsp[, treat_post := iap * post]

# Create log nightlights (primary outcome)
dmsp[, ln_light := log(dmsp_total_light_cal + 1)]

cat(sprintf("\nDMSP Panel: %d districts, %d years (%d-%d)\n",
            uniqueN(dmsp$pc11_district_id), uniqueN(dmsp$year),
            min(dmsp$year), max(dmsp$year)))
cat(sprintf("Treated (IAP=1): %d districts\n", uniqueN(dmsp[iap == 1]$pc11_district_id)))
cat(sprintf("Control (IAP=0): %d districts\n", uniqueN(dmsp[iap == 0]$pc11_district_id)))

# Verify all 60 IAP districts found in data
matched <- sum(iap_ids %in% unique(dmsp$pc11_district_id))
cat(sprintf("IAP districts matched: %d / 60\n", matched))
if (matched < 60) {
  missing <- iap_ids[!iap_ids %in% unique(dmsp$pc11_district_id)]
  cat("Missing IDs: ", paste(missing, collapse = ", "), "\n")
  stop("Not all IAP districts matched in DMSP data!")
}

# ── Also prepare VIIRS panel (for post-2013 extension) ──────────────
viirs[, iap := as.integer(pc11_district_id %in% iap_ids)]
viirs[, post := as.integer(year >= 2011)]
viirs[, treat_post := iap * post]
viirs[, ln_light := log(viirs_annual_sum + 1)]

# ── Save processed data ────────────────────────────────────────────
fwrite(dmsp, "data/dmsp_district_panel.csv")
fwrite(viirs, "data/viirs_district_panel.csv")
fwrite(iap_districts, "data/iap_districts.csv")

# Save Census PCA for later use
fwrite(pca01, "data/pca01_district.csv")
fwrite(pca11, "data/pca11_district.csv")
fwrite(td, "data/td_district.csv")

cat("\nAll data saved successfully.\n")
