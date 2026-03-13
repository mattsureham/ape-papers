# 02_clean_data.R — Construct RDD analysis sample
# apep_0613: Female mayors and fiscal composition in Mexico

source("00_packages.R")

data_dir <- "../data"

# ─── 1. Load and clean election data ────────────────────────────────────────
cat("Loading election data...\n")
elec <- read.csv(file.path(data_dir, "aymu1989_incumbents.csv"),
                 stringsAsFactors = FALSE)
cat(sprintf("Raw election data: %d elections\n", nrow(elec)))

# Parse columns
elec <- elec %>%
  mutate(
    mg = suppressWarnings(as.numeric(mg)),
    dmujer = suppressWarnings(as.integer(dmujer)),
    inegi = suppressWarnings(as.integer(inegi))
  ) %>%
  filter(!is.na(mg), !is.na(dmujer), !is.na(inegi),
         dextra == 0, yr >= 2000) %>%
  mutate(
    id_entidad = sprintf("%02d", inegi %/% 1000),
    id_municipio = sprintf("%03d", inegi %% 1000)
  )

cat(sprintf("After filtering (2000+, regular, valid): %d elections\n", nrow(elec)))
cat(sprintf("  dmujer = 1 (female winners): %d\n", sum(elec$dmujer == 1)))
cat(sprintf("  dmujer = 0 (male winners): %d\n", sum(elec$dmujer == 0)))

