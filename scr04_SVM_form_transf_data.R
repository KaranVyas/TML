#!/usr/bin/Rscript --vanilla
#  nohup ./scr04_SVM_form_transf_data.R > ../logs/scr04_SVM_form_transf_data.log &
rm(list = ls())
library(tidyverse)

path_proj = "/home/shared/1911TML/"
path_data_orig =  paste0(path_proj, "datasets/originals/")
path_data_transf = paste0(path_proj, "datasets/transformed/SVM/")
dir.create(path_data_transf, recursive = T)

path_predictions = paste0(path_proj, "predictions/base/full_data/SVM/")

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

cat("\nLoading preds_full_data_SVM.rds\n")
timestamp()

#### Preds full_data failed, so needs to be formed again
fnams = list.files(paste0(path_predictions, "tmp/"), full.names = T)
pred_all = map_dfr(fnams, read_rds)
timestamp()
#### END
#pred_all = read_rds(paste0(path_predictions, "preds_full_data_SVM.rds"))

cat("\npivot_widering\n")
timestamp()

#pred_all = pred_all %>% pivot_wider(names_from = target_id, values_from = value)
pred_all = pred_all %>% spread(key = target_id, value = value)

cat("\nLoading original datasets...\n")
timestamp()

dset_fnams = list.files(path_data_orig)
names(dset_fnams) = str_remove_all(dset_fnams, "data_|.csv")

dsets = map_dfr(dset_fnams, ~ read_csv(paste0(path_data_orig, .x), col_types = cols(
  .default = col_double(),
  target_id = col_character(),
  molecule_id = col_character(),
  dataset_id = col_character()
)) %>% select(target_id, molecule_id, pXC50, dataset_id))
#data_info = data_info %>% mutate(dataset_id = as.character(dataset_id))
#dsets = dsets %>%
#  inner_join(data_info) %>%
#  select(target_id, dataset_id, molecule_id, pXC50) 

cat("\nSplitting\n")
timestamp()

pred_all = dsets %>% inner_join(pred_all) %>%
  split(., .$target_id)

cat("\nWriting ...\n")
timestamp()

iwalk(pred_all, ~{
  tid_drop = .x$target_id[1]
  .x %>% select(-one_of(tid_drop)) %>%
    write_csv(path = paste0(path_data_transf, "data_", .y, ".csv"))
})

cat("\nDone!\n")
timestamp()
