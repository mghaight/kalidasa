library(httr2)
library(rvest)
library(readr)
library(dplyr)
library(stringr)

# dataframe includes all works from the DCS arranged
# alphabetically and then by {book, chapter}, like so:
# chapter_id, work_title, book_num, chapter_num
if (file.exists("chapter_ids_df.rds")) {
  chapter_ids_df <- readRDS("chapter_ids_df.rds")
} else {
  chapter_ids_df <- readr::read_csv("chapter_ids.csv") |>
    dplyr::arrange(work_title, book_num, chapter_num)
  saveRDS(chapter_ids_df, file = "chapter_ids_df.rds")
}

# vector of titles
works <- unique(chapter_ids_df$work_title)

# base POST request for the dcs text handler which prints curl info to the console
dcs_url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"
base_req <- httr2::request(dcs_url) |>
  httr2::req_method("POST") |>
  httr2::req_options(verbose = TRUE)

# create a named list of requests by work_title
if (file.exists("dcs_reqs.rds")) {
  dcs_reqs <- readRDS("dcs_reqs.rds")
} else {
  dcs_reqs <- setNames(
    lapply(works, function(work) {
      work_ids <- dplyr::filter(chapter_ids_df, work_title == work)$chapter_id
      setNames(
        lapply(work_ids, function(id) {
          base_req |>
            httr2::req_body_form(mode = "printsentences", chapterid = as.character(id))
        }),
        as.character(work_ids)
      )
    }),
    paste0(works, "_reqs")
  )
  saveRDS(dcs_reqs, file = "dcs_reqs.rds")
}

# get the responses and rename the lists
if (file.exists("dcs_resps.rds")) {
  dcs_resps <- readRDS("dcs_resps.rds")
} else {
  dcs_resps <- lapply(dcs_reqs, httr2::req_perform_sequential)
  names(dcs_resps) <- sub("_reqs$", "_resps", names(dcs_reqs))
  saveRDS(dcs_resps, file = "dcs_resps.rds")
}

# parse HTML from responses
if (file.exists("dcs_resps_html.rds")) {
  dcs_resps_html <- readRDS("dcs_resps_html.rds")
} else {
  dcs_resps_html <- lapply(dcs_resps, function(work_resps) {
    # reading the resps as strings so there isn't pointer invalidation across sessions
    lapply(work_resps, httr2::resp_body_string)
  })
  names(dcs_resps_html) <- paste0(names(dcs_resps), "_html")
  saveRDS(dcs_resps_html, file = "dcs_resps_html.rds")
}

# create a list of character vectors that contain the whole text
if (file.exists("text_vectors.rds")) {
  text_vectors <- readRDS("text_vectors.rds")
} else {
  text_vectors <- lapply(dcs_resps_html, function(work_resps_html) {
    lapply(work_resps_html, function(resp_html) {
      resp_html |>
        rvest::read_html() |>
        rvest::html_elements(".sentence_div") |>
        rvest::html_text() |>
        stringr::str_remove_all("Par\\.\\?") |>
        stringr::str_squish()
    })
  })

  # name the lists by their title from the old works vector
  names(text_vectors) <- works
  saveRDS(text_vectors, file = "text_vectors.rds")
}
