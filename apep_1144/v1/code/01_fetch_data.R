# ─── Fetch QWI employment data from Azure and merge with patent panel ────────
source("code/00_packages.R")
source(file.path(Sys.getenv("HOME"), "auto-policy-evals/scripts/lib/azure_data.R"))

# ─── 1. Connect to Azure QWI ────────────────────────────────────────────────
cat("Connecting to Azure QWI...\n")
con <- apep_azure_connect()

# State FIPS to abbreviation mapping
fips_map <- fread(text = "
fips,state
01,AL
02,AK
04,AZ
05,AR
06,CA
08,CO
09,CT
10,DE
11,DC
12,FL
13,GA
15,HI
16,ID
17,IL
18,IN
19,IA
20,KS
21,KY
22,LA
23,ME
24,MD
25,MA
26,MI
27,MN
28,MS
29,MO
30,MT
31,NE
32,NV
33,NH
34,NJ
35,NM
36,NY
37,NC
38,ND
39,OH
40,OK
41,OR
42,PA
44,RI
45,SC
46,SD
47,TN
48,TX
49,UT
50,VT
51,VA
53,WA
54,WV
55,WI
56,WY
")
fips_map[, fips := as.integer(fips)]

# ─── 2. Fetch all-sector employment by state × quarter ──────────────────────
cat("Fetching state × quarter employment (all sectors)...\n")

# QWI: geography is county FIPS, year/quarter are separate columns
# sex=0 means all, education='E0' means all, industry='00' means all sectors
qwi_all <- DBI::dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    SUM(Emp) AS Emp,
    SUM(HirN) AS HirN,
    SUM(EarnS * Emp) / NULLIF(SUM(CASE WHEN EarnS IS NOT NULL THEN Emp ELSE NULL END), 0) AS EarnS
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE industry = '00'
    AND sex = 0 AND education = 'E0'
    AND ownercode = 'A05'
    AND year BETWEEN 2004 AND 2014
  GROUP BY 1, 2, 3
")
qwi_all <- as.data.table(qwi_all)
cat(sprintf("  Rows: %d\n", nrow(qwi_all)))
cat(sprintf("  Non-NA Emp: %d\n", sum(!is.na(qwi_all$Emp))))

# ─── 3. Aggregate to state × year ───────────────────────────────────────────
cat("Aggregating to state × year...\n")
qwi_annual <- qwi_all[, .(
  Emp     = mean(Emp, na.rm = TRUE),    # mean across 4 quarters
  HirN    = sum(HirN, na.rm = TRUE),    # sum across 4 quarters
  EarnS   = mean(EarnS, na.rm = TRUE)   # mean across 4 quarters
), by = .(state_fips, year)]

# Merge state abbreviations
qwi_annual <- merge(qwi_annual, fips_map, by.x = "state_fips", by.y = "fips")
cat(sprintf("  State-year obs: %d\n", nrow(qwi_annual)))
cat(sprintf("  States: %d\n", uniqueN(qwi_annual$state)))

# ─── 4. Fetch sector-level employment (for mechanism splits) ────────────────
cat("Fetching sector-level employment...\n")
qwi_sector <- DBI::dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry,
    SUM(Emp) AS Emp,
    SUM(HirN) AS HirN
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE sex = 0 AND education = 'E0'
    AND ownercode = 'A05'
    AND industry IN ('31-33', '51', '54', '44-45', '72', '81')
    AND year BETWEEN 2004 AND 2014
  GROUP BY 1, 2, 3, 4
")
qwi_sector <- as.data.table(qwi_sector)
cat(sprintf("  Sector rows: %d\n", nrow(qwi_sector)))

# Aggregate across quarters (4 per year)
qwi_sector_annual <- qwi_sector[, .(
  Emp  = mean(Emp, na.rm = TRUE),
  HirN = sum(HirN, na.rm = TRUE)
), by = .(state_fips, year, industry)]

# Create exposed vs local-service aggregates
exposed <- c("31-33", "51", "54")
local_svc <- c("44-45", "72", "81")

sector_wide <- qwi_sector_annual[, .(
  Emp_exposed   = sum(Emp[industry %in% exposed], na.rm = TRUE),
  Emp_local_svc = sum(Emp[industry %in% local_svc], na.rm = TRUE),
  HirN_exposed  = sum(HirN[industry %in% exposed], na.rm = TRUE),
  HirN_local_svc = sum(HirN[industry %in% local_svc], na.rm = TRUE)
), by = .(state_fips, year)]

sector_wide <- merge(sector_wide, fips_map, by.x = "state_fips", by.y = "fips")

# ─── 5. Read patent panel and merge ─────────────────────────────────────────
cat("Merging with patent panel...\n")
patent <- fread("data/patent_panel.csv")

# Create outcome at t+1: for each patent-year t, match employment at t+1
panel <- merge(patent, qwi_annual[, .(state, year, Emp, HirN, EarnS)],
               by.x = c("state", "year"), by.y = c("state", "year"), all.x = TRUE)

# Rename current-year outcomes
setnames(panel, c("Emp", "HirN", "EarnS"), c("Emp_t", "HirN_t", "EarnS_t"))

# Merge t+1 outcomes
qwi_t1 <- qwi_annual[, .(state, year_t = year - 1L, Emp_t1 = Emp, HirN_t1 = HirN, EarnS_t1 = EarnS)]
panel <- merge(panel, qwi_t1, by.x = c("state", "year"), by.y = c("state", "year_t"), all.x = TRUE)

# Also merge t-1 outcomes (for placebo pre-trend)
qwi_tm1 <- qwi_annual[, .(state, year_tm1 = year + 1L, Emp_tm1 = Emp)]
panel <- merge(panel, qwi_tm1, by.x = c("state", "year"), by.y = c("state", "year_tm1"), all.x = TRUE)

# Merge sector splits (t+1)
sector_t1 <- sector_wide[, .(state, year_t = year - 1L,
                              Emp_exposed_t1 = Emp_exposed, Emp_local_svc_t1 = Emp_local_svc,
                              HirN_exposed_t1 = HirN_exposed, HirN_local_svc_t1 = HirN_local_svc)]
panel <- merge(panel, sector_t1, by.x = c("state", "year"), by.y = c("state", "year_t"), all.x = TRUE)

# Log transforms
panel[, log_grants := log(total_grants)]
panel[, log_Emp_t1 := log(Emp_t1)]
panel[, log_HirN_t1 := log(HirN_t1)]
panel[, log_EarnS_t1 := log(EarnS_t1)]
panel[, log_Emp_exposed_t1 := log(Emp_exposed_t1)]
panel[, log_Emp_local_svc_t1 := log(Emp_local_svc_t1)]
panel[, log_Emp_tm1 := log(Emp_tm1)]

cat(sprintf("\nFinal merged panel: %d obs, %d states, years %d-%d\n",
            nrow(panel), uniqueN(panel$state), min(panel$year), max(panel$year)))
cat(sprintf("  Non-missing Emp_t1: %d\n", sum(!is.na(panel$Emp_t1))))
cat(sprintf("  Non-missing log_Emp_t1: %d\n", sum(!is.na(panel$log_Emp_t1))))

fwrite(panel, "data/analysis_panel.csv")
cat("Saved data/analysis_panel.csv\n")

DBI::dbDisconnect(con, shutdown = TRUE)
