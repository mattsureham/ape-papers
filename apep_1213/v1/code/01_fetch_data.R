# 01_fetch_data.R — Fetch Moldova NBS StatBank data
# apep_1213: Moldova bank crisis and firm employment

source("00_packages.R")

cat("=== Fetching Moldova NBS StatBank data ===\n")

base_url <- "http://statbank.statistica.md/PxWeb/api/v1/en"

# Helper to query PxWeb API and parse result into a data.table
fetch_pxweb <- function(table_path, query_body, max_retries = 3) {
  url <- paste0(base_url, "/", table_path)
  for (attempt in 1:max_retries) {
    resp <- tryCatch({
      httr::POST(
        url,
        body = toJSON(query_body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(120)
      )
    }, error = function(e) {
      cat(sprintf("  Attempt %d connection error: %s\n", attempt, e$message))
      NULL
    })
    if (is.null(resp)) {
      if (attempt == max_retries) stop(sprintf("Failed after %d attempts for %s", max_retries, url))
      Sys.sleep(2 * attempt)
      next
    }
    if (httr::status_code(resp) != 200) {
      cat(sprintf("  Attempt %d HTTP %d\n", attempt, httr::status_code(resp)))
      if (attempt == max_retries) stop(sprintf("HTTP %d from %s", httr::status_code(resp), url))
      Sys.sleep(2 * attempt)
      next
    }
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(raw)
    # Parse data: parsed$data is a data.frame with $key (list col) and $values (list col)
    n_rows <- nrow(parsed$data)
    if (is.null(n_rows) || n_rows == 0) stop("No data returned")
    # Dimension columns have type "d" or "t"; content column has type "c"
    dim_mask <- parsed$columns$type %in% c("d", "t")
    dim_names <- parsed$columns$code[dim_mask]
    rows_list <- vector("list", n_rows)
    for (i in seq_len(n_rows)) {
      row_key <- parsed$data$key[[i]]
      row_val <- parsed$data$values[[i]]
      row <- as.list(row_key)
      names(row) <- dim_names
      row$value <- as.numeric(row_val[1])
      rows_list[[i]] <- row
    }
    dt <- rbindlist(rows_list)
    return(dt)
  }
}

# District codes (raions only, excluding regional aggregates)
raion_codes <- c("34", "35", "3", "10", "11", "13", "14", "15", "16", "21",
                 "24", "25", "26", "1", "6", "9", "12", "17", "18", "20",
                 "22", "23", "27", "28", "31", "32", "2", "4", "5", "7",
                 "8", "19", "29", "30", "33")

# ============================================================
# 1. Pre-crisis data: ANT030200reg (2005-2014)
# ============================================================
cat("\n--- Fetching pre-crisis enterprise data (2005-2014) ---\n")

year_codes_pre <- as.character(2005:2014)

dt_pre <- fetch_pxweb(
  "40%20Statistica%20economica/24%20ANT/ANT030/ANT030200reg.px",
  list(
    query = list(
      list(code = "Raioane", selection = list(filter = "item", values = raion_codes)),
      list(code = "Marimea intreprinderii", selection = list(filter = "item", values = list("0"))),
      list(code = "Indicatori", selection = list(filter = "item", values = list("0", "1", "2"))),
      list(code = "Ani", selection = list(filter = "item", values = year_codes_pre))
    ),
    response = list(format = "json")
  )
)

setnames(dt_pre, c("Raioane", "Marimea intreprinderii", "Indicatori", "Ani"),
         c("raion_code", "size", "indicator_code", "year"))
dt_pre[, year := as.integer(year)]

# Map indicator codes to names
dt_pre[, indicator := fcase(
  indicator_code == "0", "n_enterprises",
  indicator_code == "1", "avg_employees",
  indicator_code == "2", "turnover_mln"
)]

df_pre_wide <- dcast(dt_pre, raion_code + year ~ indicator, value.var = "value")
cat(sprintf("  Pre-crisis: %d raion-years, %d raions, years %d-%d\n",
    nrow(df_pre_wide), uniqueN(df_pre_wide$raion_code),
    min(df_pre_wide$year), max(df_pre_wide$year)))
stopifnot(nrow(df_pre_wide) > 200)

# ============================================================
# 2. Post-crisis data: ANT030055reg (2015-2024)
# ============================================================
cat("\n--- Fetching post-crisis enterprise data (2015-2024) ---\n")

year_codes_post <- as.character(2015:2024)

dt_post <- fetch_pxweb(
  "40%20Statistica%20economica/24%20ANT/ANT030/ANT030055reg.px",
  list(
    query = list(
      list(code = "Raioane/Regiuni", selection = list(filter = "item", values = raion_codes)),
      list(code = "Activitati economice", selection = list(filter = "item", values = list("000"))),
      list(code = "Indicatori", selection = list(filter = "item",
        values = list("Numarul de intreprinderi", "Numarul mediu de personal",
                      "Venituri din vinzari, mil lei"))),
      list(code = "Ani", selection = list(filter = "item", values = year_codes_post))
    ),
    response = list(format = "json")
  )
)

setnames(dt_post, c("Raioane/Regiuni", "Activitati economice", "Indicatori", "Ani"),
         c("raion_code", "sector", "indicator_raw", "year"))
dt_post[, year := as.integer(year)]
dt_post[, indicator := fcase(
  grepl("intreprinderi", indicator_raw), "n_enterprises",
  grepl("personal", indicator_raw), "avg_employees",
  grepl("Venituri", indicator_raw), "turnover_mln"
)]

df_post_wide <- dcast(dt_post, raion_code + year ~ indicator, value.var = "value")
cat(sprintf("  Post-crisis: %d raion-years, %d raions, years %d-%d\n",
    nrow(df_post_wide), uniqueN(df_post_wide$raion_code),
    min(df_post_wide$year), max(df_post_wide$year)))
stopifnot(nrow(df_post_wide) > 200)

# ============================================================
# 3. Sector-level pre-crisis: ANT030400reg (2005-2014)
#    Financial intermediation (J) for treatment construction
# ============================================================
cat("\n--- Fetching sector-level data (financial intermediation, 2005-2014) ---\n")

dt_sector_pre <- fetch_pxweb(
  "40%20Statistica%20economica/24%20ANT/ANT030/ANT030400reg.px",
  list(
    query = list(
      list(code = "Raioane/Regiuni", selection = list(filter = "item", values = raion_codes)),
      list(code = "Activitati economice", selection = list(filter = "item",
        values = list("00", "J"))),
      list(code = "Ani", selection = list(filter = "item", values = year_codes_pre)),
      list(code = "Indicatori", selection = list(filter = "item", values = list("0", "2")))
    ),
    response = list(format = "json")
  )
)

setnames(dt_sector_pre, c("Raioane/Regiuni", "Activitati economice", "Ani", "Indicatori"),
         c("raion_code", "sector", "year", "indicator_code"))
dt_sector_pre[, year := as.integer(year)]
dt_sector_pre[, indicator := fcase(
  indicator_code == "0", "n_enterprises",
  indicator_code == "2", "avg_employees"
)]

cat(sprintf("  Sector pre-crisis: %d records\n", nrow(dt_sector_pre)))

# ============================================================
# 4. Sector-level post-crisis: ANT030055reg — Financial (K)
# ============================================================
cat("\n--- Fetching sector-level data (financial sector, 2015-2024) ---\n")

dt_sector_post <- fetch_pxweb(
  "40%20Statistica%20economica/24%20ANT/ANT030/ANT030055reg.px",
  list(
    query = list(
      list(code = "Raioane/Regiuni", selection = list(filter = "item", values = raion_codes)),
      list(code = "Activitati economice", selection = list(filter = "item",
        values = list("000", "K"))),
      list(code = "Indicatori", selection = list(filter = "item",
        values = list("Numarul de intreprinderi", "Numarul mediu de personal"))),
      list(code = "Ani", selection = list(filter = "item", values = year_codes_post))
    ),
    response = list(format = "json")
  )
)

setnames(dt_sector_post, c("Raioane/Regiuni", "Activitati economice", "Indicatori", "Ani"),
         c("raion_code", "sector", "indicator_raw", "year"))
dt_sector_post[, year := as.integer(year)]
dt_sector_post[, indicator := fcase(
  grepl("intreprinderi", indicator_raw), "n_enterprises",
  grepl("personal", indicator_raw), "avg_employees"
)]

cat(sprintf("  Sector post-crisis: %d records\n", nrow(dt_sector_post)))

# ============================================================
# 5. Population by raion (2014-2024)
# ============================================================
cat("\n--- Fetching population data (2014-2024) ---\n")

dt_pop <- fetch_pxweb(
  "20%20Populatia%20si%20procesele%20demografice/POP010/POPro/POP010400rclreg.px",
  list(
    query = list(
      list(code = "Raioane", selection = list(filter = "item", values = raion_codes)),
      list(code = "Grupe de varsta", selection = list(filter = "item", values = list("0"))),
      list(code = "Ani", selection = list(filter = "item", values = as.character(2014:2024))),
      list(code = "Medii", selection = list(filter = "item", values = list("0"))),
      list(code = "Sexe", selection = list(filter = "item", values = list("0")))
    ),
    response = list(format = "json")
  )
)

setnames(dt_pop, "Raioane", "raion_code")
dt_pop[, year := as.integer(Ani)]
dt_pop[, population := value]
dt_pop <- dt_pop[, .(raion_code, year, population)]

cat(sprintf("  Population: %d raion-years\n", nrow(dt_pop)))

# ============================================================
# 6. Raion name mapping
# ============================================================
raion_names <- data.table(
  raion_code = c("34", "35", "3", "10", "11", "13", "14", "15", "16", "21",
                 "24", "25", "26", "1", "6", "9", "12", "17", "18", "20",
                 "22", "23", "27", "28", "31", "32", "2", "4", "5", "7",
                 "8", "19", "29", "30", "33"),
  raion_name = c("Chisinau", "Balti", "Briceni", "Donduseni", "Drochia",
                 "Edinet", "Falesti", "Floresti", "Glodeni", "Ocnita",
                 "Riscani", "Singerei", "Soroca", "Anenii Noi", "Calarasi",
                 "Criuleni", "Dubasari", "Hincesti", "Ialoveni", "Nisporeni",
                 "Orhei", "Rezina", "Straseni", "Soldanesti", "Telenesti",
                 "Ungheni", "Basarabeasca", "Cahul", "Cantemir", "Causeni",
                 "Cimislia", "Leova", "Stefan Voda", "Taraclia", "Gagauzia"),
  is_municipality = c(TRUE, TRUE, rep(FALSE, 33)),
  region = c("Chisinau", "North", "North", "North", "North", "North", "North",
             "North", "North", "North", "North", "North", "North",
             "Centre", "Centre", "Centre", "Centre", "Centre", "Centre", "Centre",
             "Centre", "Centre", "Centre", "Centre", "Centre", "Centre",
             "South", "South", "South", "South", "South", "South", "South",
             "South", "Gagauzia")
)

# ============================================================
# Save all raw data
# ============================================================
cat("\n=== Saving data ===\n")

save(df_pre_wide, df_post_wide, dt_sector_pre, dt_sector_post,
     dt_pop, raion_names,
     file = "../data/raw_nbs_data.RData")

cat(sprintf("Pre-crisis panel: %d obs (%d raions x %d years)\n",
    nrow(df_pre_wide), uniqueN(df_pre_wide$raion_code), uniqueN(df_pre_wide$year)))
cat(sprintf("Post-crisis panel: %d obs (%d raions x %d years)\n",
    nrow(df_post_wide), uniqueN(df_post_wide$raion_code), uniqueN(df_post_wide$year)))
cat(sprintf("Sector data: %d pre + %d post records\n",
    nrow(dt_sector_pre), nrow(dt_sector_post)))
cat(sprintf("Population: %d raion-years\n", nrow(dt_pop)))
cat("\nData fetch complete.\n")
