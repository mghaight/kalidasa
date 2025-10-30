#' Get the body of a text
#'
#' `get_text()` gets a single text by text_id. `get_text()` also takes an
#' optional ch_id to get section of any text. Useful to do line-level analysis
#' or to read the text inside the console.
#'
#' @param t_id    a text_id for a single text in the DCS data set. The text_id
#'                corresponds to the text_id used on the official DCS website.
#'
#' @param ch_id   an optional ch_id or range of ch_ids
#'
#' @returns       a character vector of lines of the given text
#'
#' @examples
#'
#' get_text(154)
#' mahabharata <- get_text(154)
#' mbh_war <- get_text(154, ch_ids = 6:10)
#'
#' @export
get_text <- function(t_id, ch_ids = NULL) {
  if (as.character(t_id) %in% names(dcs_raw)) {
    txt <- dcs_raw[[as.character(t_id)]]
  } else {
    stop("Not a valid text_id.")
  }

  if (is.null(ch_ids)) {
    ch_range <- seq_along(unique(txt$maj_div))
  } else {
    if (all(ch_ids %in% seq_along(unique(txt$maj_div)))) {
      ch_range <- ch_ids
    } else {
      stop("Not a valid ch_id.")
    }
  }

  txt |>
    dplyr::filter(maj_div %in% ch_range) |>
    dplyr::pull(text)
}


#' Print the titles available in the dataset
#'
#' `print_titles()` prints a tibble of each text title and associated text_id
#' for every text in the dataset. Useful to lookup text_ids in a simple tibble
#' to use as a reference in other kalidasa functions, which often expect a
#' text_id to get around using diacritics in scripts.
#'
#' @returns   a tibble of text_ids and titles
#'
#' @examples
#'
#' print_titles()
#'
#' @export
print_titles <- function() {
  dcs_meta |>
    dplyr::select(text_id, title) |>
    print(n = Inf)
}


#' Search for a text title
#'
#' `search_texts()` searches the dataset for a query against the text titles
#' using cosine distance of quadragrams to be sensitive to typos and
#' alternative transliteration styles for Sanskrit terms.
#'
#' @param query   a string query
#'
#' @return        a tibble of text_ids and titles, sorted in order of relevance
#'                to the query
#'
#' @examples
#'
#' search_texts("kavya")
#' search_texts("kavyadarsa")
#'
#' @export
search_texts <- function(query) {
  normalized_query <- stringi::stri_trans_general(query, id = "ascii; lower") |>
    as.character()
  dcs_meta |>
    dplyr::mutate(
      score = stringdist::stringdist(
        a = normalized_query,
        b = stringi::stri_trans_general(title, id = "ascii; lower") |>
          as.character(),
        method = "cosine",
        q = min(4, nchar(normalized_query))
      )
    ) |>
    dplyr::arrange(score) |>
    dplyr::filter(if (any(score == 0)) score == 0 else score < 1) |>
    dplyr::select(text_id, title)
}
