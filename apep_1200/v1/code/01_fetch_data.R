# 01_fetch_data.R — Fetch Swiss referendum and population data
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

# Also need pxweb for BFS data
if (!requireNamespace("pxweb", quietly = TRUE)) {
  install.packages("pxweb", repos = "https://cloud.r-project.org")
}
library(pxweb)

cat("=== Fetching Swiss Data ===\n")

# ---------------------------------------------------------------
# 1. Municipal vote results for the 2014 MII (swissdd)
# ---------------------------------------------------------------

cat("\n--- Fetching 2014 MII vote results ---\n")

mii_votes_raw <- get_nationalvotes(
  votedates = "2014-02-09",
  geolevel = "municipality"
)

# Filter to the Mass Immigration Initiative (id = 5800)
mii <- mii_votes_raw %>%
  filter(id == 5800) %>%
  select(
    mun_id, mun_name, canton_id, canton_name,
    yes_pct = jaStimmenInProzent,
    yes_abs = jaStimmenAbsolut,
    no_abs = neinStimmenAbsolut,
    turnout = stimmbeteiligungInProzent,
    eligible = anzahlStimmberechtigte,
    valid_votes = gueltigeStimmen
  ) %>%
  mutate(
    mun_id = as.integer(mun_id),
    canton_id = as.integer(canton_id),
    yes_margin = yes_pct - 50,
    above_50 = as.integer(yes_pct > 50)
  )

cat("MII vote data:", nrow(mii), "municipalities\n")
cat("Mean yes-share:", round(mean(mii$yes_pct, na.rm = TRUE), 1), "%\n")
cat("Above 50%:", sum(mii$above_50), "/", nrow(mii), "\n")

saveRDS(mii, "../data/mii_votes.rds")
cat("✓ Vote data saved\n")

# ---------------------------------------------------------------
# 2. BFS PXWeb: Municipal population by citizenship (2010-2019)
# ---------------------------------------------------------------

cat("\n--- Fetching BFS municipal population data via pxweb ---\n")

url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_201/px-x-0102020000_201.px"

pxq <- pxweb_query(list(
  "Jahr" = as.character(2010:2019),
  "Kanton (-) / Bezirk (>>) / Gemeinde (......)" = "*",
  "Staatsangehörigkeit (Kategorie)" = c("0", "2"),  # Total and Foreign
  "Geschlecht" = "0",
  "Demografische Komponente" = "0"  # Population on Jan 1
))

px_data <- pxweb_get(url, pxq)
pop_raw <- as.data.frame(px_data,
                          column.name.type = "text",
                          variable.value.type = "text")

cat("Population data:", nrow(pop_raw), "rows\n")

saveRDS(pop_raw, "../data/bfs_population.rds")
cat("✓ Population data saved\n")

# ---------------------------------------------------------------
# 3. Placebo referendum: Ecopop (2014-11-30)
# ---------------------------------------------------------------

cat("\n--- Fetching Ecopop placebo vote ---\n")

ecopop_raw <- get_nationalvotes(
  votedates = "2014-11-30",
  geolevel = "municipality"
)

cat("Ecopop votes:", nrow(ecopop_raw), "rows, IDs:", paste(unique(ecopop_raw$id), collapse = ", "), "\n")
saveRDS(ecopop_raw, "../data/ecopop_votes_raw.rds")
cat("✓ Placebo vote data saved\n")

cat("\n=== Data fetch complete ===\n")
