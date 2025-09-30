# main script that generate the `kalidasa` R package datasets

if (!file.exists("dcs_ids_addr.rds")) {
  source("scrape_ids.R", echo = TRUE)
} else {
  dcs_ids_addr <- readRDS("dcs_ids_addr.rds")
}

if (!file.exists("dcs_meta.rds")) {
  source("dcs_meta.R", echo = TRUE)
} else {
  dcs_meta <- readRDS("dcs_meta.rds")
}
