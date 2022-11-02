rm(list = ls())
library(tidyverse)

algorithms = c("RF", "SVM", "KNN", "Ridge")
meta = c("base", "transformed")

path_project = "/home/shared/openml_stdy07/"
path_predictions = paste0(path_project, "predictions/")
prefix_fnam = "split_test_"

file_names = list.files(path_predictions, pattern = prefix_fnam)

perf_df = tibble(filename = file_names) %>%
  mutate(meta_alg = str_remove_all(filename, paste0(prefix_fnam,"|.csv"))) %>%
  separate(meta_alg, into = c("meta_alg", "algorithm")) %>%
  filter(meta_alg %in% meta, algorithm %in% algorithms)

# Load predictions file
perf_df = map_dfr(perf_df$filename, ~ {
  read_csv(paste0(path_predictions, .x), col_types = "cddddc") %>%
    mutate(filename = .x)
}) %>%
  inner_join(perf_df)
head(perf_df)

perf_df = perf_df %>% group_by(flow, algorithm, rows_id) %>%
  summarise(
    id = first(id),
    fold = first(fold),
    truth = first(truth),
    response = mean(response, na.rm = T)
  ) %>% 
  mutate(meta_alg = "average", sufix_fnam = paste0(meta_alg, "_", algorithm, ".csv")) %>%
  ungroup()

perf_df %>% 
  split(., .$sufix_fnam) %>%
  iwalk( ~ .x %>% 
           select(-c(sufix_fnam, algorithm, meta_alg)) %>% 
           write_csv(paste0(path_predictions, prefix_fnam, .y))
         )

