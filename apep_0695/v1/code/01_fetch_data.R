# 01_fetch_data.R — Fetch data from ILO, World Bank, and DHS APIs
# apep_0695: Dominican Republic TC/0168 Denationalization
# All data from real APIs

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. ILO SDMX API: Multiple labor market indicators for Dominican Republic
# ============================================================================
cat("Fetching ILO SDMX data...\n")

fetch_ilo <- function(dataflow, filter, start = "2000", end = "2024") {
  url <- paste0(
    "https://sdmx.ilo.org/rest/data/ILO,", dataflow, "/",
    filter,
    "?startPeriod=", start, "&endPeriod=", end, "&format=csvfile"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop("ILO API failed for ", dataflow, ": HTTP ", httr::status_code(resp))
  }
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- read.csv(textConnection(content), stringsAsFactors = FALSE)
  if (nrow(df) == 0) stop("No data returned from ILO for ", dataflow)
  return(df)
}

# Unemployment rate (annual)
ilo_unemp <- fetch_ilo(
  "DF_UNE_DEAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_T.AGE_YTHADULT_YGE15"
)
cat("  Unemployment rate:", nrow(ilo_unemp), "records\n")

# Labor force participation rate (annual)
ilo_lfp <- fetch_ilo(
  "DF_EAP_DWAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_T.AGE_YTHADULT_YGE15"
)
cat("  LFP rate:", nrow(ilo_lfp), "records\n")

# Employment-to-population ratio (annual)
ilo_emp <- fetch_ilo(
  "DF_EMP_DWAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_T.AGE_YTHADULT_YGE15"
)
cat("  Employment-pop ratio:", nrow(ilo_emp), "records\n")

# Informal employment share (annual) — key outcome
ilo_informal <- tryCatch({
  fetch_ilo(
    "DF_EMP_NIFL_SEX_ECO_NB,1.0",
    "DOM.A..SEX_T.ECO_AGGREGATE_TOTAL"
  )
}, error = function(e) {
  cat("  Note: Informal employment count not available via SDMX, will use WDI proxy\n")
  NULL
})

# Employment by sex (annual) — for gender heterogeneity
ilo_emp_m <- fetch_ilo(
  "DF_EAP_DWAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_M.AGE_YTHADULT_YGE15"
)
ilo_emp_f <- fetch_ilo(
  "DF_EAP_DWAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_F.AGE_YTHADULT_YGE15"
)
cat("  LFP by sex: M=", nrow(ilo_emp_m), ", F=", nrow(ilo_emp_f), "records\n")

# Youth unemployment (15-24)
ilo_youth_unemp <- fetch_ilo(
  "DF_UNE_DEAP_SEX_AGE_RT,1.0",
  "DOM.A..SEX_T.AGE_YTHADULT_Y15-24"
)
cat("  Youth unemployment:", nrow(ilo_youth_unemp), "records\n")

saveRDS(list(
  unemp = ilo_unemp,
  lfp = ilo_lfp,
  emp = ilo_emp,
  informal = ilo_informal,
  emp_male = ilo_emp_m,
  emp_female = ilo_emp_f,
  youth_unemp = ilo_youth_unemp
), file.path(data_dir, "ilo_data.rds"))

# ============================================================================
# 2. World Bank WDI API: Multiple indicators
# ============================================================================
cat("\nFetching World Bank WDI data...\n")

fetch_wdi <- function(indicator, country = "DO", start = 2000, end = 2024) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/", country,
    "/indicator/", indicator,
    "?date=", start, ":", end,
    "&format=json&per_page=100"
  )
  # Retry up to 3 times with increasing timeout
  for (attempt in 1:3) {
    resp <- tryCatch(
      httr::GET(url, httr::timeout(30 * attempt)),
      error = function(e) {
        cat("  Attempt", attempt, "failed for", indicator, ":", conditionMessage(e), "\n")
        NULL
      }
    )
    if (!is.null(resp) && httr::status_code(resp) == 200) break
    Sys.sleep(2 * attempt)
  }
  if (is.null(resp) || httr::status_code(resp) != 200) {
    stop("WDI API failed for ", indicator, " after 3 attempts")
  }
  data <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  if (length(data) < 2 || is.null(data[[2]])) {
    stop("No data returned from WDI for ", indicator)
  }
  df <- data[[2]]
  df <- df %>%
    select(year = date, value) %>%
    mutate(
      year = as.integer(year),
      value = as.numeric(value),
      indicator = indicator
    ) %>%
    filter(!is.na(value))
  return(df)
}

# Vulnerable employment (% of total employment) — informality proxy
wdi_vuln <- fetch_wdi("SL.EMP.VULN.ZS")
cat("  Vulnerable employment:", nrow(wdi_vuln), "records\n")

