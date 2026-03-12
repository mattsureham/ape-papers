## 02_clean_data.R — Clean and merge all data sources
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: Metro-only control group, entropy balancing weights, spillover donut

source("00_packages.R")

cat("=== Loading raw data ===\n")

# --- Vera ---
vera <- fread(file.path(DATA_DIR, "vera_incarceration_trends.csv"))
vera[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
cat("Vera raw:", nrow(vera), "rows\n")

vera_annual <- vera[quarter == 4 | is.na(quarter), .(
  total_jail_pop       = total_jail_pop[1],
  total_jail_pretrial  = total_jail_pretrial[1],
  total_jail_sentenced = total_jail_sentenced[1],
  black_jail_pop       = black_jail_pop[1],
  white_jail_pop       = white_jail_pop[1],
  latinx_jail_pop      = latinx_jail_pop[1],
  aapi_jail_pop        = aapi_jail_pop[1],
  native_jail_pop      = native_jail_pop[1],
  total_pop            = total_pop[1],
  total_pop_15to64     = total_pop_15to64[1],
  black_pop_15to64     = black_pop_15to64[1],
  white_pop_15to64     = white_pop_15to64[1],
  total_jail_pop_rate  = total_jail_pop_rate[1],
  black_jail_pop_rate  = black_jail_pop_rate[1],
  white_jail_pop_rate  = white_jail_pop_rate[1],
  total_jail_adm       = total_jail_adm[1],
  urbanicity           = urbanicity[1],
  region               = region[1],
  county_name          = county_name[1],
  state_abbr           = state_abbr[1]
), by = .(fips, year)]

vera_fallback <- vera[, .(
  total_jail_pop       = last(na.omit(total_jail_pop)),
  total_jail_pretrial  = last(na.omit(total_jail_pretrial)),
  total_jail_sentenced = last(na.omit(total_jail_sentenced)),
  black_jail_pop       = last(na.omit(black_jail_pop)),
  white_jail_pop       = last(na.omit(white_jail_pop)),
  latinx_jail_pop      = last(na.omit(latinx_jail_pop)),
  aapi_jail_pop        = last(na.omit(aapi_jail_pop)),
  native_jail_pop      = last(na.omit(native_jail_pop)),
  total_pop            = last(na.omit(total_pop)),
  total_pop_15to64     = last(na.omit(total_pop_15to64)),
  black_pop_15to64     = last(na.omit(black_pop_15to64)),
  white_pop_15to64     = last(na.omit(white_pop_15to64)),
  total_jail_pop_rate  = last(na.omit(total_jail_pop_rate)),
  black_jail_pop_rate  = last(na.omit(black_jail_pop_rate)),
  white_jail_pop_rate  = last(na.omit(white_jail_pop_rate)),
  total_jail_adm       = last(na.omit(total_jail_adm)),
  urbanicity           = last(na.omit(urbanicity)),
  region               = last(na.omit(region)),
  county_name          = last(na.omit(county_name)),
  state_abbr           = last(na.omit(state_abbr))
), by = .(fips, year)]

vera_annual <- vera_annual[!is.na(total_jail_pop)]
vera_fb_needed <- vera_fallback[!paste(fips, year) %in% paste(vera_annual$fips, vera_annual$year)]
vera_fb_needed <- vera_fb_needed[!is.na(total_jail_pop)]
vera_annual <- rbind(vera_annual, vera_fb_needed)
vera_annual <- vera_annual[year >= 2005 & year <= 2023]
cat("Vera annual panel:", nrow(vera_annual), "county-years\n")

vera_annual[, `:=`(
  jail_rate = fifelse(
    !is.na(total_jail_pop_rate), total_jail_pop_rate,
    fifelse(total_pop_15to64 > 0, total_jail_pop / total_pop_15to64 * 100000, NA_real_)
  ),
  black_jail_rate = fifelse(
    !is.na(black_jail_pop_rate), black_jail_pop_rate,
    fifelse(black_pop_15to64 > 0, black_jail_pop / black_pop_15to64 * 100000, NA_real_)
  ),
  white_jail_rate = fifelse(
    !is.na(white_jail_pop_rate), white_jail_pop_rate,
    fifelse(white_pop_15to64 > 0, white_jail_pop / white_pop_15to64 * 100000, NA_real_)
  ),
  pretrial_share = fifelse(total_jail_pop > 0, total_jail_pretrial / total_jail_pop, NA_real_),
  state_fips = substr(fips, 1, 2)
)]

# --- County Health Rankings (Homicide data) ---
cat("\n=== Processing CHR homicide data ===\n")
chr_files <- list.files(DATA_DIR, pattern = "chr_\\d{4}\\.csv", full.names = TRUE)
cat("CHR files found:", length(chr_files), "\n")

chr_list <- list()
for (f in chr_files) {
  yr <- as.integer(str_extract(basename(f), "\\d{4}"))
  tryCatch({
    raw <- fread(f, header = TRUE, skip = 1, fill = TRUE)
    if (ncol(raw) < 100) {
      cat(sprintf("  CHR %d: too few columns (%d), skipping\n", yr, ncol(raw)))
      next
    }
    header <- fread(f, nrows = 1, header = FALSE)
    cnames <- as.character(header[1, ])
    hom_idx <- grep("Homicides raw value", cnames, ignore.case = TRUE)
    hom_num_idx <- grep("Homicides numerator", cnames, ignore.case = TRUE)
    hom_den_idx <- grep("Homicides denominator", cnames, ignore.case = TRUE)
    fips_idx <- grep("fipscode|5.digit FIPS", cnames, ignore.case = TRUE)
    if (length(fips_idx) == 0) fips_idx <- 3

    if (length(hom_idx) > 0 && length(fips_idx) > 0) {
      df <- data.frame(
        chr_year = yr,
        fips = as.character(raw[[fips_idx[1]]]),
        homicide_rate = suppressWarnings(as.numeric(raw[[hom_idx[1]]])),
        stringsAsFactors = FALSE
      )
      if (length(hom_num_idx) > 0) {
        df$homicide_numerator <- suppressWarnings(as.numeric(raw[[hom_num_idx[1]]]))
      }
      if (length(hom_den_idx) > 0) {
        df$homicide_denominator <- suppressWarnings(as.numeric(raw[[hom_den_idx[1]]]))
      }
      hom_black_idx <- grep("Homicides.*Black", cnames)
      hom_white_idx <- grep("Homicides.*White", cnames)
      if (length(hom_black_idx) > 0) {
        df$homicide_rate_black <- suppressWarnings(as.numeric(raw[[hom_black_idx[1]]]))
      }
      if (length(hom_white_idx) > 0) {
        df$homicide_rate_white <- suppressWarnings(as.numeric(raw[[hom_white_idx[1]]]))
      }
      df$fips <- str_pad(df$fips, width = 5, pad = "0")
      df <- df[nchar(df$fips) == 5 & !is.na(df$homicide_rate) & df$fips != "00000", ]
      chr_list[[as.character(yr)]] <- df
      cat(sprintf("  CHR %d: %d counties with homicide data\n", yr, nrow(df)))
    }
  }, error = function(e) {
    cat(sprintf("  CHR %d: ERROR - %s\n", yr, e$message))
  })
}
chr_panel <- bind_rows(chr_list)
cat("CHR homicide panel:", nrow(chr_panel), "county-years\n")

# --- CDC WONDER homicide data (extended panel) ---
cat("\n=== Processing CDC WONDER homicide data ===\n")
wonder_file <- file.path(DATA_DIR, "cdc_wonder_homicide.csv")
has_wonder <- FALSE
if (file.exists(wonder_file) && file.size(wonder_file) > 100) {
  wonder_raw <- tryCatch(fread(wonder_file), error = function(e) NULL)
  if (!is.null(wonder_raw) && nrow(wonder_raw) > 0) {
    has_wonder <- TRUE
    cat("CDC WONDER data loaded:", nrow(wonder_raw), "rows\n")
  }
}
if (!has_wonder) {
  cat("CDC WONDER data not available; using CHR homicide data only.\n")
}

# --- ACS Demographics ---
cat("\n=== Processing ACS demographics ===\n")
acs <- fread(file.path(DATA_DIR, "acs_county_demographics.csv"))
acs[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
cat("ACS panel:", nrow(acs), "county-years\n")

# --- FRED Unemployment ---
cat("\n=== Processing FRED unemployment ===\n")
fred <- fread(file.path(DATA_DIR, "fred_state_unemployment.csv"))
fred[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]

# --- Treatment indicator ---
cat("\n=== Merging treatment indicator ===\n")
treatment <- fread(file.path(DATA_DIR, "progressive_da_treatment.csv"))
treatment[, fips := str_pad(as.character(fips), width = 5, pad = "0")]

# --- MERGE ALL ---
cat("\n=== Building analysis panel ===\n")
panel <- vera_annual
panel <- merge(panel, treatment[, .(fips, treatment_year, da_name)],
               by = "fips", all.x = TRUE)
panel[is.na(treatment_year), treatment_year := 0]
panel[, treated := fifelse(treatment_year > 0 & year >= treatment_year, 1L, 0L)]
panel[, ever_treated := fifelse(treatment_year > 0, 1L, 0L)]
panel <- merge(panel, acs, by = c("fips", "year"), all.x = TRUE)
panel <- merge(panel, fred[, .(state_fips, year, unemp_rate)],
               by = c("state_fips", "year"), all.x = TRUE)

chr_dt <- as.data.table(chr_panel)
panel <- merge(panel, chr_dt, by.x = c("fips", "year"),
               by.y = c("fips", "chr_year"), all.x = TRUE)

panel[, `:=`(
  poverty_rate = fifelse(total_pop_acs > 0, poverty_pop / total_pop_acs * 100, NA_real_),
  black_share = fifelse(total_pop_acs > 0, black_pop / total_pop_acs * 100, NA_real_),
  log_pop = log(total_pop + 1),
  log_jail_pop = log(total_jail_pop + 1),
  log_income = log(pmax(median_hh_income, 1)),
  bw_jail_ratio = fifelse(white_jail_rate > 0, black_jail_rate / white_jail_rate, NA_real_)
)]

cat("\n=== Panel summary ===\n")
cat("Total county-years:", nrow(panel), "\n")
cat("Unique counties:", length(unique(panel$fips)), "\n")
cat("Year range:", range(panel$year), "\n")
cat("Treated county-years:", sum(panel$treated), "\n")
cat("Ever-treated counties:", sum(panel$ever_treated & !duplicated(panel$fips)), "\n")
cat("Never-treated counties:", sum(!panel$ever_treated & !duplicated(panel$fips)), "\n")

fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

# ======================================================================
# NEW v2: Metro-only control group
# ======================================================================
cat("\n=== Creating metro-only control group ===\n")

# Use Vera urbanicity field + population threshold
# "urban" and "suburban" in Vera correspond to metro areas
# Also require population > 100K for comparability

# Check MSA file
msa_file <- file.path(DATA_DIR, "county_msa.csv")
if (file.exists(msa_file)) {
  msa <- fread(msa_file)
  msa[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
  panel <- merge(panel, msa[, .(fips, cbsa_code, metro_micro)], by = "fips", all.x = TRUE)
  panel[, is_metro := fifelse(grepl("Metropolitan", metro_micro, ignore.case = TRUE), 1L, 0L)]
  cat("MSA classification merged\n")
} else {
  # Fallback: use Vera urbanicity + population
  panel[, is_metro := fifelse(
    urbanicity %in% c("urban", "suburban") | total_pop > 100000, 1L, 0L
  )]
  cat("Using Vera urbanicity + population threshold for metro classification\n")
}

# Metro-only panel: keep all treated + metro controls
panel[, metro_sample := fifelse(ever_treated == 1 | is_metro == 1, 1L, 0L)]
metro_panel <- panel[metro_sample == 1]
cat("Metro-only panel:", nrow(metro_panel), "county-years\n")
cat("  Metro control counties:", sum(metro_panel$ever_treated == 0 & !duplicated(metro_panel$fips)), "\n")
cat("  Treated counties:", sum(metro_panel$ever_treated == 1 & !duplicated(metro_panel$fips)), "\n")

fwrite(metro_panel, file.path(DATA_DIR, "metro_panel.csv"))

# ======================================================================
# NEW v2: Entropy balancing weights
# ======================================================================
cat("\n=== Computing entropy balancing weights ===\n")

# Use pre-treatment (2010-2014) averages for balancing
pre_means <- panel[year >= 2010 & year <= 2014, .(
  mean_pop = mean(total_pop, na.rm = TRUE),
  mean_black_share = mean(black_share, na.rm = TRUE),
  mean_poverty = mean(poverty_rate, na.rm = TRUE),
  mean_jail_rate = mean(jail_rate, na.rm = TRUE),
  mean_unemp = mean(unemp_rate, na.rm = TRUE)
), by = .(fips, ever_treated)]

pre_means <- pre_means[complete.cases(pre_means)]

tryCatch({
  # Entropy balance: weight controls to match treated moments
  treat_idx <- pre_means$ever_treated == 1
  X_covs <- as.matrix(pre_means[, .(mean_pop, mean_black_share, mean_poverty,
                                      mean_jail_rate, mean_unemp)])

  eb_out <- ebalance(
    Treatment = as.numeric(treat_idx),
    X = X_covs
  )

  # Assign weights
  ebal_weights <- data.table(
    fips = pre_means$fips,
    ever_treated = pre_means$ever_treated,
    ebal_weight = NA_real_
  )
  ebal_weights[ever_treated == 1, ebal_weight := 1]
  ebal_weights[ever_treated == 0, ebal_weight := eb_out$w]

  # Check balance
  cat("Entropy balancing weights computed\n")
  cat("  Treated units:", sum(treat_idx), "\n")
  cat("  Control units:", sum(!treat_idx), "\n")
  cat("  Max control weight:", round(max(eb_out$w), 3), "\n")
  cat("  Mean control weight:", round(mean(eb_out$w), 3), "\n")

  # Merge weights to panel
  panel <- merge(panel, ebal_weights[, .(fips, ebal_weight)],
                 by = "fips", all.x = TRUE)
  panel[is.na(ebal_weight), ebal_weight := 0]

  fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
  cat("Panel updated with entropy balancing weights\n")

  # Balance check table
  cat("\nBalance check (pre-treatment means):\n")
  cat(sprintf("%-20s %10s %10s %10s\n", "Variable", "Treated", "Control(raw)", "Control(EB)"))

  for (v in c("mean_pop", "mean_black_share", "mean_poverty", "mean_jail_rate", "mean_unemp")) {
    t_mean <- mean(pre_means[treat_idx, get(v)], na.rm = TRUE)
    c_mean <- mean(pre_means[!treat_idx, get(v)], na.rm = TRUE)
    c_mean_eb <- weighted.mean(pre_means[!treat_idx, get(v)],
                                w = eb_out$w, na.rm = TRUE)
    cat(sprintf("%-20s %10.1f %10.1f %10.1f\n", v, t_mean, c_mean, c_mean_eb))
  }

}, error = function(e) {
  cat("Entropy balancing failed:", e$message, "\n")
  cat("Proceeding without EB weights.\n")
  panel[, ebal_weight := 1]
  fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
})

# ======================================================================
# NEW v2: County adjacency for spillover donut
# ======================================================================
cat("\n=== Identifying adjacent counties for spillover donut ===\n")

adj_file <- file.path(DATA_DIR, "county_adjacency.csv")
if (file.exists(adj_file)) {
  adj <- fread(adj_file)
  adj[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
  adj[, neighbor_fips := str_pad(as.character(neighbor_fips), width = 5, pad = "0")]

  # Identify counties adjacent to ANY treated county
  treated_fips <- treatment$fips
  adjacent_to_treated <- unique(adj[fips %in% treated_fips, neighbor_fips])
  # Remove treated counties themselves
  adjacent_to_treated <- setdiff(adjacent_to_treated, treated_fips)

  panel[, adjacent_to_treated := fifelse(fips %in% adjacent_to_treated, 1L, 0L)]
  panel[, donut_sample := fifelse(ever_treated == 1 | adjacent_to_treated == 0, 1L, 0L)]

  cat("Counties adjacent to treated:", length(adjacent_to_treated), "\n")
  cat("Donut sample counties:", sum(panel$donut_sample == 1 & !duplicated(panel$fips)), "\n")

  fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
} else {
  cat("Adjacency file not available; donut analysis will be skipped.\n")
  panel[, adjacent_to_treated := 0L]
  panel[, donut_sample := 1L]
  fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
}

# ======================================================================
# Race-stratified panel for DDD
# ======================================================================
cat("\n=== Creating race-stratified panel for DDD ===\n")

race_panel <- panel[, .(
  fips, year, treatment_year, treated, ever_treated, state_fips,
  county_name, state_abbr, urbanicity, region,
  total_pop, total_pop_15to64,
  black_jail_pop, white_jail_pop,
  black_pop_15to64, white_pop_15to64,
  black_jail_rate, white_jail_rate,
  homicide_rate_black, homicide_rate_white,
  total_jail_pop, jail_rate,
  poverty_rate, black_share, log_pop, unemp_rate,
  is_metro, metro_sample, ebal_weight, donut_sample
)]

black_rows <- race_panel[, .(
  fips, year, treatment_year, treated, ever_treated, state_fips,
  county_name, state_abbr, urbanicity, region,
  race = "Black",
  jail_pop = black_jail_pop,
  pop_15to64 = black_pop_15to64,
  jail_rate_race = black_jail_rate,
  homicide_rate_race = homicide_rate_black,
  total_jail_pop, jail_rate,
  poverty_rate, black_share, log_pop, unemp_rate,
  is_metro, metro_sample, ebal_weight, donut_sample
)]

white_rows <- race_panel[, .(
  fips, year, treatment_year, treated, ever_treated, state_fips,
  county_name, state_abbr, urbanicity, region,
  race = "White",
  jail_pop = white_jail_pop,
  pop_15to64 = white_pop_15to64,
  jail_rate_race = white_jail_rate,
  homicide_rate_race = homicide_rate_white,
  total_jail_pop, jail_rate,
  poverty_rate, black_share, log_pop, unemp_rate,
  is_metro, metro_sample, ebal_weight, donut_sample
)]

race_long <- rbind(black_rows, white_rows)
race_long[, is_black := fifelse(race == "Black", 1L, 0L)]

cat("Race-stratified panel:", nrow(race_long), "county-year-race observations\n")
fwrite(race_long, file.path(DATA_DIR, "race_panel.csv"))

cat("\n=== DATA CLEANING COMPLETE ===\n")
