## =============================================================================
## 01_fetch_data.R — Fetch QWI data from Azure for SNAP drug felon ban states
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("=== Fetching QWI data from Azure ===\n")

## Connect to Azure
con <- apep_azure_connect()

## -----------------------------------------------------------------------------
## Treatment assignment: 18 states that modified the drug felon ban 2015-2019
## Source: NCSL, state legislative records
## -----------------------------------------------------------------------------
treatment <- data.table(
  state_fips = c("01","02","04","05","10","13","17","18","21","22",
                 "26","28","32","38","46","48","51","54"),
  state_abbr = c("AL","AK","AZ","AR","DE","GA","IL","IN","KY","LA",
                 "MI","MS","NV","ND","SD","TX","VA","WV"),
  treat_year = c(2015, 2016, 2015, 2017, 2016, 2016, 2018, 2017,
                 2017, 2018, 2015, 2019, 2017, 2017, 2017, 2016,
                 2018, 2016),
  treat_quarter = c(3, 1, 3, 1, 1, 3, 1, 3, 3, 3, 1, 1, 3, 1, 3, 1, 3, 1),
  ban_type = c("partial","full","partial","full","full","partial",
               "full","partial","partial","full","full","partial",
               "full","full","full","partial","partial","full")
)

## Compute treatment_qtr as year*10 + quarter for sorting
treatment[, treat_yq := treat_year * 10 + treat_quarter]

## Control states: pre-2010 opt-out (always allowed drug felons on SNAP)
## These states opted out early enough that they serve as never-treated
control_states <- data.table(
  state_fips = c("06","08","09","11","12","15","19","20","23","24",
                 "25","27","29","30","33","34","35","36","37","39",
                 "40","41","42","44","45","47","50","53","55","56"),
  state_abbr = c("CA","CO","CT","DC","FL","HI","IA","KS","ME","MD",
                 "MA","MN","MO","MT","NH","NJ","NM","NY","NC","OH",
                 "OK","OR","PA","RI","SC","TN","VT","WA","WI","WY")
)
control_states[, treat_year := 0L]
control_states[, treat_yq := 0L]

## All states of interest
all_states <- c(treatment$state_fips, control_states$state_fips)
cat(sprintf("Treatment states: %d, Control states: %d\n",
            nrow(treatment), nrow(control_states)))

## -----------------------------------------------------------------------------
## Query QWI se/ns (sex × education, NAICS sector) from Azure
## Focus on key reentry industries
## -----------------------------------------------------------------------------

## Build state file list for Azure query (files are named by lowercase abbreviation)
all_abbrs <- tolower(c(treatment$state_abbr, control_states$state_abbr))
state_files <- paste0("'az://derived/qwi/se/ns/", all_abbrs, ".parquet'")
file_list <- paste(state_files, collapse = ", ")

query <- sprintf("
  SELECT geography, year, quarter, sex, education, industry,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, EarnS, EarnBeg,
         sEmp, sHirA, sSep, sEarnS
  FROM read_parquet([%s])
  WHERE year BETWEEN 2010 AND 2022
    AND industry IN ('23','44-45','56','62','72')
    AND sex = '0'
    AND education IN ('E1','E2','E3','E4')
", file_list)

cat("Running DuckDB query on Azure QWI...\n")
df_raw <- DBI::dbGetQuery(con, query)
df_raw <- as.data.table(df_raw)

cat(sprintf("Fetched %s rows\n", format(nrow(df_raw), big.mark = ",")))

## Validate
stopifnot("No QWI data fetched" = nrow(df_raw) > 0)
stopifnot("Missing Emp column" = "Emp" %in% names(df_raw))
stopifnot("Need > 100K rows" = nrow(df_raw) > 100000)

## Extract state FIPS from geography (first 2 chars of county FIPS)
df_raw[, state_fips := substr(geography, 1, 2)]

cat(sprintf("\nStates in data: %d\n", length(unique(df_raw$state_fips))))
cat(sprintf("Education groups: %s\n", paste(unique(df_raw$education), collapse = ", ")))
cat(sprintf("Industries: %s\n", paste(unique(df_raw$industry), collapse = ", ")))
cat(sprintf("Year range: %d-%d\n", min(df_raw$year), max(df_raw$year)))

## Save
fwrite(df_raw, "../data/qwi_raw.csv")
fwrite(treatment, "../data/treatment_states.csv")
fwrite(control_states, "../data/control_states.csv")

cat(sprintf("\nSaved: qwi_raw.csv (%s rows)\n", format(nrow(df_raw), big.mark = ",")))

DBI::dbDisconnect(con)
