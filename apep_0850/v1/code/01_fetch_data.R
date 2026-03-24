## 01_fetch_data.R — apep_0850
## Fetch Swiss Grenzgänger (cross-border worker) data from BFS SDMX

source("00_packages.R")

cat("=== Fetching Grenzgänger Statistics from BFS SDMX ===\n")

# Download the full GGS dataset
ggs_url <- "https://disseminate.stats.swiss/rest/v2/data/dataflow/CH1.GGS/DF_GGS_1?format=csvfile"
ggs_file <- "../data/ggs_raw.csv"

if (!file.exists(ggs_file)) {
  cat("Downloading GGS data (523 MB, may take a few minutes)...\n")
  download.file(ggs_url, ggs_file, mode = "wb", quiet = FALSE)
  cat("Download complete.\n")
} else {
  cat("GGS data already on disk.\n")
}

# Verify file size
fsize <- file.info(ggs_file)$size / 1e6
cat(sprintf("File size: %.1f MB\n", fsize))
stopifnot("GGS file too small — download may have failed" = fsize > 100)

# Read with data.table for speed
cat("Reading GGS CSV...\n")
ggs <- fread(ggs_file, header = TRUE)
cat(sprintf("Rows: %s, Columns: %d\n", format(nrow(ggs), big.mark = ","), ncol(ggs)))

# Inspect columns
cat("Columns:", paste(names(ggs), collapse = ", "), "\n")

# ---- Parse key dimensions ----

# Time period: "2002-Q3" -> year, quarter, date
ggs[, `:=`(
  year    = as.integer(str_extract(TIME_PERIOD, "^\\d{4}")),
  quarter = as.integer(str_extract(TIME_PERIOD, "Q(\\d)", group = 1)),
  canton  = as.integer(CANTON_WORK),
  noga    = as.integer(NOGA),
  country = CNTRY,
  sex     = SEX,
  cbw     = as.numeric(OBS_VALUE)
)]

# Create a quarterly time index
ggs[, time_q := year + (quarter - 1) / 4]

# ---- Filter to analysis sample ----
# Focus on cross-border workers from France (FR) coming to border cantons
# Geneva (25), Vaud (22), Basel-Stadt (12), Jura (26), Neuchâtel (24)
# Also keep Ticino (21) for Italy-origin replication
# Keep all sexes combined (_T)

border_cantons_fr <- c(25, 22, 12, 26, 24)  # French border cantons
ticino <- 21

# Canton names for labels
canton_names <- data.table(
  canton = c(1:26),
  canton_name = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                  "Nidwalden", "Glarus", "Zug", "Fribourg", "Solothurn",
                  "Basel-Stadt", "Basel-Landschaft", "Schaffhausen", "Appenzell A.Rh.",
                  "Appenzell I.Rh.", "St. Gallen", "Graubünden", "Aargau",
                  "Thurgau", "Ticino", "Vaud", "Valais", "Neuchâtel",
                  "Genève", "Jura")
)

# Filter: French border cantons, from France, both sexes combined
cat("Filtering to French border cantons, France-origin CBW...\n")
df_fr <- ggs[canton %in% border_cantons_fr & country == "FR" & sex == "_T"]
cat(sprintf("French border sample: %s rows\n", format(nrow(df_fr), big.mark = ",")))

# Also prepare Ticino from Italy for replication
df_ti <- ggs[canton == ticino & country == "IT" & sex == "_T"]
cat(sprintf("Ticino-Italy sample: %s rows\n", format(nrow(df_ti), big.mark = ",")))

# ---- Aggregate to canton x sector x quarter ----
# Sum across country (just FR for main, IT for Ticino) — already filtered
panel_fr <- df_fr[, .(cbw = sum(cbw, na.rm = TRUE)),
                   by = .(canton, noga, year, quarter, time_q, TIME_PERIOD)]

panel_ti <- df_ti[, .(cbw = sum(cbw, na.rm = TRUE)),
                   by = .(canton, noga, year, quarter, time_q, TIME_PERIOD)]

cat(sprintf("French panel: %s canton-sector-quarter obs\n",
            format(nrow(panel_fr), big.mark = ",")))
cat(sprintf("Ticino panel: %s canton-sector-quarter obs\n",
            format(nrow(panel_ti), big.mark = ",")))

# ---- Quick validation: Geneva CBW trends ----
geneva_total <- panel_fr[canton == 25, .(total_cbw = sum(cbw)), by = .(year, quarter)]
setorder(geneva_total, year, quarter)
cat("\n=== Geneva total French CBW by year (Q1) ===\n")
print(geneva_total[quarter == 1])

# ---- Sector-level summary for bite classification ----
# Pre-treatment average CBW by sector in Geneva (2015-2019)
pre_geneva <- panel_fr[canton == 25 & year >= 2015 & year <= 2019,
                        .(avg_cbw = mean(cbw)), by = noga]
setorder(pre_geneva, -avg_cbw)
cat("\n=== Top 15 sectors by average CBW in Geneva (2015-2019) ===\n")
print(head(pre_geneva, 15))

# ---- Save processed data ----
saveRDS(panel_fr, "../data/panel_fr.rds")
saveRDS(panel_ti, "../data/panel_ti.rds")
saveRDS(canton_names, "../data/canton_names.rds")
saveRDS(ggs[sex == "_T", .(canton, noga, country, year, quarter, time_q, cbw)],
        "../data/ggs_all_cantons.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Unique cantons (FR panel): %d\n", uniqueN(panel_fr$canton)))
cat(sprintf("Unique sectors (FR panel): %d\n", uniqueN(panel_fr$noga)))
cat(sprintf("Quarter range: %s to %s\n",
            min(panel_fr$TIME_PERIOD), max(panel_fr$TIME_PERIOD)))
