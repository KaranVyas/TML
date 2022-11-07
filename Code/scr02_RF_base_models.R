#!/usr/bin/Rscript --vanilla
#  nohup ./scr02_RF_base_models.R > ../logs/scr02_RF_base_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

cl <- makeCluster(80)
registerDoParallel(cl)

path_proj = "/home/shared/1911TML//"
path_datasets = paste0(path_proj, "datasets/originals/")
path_splits = paste0(path_proj, "data_splits/")
path_models_full = paste0(path_proj, "models/base/full_data/RF/")
dir.create(path_models_full, recursive = T)
path_models_split = paste0(path_proj, "models/base/split_data/RF/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/base/split_data/RF/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/base/split_data/RF/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

# learner
lrn_full = makeLearner("regr.ranger")
lrn_split = makeLearner("regr.ranger")

cat("\nCreating the models...")
tmp = foreach(did = data_info$target_id, .packages = c("mlr","dplyr", "purrr", "readr"),
              .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %dopar% {    #DOPAR !!!
                configureMlr(show.info = F, on.learner.error = "warn", show.learner.output = F)
                dset = read_csv(paste0(path_datasets, "data_", did, ".csv"), col_types = cols(
                  .default = col_double(),
                  target_id = col_character(),
                  molecule_id = col_character()
                ))
                dsplit = read_csv(paste0(path_splits, "data-split_", did, ".csv"), col_types = cols(
                  rows_id = col_character(),
                  fold = col_double()
                )) %>% rename(molecule_id = rows_id)
                
                dsplit = dset %>% select(molecule_id) %>%
                  mutate(id = 1:n()) %>%
                  inner_join(dsplit, .)
                
                dset = dset %>% select(pXC50, starts_with("b"))
                
                # model - full data
                tsk = makeRegrTask(id = as.character(did), data = as.data.frame(dset), target = "pXC50")
                mdl = train(lrn_full, tsk)
                write_rds(mdl, paste0(path_models_full, "mdl_did_", did, ".rds"))
                
                # models - split data
                mdls = map(1:10, function(foldi){
                  mdl = train(lrn_split, tsk, subset = dsplit$id[dsplit$fold != foldi])
                })
   #             write_rds(mdls, paste0(path_models_split, "mdl_did_", did, ".rds"))
                
                # predictions - split data - train
                preds = map2_dfr(mdls, 1:10, function(mdli, foldi){
                  (predict(mdli, tsk, subset = dsplit$id[dsplit$fold != foldi]))$data %>%
                    mutate(fold = foldi)
                })
                preds = dsplit %>% select(-fold) %>% inner_join(preds)
                write_csv(preds, paste0(path_predictions_train, "preds_did_", did, ".csv"))
                
                # predictions - split data - test
                preds = map2_dfr(mdls, 1:10, function(mdli, foldi){
                  (predict(mdli, tsk, subset = dsplit$id[dsplit$fold == foldi]))$data
                })
                preds = dsplit %>% inner_join(preds)
                write_csv(preds, paste0(path_predictions_test, "preds_did_", did, ".csv"))
                #browser()
                TRUE
              } 

cat("\nAll done!\n")