# ─── 2. Classify runner-up gender from names ────────────────────────────────
# Broad heuristic for Spanish names
classify_gender <- function(full_name) {
  if (is.na(full_name) || trimws(full_name) == "") return(NA_character_)

  # Clean and extract first name
  name_clean <- toupper(trimws(full_name))
  name_clean <- iconv(name_clean, to = "ASCII//TRANSLIT")
  parts <- strsplit(name_clean, "\\s+")[[1]]
  first <- parts[1]

  # Definite female names
  fem <- c("MARIA", "ANA", "ROSA", "MARTHA", "PATRICIA", "CLAUDIA",
           "LETICIA", "GABRIELA", "ADRIANA", "ALEJANDRA", "SANDRA",
           "VERONICA", "MONICA", "SILVIA", "GUADALUPE", "MARGARITA",
           "ELIZABETH", "MARISOL", "DIANA", "LAURA", "ALICIA",
           "BEATRIZ", "CARMEN", "CRISTINA", "ELENA", "ESTELA",
           "GLORIA", "IRMA", "JULIA", "LOURDES", "LUCIA",
           "MAGDALENA", "NORMA", "OLGA", "PILAR", "RAQUEL",
           "SUSANA", "TERESA", "VIRGINIA", "YOLANDA", "ZOILA",
           "NANCY", "JESSICA", "BRENDA", "PAOLA", "DANIELA",
           "KARINA", "MARINA", "ARELY", "ESMERALDA", "FERNANDA",
           "GRISELDA", "HILDA", "INES", "IVONNE", "JOSEFINA",
           "LILIANA", "MINERVA", "NELLY", "OFELIA", "REBECA",
           "ROCIO", "SARA", "SONIA", "XIMENA", "EDITH", "MIRIAM",
           "SANDY", "MARITZA", "ARMINDA", "PAZ", "FLOR",
           "IRIS", "IVETTE", "KARLA", "ANDREA", "ANGELICA",
           "BERTHA", "CONSUELO", "DELIA", "DOLORES", "ERIKA",
           "ESPERANZA", "EUGENIA", "FABIOLA", "FRANCISCA", "GRACIELA",
           "JUANA", "LEONOR", "LUISA", "MANUELA", "MERCEDES",
           "NATALIA", "NORA", "LUZ", "SOL", "ITZEL", "CITLALI",
           "VIRIDIANA", "MARIBEL", "LORENA", "LIZBETH", "CECILIA",
           "CAROLINA", "ALMA", "BLANCA", "CLARA", "ELSA", "EMMA",
           "FATIMA", "GISELA", "HORTENSIA", "SOCORRO", "VALENTINA",
           "VANESSA", "MARIANA", "NORMA", "RUTH", "NAYELI",
           "ERENDIRA", "CITLALLI", "DULCE", "PERLA", "ARACELI",
           "AURORA", "CATALINA", "CELIA", "ELVIA", "EVA",
           "GEORGINA", "HERMELINDA", "IMELDA", "ISELA", "LIDIA",
           "MARCELA", "ROSARIO", "VERONICA", "XOCHITL", "YAZMIN",
           "ANTONIA", "BENITA", "PETRA", "VICENTA", "ISIDRA",
           "PAULA", "RAMONA", "RAFAELA", "TOMASA", "DOMINGA",
           "FELICITAS", "EUGENIA", "ENRIQUETA", "ERNESTINA",
           "CONCEPCION", "SOLEDAD", "AMPARO", "CONSUELO",
           "REMEDIOS", "MILAGROS", "ASUNCION", "ENCARNACION",
           "ASCENSION", "TRINIDAD")

  # Definite male names
  mal <- c("JOSE", "JUAN", "CARLOS", "MIGUEL", "FRANCISCO", "PEDRO",
           "LUIS", "JESUS", "ANTONIO", "MANUEL", "RAFAEL", "ROBERTO",
           "FERNANDO", "JORGE", "ALFREDO", "ARTURO", "CESAR", "DANIEL",
           "DAVID", "EDUARDO", "ENRIQUE", "ERNESTO", "GERARDO",
           "HECTOR", "HUGO", "IGNACIO", "JAVIER", "MARIO", "PABLO",
           "RAUL", "RICARDO", "SERGIO", "VICTOR", "ALBERTO",
           "ALEJANDRO", "ANDRES", "BENITO", "BERNARDO", "DOMINGO",
           "EDGAR", "FELIPE", "GUILLERMO", "GUSTAVO", "ISMAEL",
           "JAIME", "LEONEL", "LORENZO", "MARCO", "MARTIN",
           "NICOLAS", "OSCAR", "RAMON", "RENE", "RODRIGO",
           "ROLANDO", "RUBEN", "SALVADOR", "SANTIAGO", "SAUL",
           "TOMAS", "ABEL", "ADOLFO", "AGUSTIN", "ALDO", "ARMANDO",
           "EMILIO", "ESTEBAN", "FABIAN", "GABRIEL", "GILBERTO",
           "GONZALO", "IVAN", "JOEL", "JULIAN", "MARCELO",
           "MATEO", "MAURICIO", "MOISES", "NOE", "OCTAVIO",
           "ORLANDO", "PATRICIO", "PROSPERO", "ROGELIO", "TEODORO",
           "VALENTIN", "VICENTE", "ANTERO", "BALTAZAR", "CALIXTO",
           "CRISPIN", "DEMETRIO", "EFRAIN", "ELEAZAR", "ERASMO",
           "EZEQUIEL", "FIDEL", "GENARO", "HERIBERTO", "HIPOLITO",
           "ISIDRO", "JACINTO", "LAZARO", "LEOPOLDO", "MAXIMINO",
           "NORBERTO", "OLEGARIO", "PORFIRIO", "QUIRINO", "ROSENDO",
           "SILVERIO", "ULISES", "WENCESLAO", "ZENON", "ADAN",
           "ALAN", "CHRISTIAN", "DIEGO", "ERIK", "FREDDY",
           "GONZALEZ", "HERNAN", "IRVING", "LEONIDAS", "MISAEL",
           "NEHEMIAS", "OBED", "PASCUAL", "RIGOBERTO", "SERAFIN",
           "URIEL", "WILBERT", "YAHIR", "ABRAHAM", "AMADOR",
           "CELSO", "DAGOBERTO", "ELEUTERIO", "FERMIN", "GILDARDO",
           "HOMERO", "ISAIAS", "JUVENTINO", "LADISLAO", "MODESTO")

  # Check name list
  if (first %in% fem) return("F")
  if (first %in% mal) return("M")

  # Check second element (many Mexican names start with compound: MARIA DE, JOSE LUIS)
  if (length(parts) >= 2) {
    second <- parts[2]
    if (first == "MARIA" || first == "MA" || first == "MA.") return("F")
    if (first == "JOSE" || first == "J") return("M")
    if (second %in% fem) return("F")
    if (second %in% mal) return("M")
  }

  # Spanish naming heuristic: final vowel
  if (nchar(first) >= 3) {
    if (grepl("A$", first) && !first %in% c("BORJA", "OCHOA", "GARCIA", "COSTA")) return("F")
    if (grepl("O$", first)) return("M")
  }

  return(NA_character_)
}

