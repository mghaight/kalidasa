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
  225, # Kāvyālaṃkāravṛtti
  226, # Commentary on the Kāvyālaṃkāravṛtti
  258, # Cakra (?) on Suśr
  275, # Aṣṭāṅgasaṃgraha
  317, # Khādiragṛhyasūtrarudraskandavyākhyā
  379, # Abhidharmakośabhāṣya
)

dcs_meta <- dplyr::filter(dcs_meta, !(text_id %in% text_ids_to_cull))
dcs <- dplyr::filter(dcs, !(text_id %in% text_ids_to_cull))

# TODO
# 1. `status` col in dcs_meta should be renamed `complete` and rows should either be `1`-complete or `0`-incomplete
# 2.

dcs_raw

dcs_rich
