library(httr2)
library(rvest)
library(stringr)

# DCS chapter ids for each canto of Kumārasambhava
ks_chapter_ids <- c("7305", "7312", "7315", "7328", "7332", "7343", "8650", "8657")

# DCS chapter ids for halves of Meghadūta
md_chapter_ids <- c("2848", "7334")

url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"
base_req <- request(url) |>
  req_method("POST")

# requests for all of Kumārasambhava
ks_reqs <- lapply(ks_chapter_ids, function(id) {
  base_req |> req_body_form(mode = "printsentences", chapterid = id)
})

# requests for all of Meghadūta
md_reqs <- lapply(md_chapter_ids, function(id) {
  base_req |> req_body_form(mode = "printsentences", chapterid = id)
})

# process requests
ks_resp <- req_perform_parallel(ks_reqs)
md_resp <- req_perform_parallel(md_reqs)

# get character vector of Kumārasambhava text
ks_full <- c()
for (chp in ks_resp) {
  chp_text <- chp |>
    resp_body_string() |>
    read_html() |>
    html_elements(".sentence_div") |>
    html_text() |>
    str_remove_all("Par\\.\\?") |>
    str_remove_all("\n")
  ks_full <- c(ks_full, chp_text)
}

# get character vector of Meghadūta text
md_full <- c()
for (chp in md_resp) {
  chp_text <- chp |>
    resp_body_string() |>
    read_html() |>
    html_elements(".sentence_div") |>
    html_text() |>
    str_remove_all("Par\\.\\?") |>
    str_remove_all("\n")
  md_full <- c(md_full, chp_text)
}

# write vectors as files
writeLines(ks_full, con = "../raw/ks.txt")
writeLines(md_full, con = "../raw/md.txt")
