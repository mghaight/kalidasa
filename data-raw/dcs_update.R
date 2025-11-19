# script that scrapes the DCS to create a comprehensive list of contents
# this script is called by kalidasa.R

dcs_index_url <- "http://www.sanskrit-linguistics.org/dcs/index.php"
dcs_handler_url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"
timeout <- 1 # this is a bandaid for a httr2::req_throttle bug

# create the dcs dataframe
# this first request gets a list of titles and their text_ids
cli::cli_h2("Fetching list of texts")
dcs_check <- httr2::request(dcs_index_url) |>
  httr2::req_url_query(contents = "texte") |>
  httr2::req_retry(max_tries = 3) |>
  httr2::req_perform() |>
  httr2::resp_body_string(encoding = "UTF-8") |>
  rvest::read_html() |>
  # get all of the option tags within the text_id selection pane
  rvest::html_elements("select#text_id option") |>
  (function(opts) {
    tibble::tibble(
      title = rvest::html_text2(opts),
      text_id = rvest::html_attr(opts, "value", default = NA)
    ) |>
      # remove the erroneous test text object that Oliver keeps around
      dplyr::filter(title != "AMTest")
  })()

# adding chapter_ids per text to the df
cli::cli_h2("Fetching chapter ids")
dcs_check <- dplyr::mutate(dcs_check, chapter_data = purrr::map(text_id, function(t_id) {
  httr2::request(dcs_handler_url) |>
    httr2::req_method("POST") |>
    httr2::req_body_form(mode = "printchapters", textid = t_id) |>
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
    rvest::html_elements("select#chapter_id option") |>
    (function(opts) {
      tibble::tibble(
        chapter_id = rvest::html_attr(opts, "value", default = NA),
        ch_data = rvest::html_text2(opts) |>
          # normalizing space around delimiters
          stringr::str_squish() |>
          stringr::str_replace_all("\\s*,\\s*", ",")
      ) |>
        # split the html text data into columns
        tidyr::separate_wider_delim(
          ch_data,
          names = c("short_title", "maj_div", "min_div", "sub_div"),
          delim = ",",
          too_few = "align_start",
          too_many = "merge"
        )
    })()
},
.progress = TRUE
)) |>
  tidyr::unnest_longer(chapter_data) |>
  tidyr::unnest_wider(chapter_data) |>
  dplyr::select(text_id, chapter_id)

dcs_update <- dplyr::anti_join(dcs_check, dplyr::select(dcs, text_id, chapter_id))
if (nrow(dcs_update)) {
  cli::cli_h3("DCS dataset is out of date, consider rebuilding...")
} else {
  cli::cli_h3("DCS dataset is up to date")
}
