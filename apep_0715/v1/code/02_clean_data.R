## 02_clean_data.R — Parse and construct analysis panel
## apep_0715: FOBT Stake Reduction

source("00_packages.R")
setwd(file.path(dirname(getwd())))

cat("=== Building analysis panel ===\n")

# ─────────────────────────────────────────────────────────────
# 1. Parse Sheet 1: GGY Overview by Sector
# ─────────────────────────────────────────────────────────────
s1 <- readxl::read_excel("data/industry_statistics.xlsx", sheet = "1", col_names = FALSE)

# Row 8 has headers, rows 9+ have data
# Columns: Period, Overall Total, % Change, Total excl National Lottery,
#           Arcades, Betting(non-remote), Bingo(non-remote), Casino(non-remote),
#           Betting(remote), Bingo(remote), Casino(remote), Lotteries(remote), National Lottery(non-remote)
ggy_raw <- s1[9:nrow(s1), ]
# Keep only rows with data (period in col 1)
ggy_raw <- ggy_raw[!is.na(ggy_raw[[1]]), ]

# Extract fiscal year from period string
extract_fy <- function(period_str) {
  period_str <- as.character(period_str)
  # Handle date serial numbers (Excel dates)
  if (grepl("^\\d{5}$", period_str)) {
    # This shouldn't happen for sheet 1 — periods are text
    return(NA_character_)
  }
  # Extract end year: "Apr 2008 - Mar 2009" -> 2009
  m <- regmatches(period_str, regexpr("\\d{4}$", period_str))
  if (length(m) == 1) return(m)
  # Handle "31/03/2022R" format
  m2 <- regmatches(period_str, regexpr("\\d{4}", period_str))
  if (length(m2) == 1) return(m2)
  return(NA_character_)
}

ggy_overview <- data.frame(
  period = as.character(ggy_raw[[1]]),
  total_ggy = as.numeric(ggy_raw[[2]]),
  arcades_nr = as.numeric(ggy_raw[[5]]),
  betting_nr = as.numeric(ggy_raw[[6]]),
  bingo_nr = as.numeric(ggy_raw[[7]]),
  casino_nr = as.numeric(ggy_raw[[8]]),
  betting_r = as.numeric(ggy_raw[[9]]),
  bingo_r = as.numeric(ggy_raw[[10]]),
  casino_r = as.numeric(ggy_raw[[11]]),
  stringsAsFactors = FALSE
)
ggy_overview$fy_end <- sapply(ggy_overview$period, extract_fy)
ggy_overview$fy_end <- as.integer(ggy_overview$fy_end)
ggy_overview <- ggy_overview[!is.na(ggy_overview$fy_end), ]

cat("GGY Overview: ", nrow(ggy_overview), "years,", min(ggy_overview$fy_end), "-", max(ggy_overview$fy_end), "\n")
cat("Sample:\n")
print(ggy_overview[1:3, c("fy_end", "total_ggy", "betting_nr", "betting_r")])

# ─────────────────────────────────────────────────────────────
# 2. Parse Sheet 3: Premises Count by Sector
# ─────────────────────────────────────────────────────────────
s3 <- readxl::read_excel("data/industry_statistics.xlsx", sheet = "3", col_names = FALSE)
# Row 9 has headers, rows 10+ have data
prem_raw <- s3[10:nrow(s3), ]
prem_raw <- prem_raw[!is.na(prem_raw[[1]]), ]

# Column 1 is Excel date serial or date string
# Columns: Date, Total, %Change, AGC, Betting, Bingo, Casino, FEC
premises <- data.frame(
  date_raw = as.character(prem_raw[[1]]),
  total_premises = as.numeric(prem_raw[[2]]),
  agc = as.numeric(prem_raw[[4]]),
  betting = as.numeric(prem_raw[[5]]),
  bingo = as.numeric(prem_raw[[6]]),
  casino = as.numeric(prem_raw[[7]]),
  fec = as.numeric(prem_raw[[8]]),
  stringsAsFactors = FALSE
)

