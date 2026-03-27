# 02_clean_data.R — Construct analysis dataset for apep_1061
# Polish abortion ruling border-distance DiD

source("00_packages.R")

# ---------------------------------------------------------------
# 1. Load raw data
# ---------------------------------------------------------------
tfr_nuts2 <- readRDS("../data/tfr_nuts2.rds")

# ---------------------------------------------------------------
# 2. Compute distance to nearest border clinic
# ---------------------------------------------------------------
# Polish NUTS2 voivodship capitals with approximate coordinates
# Source: https://en.wikipedia.org/wiki/Voivodeships_of_Poland
voivodship_capitals <- data.frame(
  geo = c("PL21", "PL22", "PL41", "PL42", "PL43", "PL51",
          "PL52", "PL61", "PL62", "PL63", "PL71", "PL72",
          "PL81", "PL82", "PL84", "PL91", "PL92"),
  capital = c("Kraków", "Katowice", "Poznań", "Szczecin", "Zielona Góra",
              "Wrocław", "Opole", "Bydgoszcz", "Olsztyn", "Gdańsk",
              "Łódź", "Warszawa", "Lublin", "Rzeszów", "Białystok",
              "Kielce", "Radom"),
  voivodship = c("Małopolskie", "Śląskie", "Wielkopolskie",
                 "Zachodniopomorskie", "Lubuskie", "Dolnośląskie",
                 "Opolskie", "Kujawsko-pomorskie", "Warmińsko-mazurskie",
                 "Pomorskie", "Łódzkie", "Mazowieckie", "Lubelskie",
                 "Podkarpackie", "Podlaskie", "Świętokrzyskie", "Mazowieckie-regional"),
  lat = c(50.0647, 50.2649, 52.4064, 53.4285, 51.9356, 51.1079,
          50.6751, 53.1235, 53.7784, 54.3520, 51.7592, 52.2297,
          51.2465, 50.0412, 53.1325, 50.8661, 51.4027),
  lon = c(19.9450, 19.0238, 16.9252, 14.5528, 15.5062, 17.0385,
          17.9213, 18.0084, 20.4801, 18.6466, 19.4560, 21.0122,
          22.5684, 21.9991, 23.1688, 20.6286, 21.1471),
  stringsAsFactors = FALSE
)

