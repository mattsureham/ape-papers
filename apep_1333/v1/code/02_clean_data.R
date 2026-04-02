# 02_clean_data.R — Construct analysis panel for MPA fish DiD
# Treatment: Central Coast MLPA implemented September 2007
# Sites assigned based on SBC LTER site documentation and MPA boundaries

setwd(here::here())
source("code/00_packages.R")

fish <- readRDS("data/fish_raw.rds")

# ========================================================================
# 1. Assign MPA treatment status
# ========================================================================
# Based on SBC LTER site documentation (Reed et al. 2016; Caselle et al. 2015)
# and Central Coast MLPA boundaries (CDFW ds582)
#
# MPA sites (treated Sept 2007):
#   NAPL (Naples Reef) — inside Naples SMCA
#   IVEE (Isla Vista Reef) — inside Campus Point SMCA (no-take)
#
# Channel Islands sites (federal reserves 2003, state 2007):
#   SCDI (Santa Cruz Island, Diablo) — inside Scorpion SMR
#   SCTW (Santa Cruz Island, Twin Harbor W) — inside Painted Cave SMCA
#
# Non-MPA sites (never treated):
#   ABUR, AHND, AQUE, BULL, CARP, GOLB, MOHK

site_info <- data.table(
  SITE = c("NAPL", "IVEE", "SCDI", "SCTW",
           "ABUR", "AHND", "AQUE", "BULL", "CARP", "GOLB", "MOHK"),
  mpa_status = c("MPA_mainland", "MPA_mainland", "MPA_island", "MPA_island",
                  "control", "control", "control", "control", "control", "control", "control"),
  mpa_name = c("Naples SMCA", "Campus Point SMCA (No-Take)", "Scorpion SMR", "Painted Cave SMCA",
               NA, NA, NA, NA, NA, NA, NA),
  treatment_year = c(2007, 2007, 2003, 2003,
                     NA, NA, NA, NA, NA, NA, NA)
)

fish <- merge(fish, site_info, by = "SITE", all.x = TRUE)

# ========================================================================
# 2. Classify fish species as targeted vs non-targeted
# ========================================================================
# Targeted = species commonly taken by recreational/commercial fishing in CA kelp forests
# Based on CDFW regulations and Caselle et al. (2015) "Recovery trajectories"
#
# Key targeted species in CA kelp forests:
targeted_species <- c(
  "CALA",   # California sheephead (Semicossyphus pulcher)
  "PANE",   # Kelp bass (Paralabrax clathratus)  — SP_CODE may differ
  "PACL",   # Kelp bass
  "ANDA",   # Sargo (Anisotremus davidsonii)
  "SESE",   # Señorita is actually not targeted — remove
  "PARM",   # Barred sand bass (Paralabrax maculatofasciatus)
  "SCGU",   # Black perch/surfperch (Embiotoca jacksoni)
  "EMJA",   # Black surfperch
  "RHAM",   # Rubberlip surfperch (Rhacochilus toxotes)
  "RHTO",   # Rubberlip seaperch
  "HASE",   # Ocean whitefish (Caulolatilus princeps)
  "CAPR",   # Ocean whitefish
  "OXCA",   # California scorpionfish (Scorpaena guttata)
  "SCGU2",  # Scorpionfish
  "PANE2",  # Barred sand bass
  "MEAU",   # Kelp rockfish (Sebastes atrovirens)
  "SEAT",   # Kelp rockfish
  "SEMY",   # Blue rockfish (Sebastes mystinus)
  "SECA",   # Gopher rockfish (Sebastes carnatus)
  "SECR",   # Black-and-yellow rockfish (Sebastes chrysomelas)
  "SERA",   # Olive rockfish (Sebastes serranoides)
  "SESE2",  # Treefish (Sebastes serriceps)
  "SESP"    # Rockfish genus
)

# Get actual species codes in data
actual_spcodes <- unique(fish$SP_CODE)
cat("Species codes in data:", length(actual_spcodes), "\n")

# Match targeted species using both SP_CODE and common names
# More robust: use common/scientific names to classify
fish[, targeted := 0L]

# Targeted based on scientific name (primary classification)
targeted_genera <- c("Semicossyphus", "Paralabrax", "Sebastes", "Scorpaena",
                     "Caulolatilus", "Rhacochilus")
targeted_common <- c("Sheephead", "Kelp Bass", "Barred Sand Bass",
                     "Rockfish", "Scorpionfish", "Surfperch", "Seaperch",
                     "Whitefish", "Cabezon", "Lingcod")