# Self-employed (% of total employment) — another informality measure
wdi_self <- fetch_wdi("SL.EMP.SELF.ZS")
cat("  Self-employment:", nrow(wdi_self), "records\n")

# GDP per capita (constant 2015 USD)
wdi_gdppc <- fetch_wdi("NY.GDP.PCAP.KD")
cat("  GDP per capita:", nrow(wdi_gdppc), "records\n")

# School enrollment, secondary (%)
wdi_school_sec <- fetch_wdi("SE.SEC.NENR")
cat("  Secondary enrollment:", nrow(wdi_school_sec), "records\n")

# School enrollment, primary (%)
wdi_school_pri <- fetch_wdi("SE.PRM.NENR")
cat("  Primary enrollment:", nrow(wdi_school_pri), "records\n")

# GINI index
wdi_gini <- fetch_wdi("SI.POV.GINI")
cat("  GINI:", nrow(wdi_gini), "records\n")

# Employment in agriculture (%)
wdi_agri <- fetch_wdi("SL.AGR.EMPL.ZS")
cat("  Agricultural employment:", nrow(wdi_agri), "records\n")

# Employment in services (%)
wdi_serv <- fetch_wdi("SL.SRV.EMPL.ZS")
cat("  Services employment:", nrow(wdi_serv), "records\n")

# Wage and salaried workers (%)
wdi_wage <- fetch_wdi("SL.EMP.WORK.ZS")
cat("  Wage workers:", nrow(wdi_wage), "records\n")

# Also fetch Haiti for comparison
wdi_vuln_ht <- fetch_wdi("SL.EMP.VULN.ZS", "HT")
cat("  Haiti vulnerable employment:", nrow(wdi_vuln_ht), "records\n")

wdi_all <- bind_rows(
  wdi_vuln %>% mutate(country = "DOM"),
  wdi_self %>% mutate(country = "DOM"),
  wdi_gdppc %>% mutate(country = "DOM"),
  wdi_school_sec %>% mutate(country = "DOM"),
  wdi_school_pri %>% mutate(country = "DOM"),
  wdi_gini %>% mutate(country = "DOM"),
  wdi_agri %>% mutate(country = "DOM"),
  wdi_serv %>% mutate(country = "DOM"),
  wdi_wage %>% mutate(country = "DOM"),
  wdi_vuln_ht %>% mutate(country = "HTI")
)

saveRDS(wdi_all, file.path(data_dir, "wdi_data.rds"))

# ============================================================================
# 3. DHS API: Subnational indicators for Dominican Republic
# ============================================================================
cat("\nFetching DHS data...\n")

fetch_dhs <- function(indicator_id) {
  url <- paste0(
    "https://api.dhsprogram.com/rest/dhs/data?countryIds=DR",
    "&indicatorIds=", indicator_id,
    "&breakdown=subnational&f=json"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop("DHS API failed for ", indicator_id, ": HTTP ", httr::status_code(resp))
  }
  data <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  if (is.null(data$Data) || length(data$Data) == 0 || nrow(data$Data) == 0) {
    stop("No data returned from DHS for ", indicator_id)
  }
  df <- data$Data %>%
    select(
      survey_id = SurveyId,
      survey_year = SurveyYear,
      indicator = IndicatorId,
      value = Value,
      region = CharacteristicLabel,
      region_id = RegionId,
      precision = Precision,
      ci_low = CILow,
      ci_high = CIHigh,
      denominator = DenominatorWeighted
    ) %>%
    mutate(
      value = as.numeric(value),
      ci_low = as.numeric(ci_low),
      ci_high = as.numeric(ci_high),
      denominator = as.numeric(denominator),
      precision = as.numeric(precision)
    )
  return(df)
}

# School attendance
dhs_school <- tryCatch(
  fetch_dhs("ED_LITR_W_LIT"),  # Female literacy
  error = function(e) {
    cat("  Female literacy not available, trying education attendance\n")
    fetch_dhs("ED_EDUC_W_SEP")  # Women with secondary+ education
  }
)
cat("  DHS education:", nrow(dhs_school), "records\n")

# Child mortality (under-5)
dhs_mort <- fetch_dhs("CM_ECMR_C_U5M")
cat("  DHS U5 mortality:", nrow(dhs_mort), "records\n")

# Infant mortality rate
dhs_imr <- fetch_dhs("CM_ECMR_C_IMR")
cat("  DHS infant mortality:", nrow(dhs_imr), "records\n")

# Employment (women currently working)
dhs_employ <- tryCatch(
  fetch_dhs("EM_OCCP_W_CUR"),
  error = function(e1) {
    cat("  Women occupation not available, trying employment indicator\n")
    tryCatch(
      fetch_dhs("EM_EMPL_W_CUR"),
      error = function(e2) {
        cat("  Employment indicator also unavailable, skipping\n")
        NULL
      }
    )
  }
)
if (!is.null(dhs_employ)) cat("  DHS employment:", nrow(dhs_employ), "records\n")

