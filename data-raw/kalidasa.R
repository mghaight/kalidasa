# main script that generate the `kalidasa` R package datasets

if (!file.exists("dcs_ids.rds")) {
  source("scrape_ids.R", echo = TRUE)
} else {
  dcs_ids <- readRDS("dcs_ids.rds")
}

if (!file.exists("dcs_meta.rds")) {
  source("dcs_meta.R", echo = TRUE)
} else {
  dcs_meta <- readRDS("dcs_meta.rds")
}