fish[, targeted := as.integer(
  TAXON_GENUS %in% targeted_genera |
  grepl(paste(targeted_common, collapse = "|"), COMMON_NAME, ignore.case = TRUE)
)]

cat("Targeted species identified:", sum(fish$targeted == 1 & !duplicated(fish$SP_CODE)),
    "out of", length(unique(fish$SP_CODE)), "\n")

# ========================================================================
# 3. Construct analysis panel: site × year level
# ========================================================================
# Primary outcome: total fish density per transect (standardized by area)
# Aggregate across transects within site-year

# Handle missing count values (-99999 = missing in SBC LTER)
fish[COUNT == -99999, COUNT := NA]
fish[AREA == -99999, AREA := NA]

# Site-year-species panel: total count across transects
panel_spp <- fish[!is.na(COUNT) & !is.na(AREA),
                  .(total_count = sum(COUNT, na.rm = TRUE),
                    total_area = sum(AREA, na.rm = TRUE),
                    n_transects = uniqueN(TRANSECT)),
                  by = .(SITE, YEAR, SP_CODE, COMMON_NAME, SCIENTIFIC_NAME,
                         targeted, mpa_status, treatment_year)]
panel_spp[, density := total_count / total_area * 60]  # standardize to per 60m² transect

# Site-year panel (all species aggregated)
panel_site <- fish[!is.na(COUNT) & !is.na(AREA),
                   .(total_fish = sum(COUNT, na.rm = TRUE),
                     total_area = sum(AREA, na.rm = TRUE),
                     species_richness = uniqueN(SP_CODE[COUNT > 0]),
                     targeted_fish = sum(COUNT[targeted == 1], na.rm = TRUE),
                     nontargeted_fish = sum(COUNT[targeted == 0], na.rm = TRUE),
                     n_transects = uniqueN(TRANSECT)),
                   by = .(SITE, YEAR, mpa_status, treatment_year)]

panel_site[, `:=`(
  fish_density = total_fish / total_area * 60,
  targeted_density = targeted_fish / total_area * 60,
  nontargeted_density = nontargeted_fish / total_area * 60,
  log_density = log(total_fish / total_area * 60 + 1),
  log_targeted = log(targeted_fish / total_area * 60 + 1),
  log_nontargeted = log(nontargeted_fish / total_area * 60 + 1)
)]

# Treatment indicators
panel_site[, `:=`(
  mpa = as.integer(mpa_status == "MPA_mainland"),
  post = as.integer(YEAR >= 2008),  # post = Sept 2007 implementation
  island = as.integer(mpa_status == "MPA_island")
)]
panel_site[, treated := mpa * post]

# For species-level panel
panel_spp[, `:=`(
  mpa = as.integer(mpa_status == "MPA_mainland"),
  post = as.integer(YEAR >= 2008),
  island = as.integer(mpa_status == "MPA_island"),
  log_density = log(density + 1)
)]

# ========================================================================
# 4. Restrict to mainland sites (exclude Channel Islands for main analysis)
# ========================================================================
panel_main <- panel_site[mpa_status %in% c("MPA_mainland", "control")]
panel_spp_main <- panel_spp[mpa_status %in% c("MPA_mainland", "control")]

cat("\n=== Analysis Panel Summary ===\n")
cat("Mainland sites:", uniqueN(panel_main$SITE), "\n")
cat("  MPA sites:", uniqueN(panel_main[mpa == 1]$SITE), "\n")
cat("  Control sites:", uniqueN(panel_main[mpa == 0]$SITE), "\n")
cat("Years:", min(panel_main$YEAR), "-", max(panel_main$YEAR), "\n")
cat("Pre-treatment years:", sum(unique(panel_main$YEAR) < 2008), "\n")
cat("Post-treatment years:", sum(unique(panel_main$YEAR) >= 2008), "\n")
cat("Site-years:", nrow(panel_main), "\n")
cat("Species in species panel:", uniqueN(panel_spp_main$SP_CODE), "\n")

# ========================================================================
# 5. Save analysis panels
# ========================================================================
saveRDS(panel_main, "data/panel_main.rds")
saveRDS(panel_spp_main, "data/panel_spp_main.rds")
saveRDS(panel_site, "data/panel_full.rds")
saveRDS(panel_spp, "data/panel_spp_full.rds")
saveRDS(site_info, "data/site_info.rds")
cat("Analysis panels saved.\n")
