# 02_clean_data.R — Construct analysis dataset
# apep_0620: Second-generation refugee dispersal outcomes in Denmark

source("00_packages.R")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Treatment variable: immigrant share from FOLK1C (2008Q1)
# ─────────────────────────────────────────────────────────────────────────────
cat("1. Constructing treatment variable...\n")
folk <- readRDS("../data/folk1c_all.rds")
names(folk) <- c("muni", "ancestry", "time", "count")

# 2008Q1 baseline
folk_2008 <- folk %>%
  filter(time == "2008Q1") %>%
  select(muni, ancestry, count) %>%
  pivot_wider(names_from = ancestry, values_from = count, values_fill = 0)

names(folk_2008) <- c("muni", "total_pop", "danish_pop", "immigrant_pop", "descendant_pop")

# Treatment: immigrant share of total population in 2008
folk_2008 <- folk_2008 %>%
  mutate(
    imm_share_2008 = immigrant_pop / total_pop,
    desc_share_2008 = descendant_pop / total_pop,
    nw_share_2008 = (immigrant_pop + descendant_pop) / total_pop
  )

cat(sprintf("  %d municipalities with 2008 population data\n", nrow(folk_2008)))
cat(sprintf("  Mean immigrant share: %.3f (SD: %.3f)\n",
  mean(folk_2008$imm_share_2008), sd(folk_2008$imm_share_2008)))
cat(sprintf("  Range: %.3f to %.3f\n",
  min(folk_2008$imm_share_2008), max(folk_2008$imm_share_2008)))

# ─────────────────────────────────────────────────────────────────────────────
# 2. Outcome: descendant employment rate (RAS200)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n2. Constructing employment outcomes...\n")
ras_desc <- readRDS("../data/ras_nw_descendants.rds")
names(ras_desc) <- c("muni", "ancestry", "age", "sex", "measure", "year", "emp_rate")
# StatBank returns INDHOLD as character; convert to numeric
ras_desc$emp_rate <- as.numeric(gsub(",", ".", ras_desc$emp_rate))

# Aggregate across age groups (weighted average not possible; use pooled)
# Note: employment rates are already percentages
emp_panel <- ras_desc %>%
  group_by(muni, year) %>%
  summarise(
    emp_rate_desc = mean(emp_rate, na.rm = TRUE),
    n_age_groups = sum(!is.na(emp_rate)),
    .groups = "drop"
  )

cat(sprintf("  Municipality-year panel: %d observations\n", nrow(emp_panel)))
cat(sprintf("  %d municipalities, %d years\n",
  n_distinct(emp_panel$muni), n_distinct(emp_panel$year)))

# Latest year cross-section
emp_2022 <- emp_panel %>% filter(year == 2022)
cat(sprintf("  2022 cross-section: %d municipalities\n", nrow(emp_2022)))
cat(sprintf("  Mean descendant employment rate: %.1f%% (SD: %.1f%%)\n",
  mean(emp_2022$emp_rate_desc, na.rm = TRUE),
  sd(emp_2022$emp_rate_desc, na.rm = TRUE)))

# ─────────────────────────────────────────────────────────────────────────────
# 3. Outcome: descendant education (HFUDD11)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n3. Constructing education outcomes...\n")
hfudd <- readRDS("../data/hfudd_descendants.rds")
names(hfudd) <- c("muni", "ancestry", "age", "edu_level", "sex", "year", "count")

# Compute education shares by municipality and year
edu_panel <- hfudd %>%
  group_by(muni, year, edu_level) %>%
  summarise(count = sum(count, na.rm = TRUE), .groups = "drop") %>%
  group_by(muni, year) %>%
  mutate(
    total = sum(count[edu_level == "Total"]),
    share = ifelse(total > 0, count / total, NA_real_)
  ) %>%
  ungroup()

# Key education outcomes:
# H10 = Primary only (low education)
# H60 + H70 + H80 = Bachelor + Master + PhD (tertiary)
edu_wide <- edu_panel %>%
  filter(edu_level %in% c("Total", "H10 Primary education",
    "H60 Short-cycle higher education", "H70 Bachelor programmes",
    "H80 Master and PhD programmes")) %>%
  select(muni, year, edu_level, share) %>%
  pivot_wider(names_from = edu_level, values_from = share)