cat("Classifying runner-up gender...\n")
elec$runnerup_gender <- sapply(elec$runnerup, classify_gender)

# Also classify winner gender from incumbent name (cross-check)
elec$winner_gender <- ifelse(elec$dmujer == 1, "F", "M")

cat("Runner-up gender classification:\n")
print(table(elec$runnerup_gender, useNA = "always"))

# ─── 3. Construct analysis sample ──────────────────────────────────────────
# Strategy: Use all elections where we can confirm mixed-gender race
# dmujer = 1 AND runnerup classified as M → confirmed mixed-gender
# dmujer = 0 AND runnerup classified as F → confirmed mixed-gender

elec_mixed <- elec %>%
  filter(
    (dmujer == 1 & runnerup_gender == "M") |
    (dmujer == 0 & runnerup_gender == "F")
  ) %>%
  mutate(
    # Running variable: positive = female candidate's margin of victory
    female_margin = ifelse(dmujer == 1, mg, -mg)
  )

cat(sprintf("\nConfirmed mixed-gender races: %d\n", nrow(elec_mixed)))
cat(sprintf("  Female wins: %d (%.1f%%)\n",
            sum(elec_mixed$dmujer == 1), 100 * mean(elec_mixed == 1)))
cat(sprintf("  Male wins (female runner-up): %d\n",
            sum(elec_mixed$dmujer == 0)))
cat(sprintf("  |margin| < 10%%: %d\n",
            sum(abs(elec_mixed$female_margin) < 0.10)))
cat(sprintf("  |margin| < 5%%: %d\n",
            sum(abs(elec_mixed$female_margin) < 0.05)))

# ─── 4. Load and reshape EFIPEM fiscal data ─────────────────────────────────
cat("\nLoading EFIPEM fiscal data...\n")
efipem_dir <- file.path(data_dir, "efipem", "conjunto_de_datos")
csv_files <- list.files(efipem_dir, pattern = "\\.csv$", full.names = TRUE)

fiscal_list <- lapply(csv_files, function(f) {
  df <- read.csv(f, stringsAsFactors = FALSE)
  df %>%
    filter(TEMA == "Egresos",
           CATEGORIA %in% c("Tema", "Capítulo")) %>%
    select(ANIO, ID_ENTIDAD, ID_MUNICIPIO, DESCRIPCION_CATEGORIA, VALOR) %>%
    mutate(
      ANIO = as.integer(ANIO),
      ID_ENTIDAD = sprintf("%02d", as.integer(ID_ENTIDAD)),
      ID_MUNICIPIO = sprintf("%03d", as.integer(ID_MUNICIPIO)),
      VALOR = as.numeric(VALOR)
    )
})

fiscal_long <- bind_rows(fiscal_list)
cat(sprintf("Fiscal data: %d rows, years %d-%d\n",
            nrow(fiscal_long), min(fiscal_long$ANIO), max(fiscal_long$ANIO)))

