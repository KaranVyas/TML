rm(list = ls())

library(tidyverse)

proj_name = "1911TML"
path_proj = paste0("/home/shared/", proj_name, "/")
path_legacy_data = paste0(path_proj, "legacy/")

targ_ids = read_csv(paste0(path_proj, "datasets_info.csv"))
head(targ_ids)

# copy data split files
path_split = paste0(path_proj, "data_splits/")
dir.create(path_split, recursive = T)

files_to_copy = targ_ids %>% pull(dataset_id) %>%
  paste0("/home/shared/1909TML/data_splits/data-split_", ., ".csv")
file.copy(from = files_to_copy,
          to = path_split)

files_from = paste0(path_split, "data-split_", targ_ids$dataset_id, ".csv")
files_to = paste0(path_split, "data-split_", targ_ids$target_id, ".csv")
file.rename(from = files_from, to = files_to)
