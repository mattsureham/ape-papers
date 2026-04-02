## 02_clean_data.R — Clean and construct analysis variables

source("00_packages.R")

wb <- readRDS("../data/wb_panel.rds")
eres <- readRDS("../data/eresidency.rds")

# ── Country labels ────────────────────────────────────────────────────────────
country_labels <- c(
  EST = "Estonia", LVA = "Latvia", LTU = "Lithuania",
  FIN = "Finland", CZE = "Czech Republic", POL = "Poland",
  DNK = "Denmark", SWE = "Sweden", NOR = "Norway"
)
wb$country <- country_labels[wb$iso3]

# ── Treatment indicators ─────────────────────────────────────────────────────
wb$treated  <- as.integer(wb$iso3 == "EST")
wb$post     <- as.integer(wb$year >= 2015)  # e-Residency launched Dec 2014, first full year 2015
wb$treat_post <- wb$treated * wb$post

# Baltic control indicator
wb$baltic <- as.integer(wb$iso3 %in% c("EST", "LVA", "LTU"))

# ── Rename key variables ─────────────────────────────────────────────────────
wb <- wb %>%
  rename(
    biz_density  = IC.BUS.NDNS.ZS,
    biz_nreg     = IC.BUS.NREG,
    gdp_pc       = NY.GDP.PCAP.KD,
    trade_open   = NE.TRD.GNFS.ZS,
    internet     = IT.NET.USER.ZS,
    pop_working  = SP.POP.1564.TO
  )

# ── Log transforms ───────────────────────────────────────────────────────────
wb$ln_biz_density <- log(wb$biz_density + 0.01)
wb$ln_gdp_pc      <- log(wb$gdp_pc)
wb$ln_biz_nreg    <- log(wb$biz_nreg + 1)

# ── Filter to analysis sample ────────────────────────────────────────────────
# Keep 2006-2022 for consistent coverage of business density
panel <- wb %>%
  filter(year >= 2006, year <= 2022) %>%
  arrange(iso3, year)

# Check coverage
coverage <- panel %>%
  group_by(iso3) %>%
  summarise(
    n_years = n(),
    biz_dens_obs = sum(!is.na(biz_density)),
    first_year = min(year),
    last_year = max(year),
    .groups = "drop"
  )

cat("Panel coverage:\n")
print(as.data.frame(coverage))

# ── Baltic subset ────────────────────────────────────────────────────────────
baltic <- panel %>% filter(baltic == 1)
cat(sprintf("\nBaltic panel: %d obs (%d countries x %d years max)\n",
            nrow(baltic), n_distinct(baltic$iso3), n_distinct(baltic$year)))

# ── Merge e-Residency data with Estonia ──────────────────────────────────────
est_panel <- panel %>%
  filter(iso3 == "EST") %>%
  left_join(eres, by = "year")

# Compute e-Resident share of total new registrations
est_panel <- est_panel %>%
  mutate(
    e_firm_share = ifelse(!is.na(new_e_firms) & !is.na(biz_nreg) & biz_nreg > 0,
                          new_e_firms / biz_nreg, NA_real_)
  )

cat("\nEstonia: e-Resident firm share of new registrations:\n")
est_share <- est_panel %>%
  filter(!is.na(e_firm_share)) %>%
  select(year, biz_nreg, new_e_firms, e_firm_share)
print(as.data.frame(est_share))

# ── Save ──────────────────────────────────────────────────────────────────────
saveRDS(panel, "../data/panel_clean.rds")
saveRDS(baltic, "../data/baltic_clean.rds")
saveRDS(est_panel, "../data/estonia_decomp.rds")

cat("\nCleaned data saved.\n")