# Pivot: one row per municipality-year with spending categories
fiscal_wide <- fiscal_long %>%
  mutate(
    var_name = case_when(
      DESCRIPCION_CATEGORIA == "Total de egresos" ~ "total_exp",
      DESCRIPCION_CATEGORIA == "Servicios personales" ~ "serv_pers",
      grepl("Transferencias", DESCRIPCION_CATEGORIA) ~ "transfers",
      grepl("Inversi", DESCRIPCION_CATEGORIA) ~ "inv_pub",
      DESCRIPCION_CATEGORIA == "Materiales y suministros" ~ "mat_sum",
      DESCRIPCION_CATEGORIA == "Servicios generales" ~ "serv_gen",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(var_name)) %>%
  group_by(ANIO, ID_ENTIDAD, ID_MUNICIPIO, var_name) %>%
  summarise(VALOR = sum(VALOR, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = var_name, values_from = VALOR, values_fill = 0) %>%
  filter(total_exp > 0) %>%
  mutate(
    share_serv_pers = serv_pers / total_exp,
    share_transfers = transfers / total_exp,
    share_inv_pub = inv_pub / total_exp,
    share_mat_sum = mat_sum / total_exp,
    share_serv_gen = serv_gen / total_exp,
    log_total_exp = log(total_exp)
  ) %>%
  filter(share_serv_pers <= 1, share_transfers <= 1, share_inv_pub <= 1)

cat(sprintf("Fiscal data (wide): %d municipality-years\n", nrow(fiscal_wide)))

# ─── 5. Merge: term-average fiscal outcomes for each election ───────────────
cat("\nMerging fiscal outcomes (term averages)...\n")

# Mexican mayors take office ~Jan 1 of yr+1, serve 3 years
# Create lookup of election → term years
elec_mixed <- elec_mixed %>%
  mutate(
    term_start = yr + 1,
    term_end = yr + 3
  )

# Join fiscal data for term years
term_fiscal <- elec_mixed %>%
  select(ord, id_entidad, id_municipio, term_start, term_end) %>%
  rowwise() %>%
  mutate(term_year = list(term_start:term_end)) %>%
  unnest(term_year) %>%
  left_join(fiscal_wide,
            by = c("id_entidad" = "ID_ENTIDAD",
                   "id_municipio" = "ID_MUNICIPIO",
                   "term_year" = "ANIO")) %>%
  group_by(ord) %>%
  summarise(
    n_fiscal_years = sum(!is.na(total_exp)),
    total_exp = mean(total_exp, na.rm = TRUE),
    share_serv_pers = mean(share_serv_pers, na.rm = TRUE),
    share_transfers = mean(share_transfers, na.rm = TRUE),
    share_inv_pub = mean(share_inv_pub, na.rm = TRUE),
    share_mat_sum = mean(share_mat_sum, na.rm = TRUE),
    share_serv_gen = mean(share_serv_gen, na.rm = TRUE),
    log_total_exp = mean(log_total_exp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_fiscal_years >= 1)  # At least 1 year of fiscal data

# Pre-election fiscal variables (election year = yr, use yr as pre)
pre_fiscal <- elec_mixed %>%
  select(ord, id_entidad, id_municipio, yr) %>%
  left_join(fiscal_wide,
            by = c("id_entidad" = "ID_ENTIDAD",
                   "id_municipio" = "ID_MUNICIPIO",
                   "yr" = "ANIO")) %>%
  select(ord,
         pre_total_exp = total_exp,
         pre_share_serv_pers = share_serv_pers,
         pre_share_transfers = share_transfers,
         pre_share_inv_pub = share_inv_pub,
         pre_log_total_exp = log_total_exp)

# Merge everything
analysis <- elec_mixed %>%
  inner_join(term_fiscal, by = "ord") %>%
  left_join(pre_fiscal, by = "ord")

analysis$state <- as.integer(analysis$id_entidad)

cat(sprintf("\n=== Final analysis sample ===\n"))
cat(sprintf("Elections with fiscal data: %d\n", nrow(analysis)))
cat(sprintf("  Female wins: %d (%.1f%%)\n",
            sum(analysis$dmujer == 1),
            100 * mean(analysis$dmujer)))
cat(sprintf("  Male wins: %d\n", sum(analysis$dmujer == 0)))
cat(sprintf("  Unique municipalities: %d\n", n_distinct(analysis$inegi)))
cat(sprintf("  Year range: %d-%d\n", min(analysis$yr), max(analysis$yr)))
cat(sprintf("  |margin| < 10%%: %d\n",
            sum(abs(analysis$female_margin) < 0.10)))
cat(sprintf("  |margin| < 5%%: %d\n",
            sum(abs(analysis$female_margin) < 0.05)))

cat("\nSpending shares (mean +/- SD):\n")
for (v in c("share_serv_pers", "share_transfers", "share_inv_pub")) {
  cat(sprintf("  %s: %.3f +/- %.3f\n", v,
              mean(analysis[[v]], na.rm = TRUE),
              sd(analysis[[v]], na.rm = TRUE)))
}

# Save
saveRDS(analysis, file.path(data_dir, "analysis_rdd.rds"))
cat("\nSaved: data/analysis_rdd.rds\n")