# Simplify names
edu_names <- names(edu_wide)
names(edu_wide) <- c("muni", "year",
  edu_names[3:length(edu_names)] %>%
    str_replace_all("H10.*", "share_primary") %>%
    str_replace_all("H60.*", "share_short_higher") %>%
    str_replace_all("H70.*", "share_bachelor") %>%
    str_replace_all("H80.*", "share_master_phd") %>%
    str_replace_all("Total", "share_total"))

# Create tertiary share
if ("share_short_higher" %in% names(edu_wide) &
    "share_bachelor" %in% names(edu_wide) &
    "share_master_phd" %in% names(edu_wide)) {
  edu_wide <- edu_wide %>%
    mutate(share_tertiary = rowSums(
      select(., share_short_higher, share_bachelor, share_master_phd),
      na.rm = TRUE
    ))
} else {
  # Fallback: compute manually from raw counts
  edu_tertiary <- edu_panel %>%
    filter(grepl("H[678]0", edu_level) | edu_level == "Total") %>%
    group_by(muni, year) %>%
    summarise(
      tertiary_count = sum(count[edu_level != "Total"], na.rm = TRUE),
      total_count = sum(count[edu_level == "Total"], na.rm = TRUE),
      share_tertiary = ifelse(total_count > 0, tertiary_count / total_count, NA),
      .groups = "drop"
    )
  edu_wide <- edu_wide %>%
    left_join(edu_tertiary %>% select(muni, year, share_tertiary), by = c("muni", "year"))
}

# Latest year education
edu_2023 <- edu_wide %>% filter(year == 2023)
cat(sprintf("  2023 cross-section: %d municipalities\n", nrow(edu_2023)))
if ("share_primary" %in% names(edu_2023)) {
  cat(sprintf("  Mean primary-only share: %.3f\n", mean(edu_2023$share_primary, na.rm = TRUE)))
}
cat(sprintf("  Mean tertiary share: %.3f\n", mean(edu_2023$share_tertiary, na.rm = TRUE)))

# ─────────────────────────────────────────────────────────────────────────────
# 4. Controls: total population and employment
# ─────────────────────────────────────────────────────────────────────────────
cat("\n4. Constructing controls...\n")

# Total population (FOLK1A)
folk1a <- readRDS("../data/folk1a_total.rds")
names(folk1a) <- c("muni", "sex", "age", "civil", "time", "total_pop_folk1a")
pop_2008 <- folk1a %>%
  filter(time == "2008Q1") %>%
  select(muni, total_pop_folk1a)

# Total employment rate
ras_total <- readRDS("../data/ras_total.rds")
names(ras_total) <- c("muni", "ancestry", "age", "sex", "measure", "year", "total_emp_rate")
ras_total$total_emp_rate <- as.numeric(gsub(",", ".", ras_total$total_emp_rate))
emp_total_2008 <- ras_total %>%
  filter(year == 2008) %>%
  select(muni, total_emp_rate)

# Danish origin employment (benchmark)
ras_dk <- readRDS("../data/ras_danish_origin.rds")
names(ras_dk) <- c("muni", "ancestry", "age", "sex", "measure", "year", "dk_emp_rate")
ras_dk$dk_emp_rate <- as.numeric(gsub(",", ".", ras_dk$dk_emp_rate))
emp_dk_2022 <- ras_dk %>%
  group_by(muni) %>%
  summarise(dk_emp_rate = mean(dk_emp_rate, na.rm = TRUE), .groups = "drop")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Merge into analysis dataset
# ─────────────────────────────────────────────────────────────────────────────
cat("\n5. Merging analysis dataset...\n")

# Cross-sectional dataset (latest outcomes)
analysis <- folk_2008 %>%
  select(muni, total_pop, immigrant_pop, descendant_pop, imm_share_2008) %>%
  left_join(emp_2022 %>% select(muni, emp_rate_desc), by = "muni") %>%
  left_join(edu_2023 %>% select(muni, starts_with("share_")), by = "muni") %>%
  left_join(pop_2008 %>% select(muni, total_pop_folk1a), by = "muni") %>%
  left_join(emp_total_2008, by = "muni") %>%
  left_join(emp_dk_2022, by = "muni") %>%
  mutate(
    log_pop = log(total_pop),
    emp_gap = dk_emp_rate - emp_rate_desc  # employment gap vs Danish origin
  )