# Nearest border clinics offering abortion services to Polish women
# Major clinics known to serve Polish patients post-2020
border_clinics <- data.frame(
  clinic = c("Prenzlau_DE", "Berlin_DE", "Frankfurt_Oder_DE",
             "Ostrava_CZ", "Brno_CZ", "Prague_CZ",
             "Bratislava_SK", "Kaliningrad_RU"),
  lat = c(53.3167, 52.5200, 52.3471,
          49.8209, 49.1951, 50.0755,
          48.1486, 54.7104),
  lon = c(13.8667, 13.4050, 14.5506,
          18.2625, 16.6068, 14.4378,
          17.1077, 20.4522),
  # Only include accessible clinics (EU/Schengen, known providers)
  accessible = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Keep only accessible clinics (EU/Schengen)
border_clinics <- border_clinics[border_clinics$accessible, ]

# Compute geodesic distance from each voivodship capital to each clinic
dist_matrix <- geodist(
  x = voivodship_capitals[, c("lon", "lat")],
  y = border_clinics[, c("lon", "lat")],
  measure = "geodesic"
)  # Returns meters

# Convert to km
dist_matrix_km <- dist_matrix / 1000

# Minimum distance to any accessible clinic
voivodship_capitals$dist_min_km <- apply(dist_matrix_km, 1, min)

# Also compute distance to nearest German and Czech clinic separately
de_idx <- grep("_DE$", border_clinics$clinic)
cz_idx <- grep("_CZ$", border_clinics$clinic)
voivodship_capitals$dist_de_km <- apply(dist_matrix_km[, de_idx, drop = FALSE], 1, min)
voivodship_capitals$dist_cz_km <- apply(dist_matrix_km[, cz_idx, drop = FALSE], 1, min)

cat("Distance to nearest clinic (km):\n")
print(voivodship_capitals[order(voivodship_capitals$dist_min_km),
                          c("voivodship", "dist_min_km", "dist_de_km", "dist_cz_km")])

# ---------------------------------------------------------------
# 3. Merge TFR with distance and controls
# ---------------------------------------------------------------
# Keep only regions present in the TFR data
available_regions <- unique(tfr_nuts2$geo)
voivod_match <- voivodship_capitals[voivodship_capitals$geo %in% available_regions, ]

cat(sprintf("\nMatched %d of %d voivodships to TFR data\n",
            nrow(voivod_match), nrow(voivodship_capitals)))

# Merge distance to TFR panel
panel <- merge(tfr_nuts2, voivod_match[, c("geo", "voivodship", "dist_min_km",
                                            "dist_de_km", "dist_cz_km", "lat", "lon")],
               by = "geo", all.x = FALSE)

# Add post-treatment indicator (ruling effective January 2021)
panel$post <- as.integer(panel$year >= 2021)

# Treatment intensity: standardized distance (mean 0, sd 1)
panel$dist_std <- (panel$dist_min_km - mean(panel$dist_min_km)) / sd(panel$dist_min_km)

# Interaction term
panel$post_x_dist <- panel$post * panel$dist_min_km
panel$post_x_dist_std <- panel$post * panel$dist_std

# Distance quintiles for event study
panel$dist_quintile <- cut(panel$dist_min_km,
                           breaks = quantile(panel$dist_min_km, probs = seq(0, 1, 0.2)),
                           include.lowest = TRUE, labels = 1:5)

# High/low distance binary split (above/below median)
med_dist <- median(unique(panel$dist_min_km))
panel$far_from_border <- as.integer(panel$dist_min_km > med_dist)

# ---------------------------------------------------------------
# 4. Merge controls
# ---------------------------------------------------------------
if (file.exists("../data/gdp_nuts2.rds")) {
  gdp <- readRDS("../data/gdp_nuts2.rds")
  panel <- merge(panel, gdp, by = c("geo", "year"), all.x = TRUE)
}

if (file.exists("../data/unemp_nuts2.rds")) {
  unemp <- readRDS("../data/unemp_nuts2.rds")
  panel <- merge(panel, unemp, by = c("geo", "year"), all.x = TRUE)
}

if (file.exists("../data/pop_nuts2.rds")) {
  pop <- readRDS("../data/pop_nuts2.rds")
  panel <- merge(panel, pop, by = c("geo", "year"), all.x = TRUE)
}

# ---------------------------------------------------------------
# 5. Create event-time variable
# ---------------------------------------------------------------
panel$event_time <- panel$year - 2021  # 0 = first treated year

# ---------------------------------------------------------------
# 6. Clean and validate
# ---------------------------------------------------------------
panel <- panel[order(panel$geo, panel$year), ]

cat(sprintf("\nFinal panel: %d observations, %d regions, %d years\n",
            nrow(panel), length(unique(panel$geo)), length(unique(panel$year))))
cat(sprintf("Distance range: %.0f - %.0f km\n",
            min(panel$dist_min_km), max(panel$dist_min_km)))
cat(sprintf("TFR range: %.2f - %.2f\n", min(panel$tfr), max(panel$tfr)))
cat(sprintf("Pre-treatment years: %d\n", sum(unique(panel$year) < 2021)))
cat(sprintf("Post-treatment years: %d\n", sum(unique(panel$year) >= 2021)))

# Validate no missing TFR
stopifnot(sum(is.na(panel$tfr)) == 0)

# ---------------------------------------------------------------
# 7. Also prepare NUTS3 panel if available
# ---------------------------------------------------------------
if (file.exists("../data/births_nuts3.rds")) {
  births_nuts3 <- readRDS("../data/births_nuts3.rds")

  # Extract NUTS2 code from NUTS3 (first 4 chars)
  births_nuts3$nuts2 <- substr(births_nuts3$geo, 1, 4)

  # Merge distance (from NUTS2 capital — approximation for NUTS3)
  births_nuts3 <- merge(births_nuts3,
                        voivod_match[, c("geo", "voivodship", "dist_min_km",
                                         "dist_de_km", "dist_cz_km")],
                        by.x = "nuts2", by.y = "geo", all.x = FALSE)

  births_nuts3$post <- as.integer(births_nuts3$year >= 2021)
  births_nuts3$post_x_dist <- births_nuts3$post * births_nuts3$dist_min_km
  births_nuts3$dist_std <- (births_nuts3$dist_min_km - mean(births_nuts3$dist_min_km)) /
                            sd(births_nuts3$dist_min_km)
  births_nuts3$post_x_dist_std <- births_nuts3$post * births_nuts3$dist_std
  births_nuts3$event_time <- births_nuts3$year - 2021
  births_nuts3$far_from_border <- as.integer(births_nuts3$dist_min_km > med_dist)

  saveRDS(births_nuts3, "../data/panel_nuts3.rds")
  cat(sprintf("\nNUTS3 panel: %d obs, %d regions\n",
              nrow(births_nuts3), length(unique(births_nuts3$geo))))
}

# ---------------------------------------------------------------
# 8. Save analysis panel
# ---------------------------------------------------------------
saveRDS(panel, "../data/panel_nuts2.rds")
cat("\nSaved: ../data/panel_nuts2.rds\n")
