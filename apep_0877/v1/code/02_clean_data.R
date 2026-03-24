## 02_clean_data.R — Construct analysis datasets
## apep_0877: Croatia 2013 Fiscalization

source("code/00_packages.R")

cat("=== Building analysis datasets ===\n")

# ---------------------------------------------------------------
# 1. Cross-country VAT panel (primary specification)
# ---------------------------------------------------------------
vat <- readRDS("data/vat_gdp.rds")
macro <- readRDS("data/macro_controls.rds")

panel_vat <- vat %>%
  left_join(macro, by = c("country", "year")) %>%
  mutate(
    croatia = as.integer(country == "HR"),
    post    = as.integer(year >= 2013),
    treat   = croatia * post,
    # Event time for event study
    event_time = year - 2013
  )

cat("Cross-country VAT panel:\n")
cat(sprintf("  %d country-years, %d countries, years %d-%d\n",
            nrow(panel_vat), n_distinct(panel_vat$country),
            min(panel_vat$year), max(panel_vat$year)))

# Pre-treatment means
pre_means <- panel_vat %>%
  filter(year < 2013) %>%
  group_by(country) %>%
  summarise(mean_vat = mean(vat_gdp, na.rm = TRUE), .groups = "drop")
cat("\nPre-treatment VAT/GDP means:\n")
print(pre_means)

saveRDS(panel_vat, "data/panel_vat.rds")

# ---------------------------------------------------------------
# 2. Sector-level GVA panel (within-Croatia + cross-country)
# ---------------------------------------------------------------
gva <- readRDS("data/gva_sector.rds")

# Map NACE sectors to fiscalization treatment cohorts
# Phase 1 (Jan 2013): I (accommodation + food/bev)
# Phase 2 (Apr 2013): G (wholesale, retail, motor vehicles)
# Phase 3 (Jul 2013): B-E (industry), F (construction), H (transport),
#                      J (information), M (professional), N (admin),
#                      P (education), Q (health), R (arts), S (other services)
# Never-treated: A (agriculture), K (finance), L (real estate),
#                O (public admin), T (household), U (extraterritorial)

# Use finest non-overlapping NACE codes (A*38-like)
# Strategy: pick leaf nodes — codes that don't have a more disaggregated child
all_nace <- sort(unique(gva$nace))
# Remove "TOTAL" and broad aggregates (single letter except standalone sections)
# Keep 2-3 digit codes, and single letters only when no finer breakdown exists
parent_prefixes <- c("TOTAL", "B-E", "G-I", "O-Q", "R-U", "M_N")

# Build leaf set: keep a code only if no other code starts with it as prefix
is_leaf <- function(code, all_codes) {
  if (code %in% parent_prefixes) return(FALSE)
  children <- all_codes[all_codes != code & startsWith(all_codes, code)]
  # Remove codes that are just the same with different separators
  length(children) == 0
}

leaf_codes <- all_nace[sapply(all_nace, is_leaf, all_codes = all_nace)]
# Also remove single-letter codes that have sub-codes
single_letters_with_children <- sapply(LETTERS, function(l) {
  has_child <- any(grepl(paste0("^", l, "[0-9]"), leaf_codes))
  if (has_child) l else NA
})
single_letters_with_children <- na.omit(single_letters_with_children)
leaf_codes <- leaf_codes[!(leaf_codes %in% single_letters_with_children)]
cat("Leaf NACE codes:", length(leaf_codes), "\n")

gva_sections <- gva %>%
  filter(nace %in% leaf_codes)

# Treatment cohort assignment
gva_sections <- gva_sections %>%
  mutate(
    # Extract NACE section letter
    section = gsub("^([A-Z]).*", "\\1", nace),
    phase = case_when(
      section == "I" ~ 1L,  # Accommodation + food/bev: Jan 2013
      section == "G" ~ 2L,  # Wholesale + retail: Apr 2013
      section %in% c("B", "C", "D", "E", "F", "H",
                      "J", "M", "N", "P", "Q", "R", "S") ~ 3L,  # Jul 2013
      section %in% c("A", "K", "L", "O", "T", "U") ~ 0L,  # Never-treated
      TRUE ~ NA_integer_
    ),
    treated = as.integer(phase > 0),
    # Treatment year (for CS-DiD): use Jan=2013 for all, distinguish via phase
    first_treat = case_when(
      phase == 1L ~ 2013,
      phase == 2L ~ 2013,  # Same year (quarterly would distinguish)
      phase == 3L ~ 2013,
      TRUE ~ 0  # Never-treated = 0 for did package
    ),
    croatia = as.integer(country == "HR"),
    post = as.integer(year >= 2013),
    # Sector-specific treatment (treated in Croatia post-2013)
    sector_treat = as.integer(treated == 1 & croatia == 1 & post == 1),
    # Log GVA
    log_gva = log(gva + 1)
  )

