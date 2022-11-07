#!/usr/bin/Rscript --vanilla
#  nohup ./scr05_create_SVM_transf_models.R > ../logs/scr05_create_SVM_transf_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

cl <- makeCluster(80)
registerDoParallel(cl)

path_proj = "/home/shared/1911TML/"
path_datasets = paste0(path_proj, "datasets/transformed/SVM/")
path_splits = paste0(path_proj, "data_splits/")
path_models_full = paste0(path_proj, "models/transformed/full_data/SVM/")
dir.create(path_models_full, recursive = T)
path_models_split = paste0(path_proj, "models/transformed/split_data/SVM/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/transformed/split_data/SVM/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/transformed/split_data/SVM/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

# learner
lrn_full = makeLearner("regr.ksvm")
lrn_split = makeLearner("regr.ksvm")

cat("\nCreating the models...")
tmp = foreach(did = data_info$target_id, .packages = c("mlr","dplyr", "purrr", "readr"),
              .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %dopar% {    #DOPAR !!!
               configureMlr(show.info = F, on.learner.error = "warn", show.learner.output = F)
                #browser()
                dset = read_csv(paste0(path_datasets, "data_", did, ".csv"), col_types = cols(
                  .default = col_double(),
                  target_id = col_character(),
                  molecule_id = col_character()
                ))
                
                ### remove NAs
                dset = dset %>% select_if(~ !any(is.na(.)))
                ### END remove NAs
                
                dsplit = read_csv(paste0(path_splits, "data-split_", did, ".csv"), col_types = cols(
                  rows_id = col_character(),
                  fold = col_double()
                )) %>% rename(molecule_id = rows_id)
                
                dsplit = dset %>% select(molecule_id) %>%
                  mutate(id = 1:n()) %>%
                  inner_join(dsplit, .)
                
                dset = dset %>% select(pXC50, starts_with("CHEMBL"))
                
                # model - full data
                tsk = makeRegrTask(id = as.character(did), data = as.data.frame(dset), target = "pXC50")
                mdl = train(lrn_full, tsk)
                write_rds(mdl, paste0(path_models_full, "mdl_did_", did, ".rds"))
                
                # models - split data
                mdls = map(1:10, function(foldi){
                  mdl = train(lrn_split, tsk, subset = dsplit$id[dsplit$fold != foldi])
                })
                # write_rds(mdls, paste0(path_models_split, "mdl_did_", did, ".rds"))
                
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
                TRUE
              } 

cat("\nAll done!\n")