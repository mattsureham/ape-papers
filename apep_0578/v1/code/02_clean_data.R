## ============================================================================
## 02_clean_data.R — Construct treatment panel
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"

cat("=== Building treatment panel ===\n")

## ---------------------------------------------------------------------------
## 1. Load raw data
## ---------------------------------------------------------------------------
gdp <- fread(file.path(data_dir, "nuts3_gdp.csv"))
emp <- fread(file.path(data_dir, "nuts3_employment.csv"))

## Deduplicate employment: raw data has multiple wstatus rows (EMP/SAL/SELF)
## Keep total (maximum) per region-year
emp <- emp[, .(employment = max(employment, na.rm = TRUE)), by = .(nuts3, year)]
cat("Employment after dedup:", nrow(emp), "rows,",
    nrow(emp[, .N, by=.(nuts3,year)][N>1]), "remaining duplicates\n")

## ---------------------------------------------------------------------------
## 2. Define treated border regions and cohorts
## ---------------------------------------------------------------------------
# Border control reintroduction dates and affected NUTS3 regions
# Source: European Commission notifications under Article 25/28 Schengen Borders Code

# Germany-Austria border (Sep 13, 2015) — Bavaria/Upper Austria/Tyrol/Salzburg
de_at_de <- c("DE213", "DE214", "DE215", "DE216", "DE217", "DE218",
              "DE219", "DE21A", "DE21B", "DE21C", "DE21D", "DE21E",
              "DE21F", "DE21G", "DE21H", "DE21I", "DE21J", "DE21K",
              "DE21L", "DE21M", "DE21N",
              "DE221", "DE222", "DE223", "DE224", "DE225", "DE226",
              "DE227", "DE228", "DE229", "DE22A", "DE22B", "DE22C",
              "DE272", "DE273", "DE274", "DE275", "DE276", "DE277",
              "DE279", "DE27A", "DE27B", "DE27C", "DE27D", "DE27E")
de_at_at <- c("AT111", "AT112", "AT113",
              "AT121", "AT122", "AT123", "AT124", "AT125", "AT126",
              "AT311", "AT312", "AT313", "AT314", "AT315",
              "AT321", "AT322", "AT323")

# Austria-Hungary border (Sep 16, 2015)
at_hu_at <- c("AT111", "AT112", "AT113")
at_hu_hu <- c("HU221", "HU222", "HU223")

# Austria-Slovenia border (Sep 16, 2015)
at_si_at <- c("AT211", "AT212", "AT213")
at_si_si <- c("SI031", "SI032")

# Sweden-Denmark / Øresund (Nov 12, 2015)
se_dk_se <- c("SE224")
se_dk_dk <- c("DK012", "DK013")

# Denmark-Germany (Jan 4, 2016)
dk_de_dk <- c("DK032")
dk_de_de <- c("DEF01", "DEF02", "DEF03", "DEF04", "DEF05",
              "DEF06", "DEF07", "DEF08", "DEF09", "DEF0A",
              "DEF0B", "DEF0C", "DEF0D", "DEF0E", "DEF0F")

# France — all borders (Nov 13, 2015)
# Border NUTS3 regions in France (simplified — key border departments)
fr_border <- c("FRF11", "FRF12", "FRF21", "FRF22", "FRF23", "FRF24",
               "FRF31", "FRF32", "FRF33", "FRF34",
               "FRC11", "FRC12", "FRC13", "FRC14",
               "FRC21", "FRC22", "FRC23", "FRC24",
               "FRK21", "FRK22", "FRK23", "FRK24", "FRK25", "FRK26",
               "FRK27", "FRK28",
               "FRL01", "FRL02", "FRL03", "FRL04", "FRL05", "FRL06",
               "FRJ11", "FRJ12", "FRJ13", "FRJ14", "FRJ15",
               "FRJ21", "FRJ22", "FRJ23", "FRJ24", "FRJ25", "FRJ26", "FRJ27", "FRJ28")