# Drop sectors with too many missing values
sector_coverage <- gva_sections %>%
  group_by(country, nace) %>%
  summarise(n_years = sum(!is.na(gva)), .groups = "drop")

gva_clean <- gva_sections %>%
  inner_join(
    sector_coverage %>% filter(n_years >= 10),
    by = c("country", "nace")
  )

cat("\nSector-level GVA panel:\n")
cat(sprintf("  %d obs, %d country-sector pairs, %d NACE codes\n",
            nrow(gva_clean), n_distinct(paste(gva_clean$country, gva_clean$nace)),
            n_distinct(gva_clean$nace)))

# Check treatment assignment
treat_summary <- gva_clean %>%
  filter(country == "HR") %>%
  distinct(nace, section, phase, treated) %>%
  arrange(phase, nace)
cat("\nCroatia sector treatment assignment:\n")
cat(sprintf("  Total: %d sectors (%d treated, %d never-treated)\n",
            nrow(treat_summary),
            sum(treat_summary$treated == 1),
            sum(treat_summary$treated == 0)))

saveRDS(gva_clean, "data/panel_gva.rds")

# ---------------------------------------------------------------
# 3. SBS turnover panel (at NACE 2-digit level)
# ---------------------------------------------------------------
sbs <- readRDS("data/sbs_turnover.rds")

# Map 2-digit NACE codes to phases
sbs_2digit <- sbs %>%
  filter(grepl("^[A-Z][0-9]{2}$", nace) |
         nace %in% c("I55", "I56", "G45", "G46", "G47")) %>%
  mutate(
    section = substr(nace, 1, 1),
    phase = case_when(
      nace %in% c("I55", "I56") ~ 1L,
      nace %in% c("G45", "G46", "G47") ~ 2L,
      section %in% c("B", "C", "D", "E", "F", "H",
                       "J", "M", "N", "P", "Q", "R", "S") ~ 3L,
      section %in% c("A", "K", "L", "O", "T", "U") ~ 0L,
      TRUE ~ NA_integer_
    ),
    treated = as.integer(phase > 0),
    croatia = as.integer(country == "HR"),
    post = as.integer(year >= 2013),
    sector_treat = as.integer(treated == 1 & croatia == 1 & post == 1),
    log_turnover = log(turnover + 1)
  ) %>%
  filter(!is.na(phase))

# Keep sectors with >=8 years of data
sbs_coverage <- sbs_2digit %>%
  group_by(country, nace) %>%
  summarise(n_years = sum(!is.na(turnover)), .groups = "drop")

sbs_clean <- sbs_2digit %>%
  inner_join(
    sbs_coverage %>% filter(n_years >= 8),
    by = c("country", "nace")
  )

cat("\nSBS 2-digit panel:\n")
cat(sprintf("  %d obs, %d country-sector pairs\n",
            nrow(sbs_clean), n_distinct(paste(sbs_clean$country, sbs_clean$nace))))

hr_sbs_summary <- sbs_clean %>%
  filter(country == "HR") %>%
  distinct(nace, phase, treated)
cat(sprintf("  Croatia: %d sectors (%d treated, %d never-treated)\n",
            nrow(hr_sbs_summary),
            sum(hr_sbs_summary$treated == 1),
            sum(hr_sbs_summary$treated == 0)))

saveRDS(sbs_clean, "data/panel_sbs.rds")

# ---------------------------------------------------------------
# 4. Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# VAT/GDP by country
cat("\nVAT/GDP by country (pre vs post 2013):\n")
panel_vat %>%
  group_by(country, post) %>%
  summarise(mean_vat = round(mean(vat_gdp, na.rm = TRUE), 2),
            sd_vat = round(sd(vat_gdp, na.rm = TRUE), 2),
            .groups = "drop") %>%
  mutate(period = ifelse(post == 1, "Post", "Pre")) %>%
  select(country, period, mean_vat, sd_vat) %>%
  print(n = 20)

# GVA by treatment phase in Croatia
cat("\nCroatia GVA by treatment phase (pre vs post):\n")
gva_clean %>%
  filter(country == "HR") %>%
  group_by(phase, post) %>%
  summarise(mean_gva = round(mean(gva, na.rm = TRUE), 1),
            n_sectors = n_distinct(nace),
            .groups = "drop") %>%
  mutate(period = ifelse(post == 1, "Post", "Pre"),
         phase_label = case_when(phase == 0 ~ "Never-treated",
                                  phase == 1 ~ "Phase 1 (Jan)",
                                  phase == 2 ~ "Phase 2 (Apr)",
                                  phase == 3 ~ "Phase 3 (Jul)")) %>%
  select(phase_label, period, mean_gva, n_sectors) %>%
  print(n = 10)

cat("\n=== Data cleaning complete ===\n")
