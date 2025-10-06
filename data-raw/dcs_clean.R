# script that cleans the dcs df that dcs_scrape.R generates
# this script is called by kalidasa.R

# I am manually removing some texts from the dataset after poking around in it.
# Primarily I am removing works that are highly incomplete.
# Of course, one could rebuild the dataset themselves and keep any of these
# works by commenting out the appropriate line.
text_ids_to_cull <- c(
  9, # G￸ḍhārthaprakāśaka
  60, # Commentary on Amaraughaśāsana
  113, # Amṛtabindūpaniṣat
  162, # Carakatattvapradīpikā
  # 225, # Kāvyālaṃkāravṛtti
  # 226, # Commentary on the Kāvyālaṃkāravṛtti
  251, # Bhadrabāhucarita
  258, # Cakra (?) on Suśr
  275, # Aṣṭāṅgasaṃgraha
  317, # Khādiragṛhyasūtrarudraskandavyākhyā
  379 # Abhidharmakośabhāṣya
)

dcs_meta <- dplyr::filter(dcs_meta, !(text_id %in% text_ids_to_cull))
dcs <- dplyr::filter(dcs, !(text_id %in% text_ids_to_cull))

# preparing the raw dataset
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

saveRDS(dcs_raw, file = "dcs_raw.rds")