# Build treatment assignment table
treat_list <- list(
  data.table(nuts3 = unique(c(de_at_de, de_at_at)),
             cohort = 2015, border_segment = "DE-AT",
             treat_date = "2015-09-13"),
  data.table(nuts3 = unique(c(at_hu_at, at_hu_hu)),
             cohort = 2015, border_segment = "AT-HU",
             treat_date = "2015-09-16"),
  data.table(nuts3 = unique(c(at_si_at, at_si_si)),
             cohort = 2015, border_segment = "AT-SI",
             treat_date = "2015-09-16"),
  data.table(nuts3 = unique(c(se_dk_se, se_dk_dk)),
             cohort = 2015, border_segment = "SE-DK",
             treat_date = "2015-11-12"),
  data.table(nuts3 = unique(c(dk_de_dk, dk_de_de)),
             cohort = 2016, border_segment = "DK-DE",
             treat_date = "2016-01-04"),
  data.table(nuts3 = unique(fr_border),
             cohort = 2015, border_segment = "FR-all",
             treat_date = "2015-11-13")
)

treatment <- rbindlist(treat_list)
# Some regions appear in multiple segments (e.g., AT111 on both DE-AT and AT-HU)
# Keep earliest cohort for CS estimator
treatment <- treatment[order(cohort)][!duplicated(nuts3)]

cat("Treatment regions:", nrow(treatment), "\n")
cat("  By segment:\n")
print(treatment[, .N, by = border_segment])

## ---------------------------------------------------------------------------
## 3. Define control border regions (unaffected Schengen internal borders)
## ---------------------------------------------------------------------------

# Germany-Netherlands border (never controlled) — NUTS3 regions
de_nl_de <- c("DEA11", "DEA12", "DEA13", "DEA14", "DEA15",
              "DEA16", "DEA17", "DEA18", "DEA19", "DEA1A",
              "DEA1B", "DEA1C", "DEA1D", "DEA1E", "DEA1F",
              "DEA34", "DEA35", "DEA36", "DEA37", "DEA38")
de_nl_nl <- c("NL111", "NL112", "NL113",
              "NL131", "NL132", "NL133",
              "NL211", "NL212", "NL213",
              "NL221", "NL222", "NL223", "NL224", "NL225", "NL226",
              "NL310", "NL321", "NL322", "NL323", "NL324", "NL325",
              "NL326", "NL327", "NL328")

# Germany-Belgium border
de_be_de <- c("DEA21", "DEA22", "DEA23", "DEA24", "DEA25",
              "DEA26", "DEA27", "DEA28", "DEA29", "DEA2A",
              "DEA2B", "DEA2C", "DEA2D")

# Austria-Italy border (South Tyrol/Trentino — never controlled)
at_it_at <- c("AT331", "AT332", "AT333", "AT334", "AT335")
at_it_it <- c("ITH10", "ITH20")

# Austria-Liechtenstein (never controlled)
# at_li <- c("AT342")  # Small

# Build control border regions
control_border <- unique(c(de_nl_de, de_nl_nl, de_be_de, at_it_at, at_it_it))
control_border <- setdiff(control_border, treatment$nuts3)

cat("Control border regions:", length(control_border), "\n")

## ---------------------------------------------------------------------------
## 4. Identify interior (non-border) NUTS3 regions
## ---------------------------------------------------------------------------
# All NUTS3 from the same countries as treatment/control
treated_countries <- unique(substr(treatment$nuts3, 1, 2))
all_country_regions <- unique(c(gdp$nuts3, emp$nuts3))
all_country_regions <- all_country_regions[substr(all_country_regions, 1, 2) %in% treated_countries]
# NUTS3 codes are typically 5 characters
all_country_regions <- all_country_regions[nchar(all_country_regions) == 5]

interior_regions <- setdiff(all_country_regions,
                            c(treatment$nuts3, control_border))
cat("Interior regions (same countries):", length(interior_regions), "\n")

## ---------------------------------------------------------------------------
## 5. Construct analysis panel
## ---------------------------------------------------------------------------
# Assign region types
region_type <- data.table(
  nuts3 = c(treatment$nuts3, control_border, interior_regions),
  region_type = c(rep("treated_border", nrow(treatment)),
                  rep("control_border", length(control_border)),
                  rep("interior", length(interior_regions)))
)