# Convert Excel serial dates to years
premises$fy_end <- sapply(premises$date_raw, function(x) {
  if (grepl("^\\d{5}$", x)) {
    d <- as.Date(as.numeric(x), origin = "1899-12-30")
    return(lubridate::year(d))
  }
  m <- regmatches(x, regexpr("\\d{4}", x))
  if (length(m) == 1) return(as.integer(m))
  return(NA_integer_)
})
premises <- premises[!is.na(premises$fy_end), ]

cat("\nPremises: ", nrow(premises), "years,", min(premises$fy_end), "-", max(premises$fy_end), "\n")
cat("Betting premises over time:\n")
print(premises[, c("fy_end", "betting")])

# ─────────────────────────────────────────────────────────────
# 3. Parse Sheet 6d: Gaming Machines in Betting Premises
# ─────────────────────────────────────────────────────────────
s6d <- readxl::read_excel("data/industry_statistics.xlsx", sheet = "6d", col_names = FALSE)
machine_raw <- s6d[10:nrow(s6d), ]
machine_raw <- machine_raw[!is.na(machine_raw[[1]]), ]

machines_betting <- data.frame(
  period = as.character(machine_raw[[1]]),
  total_machines = as.numeric(machine_raw[[2]]),
  b2_machines = as.numeric(machine_raw[[4]]),
  b3_machines = as.numeric(machine_raw[[5]]),
  c_machines = as.numeric(machine_raw[[6]]),
  total_machine_ggy = as.numeric(machine_raw[[7]]),
  b2_ggy = as.numeric(machine_raw[[9]]),  # Check column alignment
  stringsAsFactors = FALSE
)
machines_betting$fy_end <- sapply(machines_betting$period, extract_fy)
machines_betting$fy_end <- as.integer(machines_betting$fy_end)
machines_betting <- machines_betting[!is.na(machines_betting$fy_end), ]

cat("\nMachines in betting:", nrow(machines_betting), "years\n")
print(machines_betting[, c("fy_end", "total_machines", "b2_machines", "total_machine_ggy")])

# ─────────────────────────────────────────────────────────────
# 4. Parse Sheet 6: Betting (non-remote) detailed
# ─────────────────────────────────────────────────────────────
s6 <- readxl::read_excel("data/industry_statistics.xlsx", sheet = "6", col_names = FALSE)
bet_raw <- s6[9:nrow(s6), ]
bet_raw <- bet_raw[!is.na(bet_raw[[1]]), ]

betting_detail <- data.frame(
  period = as.character(bet_raw[[1]]),
  total_turnover = as.numeric(bet_raw[[2]]),
  otc_turnover = as.numeric(bet_raw[[4]]),
  total_ggy = as.numeric(bet_raw[[8]]),
  otc_ggy = as.numeric(bet_raw[[10]]),
  stringsAsFactors = FALSE
)
betting_detail$fy_end <- sapply(betting_detail$period, extract_fy)
betting_detail$fy_end <- as.integer(betting_detail$fy_end)
betting_detail <- betting_detail[!is.na(betting_detail$fy_end), ]

# Machine GGY = total betting GGY - OTC GGY (approximately)
betting_detail$machine_ggy <- betting_detail$total_ggy - betting_detail$otc_ggy

cat("\nBetting detail:", nrow(betting_detail), "years\n")
cat("OTC vs Machine GGY:\n")
print(betting_detail[, c("fy_end", "total_ggy", "otc_ggy", "machine_ggy")])

# ─────────────────────────────────────────────────────────────
# 5. Parse Sheet 10b: Remote Betting GGY
# ─────────────────────────────────────────────────────────────
s10b <- readxl::read_excel("data/industry_statistics.xlsx", sheet = "10b", col_names = FALSE)
remote_raw <- s10b[9:nrow(s10b), ]
remote_raw <- remote_raw[!is.na(remote_raw[[1]]), ]

remote_betting <- data.frame(
  period = as.character(remote_raw[[1]]),
  total_turnover = as.numeric(remote_raw[[2]]),
  total_ggy = as.numeric(remote_raw[[7]]),
  stringsAsFactors = FALSE
)
remote_betting$fy_end <- sapply(remote_betting$period, extract_fy)
remote_betting$fy_end <- as.integer(remote_betting$fy_end)
remote_betting <- remote_betting[!is.na(remote_betting$fy_end), ]

