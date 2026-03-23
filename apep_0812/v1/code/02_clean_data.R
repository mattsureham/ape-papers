## 02_clean_data.R — Clean and merge all data sources
## apep_0812: Pump Prices and Le Pen

source("00_packages.R")
library(readxl)

data_dir <- "../data"

# ============================================================
# Helper: parse wide-format election file
# Each candidate occupies 6 columns: Sexe, Nom, Prénom, Voix, %Ins, %Exp
# Returns tibble with codgeo + candidate vote shares
# ============================================================
parse_election <- function(path, sheet = 1, skip = 0, year,
                           candidates, dept_col = 1, com_col = 3) {
  cat(sprintf("  Parsing %d from %s (sheet=%s, skip=%d)...\n",
              year, basename(path), sheet, skip))
  d <- read_excel(path, sheet = sheet, skip = skip, .name_repair = "unique_quiet")

  # Build commune code
  dept <- str_pad(as.character(d[[dept_col]]), 2, pad = "0")
  com <- str_pad(as.character(d[[com_col]]), 3, pad = "0")
  # Handle Corsica (dept 20 → 2A/2B)
  com_num <- suppressWarnings(as.numeric(com))
  dept <- ifelse(!is.na(com_num) & dept == "20" & com_num <= 360, "2A",
          ifelse(!is.na(com_num) & dept == "20" & com_num > 360, "2B", dept))
  codgeo <- paste0(dept, com)

  # Find Inscrits, Abstentions, Exprimés columns by name
  inscrits <- as.numeric(d[["Inscrits"]])
  abstentions <- as.numeric(d[["Abstentions"]])

  expr_col <- grep("^Exprim", names(d), value = TRUE)[1]
  exprimes <- as.numeric(d[[expr_col]])

  # Find each candidate's Voix column by searching Nom columns
  result <- tibble(codgeo = codgeo,
                   inscrits = inscrits,
                   exprimes = exprimes,
                   turnout = (inscrits - abstentions) / inscrits * 100)

  # Search ALL columns for each candidate name, then take Voix = col + 2
  for (cand_name in names(candidates)) {
    pattern <- candidates[[cand_name]]
    found <- FALSE
    for (nc in seq_along(names(d))) {
      vals <- as.character(d[[nc]])
      # Check if this column contains the candidate name (all rows same name = wide format)
      n_match <- sum(grepl(pattern, vals[1:min(50, length(vals))], ignore.case = TRUE),
                     na.rm = TRUE)
      if (n_match >= min(10, nrow(d) %/% 2)) {
        # This is the Nom column for this candidate
        # Voix is 2 columns after Nom
        voix <- as.numeric(d[[nc + 2]])
        result[[paste0(cand_name, "_pct")]] <- voix / exprimes * 100
        found <- TRUE
        cat(sprintf("    Found %s at col %d, mean=%.1f%%\n",
                    cand_name, nc, mean(voix/exprimes*100, na.rm=TRUE)))
        break
      }
    }
    if (!found) {
      cat(sprintf("    WARNING: %s not found!\n", cand_name))
      result[[paste0(cand_name, "_pct")]] <- NA_real_
    }
  }

  result <- result %>% filter(!is.na(codgeo), !is.na(exprimes), exprimes > 0)
  cat(sprintf("    %d communes parsed\n", nrow(result)))
  result
}

# ============================================================
# 1) PARSE ELECTION DATA
# ============================================================
cat("=== Parsing election data ===\n")

# 2012 (baseline, pre-treatment)
e12 <- parse_election(
  file.path(data_dir, "pres_2012_communes.xls"),
  sheet = "Tour 1", year = 2012,
  candidates = list(lepen = "LE PEN", hollande = "HOLLANDE",
                    melenchon = "LENCHON|MÉLENCHON"))

# 2017 (post-treatment period 1)
e17 <- parse_election(
  file.path(data_dir, "pres_2017_t1.xls"),
  sheet = 1, skip = 3, year = 2017,
  candidates = list(lepen = "LE PEN", macron = "MACRON",
                    melenchon = "LENCHON|MÉLENCHON"))

# 2022 (post-treatment period 2)
e22 <- parse_election(
  file.path(data_dir, "pres_2022_t1.xlsx"),
  sheet = 1, year = 2022,
  candidates = list(lepen = "LE PEN", macron = "MACRON",
                    melenchon = "LENCHON|MÉLENCHON"))

# 2007 (pre-trend)
e07 <- parse_election(
  file.path(data_dir, "pres_2007_communes.xls"),
  sheet = "Tour 1", year = 2007,
  candidates = list(lepen = "LE PEN"))

# Add year suffixes
names(e12)[names(e12) != "codgeo"] <- paste0(names(e12)[names(e12) != "codgeo"], "_12")
names(e17)[names(e17) != "codgeo"] <- paste0(names(e17)[names(e17) != "codgeo"], "_17")
names(e22)[names(e22) != "codgeo"] <- paste0(names(e22)[names(e22) != "codgeo"], "_22")
names(e07)[names(e07) != "codgeo"] <- paste0(names(e07)[names(e07) != "codgeo"], "_07")

# ============================================================
# 2) CENSUS — Car commuting share (P11 = pre-treatment)
# ============================================================
cat("\n=== Parsing census transport data ===\n")

census <- fread(file.path(data_dir, "census_raw", "base-cc-caract_emp-2022.CSV"),
                sep = ";", header = TRUE, encoding = "Latin-1")