# Merge treatment info
region_type <- merge(region_type, treatment[, .(nuts3, cohort, border_segment)],
                     by = "nuts3", all.x = TRUE)

# Merge with GDP
panel <- merge(gdp, region_type, by = "nuts3")
panel[, country := substr(nuts3, 1, 2)]

# Create treatment indicator
panel[, treated := as.integer(region_type == "treated_border" & year >= cohort)]

# Log GDP per capita
panel[, log_gdp_pc := log(gdp_pc)]

# For Callaway-Sant'Anna: first treated period (0 for never-treated)
panel[, first_treat := fifelse(region_type == "treated_border", cohort, 0L)]

cat("\nPanel dimensions:\n")
cat("  Observations:", nrow(panel), "\n")
cat("  NUTS3 regions:", length(unique(panel$nuts3)), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")
cat("  Treated regions:", sum(region_type$region_type == "treated_border"), "\n")
cat("  Control border regions:", sum(region_type$region_type == "control_border"), "\n")
cat("  Interior regions:", sum(region_type$region_type == "interior"), "\n")

# Merge employment
panel <- merge(panel, emp, by = c("nuts3", "year"), all.x = TRUE)
panel[, log_emp := log(employment)]

# Merge GVA if available
if (file.exists(file.path(data_dir, "nuts3_gva_total.csv"))) {
  gva_total <- fread(file.path(data_dir, "nuts3_gva_total.csv"))
  gva_trade <- fread(file.path(data_dir, "nuts3_gva_trade.csv"))
  gva_manuf <- fread(file.path(data_dir, "nuts3_gva_manufacturing.csv"))

  panel <- merge(panel, gva_total, by = c("nuts3", "year"), all.x = TRUE)
  panel <- merge(panel, gva_trade, by = c("nuts3", "year"), all.x = TRUE)
  panel <- merge(panel, gva_manuf, by = c("nuts3", "year"), all.x = TRUE)

  # Sectoral shares
  panel[, share_trade := gva_trade_transport / gva_total]
  panel[, share_manuf := gva_manufacturing / gva_total]
  panel[, log_gva_total := log(gva_total)]
  panel[, log_gva_trade := log(gva_trade_transport)]
  panel[, log_gva_manuf := log(gva_manufacturing)]
}

# Merge population if available
if (file.exists(file.path(data_dir, "nuts3_population.csv"))) {
  pop <- fread(file.path(data_dir, "nuts3_population.csv"))
  panel <- merge(panel, pop, by = c("nuts3", "year"), all.x = TRUE)
  panel[, log_pop := log(population)]
}

## ---------------------------------------------------------------------------
## 6. Create numeric region ID for fixest
## ---------------------------------------------------------------------------
panel[, region_id := as.integer(as.factor(nuts3))]

## ---------------------------------------------------------------------------
## 7. Balance panel check
## ---------------------------------------------------------------------------
# Keep only regions with data in both pre and post periods
pre_post <- panel[, .(
  has_pre = any(year < 2015),
  has_post = any(year >= 2015),
  n_years = .N
), by = nuts3]

balanced_regions <- pre_post[has_pre == TRUE & has_post == TRUE & n_years >= 10, nuts3]
panel_balanced <- panel[nuts3 %in% balanced_regions]

cat("\nBalanced panel (>=10 years, both pre and post):\n")
cat("  Regions:", length(balanced_regions), "\n")
cat("  Observations:", nrow(panel_balanced), "\n")

## ---------------------------------------------------------------------------
## 8. Save
## ---------------------------------------------------------------------------
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(panel_balanced, file.path(data_dir, "analysis_panel_balanced.csv"))
fwrite(treatment, file.path(data_dir, "treatment_assignment.csv"))

# Save region classification for reference
region_summary <- region_type[, .N, by = .(region_type, border_segment)]
fwrite(region_summary, file.path(data_dir, "region_classification.csv"))

cat("\n02_clean_data.R complete.\n")
