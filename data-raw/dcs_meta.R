# script to scrape the DCS for text metadata
# this script is called by kalidasa.R

dcs_index_url <- "http://www.sanskrit-linguistics.org/dcs/index.php"
dcs_handler_url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"

# have to get the genre/subject in a separate request since its not
# included on the textdetails pages
genre_info <- httr2::request(dcs_index_url) |>
  httr2::req_url_query(contents = "corpus") |>
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
  dplyr::filter(text %in% unique(dcs_ids_addr$title)) |>
  dplyr::select(title = text, genre = subject)

dcs_meta <- lapply(unique(dcs_ids_addr$text_id), function(id) {
  httr2::request(dcs_index_url) |>
    # conservative throttling, but I'm not sure this will work bc of a bug
    # in httr2 described here: https://github.com/r-lib/httr2/issues/801
    httr2::req_throttle(capacity = 1, fill_time_s = 2) |>
    httr2::req_url_query(contents = "textdetails", IDText = id) |>
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
}) |>
  dplyr::bind_rows() |>
  dplyr::left_join(genre_info, by = "title")

saveRDS(dcs_meta, file = "dcs_meta.rds")