# Add region classification (from municipality code)
# Danish regions: Hovedstaden (1xx), Sjælland (2xx-3xx), Syddanmark (4xx),
# Midtjylland (6xx-7xx), Nordjylland (8xx)
analysis <- analysis %>%
  mutate(
    muni_code = as.numeric(gsub("[^0-9]", "", muni)),
    region = case_when(
      muni_code >= 100 & muni_code < 200 ~ "Hovedstaden",
      muni_code >= 200 & muni_code < 400 ~ "Sjælland",
      muni_code >= 400 & muni_code < 600 ~ "Syddanmark",
      muni_code >= 600 & muni_code < 800 ~ "Midtjylland",
      muni_code >= 800 ~ "Nordjylland",
      TRUE ~ "Unknown"
    )
  )

# Drop municipalities with too few descendants (< 20 total)
analysis <- analysis %>% filter(descendant_pop >= 20)
cat(sprintf("  %d municipalities with ≥20 descendants\n", nrow(analysis)))

# Panel dataset for employment (over time)
emp_panel_merged <- emp_panel %>%
  left_join(folk_2008 %>% select(muni, imm_share_2008, total_pop, immigrant_pop, descendant_pop),
    by = "muni") %>%
  filter(!is.na(imm_share_2008)) %>%
  mutate(muni_code = as.numeric(gsub("[^0-9]", "", muni)))

cat(sprintf("  Panel: %d muni-year observations\n", nrow(emp_panel_merged)))

# ─────────────────────────────────────────────────────────────────────────────
# 6. Historical balance check dataset (BEF3 overlapping municipalities)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n6. Constructing historical balance dataset...\n")
bef3_imm <- readRDS("../data/bef3_immigrants.rds")
bef3_dk <- readRDS("../data/bef3_danish.rds")
bef3_desc <- readRDS("../data/bef3_descendants.rds")

names(bef3_imm) <- c("muni", "ancestry", "year", "imm_count")
names(bef3_dk) <- c("muni", "ancestry", "year", "dk_count")
names(bef3_desc) <- c("muni", "ancestry", "year", "desc_count")

historical <- bef3_imm %>%
  select(muni, year, imm_count) %>%
  left_join(bef3_dk %>% select(muni, year, dk_count), by = c("muni", "year")) %>%
  left_join(bef3_desc %>% select(muni, year, desc_count), by = c("muni", "year")) %>%
  mutate(
    total_approx = imm_count + dk_count + replace_na(desc_count, 0),
    imm_share = imm_count / total_approx
  )

# Merge with 2008 treatment for pre-trend analysis
hist_merged <- historical %>%
  left_join(folk_2008 %>% select(muni, imm_share_2008), by = "muni") %>%
  filter(!is.na(imm_share_2008))

cat(sprintf("  %d municipality-year historical observations\n", nrow(hist_merged)))

# ─────────────────────────────────────────────────────────────────────────────
# Save all constructed datasets
# ─────────────────────────────────────────────────────────────────────────────
saveRDS(analysis, "../data/analysis_cross_section.rds")
saveRDS(emp_panel_merged, "../data/analysis_panel.rds")
saveRDS(hist_merged, "../data/analysis_historical.rds")

cat("\n=== Data construction complete ===\n")
cat(sprintf("Cross-section: %d municipalities\n", nrow(analysis)))
cat(sprintf("Panel: %d municipality-years\n", nrow(emp_panel_merged)))
cat(sprintf("Historical: %d municipality-years\n", nrow(hist_merged)))

# Summary statistics for verification
cat("\n--- Summary Statistics ---\n")
cat("Treatment (imm_share_2008):\n")
print(summary(analysis$imm_share_2008))
cat("\nOutcome: Employment rate (descendants, 2022):\n")
print(summary(analysis$emp_rate_desc))
cat("\nOutcome: Tertiary education share (descendants, 2023):\n")
print(summary(analysis$share_tertiary))
cat("\nOutcome: Employment gap vs Danish origin:\n")
print(summary(analysis$emp_gap))
