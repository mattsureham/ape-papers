##============================================================
## 02_clean_data.R — Construct treatment variables and panels
## APEP-0543: Rent Control and Property Values in France
##============================================================

source("00_packages.R")

data_dir <- "../data/"

## ─── Load DVF data ───────────────────────────────────────
dvf <- as.data.table(read_parquet(file.path(data_dir, "dvf_residential.parquet")))
cat("Loaded", nrow(dvf), "transactions\n")

## ─── Treatment assignment: Encadrement des Loyers ────────
## Official commune lists from arrêtés préfectoraux
## Sources: ecologie.gouv.fr, service-public.fr

## Treatment groups with adoption dates
## Note: We assign treatment at the COMMUNE level using code_commune (5-digit INSEE code)
## Paris = 75101-75120 (arrondissements), Lille = 59350, Lyon = 69123, etc.

## Paris arrondissements (treated July 1, 2019)
paris_communes <- paste0("751", sprintf("%02d", 1:20))
paris_date <- as.Date("2019-07-01")

## Lille + Hellemmes + Lomme (treated March 1, 2020)
lille_communes <- c("59350", "59298", "59360")  # Lille, Hellemmes, Lomme
lille_date <- as.Date("2020-03-01")

## Plaine Commune intercommunalité (9 communes, treated June 1, 2021)
plaine_commune <- c("93001", "93007", "93027", "93031",
                     "93039", "93047", "93066", "93070", "93079")
plaine_date <- as.Date("2021-06-01")

## Est Ensemble intercommunalité (9 communes, treated December 1, 2021)
est_ensemble <- c("93005", "93006", "93010", "93048",
                   "93049", "93053", "93055", "93061", "93064")
est_ensemble_date <- as.Date("2021-12-01")

## Lyon + Villeurbanne (treated November 1, 2021)
lyon_communes <- c("69123", "69266")  # Lyon, Villeurbanne
lyon_date <- as.Date("2021-11-01")

## Montpellier (treated July 1, 2022)
montpellier_communes <- c("34172")
montpellier_date <- as.Date("2022-07-01")

## Bordeaux (treated July 15, 2022)
bordeaux_communes <- c("33063")
bordeaux_date <- as.Date("2022-07-15")

## Build treatment mapping
treatment_map <- rbind(
  data.table(code_commune = paris_communes, treat_date = paris_date, treat_city = "Paris"),
  data.table(code_commune = lille_communes, treat_date = lille_date, treat_city = "Lille"),
  data.table(code_commune = plaine_commune, treat_date = plaine_date, treat_city = "Plaine Commune"),
  data.table(code_commune = est_ensemble, treat_date = est_ensemble_date, treat_city = "Est Ensemble"),
  data.table(code_commune = lyon_communes, treat_date = lyon_date, treat_city = "Lyon-Villeurbanne"),
  data.table(code_commune = montpellier_communes, treat_date = montpellier_date, treat_city = "Montpellier"),
  data.table(code_commune = bordeaux_communes, treat_date = bordeaux_date, treat_city = "Bordeaux")
)

cat("Treatment map:", nrow(treatment_map), "treated communes across",
    uniqueN(treatment_map$treat_city), "cities\n")

## ─── Merge treatment status ─────────────────────────────
dvf <- merge(dvf, treatment_map, by = "code_commune", all.x = TRUE)

## Treatment indicators
dvf[, treated_commune := !is.na(treat_date)]
dvf[, post_treatment := date_mutation >= treat_date & treated_commune]
dvf[is.na(post_treatment), post_treatment := FALSE]

## ─── Investment property classification ──────────────────
## "Investment-type" = high probability of being rental property
## Based on: apartment + small (studio / 1-2 rooms)
## "Owner-occupier-type" = low probability of being rental
## Based on: house, or large apartment (3+ rooms)

## Handle NA rooms: if room count missing, classify based on type only
## Apartments with unknown rooms → classify as investment if surface < 50m²
dvf[, npp := fifelse(is.na(nombre_pieces_principales), 99L, nombre_pieces_principales)]
dvf[, investment_type := (type_local == "Appartement" & npp <= 2)]
## For apartments with missing rooms, use surface area as proxy
dvf[type_local == "Appartement" & is.na(nombre_pieces_principales) &
    !is.na(surface_reelle_bati) & surface_reelle_bati < 50,
    investment_type := TRUE]
dvf[, npp := NULL]

## Continuous rental exposure score (robustness)
## Higher = more likely to be rental
## Components: apartment (vs house), fewer rooms, smaller surface
dvf[, rental_score := 0]
dvf[type_local == "Appartement", rental_score := rental_score + 0.4]
dvf[nombre_pieces_principales <= 1, rental_score := rental_score + 0.3]
dvf[nombre_pieces_principales == 2, rental_score := rental_score + 0.15]
dvf[!is.na(surface_reelle_bati) & surface_reelle_bati < 40,
    rental_score := rental_score + 0.2]
dvf[!is.na(surface_reelle_bati) & surface_reelle_bati >= 40 &
    surface_reelle_bati < 70,
    rental_score := rental_score + 0.1]

## ─── Control city selection ─────────────────────────────
## Select French cities with 100k+ population that never adopted
## rent control during our sample period.
## These serve as the "never-treated" control group.

