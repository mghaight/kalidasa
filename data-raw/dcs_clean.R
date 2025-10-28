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

cli::cli_h2("Removing incomplete texts")
dcs_meta <- dplyr::filter(dcs_meta, !(text_id %in% text_ids_to_cull))
dcs <- dplyr::filter(dcs, !(text_id %in% text_ids_to_cull))
dcs_raw <- dplyr::filter(dcs, !(text_id %in% text_ids_to_cull))
