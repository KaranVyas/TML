rm(list = ls())

library(mlr)
library(tidyverse)
library(foreach)
set.seed(123)

path_proj = "/home/shared/openml_stdy07/"
file_datasets = paste0(path_proj, "data/original_datasets.csv")

dsets = read_csv(file_datasets)

#-----------Issues
dsets = dsets %>% filter(flow != "weka.ZeroR")

# dsets_split = split(dsets, dsets$flow)
# tasks = imap(dsets_split, ~ {
#   .x %>% select(-c(flow, openml_task)) %>% as.data.frame() %>%
#     makeRegrTask(id = .y, data = ., target = "area_under_roc_curve")
# })
# names(tasks) = names(dsets_split)

path_predictions = paste0(path_proj, "predictions/")
dir.create(path_predictions, recursive = T)

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
learners = list(XGB = lrn_full)


cat("\nCreating the models...")

dsets_id = dsets %>% pull(flow) %>% unique(.)
names(dsets_id) = dsets_id

tmp = foreach(lrnx = learners, lrn_id = names(learners)) %do% {     #DOPAR!!!
  cat("learner = ", lrn_id, "...")
  
  mdls = imap(dsets_id, function(x,y){
    dsets %>% filter(flow == x) %>%
      select(-c(flow, openml_task)) %>% as.data.frame() %>%
      makeRegrTask(id = y, data = ., target = "area_under_roc_curve") %>%
      train(learner = lrnx, task = .)
      
  })
  
  preds = map2_dfr(dsets_id, mdls, function(x,y){
    cat(x, "\n")
    dset_f = dsets %>% filter(flow != x)
    predx = dset_f %>% select(flow, openml_task) 
    #browser()
    dset_f = dset_f %>% select(-c(flow, openml_task)) %>%
      as.data.frame() %>%
      predict(y, newdata = .)
    predx = bind_cols(predx, dset_f$data)
  }, .id = "flow_col")
  write_csv(preds, paste0(path_predictions, "full_base_", lrn_id, ".csv"))
  cat("DONE\n")
  TRUE
}