## Major untreated cities (approximate populations):
## Toulouse (500k), Nantes (320k), Strasbourg (290k), Nice (340k),
## Rennes (220k), Rouen (115k), Toulon (175k), Saint-Étienne (175k),
## Le Havre (170k), Reims (185k), Dijon (160k), Angers (155k),
## Clermont-Ferrand (145k), Tours (140k), Limoges (130k),
## Amiens (135k), Perpignan (120k), Brest (140k), Metz (120k),
## Besançon (120k), Orléans (115k), Caen (105k)

control_cities_communes <- c(
  "31555",  # Toulouse
  "44109",  # Nantes
  "67482",  # Strasbourg  (note: Alsace excluded from DVF — will be dropped)
  "06088",  # Nice
  "35238",  # Rennes
  "76540",  # Rouen
  "83137",  # Toulon
  "42218",  # Saint-Étienne
  "76351",  # Le Havre
  "51454",  # Reims
  "21231",  # Dijon
  "49007",  # Angers
  "63113",  # Clermont-Ferrand
  "37261",  # Tours
  "87085",  # Limoges
  "80021",  # Amiens
  "66136",  # Perpignan
  "29019",  # Brest
  "57463",  # Metz (note: Moselle excluded from DVF — will be dropped)
  "25056",  # Besançon
  "45234",  # Orléans
  "14118"   # Caen
)

## Mark control cities
dvf[, control_city := code_commune %in% control_cities_communes & !treated_commune]

## ─── Analysis sample ─────────────────────────────────────
## Keep only: treated communes + control cities
## This creates a focused panel for the main analysis
analysis <- dvf[treated_commune | control_city]

cat("\n=== ANALYSIS SAMPLE ===\n")
cat("Total transactions:", nrow(analysis), "\n")
cat("Treated commune transactions:", sum(analysis$treated_commune), "\n")
cat("Control city transactions:", sum(analysis$control_city), "\n")
cat("Investment-type:", sum(analysis$investment_type), "\n")
cat("Owner-occupier-type:", sum(!analysis$investment_type), "\n")

## ─── Time variables for CS-DiD ──────────────────────────
## Cohort (group) = year-quarter of treatment adoption
## For never-treated, cohort = 0

analysis[, treat_yq := fifelse(
  treated_commune,
  as.numeric(format(treat_date, "%Y")) + (quarter(treat_date) - 1) / 4,
  0  # Never treated
)]

## Time period = year-quarter numeric
analysis[, period_yq := year + (quarter(date_mutation) - 1) / 4]

## Year-quarter factor for FE
analysis[, yq := factor(year_quarter)]

## ─── Aggregate to commune × quarter panel ────────────────
## For CS-DiD, we need a balanced panel at the commune-quarter level
## Compute: median price, mean price, N transactions, pct_investment

panel <- analysis[, .(
  n_transactions = .N,
  median_price = median(valeur_fonciere),
  mean_price = mean(valeur_fonciere),
  log_median_price = log(median(valeur_fonciere)),
  median_price_sqm = median(price_sqm, na.rm = TRUE),
  pct_investment = mean(investment_type) * 100,
  median_price_invest = median(valeur_fonciere[investment_type], na.rm = TRUE),
  median_price_owner = median(valeur_fonciere[!investment_type], na.rm = TRUE),
  n_invest = sum(investment_type),
  n_owner = sum(!investment_type)
), by = .(code_commune, year_quarter, year, treated_commune,
          control_city, treat_date, treat_city, treat_yq)]

## Log prices
panel[, log_median_invest := log(median_price_invest)]
panel[, log_median_owner := log(median_price_owner)]

## Period numeric
panel[, period_yq := year + (as.numeric(substr(year_quarter, 6, 6)) - 1) / 4]

## Post indicator
panel[, post := as.Date(paste0(year_quarter, "-01"),
                        format = "%YQ%q-01") >= treat_date & treated_commune]
## Simpler post construction
panel[, qtr := as.numeric(substr(year_quarter, 6, 6))]
panel[, period_date := as.Date(paste0(year, "-", qtr * 3, "-01"))]
panel[treated_commune == TRUE, post := period_date >= treat_date]
panel[treated_commune == FALSE | is.na(treated_commune), post := FALSE]

## Investment-owner price gap (for DDD at commune level)
panel[, price_gap := log_median_invest - log_median_owner]

## ─── Save processed data ─────────────────────────────────
write_parquet(as.data.frame(analysis), file.path(data_dir, "dvf_analysis.parquet"))
write_parquet(as.data.frame(panel), file.path(data_dir, "dvf_panel.parquet"))
fwrite(analysis[, .(code_commune, date_mutation, valeur_fonciere, type_local,
                     nombre_pieces_principales, surface_reelle_bati,
                     treated_commune, post_treatment, investment_type,
                     year, year_quarter, treat_city, rental_score, price_sqm)],
       file.path(data_dir, "dvf_analysis_lite.csv"))

cat("\nSaved analysis dataset:", nrow(analysis), "transactions\n")
cat("Saved panel dataset:", nrow(panel), "commune-quarters\n")

## ─── Summary tables ──────────────────────────────────────
cat("\n=== TREATMENT GROUP SUMMARY ===\n")
treat_summary <- analysis[treated_commune == TRUE, .(
  n_pre = sum(!post_treatment),
  n_post = sum(post_treatment),
  median_price_pre = median(valeur_fonciere[!post_treatment]),
  median_price_post = median(valeur_fonciere[post_treatment]),
  pct_invest = round(mean(investment_type) * 100, 1)
), by = treat_city]
print(treat_summary)

fwrite(treat_summary, file.path(data_dir, "treatment_summary.csv"))

cat("\n02_clean_data.R complete.\n")
