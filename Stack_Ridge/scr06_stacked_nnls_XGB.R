#!/usr/bin/Rscript --vanilla
#  nohup ./scr06_stacked_nnls_XGB.R > ../logs/scr06_stacked_nnls_XGB.log &


rm(list = ls())

library(tidyverse)
library(glmnet)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

cl <- makeCluster(80)
registerDoParallel(cl)

learners = c("XGB/") #, "SVM/")
names(learners) = c("XGB") #, "SVM")

strategies = c("base/", "transformed/")
names(strategies) = c("Baseline", "TML")

path_proj = "/home/shared/1911TML/"
path_predictions = paste0(path_proj, "predictions/")
path_predictions_test = paste0(path_predictions, "stackednnls/split_data/",learners,"test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

cat("\nCreating the models...")
tmp = foreach(did = data_info$target_id, .packages = c("glmnet","dplyr", "purrr", "readr", "tidyr"),
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
                  x = foldi %>%  select(c(Baseline, TML)) %>% as.matrix()
                  y = foldi %>%  select(truth) %>% as.matrix()
                  mdl = glmnet(x,y, lambda=0, lower.limits=0, intercept=FALSE)
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
                  newx = .y %>%  select(c(Baseline, TML)) %>% as.matrix()
                  .y %>% mutate(response = predict(.x, newx = newx) %>% as.vector) 
                }) %>%
                  select(molecule_id,id,truth,response,fold)
                
                new_preds %>% write_csv(paste0(path_predictions_test, "preds_did_", did, ".csv"))
                
                TRUE
              } 

cat("\nAll done!\n")

