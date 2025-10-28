cli::cli_h2("Preparing dcs_raw dataset")
# preparing the raw text dataset
dcs_raw <- unique(dcs$text_id) |>
  purrr::set_names() |>
  purrr::map(function(t_id) {
    text_chapters <- dplyr::filter(dcs, text_id == t_id) |>
      purrr::pmap(function(...) {
        ch <- list(...)
        verse_raw <- rvest::read_html(ch$resp_body) |>
          rvest::html_elements(".sentence_div") |>
          rvest::html_text() |>
          stringr::str_remove_all("Par\\.\\?") |>
          stringr::str_squish()

        verse_num <- stringr::str_extract(verse_raw, "\\([^)]*\\)") |>
          stringr::str_remove_all("[()]")

        tibble::tibble(
          text = verse_raw |>
            stringr::str_remove_all("\\([^)]*\\)$") |>
            stringr::str_remove_all("/") |>
            stringr::str_squish(),
          maj_div = ch$maj_div,
          min_div = ch$min_div,
          sub_div = ch$sub_div,
          verse_num = verse_num
        )
      }) |>
      purrr::list_rbind()
  })

cli::cli_h2("Saving dcs_raw.rds")
saveRDS(dcs_raw, file = "dcs_raw.rds")
