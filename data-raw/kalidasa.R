# main script that generate the `kalidasa` R package datasets

if (!file.exists("dcs.rds")) {
  cli::cli_h1("Running dcs_scrape.R")
  source("dcs_scrape.R")
} else {
  cli::cli_h1("Loading dcs.rds")
  dcs <- readRDS("dcs.rds")
}

if (!file.exists("dcs_meta.rds")) {
  cli::cli_h1("Running dcs_meta.R")
  source("dcs_meta.R")
} else {
  cli::cli_h1("Loading dcs_meta.rds")
  dcs_meta <- readRDS("dcs_meta.rds")
}

if (!file.exists("dcs_raw.rds")) {
  cli::cli_h1("Running dcs_raw.R")
  source("dcs_raw.R")
} else {
  cli::cli_h1("Loading dcs_raw.rds")
  dcs_raw <- readRDS("dcs_raw.rds")
}

cli::cli_h1("Running dcs_clean.R")
source("dcs_clean.R")

if (!file.exists("dcs_rich.rds")) {
  cli::cli_h1("Running dcs_rich.R")
  source("dcs_rich.R")
} else {
  cli::cli_h1("Loading dcs_rich.rds")
  dcs_rich <- readRDS("dcs_rich.rds")
}

cli::cli_h1("Saving kalidasa datasets to kalidasa.RData")
kalidasa <- c(
  dcs,
  dcs_meta,
  dcs_raw,
  # dcs_rich
)
save(kalidasa, file = "kalidasa.RData")
