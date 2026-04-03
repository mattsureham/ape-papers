## ==========================================================
## 04_robustness.R — Robustness checks and placebos
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

source("00_packages.R")

data_dir <- "../data"

## -----------------------------------------------------------
## 1. Load panel and results
## -----------------------------------------------------------
cat("=== Loading panel ===\n")

panel <- fread(file.path(data_dir, "state_year_panel.csv"))
dams  <- fread(file.path(data_dir, "dams_clean.csv"))
results_main <- readRDS(file.path(data_dir, "main_results.rds"))

cat("Panel:", nrow(panel), "rows,", uniqueN(panel$state_abbr), "states\n")

## -----------------------------------------------------------
## 2. Placebo 1: Post-1990 dams should show no effect
## -----------------------------------------------------------
cat("\n=== Placebo 1: Post-1990 dams ===\n")

dams[, post1990 := as.integer(year_built >= 1990)]
post90 <- dams[!is.na(state_abbr), .(
  n_post1990    = as.double(sum(post1990, na.rm = TRUE)),
  post1990_share = as.double(sum(post1990, na.rm = TRUE)) / .N
), by = state_abbr]

panel <- merge(panel, post90, by = "state_abbr", all.x = TRUE)
panel[is.na(post1990_share), post1990_share := 0]

m_placebo1 <- feols(flood_declared ~ post1990_share + log_n_dams | year,
                    data = panel, cluster = ~state_abbr)
cat("Post-1990 share → floods:\n")
summary(m_placebo1)

## -----------------------------------------------------------
## 3. Placebo 2: Non-flood FEMA disasters
## -----------------------------------------------------------
cat("\n=== Placebo 2: Non-flood disasters ===\n")

# Fetch non-flood declarations
nonflood_types <- c("Severe Storm(s)", "Hurricane", "Tornado", "Fire",
                    "Earthquake", "Severe Ice Storm")

nonflood_file <- file.path(data_dir, "fema_nonflood_declarations.csv")

if (!file.exists(nonflood_file)) {
  cat("  Fetching non-flood declarations...\n")
  all_nf <- list()

  for (itype in c("Tornado", "Earthquake", "Fire")) {
    resp <- GET(
      "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries",
      query = list(
        `$filter` = paste0("incidentType eq '", itype, "'"),
        `$top` = 10000,
        `$select` = "disasterNumber,state,declarationDate,incidentType,fipsStateCode"
      ),
      timeout(60)
    )
    if (resp$status_code == 200) {
      txt <- content(resp, "text")
      if (!grepl("<html", txt)) {
        dat <- fromJSON(txt)$DisasterDeclarationsSummaries
        if (!is.null(dat) && nrow(dat) > 0)
          all_nf[[length(all_nf) + 1]] <- as.data.table(dat)
      }
    }
    Sys.sleep(0.5)
  }

  if (length(all_nf) > 0) {
    nonflood_df <- rbindlist(all_nf, fill = TRUE)
    fwrite(nonflood_df, nonflood_file)
    cat("  Non-flood declarations:", nrow(nonflood_df), "\n")
  }
} else {
  nonflood_df <- fread(nonflood_file)
  cat("  Non-flood declarations loaded:", nrow(nonflood_df), "\n")
}

if (exists("nonflood_df") && nrow(nonflood_df) > 0) {
  nonflood_df[, decl_year := as.integer(substr(declarationDate, 1, 4))]

  nf_sy <- nonflood_df[decl_year >= 2000 & decl_year <= 2024, .(
    n_nonflood = as.double(.N)
  ), by = .(state_abbr = state, year = decl_year)]

  panel <- merge(panel, nf_sy, by = c("state_abbr", "year"), all.x = TRUE)
  panel[is.na(n_nonflood), n_nonflood := 0]
  panel[, nonflood_declared := as.integer(n_nonflood > 0)]

  m_placebo2 <- feols(nonflood_declared ~ pre1970_share + log_n_dams | year,
                      data = panel, cluster = ~state_abbr)
  cat("Pre-1970 share → non-flood disasters:\n")
  summary(m_placebo2)
} else {
  cat("  Skipping placebo 2 (no data).\n")
}

## -----------------------------------------------------------
## 4. Robustness: Different dam age cutoffs (1960, 1980)
## -----------------------------------------------------------
cat("\n=== Robustness: Alternative cutoffs ===\n")

for (cutoff in c(1960, 1980)) {
  dams[, temp_pre := as.integer(year_built < cutoff)]
  cut_st <- dams[!is.na(state_abbr), .(
    cut_share = as.double(sum(temp_pre, na.rm = TRUE)) / .N
  ), by = state_abbr]

  panel_cut <- merge(panel[, .(state_abbr, year, flood_declared, log_n_dams)],
                     cut_st, by = "state_abbr", all.x = TRUE)
  panel_cut[is.na(cut_share), cut_share := 0]

  m_cut <- feols(flood_declared ~ cut_share + log_n_dams | year,
                 data = panel_cut, cluster = ~state_abbr)
  cat("Cutoff", cutoff, ":", round(coef(m_cut)["cut_share"], 4),
      "(SE:", round(se(m_cut)["cut_share"], 4), ")\n")
}
dams[, temp_pre := NULL]

## -----------------------------------------------------------
## 5. Robustness: Control for state population / area
## -----------------------------------------------------------
cat("\n=== Robustness: Log dam count controls ===\n")

m_controls <- feols(flood_declared ~ pre1970_share + log_n_dams + log_storage | year,
                    data = panel, cluster = ~state_abbr)
summary(m_controls)

## -----------------------------------------------------------
## 6. Robustness: Precipitation interaction (continuous)
## -----------------------------------------------------------
cat("\n=== Robustness: Continuous precipitation interaction ===\n")

# Only states where precipitation INCREASED
panel[, precip_increased := as.integer(precip_ratio > 1)]

m_increase <- feols(flood_declared ~ pre1970_share * precip_increased + log_n_dams | year,
                    data = panel[!is.na(precip_increased)], cluster = ~state_abbr)
summary(m_increase)

## -----------------------------------------------------------
## 7. Save robustness results
## -----------------------------------------------------------
cat("\n=== Saving robustness results ===\n")

rob <- list(
  placebo_post1990 = m_placebo1,
  controls = m_controls,
  precip_interaction = m_increase
)
if (exists("m_placebo2")) rob$placebo_nonflood <- m_placebo2

saveRDS(rob, file.path(data_dir, "robustness_results.rds"))

cat("Robustness checks complete.\n")
