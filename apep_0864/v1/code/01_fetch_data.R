## 01_fetch_data.R — Fetch referendum + population data for apep_0864
## Sources: swissdd (referendum), BFS PXWeb (population by citizenship)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. REFERENDUM DATA — swissdd package
# ============================================================
cat("=== Fetching referendum data via swissdd ===\n")

if (!requireNamespace("swissdd", quietly = TRUE)) {
  install.packages("swissdd", repos = "https://cloud.r-project.org")
}
library(swissdd)

# 2014-02-09: ID 5800 = "Gegen Masseneinwanderung" (MEI)
mei_all <- get_nationalvotes(votedates = "2014-02-09", geolevel = "municipality")

mei <- mei_all |>
  filter(id == 5800) |>
  transmute(
    bfs_nr = as.integer(mun_id),
    gem_name = mun_name,
    canton_id = as.integer(canton_id),
    canton_name = canton_name,
    yes_share = jaStimmenInProzent / 100,
    yes = jaStimmenAbsolut,
    no = neinStimmenAbsolut,
    turnout = stimmbeteiligungInProzent / 100,
    eligible = anzahlStimmberechtigte
  )

cat(sprintf("MEI: %d municipalities, mean=%.1f%%, SD=%.1fpp\n",
            nrow(mei), mean(mei$yes_share)*100, sd(mei$yes_share)*100))
stopifnot(nrow(mei) >= 2000)

# Placebo: FABI (railway financing), ID 5780
fabi <- mei_all |>
  filter(id == 5780) |>
  transmute(bfs_nr = as.integer(mun_id), placebo_yes_share = jaStimmenInProzent / 100)

saveRDS(mei, file.path(data_dir, "referendum_mei_2014.rds"))
saveRDS(fabi, file.path(data_dir, "referendum_fabi_2014.rds"))

# ============================================================
# 2. POPULATION BY CITIZENSHIP — BFS PXWeb
# ============================================================
cat("\n=== Fetching population data from BFS PXWeb ===\n")

bfs_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102010000_104/px-x-0102010000_104.px"

# Get commune codes from metadata
meta_resp <- httr2::request(bfs_url) |> httr2::req_timeout(30) |> httr2::req_perform()
meta <- httr2::resp_body_json(meta_resp, simplifyVector = FALSE)
geo_var <- meta$variables[[2]]
all_geo <- unlist(geo_var$values)

# Communes have 4-digit numeric codes (exclude Switzerland=8100, cantons, districts)
communes <- all_geo[grepl("^[0-9]{4}$", all_geo) & all_geo != "8100"]
cat(sprintf("Commune codes found: %d\n", length(communes)))

years <- as.character(2010:2023)
all_pop <- list()

for (yr in years) {
  cat(sprintf("  Fetching %s (%d communes)...", yr, length(communes)))

  # Query: all communes, permanent pop, total birthplace, total + Swiss citizenship
  query_body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
      list(code = geo_var$code, selection = list(filter = "item", values = as.list(communes))),
      list(code = "Bevölkerungstyp", selection = list(filter = "item", values = list("1"))),
      list(code = "Geburtsort", selection = list(filter = "item", values = list("-99999"))),
      list(code = "Staatsangehörigkeit", selection = list(filter = "item", values = list("-99999", "8100")))
    ),
    response = list(format = "json")
  )

  resp <- httr2::request(bfs_url) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(query_body) |>
    httr2::req_timeout(180) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(resp) != 200) {
    cat(sprintf(" HTTP %d — skipping\n", httr2::resp_status(resp)))
    next
  }

  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  n_rows <- 0

  for (row in body$data) {
    val <- row$values[[1]]
    if (!is.null(val) && val != "..." && val != "") {
      # Keys: [Year, Geo, PopType, BirthPlace, Citizenship]
      all_pop[[length(all_pop) + 1]] <- data.frame(
        bfs_nr = as.integer(row$key[[2]]),
        cit_code = row$key[[5]],
        year = as.integer(yr),
        pop = as.numeric(val),
        stringsAsFactors = FALSE
      )
      n_rows <- n_rows + 1
    }
  }

  cat(sprintf(" %d rows\n", n_rows))
  Sys.sleep(0.5)
}

pop_raw <- bind_rows(all_pop)
cat(sprintf("\nTotal population rows: %d\n", nrow(pop_raw)))

if (nrow(pop_raw) < 10000) {
  stop("FATAL: Population data too sparse. Cannot proceed.")
}

# Reshape: one row per bfs_nr × year with total_pop and swiss_pop
pop <- pop_raw |>
  mutate(cit_label = ifelse(cit_code == "-99999", "total", "swiss")) |>
  select(-cit_code) |>
  pivot_wider(names_from = cit_label, values_from = pop) |>
  mutate(
    foreign = total - swiss,
    foreign_share = foreign / total
  )

cat(sprintf("Panel: %d municipality-year obs\n", nrow(pop)))
cat(sprintf("Municipalities: %d\n", n_distinct(pop$bfs_nr)))
cat(sprintf("Years: %s\n", paste(sort(unique(pop$year)), collapse = ", ")))

saveRDS(pop, file.path(data_dir, "population_panel.rds"))

# Coverage summary
pop |>
  group_by(year) |>
  summarize(n_mun = n(), total = sum(total, na.rm=TRUE), foreign_pct = mean(foreign_share, na.rm=TRUE)*100) |>
  print(n = 20)

cat("\n=== All data fetched successfully ===\n")
