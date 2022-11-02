rm(list = ls())

# form datasets using RDKit fingerprints

proj_name = "1911TML"
path_proj = paste0("/home/shared/", proj_name, "/")
path_datasets = paste0(path_proj, "datasets/")
path_orig_data = paste0(path_datasets, "originals/")
dir.create(path_orig_data, recursive = T)

path_legacy_data = paste0(path_proj, "legacy/")

library(tidyverse)

fp_data = read_rds(paste0(path_legacy_data, "fingp_tbl_170510.rda"))
data_ids = read_rds(paste0(path_legacy_data, "full_data_ids.rds"))
head(data_ids)

dsets = data_ids %>% inner_join(fp_data)

dsets = dsets %>% split(., .$target_id)

iwalk(dsets, ~ write_csv(.x, path = paste0(path_orig_data, "data_", .y, ".csv")))

