#!/usr/bin/Rscript --vanilla
#  nohup ./scr05_create_XGB_transf_models.R > ../logs/scr05_create_XGB_transf_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

#cl <- makeCluster(80)
#registerDoParallel(cl)

learner_id = "XGB"

path_proj = "/home/shared/1911TML/"
path_datasets = paste0(path_proj, "datasets/transformed/",learner_id,"/")
path_splits = paste0(path_proj, "data_splits/")
path_models_full = paste0(path_proj, "models/transformed/full_data/",learner_id,"/")
dir.create(path_models_full, recursive = T)
path_models_split = paste0(path_proj, "models/transformed/split_data/",learner_id,"/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

# learner
#lrn_full = makeLearner("regr.fnn")
#lrn_split = makeLearner("regr.fnn")


# learner
parset <- makeParamSet(
  makeDiscreteParam("nrounds", values = c(1000, 1500)),
  makeDiscreteParam("eta", values = c(0.001, 0.01, 0.1, 0.2, 0.3))
)

rdesc <- makeResampleDesc("Holdout", split = 0.7)

lrn_full0 = makeLearner("regr.xgboost")
lrn_full0 = setHyperPars(lrn_full0, 
                         par.vals = list(
                           max_depth = 6,
                           gamma = 0.05,
                           subsample = 0.5,
                           colsample_bytree = 1,
                           min_child_weight = 1
                         ))

lrn_full <- makeTuneWrapper(lrn_full0, 
                            resampling = rdesc, 
                            measures = list(sse), 
                            par.set = parset, 
                            control = makeTuneControlGrid()
)

lrn_split0 = makeLearner("regr.xgboost")
lrn_split0 = setHyperPars(lrn_split0, 
                          par.vals = list(
                            max_depth = 6,
                            gamma = 0.05,
                            subsample = 0.5,
                            colsample_bytree = 1,
                            min_child_weight = 1
                          ))
lrn_split <- makeTuneWrapper(lrn_split0, 
                             resampling = rdesc, 
                             measures = list(sse), 
                             par.set = parset, 
                             control = makeTuneControlGrid()
)


#### to remove: data_info$target_id[217:2094]
#### 24/02/21

cat("\nCreating the models...")
tmp = foreach(did = data_info$target_id[217:2094], .packages = c("mlr","dplyr", "purrr", "readr"),
              .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %do% {    #DOPAR !!!
                cat("\nDataset:",did,"...")
                configureMlr(show.info = F, on.learner.error = "warn", show.learner.output = F)
                #browser()
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
                cat("DONE")
                TRUE
              } 

cat("\nAll done!\n")