transport <- census %>%
  as_tibble() %>%
  transmute(
    codgeo = as.character(CODGEO),
    actifs_11 = as.numeric(P11_ACTOCC15P),
    voiture_11 = as.numeric(P11_ACTOCC15P_VOITURE),
    commun_11 = as.numeric(P11_ACTOCC15P_COMMUN),
    marche_11 = as.numeric(P11_ACTOCC15P_MARCHE),
    pastrans_11 = as.numeric(P11_ACTOCC15P_PASTRANS)
  ) %>%
  mutate(
    car_share_11 = ifelse(actifs_11 > 0, voiture_11 / actifs_11 * 100, NA_real_),
    transit_share_11 = ifelse(actifs_11 > 0, commun_11 / actifs_11 * 100, NA_real_),
    wfh_share_11 = ifelse(actifs_11 > 0, pastrans_11 / actifs_11 * 100, NA_real_)
  )

cat(sprintf("  %d communes, car share mean=%.1f%%, sd=%.1f%%\n",
            nrow(transport),
            mean(transport$car_share_11, na.rm = TRUE),
            sd(transport$car_share_11, na.rm = TRUE)))

# ============================================================
# 3) FILOSOFI — Median income
# ============================================================
cat("\n=== Parsing Filosofi income data ===\n")
filo <- read_excel(file.path(data_dir, "filosofi_raw", "FILO2019_DISP_COM.xlsx"),
                   sheet = "ENSEMBLE", skip = 5)
income <- filo %>%
  transmute(codgeo = as.character(CODGEO),
            median_income = as.numeric(Q219)) %>%
  filter(!is.na(codgeo))
cat(sprintf("  %d communes, median income mean=%.0f EUR\n",
            nrow(income), mean(income$median_income, na.rm = TRUE)))

# ============================================================
# 4) POPULATION
# ============================================================
cat("\n=== Parsing population data ===\n")
pop_raw <- fread(file.path(data_dir, "pop_raw", "donnees_communes.csv"),
                 sep = ";", header = TRUE, encoding = "Latin-1")
population <- pop_raw %>%
  as_tibble() %>%
  transmute(
    codgeo = paste0(str_pad(as.character(CODDEP), 2, pad = "0"),
                    str_pad(as.character(CODCOM), 3, pad = "0")),
    pop = as.numeric(PMUN)
  ) %>%
  filter(!is.na(pop))
cat(sprintf("  %d communes, mean pop=%.0f\n", nrow(population), mean(population$pop)))

# ============================================================
# 5) MERGE
# ============================================================
cat("\n=== Merging ===\n")

df <- e12 %>%
  inner_join(e17, by = "codgeo") %>%
  inner_join(e22, by = "codgeo") %>%
  left_join(e07, by = "codgeo") %>%
  inner_join(transport, by = "codgeo") %>%
  left_join(income, by = "codgeo") %>%
  left_join(population, by = "codgeo")

cat(sprintf("  After merge: %d communes\n", nrow(df)))

# Construct analysis variables
df <- df %>%
  mutate(
    # First differences in RN vote share (main outcomes)
    delta_lepen_17_12 = lepen_pct_17 - lepen_pct_12,
    delta_lepen_22_12 = lepen_pct_22 - lepen_pct_12,
    # Pre-trend
    delta_lepen_12_07 = lepen_pct_12 - lepen_pct_07,
    # Placebo outcomes
    delta_turnout_17_12 = turnout_17 - turnout_12,
    delta_turnout_22_12 = turnout_22 - turnout_12,
    delta_melenchon_17_12 = melenchon_pct_17 - melenchon_pct_12,
    # Controls
    dept = substr(codgeo, 1, 2),
    log_pop = log(pmax(pop, 1, na.rm = TRUE)),
    car_share_std = (car_share_11 - mean(car_share_11, na.rm = TRUE)) /
                    sd(car_share_11, na.rm = TRUE),
    # Quartile treatment
    car_q = ntile(car_share_11, 4),
    ile_de_france = dept %in% c("75", "77", "78", "91", "92", "93", "94", "95")
  )

# Drop unusable communes
df_clean <- df %>%
  filter(
    !is.na(car_share_11),
    !is.na(lepen_pct_12),
    !is.na(lepen_pct_17),
    actifs_11 >= 10,
    inscrits_12 >= 50
  )

cat(sprintf("  After cleaning: %d communes\n", nrow(df_clean)))
cat(sprintf("  Car share 2011: mean=%.1f%%, sd=%.1f%%, range=[%.1f, %.1f]\n",
            mean(df_clean$car_share_11),
            sd(df_clean$car_share_11),
            min(df_clean$car_share_11),
            max(df_clean$car_share_11)))
cat(sprintf("  Delta LE PEN 2017-2012: mean=%.2f pp, sd=%.2f pp\n",
            mean(df_clean$delta_lepen_17_12, na.rm = TRUE),
            sd(df_clean$delta_lepen_17_12, na.rm = TRUE)))
cat(sprintf("  Delta LE PEN 2022-2012: mean=%.2f pp, sd=%.2f pp\n",
            mean(df_clean$delta_lepen_22_12, na.rm = TRUE),
            sd(df_clean$delta_lepen_22_12, na.rm = TRUE)))

# Save
saveRDS(df_clean, file.path(data_dir, "analysis_panel.rds"))
cat(sprintf("\nSaved analysis_panel.rds (%d communes)\n", nrow(df_clean)))