cat("\nRemote betting:", nrow(remote_betting), "years\n")
print(remote_betting[, c("fy_end", "total_ggy")])

# ─────────────────────────────────────────────────────────────
# 6. Build sector × year panel
# ─────────────────────────────────────────────────────────────
# For the sector DiD, we need GGY by sector by year
# Sectors: betting_nr, casino_nr, bingo_nr, arcades_nr
panel_ggy <- ggy_overview %>%
  select(fy_end, arcades_nr, betting_nr, bingo_nr, casino_nr) %>%
  tidyr::pivot_longer(cols = c(arcades_nr, betting_nr, bingo_nr, casino_nr),
                      names_to = "sector", values_to = "ggy") %>%
  mutate(
    sector_clean = case_when(
      sector == "betting_nr" ~ "Betting",
      sector == "casino_nr" ~ "Casino",
      sector == "bingo_nr" ~ "Bingo",
      sector == "arcades_nr" ~ "Arcades"
    ),
    treated = as.integer(sector == "betting_nr"),
    post = as.integer(fy_end >= 2020),  # FY ending Mar 2020 = first treated year
    treat_post = treated * post
  )

cat("\nSector panel:", nrow(panel_ggy), "obs,",
    length(unique(panel_ggy$sector)), "sectors ×",
    length(unique(panel_ggy$fy_end)), "years\n")

# ─────────────────────────────────────────────────────────────
# 7. Build premises panel
# ─────────────────────────────────────────────────────────────
panel_premises <- premises %>%
  select(fy_end, agc, betting, bingo, casino, fec) %>%
  tidyr::pivot_longer(cols = c(agc, betting, bingo, casino, fec),
                      names_to = "sector", values_to = "premises_count") %>%
  mutate(
    sector_clean = case_when(
      sector == "betting" ~ "Betting",
      sector == "casino" ~ "Casino",
      sector == "bingo" ~ "Bingo",
      sector == "agc" ~ "AGC",
      sector == "fec" ~ "FEC"
    ),
    treated = as.integer(sector == "betting"),
    post = as.integer(fy_end >= 2020),
    treat_post = treated * post
  )

cat("Premises panel:", nrow(panel_premises), "obs\n")

# ─────────────────────────────────────────────────────────────
# 8. Parse premises register for geographic analysis
# ─────────────────────────────────────────────────────────────
premises_reg <- readr::read_csv("data/premises_register.csv", show_col_types = FALSE)
cat("\nPremises register:", nrow(premises_reg), "total premises\n")
cat("By activity type:\n")
print(table(premises_reg$`Premises Activity`))

# Betting shops by LA
betting_by_la <- premises_reg %>%
  filter(`Premises Activity` == "Betting Shop") %>%
  group_by(`Local Authority`) %>%
  summarise(n_betting = n(), .groups = "drop") %>%
  arrange(desc(n_betting))

cat("\nBetting shops by LA (top 10):\n")
print(head(betting_by_la, 10))
cat("\nBetting shops by LA: median =", median(betting_by_la$n_betting),
    ", mean =", round(mean(betting_by_la$n_betting), 1), "\n")
cat("Total LAs with betting shops:", nrow(betting_by_la), "\n")
cat("Total betting shops in register:", sum(betting_by_la$n_betting), "\n")

# ─────────────────────────────────────────────────────────────
# 9. Save cleaned data
# ─────────────────────────────────────────────────────────────
saveRDS(ggy_overview, "data/ggy_overview.rds")
saveRDS(premises, "data/premises_national.rds")
saveRDS(machines_betting, "data/machines_betting.rds")
saveRDS(betting_detail, "data/betting_detail.rds")
saveRDS(remote_betting, "data/remote_betting.rds")
saveRDS(panel_ggy, "data/panel_ggy.rds")
saveRDS(panel_premises, "data/panel_premises.rds")
saveRDS(betting_by_la, "data/betting_by_la.rds")

cat("\n=== All data cleaned and saved ===\n")
