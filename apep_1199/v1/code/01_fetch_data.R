# ─────────────────────────────────────────────
# 01_fetch_data.R — Download DATASUS SIH hospitalization data
# ─────────────────────────────────────────────
# Downloads reduced AIH (SIH-RD) files from DATASUS FTP for selected states,
# filters to waterborne diseases (ICD-10 A00-A09), and aggregates to
# municipality-year panel.

source("00_packages.R")

# Install microdatasus if needed
if (!requireNamespace("microdatasus", quietly = TRUE)) {
  install.packages("microdatasus", repos = "https://cloud.r-project.org")
}
library(microdatasus)

DATA_DIR <- file.path(dirname(getwd()), "data")
if (!dir.exists(DATA_DIR)) dir.create(DATA_DIR, recursive = TRUE)

# States to download:
# Treated: AL (Alagoas), RJ (Rio de Janeiro), RS (Rio Grande do Sul)
# Controls: SE, PE, BA (NE neighbors), SP, MG, ES (SE neighbors), SC, PR (S neighbors)
states <- c("AL", "RJ", "RS", "SE", "PE", "BA", "SP", "MG", "ES", "SC", "PR")
years <- 2014:2023

cat("Downloading DATASUS SIH data for", length(states), "states,", length(years), "years...\n")

all_data <- list()
idx <- 1

for (yr in years) {
  for (st in states) {
    cat(sprintf("  %s %d... ", st, yr))
    tryCatch({
      # microdatasus::fetch_datasus downloads and parses SIH-RD files
      df <- fetch_datasus(
        year_start = yr,
        year_end = yr,
        uf = st,
        information_system = "SIH-RD",
        vars = c("MUNIC_RES", "DIAG_PRINC", "IDADE", "COD_IDADE", "VAL_TOT",
                 "ANO_CMPT", "MES_CMPT", "MUNIC_MOV")
      )

      if (!is.null(df) && nrow(df) > 0) {
        # Filter to waterborne diseases: ICD-10 A00-A09
        df$icd3 <- substr(df$DIAG_PRINC, 1, 3)
        waterborne <- df[grepl("^A0[0-9]$", df$icd3), ]

        if (nrow(waterborne) > 0) {
          # Construct age in years
          waterborne$age_years <- as.numeric(waterborne$IDADE)
          waterborne$age_code <- as.numeric(waterborne$COD_IDADE)
          # COD_IDADE: 2=days, 3=months, 4=years, 5=100+years
          waterborne$age_years <- ifelse(waterborne$age_code == 4, waterborne$age_years,
                                  ifelse(waterborne$age_code == 3, waterborne$age_years / 12,
                                  ifelse(waterborne$age_code == 2, waterborne$age_years / 365, NA)))

          all_data[[idx]] <- data.table(
            muni_code = waterborne$MUNIC_RES,
            year = as.integer(waterborne$ANO_CMPT),
            month = as.integer(waterborne$MES_CMPT),
            icd3 = waterborne$icd3,
            age_years = waterborne$age_years,
            cost = as.numeric(waterborne$VAL_TOT)
          )
          idx <- idx + 1
          cat(sprintf("%d waterborne records\n", nrow(waterborne)))
        } else {
          cat("0 waterborne\n")
        }
      } else {
        cat("no data returned\n")
      }
    }, error = function(e) {
      cat(sprintf("ERROR: %s\n", e$message))
    })
  }
}

if (length(all_data) == 0) {
  stop("FATAL: No SIH data downloaded. Cannot proceed with analysis.")
}

sih <- rbindlist(all_data)
cat(sprintf("\nTotal waterborne hospitalization records: %d\n", nrow(sih)))
cat(sprintf("Municipalities with data: %d\n", uniqueN(sih$muni_code)))
cat(sprintf("Years covered: %s\n", paste(sort(unique(sih$year)), collapse = ", ")))

# ─────────────────────────────────────────────
# Aggregate to municipality-year level
# ─────────────────────────────────────────────
sih_agg <- sih[, .(
  n_hosp = .N,
  n_under5 = sum(age_years < 5, na.rm = TRUE),
  n_under1 = sum(age_years < 1, na.rm = TRUE),
  total_cost = sum(cost, na.rm = TRUE),
  n_diarrhea = sum(icd3 %in% c("A00", "A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08", "A09"), na.rm = TRUE)
), by = .(muni_code, year)]

cat(sprintf("Municipality-year panel: %d observations\n", nrow(sih_agg)))

# ─────────────────────────────────────────────
# Pad with zeros for municipality-years with no hospitalizations
# ─────────────────────────────────────────────
all_munis <- unique(sih_agg$muni_code)
all_years <- min(sih_agg$year):max(sih_agg$year)
full_panel <- CJ(muni_code = all_munis, year = all_years)

sih_panel <- merge(full_panel, sih_agg, by = c("muni_code", "year"), all.x = TRUE)
sih_panel[is.na(n_hosp), `:=`(n_hosp = 0L, n_under5 = 0L, n_under1 = 0L,
                               total_cost = 0, n_diarrhea = 0L)]

fwrite(sih_panel, file.path(DATA_DIR, "sih_waterborne.csv"))
cat(sprintf("Balanced panel saved: %d observations (%d municipalities x %d years)\n",
            nrow(sih_panel), uniqueN(sih_panel$muni_code), length(all_years)))