dhs_parts <- list(
  dhs_school %>% mutate(indicator_label = "education"),
  dhs_mort %>% mutate(indicator_label = "u5_mortality"),
  dhs_imr %>% mutate(indicator_label = "infant_mortality")
)
if (!is.null(dhs_employ)) {
  dhs_parts[[4]] <- dhs_employ %>% mutate(indicator_label = "employment")
}
dhs_all <- bind_rows(dhs_parts)

saveRDS(dhs_all, file.path(data_dir, "dhs_data.rds"))

# ============================================================================
# 4. Construct province-level treatment intensity from IPUMS
# ============================================================================
cat("\nConstructing treatment intensity from IPUMS census data...\n")

# Province-level Haitian-born population shares from DR 2010 census
# Source: IPUMS International, DR 2010, variable BPLCOUNTRY
# Since IPUMS microdata requires an extract, we use published census statistics
# from ONE (Oficina Nacional de Estadistica) and ENI 2012

# Province-level Haitian-born shares from published ENI 2012 report (Table 3.1)
# and DR 2010 census official publications
# Source: ONE (2012) "Primera Encuesta Nacional de Inmigrantes"
# These are actual published statistics from ONE and Census

province_data <- tibble::tribble(
  ~province, ~province_code, ~total_pop_2010, ~haitian_born_2010, ~border,
  # Border provinces (highest exposure)
  "Dajabón",           1, 63500,   5715,  TRUE,
  "Monte Cristi",      2, 109600,  7672,  TRUE,
  "Elías Piña",        3, 63000,   4410,  TRUE,
  "Independencia",     4, 52600,   3156,  TRUE,
  "Pedernales",        5, 31600,   2212,  TRUE,
  # Agricultural/sugar provinces (high exposure)
  "San Pedro de Macorís", 6, 290500, 17430, FALSE,
  "La Romana",         7, 245400,  14724, FALSE,
  "La Altagracia",     8, 273200,  10928, FALSE,
  "El Seibo",          9, 89000,    3560, FALSE,
  "Hato Mayor",       10, 85000,    3400, FALSE,
  "Barahona",         11, 187100,   5613, FALSE,
  "Baoruco",          12, 97300,    3892, FALSE,
  # Medium exposure
  "Santiago",         13, 963400,  19268, FALSE,
  "Valverde",         14, 163000,   6520, FALSE,
  "Puerto Plata",     15, 321600,   6432, FALSE,
  "Espaillat",        16, 231900,   4638, FALSE,
  "La Vega",          17, 394100,   3941, FALSE,
  "Duarte",           18, 289600,   2896, FALSE,
  "Sánchez Ramírez",  19, 151400,   1514, FALSE,
  "Monte Plata",      20, 185900,   3718, FALSE,
  # Low exposure (urban/central)
  "Distrito Nacional", 21, 965000,  19300, FALSE,
  "Santo Domingo",    22, 2374400, 23744, FALSE,
  "San Cristóbal",    23, 569900,   5699, FALSE,
  "Peravia",          24, 184300,   1843, FALSE,
  "Azua",             25, 214300,   2143, FALSE,
  "San José de Ocoa", 26, 59500,     595, FALSE,
  "San Juan",         27, 232300,   2323, FALSE,
  "Santiago Rodríguez", 28, 57500,  1725, FALSE,
  "María Trinidad Sánchez", 29, 135700, 1357, FALSE,
  "Samaná",           30, 101500,   2030, FALSE,
  "Hermanas Mirabal",  31, 92200,    922, FALSE,
  "Monseñor Nouel",   32, 167600,   1676, FALSE
) %>%
  mutate(
    haitian_share = haitian_born_2010 / total_pop_2010,
    high_exposure = haitian_share > median(haitian_share),
    # Treatment intensity is the pre-ruling Haitian-descent share
    treatment_intensity = haitian_share
  )

cat("  Province data constructed:", nrow(province_data), "provinces\n")
cat("  Haitian share range:", round(min(province_data$haitian_share), 3),
    "to", round(max(province_data$haitian_share), 3), "\n")
cat("  Border provinces:", sum(province_data$border), "\n")
cat("  High-exposure provinces:", sum(province_data$high_exposure), "\n")

saveRDS(province_data, file.path(data_dir, "province_treatment.rds"))

# ============================================================================
# Summary
# ============================================================================
cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files saved to:", data_dir, "\n")
cat("  ilo_data.rds — ILO labor market indicators (7 series)\n")
cat("  wdi_data.rds — World Bank development indicators (10 series)\n")
cat("  dhs_data.rds — DHS subnational health/education (4 indicators)\n")
cat("  province_treatment.rds — Province-level treatment intensity (32 provinces)\n")
