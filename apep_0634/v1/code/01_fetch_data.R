# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for coal-producing states
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ─── Coal-producing states (abbreviations for Azure file paths) ──────────────
# Include all states that could have NAICS 212 (mining) employment plus some
# neighbors as controls. We cast a wide net; zero-coal counties serve as controls.

coal_states <- c(
  "al", "ar", "co", "il", "in", "ks", "ky", "la", "md", "mo",
  "mt", "ms", "nd", "nm", "oh", "ok", "pa", "tn", "tx", "ut",
  "va", "wa", "wv", "wy"
)

# Also include nearby/control states
control_states <- c(
  "az", "ca", "fl", "ga", "ia", "mi", "nc", "nj", "ny", "ri",
  "sc", "wi", "mn", "ne", "sd"
)

all_states <- c(coal_states, control_states)

# ─── Fetch data state by state ──────────────────────────────────────────────
# Filter to aggregate demographic cells (total across sex/age/race/etc.)
# and relevant industries: 0 (total) and 212 (coal mining)

cat("Fetching QWI data for", length(all_states), "states...\n")

fetch_state <- function(st) {
  q <- sprintf(
    "SELECT geography, industry, year, quarter,
            Emp, EmpTotal, EmpS, EarnS, HirA, Sep, FrmJbGn, FrmJbLs, Payroll,
            sEmpTotal, sEarnS, sHirA, sSep, sFrmJbGn, sFrmJbLs
     FROM 'az://derived/qwi/rh/n3/%s.parquet'
     WHERE industry IN (0, 212)
       AND sex = 0
       AND agegrp = 'A00'
       AND race = 'A0'
       AND ethnicity = 'A0'
       AND education = 'E0'
       AND firmage = 0
       AND firmsize = 0
       AND year >= 2000 AND year <= 2016", st)
  tryCatch(
    DBI::dbGetQuery(con, q),
    error = function(e) {
      cat(sprintf("  SKIP %s: %s\n", toupper(st), conditionMessage(e)))
      return(NULL)
    }
  )
}

dfs <- list()
for (st in all_states) {
  df <- fetch_state(st)
  if (!is.null(df) && nrow(df) > 0) {
    df$state_abbr <- toupper(st)
    dfs[[st]] <- df
    n_coal <- sum(df$industry == 212 & !is.na(df$EmpTotal) & df$EmpTotal > 0)
    cat(sprintf("  %s: %d total rows, %d coal mining obs with employment\n",
                toupper(st), nrow(df), n_coal))
  }
}

all_data <- bind_rows(dfs)
cat(sprintf("\nTotal: %d rows across %d states\n", nrow(all_data), length(dfs)))

# ─── Validate data ──────────────────────────────────────────────────────────
stopifnot("No data fetched" = nrow(all_data) > 0)

coal_counties_2005 <- all_data |>
  filter(industry == 212, year == 2005, !is.na(EmpTotal), EmpTotal > 0) |>
  distinct(geography)

cat(sprintf("Counties with coal mining employment in 2005: %d\n", nrow(coal_counties_2005)))
stopifnot("Too few coal counties" = nrow(coal_counties_2005) >= 20)

# ─── Save raw data ──────────────────────────────────────────────────────────
saveRDS(all_data, "../data/qwi_raw.rds")
cat("Saved: data/qwi_raw.rds\n")

apep_azure_disconnect(con)
cat("Data fetch complete.\n")
