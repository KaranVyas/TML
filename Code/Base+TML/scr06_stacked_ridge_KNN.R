#!/usr/bin/Rscript --vanilla
#  nohup ./scr06_stacked_ridge_KNN.R > ../logs/scr06_stacked_ridge_KNN.log &


rm(list = ls())

library(tidyverse)
library(mlr)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

cl <- makeCluster(80)
registerDoParallel(cl)

learners = c("KNN/") #, "SVM/")
names(learners) = c("KNN") #, "SVM")

strategies = c("base/", "transformed/")
names(strategies) = c("Baseline", "TML")

path_proj = "/home/shared/1911TML/"
path_predictions = paste0(path_proj, "predictions/")
path_predictions_test = paste0(path_predictions, "stackedridge/split_data/",learners,"test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

lrn = makeLearner("regr.cvglmnet")
lrn = setHyperPars(lrn, alpha = 0, nfolds = 3)

cat("\nCreating the models...")
tmp = foreach(did = data_info$target_id, .packages = c("mlr","dplyr", "purrr", "readr", "tidyr"),
              .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %dopar% {    #DOPAR !!!
                
                pred_train = map_dfr(strategies, ~ {
                  read_csv(paste0(path_predictions, .x, "split_data/", learners, "train/preds_did_", did, ".csv"), col_types = cols(
                    molecule_id = col_character(),
                    id = col_double(),
                    truth = col_double(),
                    response = col_double(),
                    fold = col_double()
                  )) 
                }, .id = "strategy") %>% 
                  spread(key = "strategy", value = "response") %>%
                  split(., .$fold)
                
                mdls = map(pred_train, function(foldi){
                  tsk = makeRegrTask(data = (foldi %>% select(Baseline, TML, truth) %>% as.data.frame()), target = "truth")
                  mdl = train(lrn, tsk)
                })
                
                pred_test = map_dfr(strategies, ~ {
                  read_csv(paste0(path_predictions, .x, "split_data/", learners, "test/preds_did_", did, ".csv"), col_types = cols(
                    molecule_id = col_character(),
                    id = col_double(),
                    truth = col_double(),
                    response = col_double(),
                    fold = col_double()
                  )) 
                }, .id = "strategy") %>% 
                  spread(key = "strategy", value = "response") %>%
                  split(., .$fold)
                
                new_preds = map2_dfr(mdls, pred_test, ~ {
                  newx = .y %>%  select(c(Baseline, TML)) %>% as.data.frame()
                  .y %>% mutate(response = predict(.x, newdata = newx)$data$response) 
                }) %>%
                  select(molecule_id,id,truth,response,fold)
                
                new_preds %>% write_csv(paste0(path_predictions_test, "preds_did_", did, ".csv"))
                
                TRUE
              } 

cat("\nAll done!\n")

