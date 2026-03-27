# ── apep_0238 v10: Packages and Configuration ──────────────────────────────
# "Demand Recessions Scar, Supply Recessions Don't"
# Duration-trap mechanism — complete rebuild from scratch

# ── Packages ──
suppressPackageStartupMessages({
  library(data.table)
  library(fredr)
  library(fixest)
  library(ggplot2)
  library(xtable)
  library(sandwich)
  library(lmtest)
})

# ── Load .env (before ROOT is defined, search upward) ──
.find_env <- function() {
  d <- getwd()
  for (i in 1:6) {
    f <- file.path(d, ".env")
    if (file.exists(f)) return(f)
    d <- dirname(d)
  }
  NULL
}
env_file <- .find_env()
if (!is.null(env_file) && file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- regmatches(line, regexpr("^[^=]+=", line))
    if (length(parts) == 1) {
      key <- sub("=+$", "", parts)
      val <- sub(paste0("^", key, "="), "", line)
      val <- gsub("^['\"]|['\"]$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

# ── API keys ──
fredr_set_key(Sys.getenv("FRED_API_KEY"))

# ── Paths ──
# Detect script directory robustly
.get_script_dir <- function() {
  # Try sys.frame (works when sourced)
  for (i in seq_len(sys.nframe())) {
    ofile <- tryCatch(sys.frame(i)$ofile, error = function(e) NULL)
    if (!is.null(ofile)) return(dirname(normalizePath(ofile)))
  }
  # Try commandArgs (works with Rscript)
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) return(dirname(normalizePath(sub("^--file=", "", file_arg))))
  # Fallback: working directory
  getwd()
}
ROOT <- normalizePath(file.path(.get_script_dir(), ".."), mustWork = TRUE)
CODE_DIR <- file.path(ROOT, "code")
DATA_DIR <- file.path(ROOT, "data")
FIG_DIR  <- file.path(ROOT, "figures")
TAB_DIR  <- file.path(ROOT, "tables")
for (d in c(DATA_DIR, FIG_DIR, TAB_DIR)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# ── Constants ──
STATES <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

STATE_FIPS <- c(AL="01",AK="02",AZ="04",AR="05",CA="06",CO="08",CT="09",DE="10",
                FL="12",GA="13",HI="15",ID="16",IL="17",IN="18",IA="19",KS="20",
                KY="21",LA="22",ME="23",MD="24",MA="25",MI="26",MN="27",MS="28",
                MO="29",MT="30",NE="31",NV="32",NH="33",NJ="34",NM="35",NY="36",
                NC="37",ND="38",OH="39",OK="40",OR="41",PA="42",RI="44",SC="45",
                SD="46",TN="47",TX="48",UT="49",VT="50",VA="51",WA="53",WV="54",
                WI="55",WY="56")

STATE_REGION <- data.table(
  state = STATES,
  region = c("South","West","West","South","West","West","NE","South","South","South",
             "West","West","MW","MW","MW","MW","South","South","NE","South",
             "NE","MW","MW","South","MW","West","MW","West","NE","NE",
             "West","NE","South","MW","MW","South","West","NE","NE","South",
             "MW","South","South","West","NE","South","West","South","MW","West"),
  division = c(6,9,8,7,9,8,1,5,5,5, 9,8,3,3,4,4,6,7,1,5,
               1,3,4,6,4,8,4,8,1,2, 8,2,5,4,3,7,9,2,1,5,
               4,6,7,8,1,5,9,5,3,8)
)

# Recession peaks (NBER)
GR_PEAK  <- as.Date("2007-12-01")
COVID_PEAK <- as.Date("2020-02-01")

# Saiz (2010) housing supply elasticities (MSA-weighted state averages)
SAIZ_ELASTICITY <- c(
  AL=2.68, AK=1.60, AZ=1.65, AR=3.00, CA=1.20, CO=1.52, CT=1.30, DE=2.40,
  FL=1.50, GA=2.20, HI=0.70, ID=1.90, IL=1.40, IN=2.80, IA=3.20, KS=3.10,
  KY=2.70, LA=2.50, ME=1.80, MD=1.30, MA=0.90, MI=2.00, MN=1.60, MS=3.00,
  MO=2.60, MT=2.20, NE=3.00, NV=1.30, NH=1.50, NJ=1.10, NM=2.10, NY=0.80,
  NC=2.30, ND=3.50, OH=2.50, OK=3.20, OR=1.40, PA=1.80, RI=1.00, SC=2.40,
  SD=3.30, TN=2.40, TX=2.50, UT=1.60, VT=2.00, VA=1.70, WA=1.20, WV=2.80,
  WI=1.90, WY=3.00
)

# ── Theme ──
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  )
theme_set(theme_apep)

cat("apep_0238 v10 initialized.\n")
