rm(list = ls())

data_dir = "/home/shared/openml_stdy07/"

library(tidyverse)
dsets = read_csv(paste0(data_dir, "data/original_datasets.csv"))

set.seed(1)

data_splitting = function(dset, .folds = 10) {
  dset = sample_frac(dset)
  nr = nrow(dset)
  nrf = ceiling(nr / .folds)
  dset %>% mutate(fold = rep(1:.folds, nrf)[1:nr])
}

dsets = dsets %>% split(.$flow) %>%
  map_dfr(data_splitting) %>%
  select(flow, rows_id = openml_task, fold)
  
dir.create(paste0(data_dir, "data_splits/"))
write_csv(dsets, paste0(data_dir, "data_splits/datasets_splits.csv"))
