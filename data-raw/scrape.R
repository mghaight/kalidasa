# script to scrape the DCS for data in two parts
# first: create a dataframe of the text titles, text ids and associated chapter ids
# second: create a list of responses for each text from the ids df
#
# this script is called by kalidasa.R

dcs_index_url <- "http://www.sanskrit-linguistics.org/dcs/index.php"
dcs_handler_url <- "http://www.sanskrit-linguistics.org/dcs/ajax-php/ajax-text-handler-wrapper.php"

if (file.exists("dcs_ids_df.rds")) {
  dcs_ids_df <- readRDS("dcs_ids_df.rds")
} else {
  # create the dcs_ids_df
  # this first request gets a list of titles and their text_ids
  dcs_ids_df <- httr2::request(dcs_index_url) |>
    httr2::req_url_query(contents = "texte") |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    rvest::read_html() |>
    # get all of the option tags within the text_id selection pane
    rvest::html_elements("select#text_id option") |>
    (function(opts) {
      tibble::tibble(
        title = rvest::html_text2(opts),
        text_id = rvest::html_attr(opts, "value", default = NA_character_)
      ) |>
        # remove the erroneous option tags so its just texts
        dplyr::filter((title != "AMTest") & grepl("^[0-9]+$", text_id))
    })() |>
    dplyr::mutate(
      # adding chapter ids to the df
      chapter_data = lapply(
        text_id, function(t_id) {
          # this second request gets a list of chapter_data for each text
          httr2::request(dcs_handler_url) |>
            httr2::req_method("POST") |>
            httr2::req_body_form(mode = "printchapters", textid = t_id) |>
            httr2::req_perform() |>
            httr2::resp_body_string(encoding = "UTF-8") |>
            rvest::read_html() |>
            rvest::html_elements("select#chapter_id option") |>
            (function(opts) {
              tibble::tibble(
                chapter_id = rvest::html_attr(opts, "value", default = NA_character_),
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
        }
      )
    ) |>
    tidyr::unnest(chapter_data) |>
    dplyr::select(title, short_title, text_id, maj_div, min_div, sub_div, chapter_id)
  # save for future use
  saveRDS(dcs_ids_df, file = "dcs_ids_df.rds")
}

if (file.exists("dcs_meta_raw.rds")) {
  dcs_meta_raw <- readRDS("dcs_meta_raw.rds")
} else {
  dcs_meta_reqs <- lapply(dcs_ids_df, function(text) {
    httr2::request(dcs_index_url) |>
      httr2::req_url_query(contents = "textdetails", IDText = text$text_id)
  })
}
