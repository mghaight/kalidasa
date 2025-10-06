# script to scrape the DCS for text metadata
# this script is called by kalidasa.R

dcs_index_url <- "http://www.sanskrit-linguistics.org/dcs/index.php"
dcs_handler_url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"
timeout <- 1 # this is a bandaid for a httr2::req_throttle bug

# have to get the genre/subject in a separate request since its not
# included on the textdetails pages
cli::cli_h2("Fetching metadata")
genre_info <- httr2::request(dcs_index_url) |>
  httr2::req_url_query(contents = "corpus") |>
  httr2::req_retry(max_tries = 3) |>
  httr2::req_perform() |>
  httr2::resp_body_string(encoding = "UTF-8") |>
  rvest::read_html() |>
  rvest::html_element("div#content table") |>
  rvest::html_table(na.strings = "") |>
  dplyr::rename_with(function(df_cols) {
    df_cols |>
      stringr::str_to_lower() |>
      stringr::str_squish() |>
      stringr::str_remove_all("[[:punct:]]") |>
      stringr::str_replace_all("\\s+", "_")
  }) |>
  # remove the random texts that Oliver keeps around
  dplyr::filter(text %in% unique(dcs$title)) |>
  dplyr::select(title = text, genre = subject)

dcs_meta <- purrr::map(unique(dcs$text_id), function(id) {
  httr2::request(dcs_index_url) |>
    httr2::req_url_query(contents = "textdetails", IDText = id) |>
    httr2::req_retry(max_tries = 3) |>
    # this is a bandaid on a httr1::req_throttle bug described here:
    # https://github.com/r-lib/httr2/issues/801
    # (function(req) {
    #   Sys.sleep(timeout)
    #   httr2::req_perform(req)
    # })() |>
    httr2::req_throttle(capacity = 30, fill_time_s = 60) |>
    # dont let curl timeout
    httr2::req_options(low_speed_limit = 0) |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    rvest::read_html() |>
    rvest::html_element("div#content table") |>
    rvest::html_table(na.strings = "") |>
    tidyr::pivot_wider(names_from = "X1", values_from = "X2") |>
    dplyr::rename_with(function(df_cols) {
      df_cols |>
        stringr::str_to_lower() |>
        stringr::str_squish() |>
        stringr::str_remove_all("[[:punct:]]") |>
        stringr::str_replace_all("\\s+", "_")
    }) |>
    tibble::add_column(text_id = id, .before = 1)
}, .progress = TRUE) |>
  dplyr::bind_rows() |>
  dplyr::left_join(genre_info, by = "title")

# Cleaning

## TODO
## 1) clean/normalize the digitized_by column
## 2) create normalized short titles for each work

cli::cli_h2("Cleaning dcs_meta")

# drop subtitle column (not really helpful for this dataset imo)
# dcs_meta <- dplyr::select(-subtitle)

# clean status information for readability
dcs_meta <- dplyr::mutate(dcs_meta, status = dplyr::if_else(!is.na(status), "complete", "incomplete"))
dcs_meta <- dplyr::mutate(dcs_meta, dplyr::na_if(year, "0"))

# adding missing genre info
dcs_meta[which(dcs_meta$text_id == 226), ]$genre <- "Alamkarashastra" # Commentary on the Kāvyālaṃkāravṛtti
dcs_meta[which(dcs_meta$text_id == 256), ]$genre <- "Atharvaveda" # Kauśikasūtradārilabhāṣya
dcs_meta[which(dcs_meta$text_id == 317), ]$genre <- "Grhyasutra" # Khādiragṛhyasūtrarudraskandavyākhyā
dcs_meta[which(dcs_meta$text_id == 572), ]$genre <- "Mimamsa" # Mīmāṃsāsūtrabhāṣya

# break up authors into list column (not sure if I want to make this choice...)
# dcs_meta <- dplyr::mutate(dcs_meta, author = purrr::map(author, function(aut) {
#   if (is.na(aut)) {
#     return(NA_character_)
#   }
#   stringr::str_split_1(aut, ",") |> stringr::str_trim()
# }))

saveRDS(dcs_meta, file = "dcs_meta.rds")
