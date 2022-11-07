#!/usr/bin/Rscript --vanilla
#  nohup ./scr02_openml_base_models.R > ../logs/scr02_openml_base_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)

 library(foreach)
# library(doParallel)

set.seed(123)

# cl <- makeCluster(4)
# registerDoParallel(cl)

path_proj = "/home/shared/openml_stdy07/"
file_datasets = paste0(path_proj, "data/original_datasets.csv")
file_splits = paste0(path_proj, "data_splits/datasets_splits.csv")

dsets = inner_join(
  read_csv(file_splits),
  read_csv(file_datasets),
  by = c("rows_id" = "openml_task", "flow")
)

#-----------Issues
dsets = dsets %>% filter(flow != "weka.ZeroR")

dsets = split(dsets, dsets$flow)
tasks = imap(dsets, ~ {
  .x %>% select(-c(flow, rows_id, fold)) %>% as.data.frame() %>%
    makeRegrTask(id = .y, data = ., target = "area_under_roc_curve")
})
names(tasks) = names(dsets)

subsets = map(dsets, ~ .x %>% select(flow, rows_id, fold))
names(subsets) = names(dsets)

path_predictions = paste0(path_proj, "predictions/")
dir.create(path_predictions, recursive = T)
#file_pred_train = paste0(path_predictions, "base_train.csv")
#file_pred_test = paste0(path_predictions, "base_test.csv")

# learner
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

#learners$Ridge = setHyperPars(learners$Ridge, alpha = 0, nfolds = 3)

cv_train = function(taskx, subsetx, lrnx, .folds = 10) {
  mdls = map(1:.folds, ~{
    subs_trn = which(subsetx$fold != .x)
    train(learner = lrnx, task = taskx, subset = subs_trn)
  })
}

cv_pred = function(taskx, subsetx, mdlx, .test = TRUE, .folds = 10) {
  cat("task = ", taskx$task.desc$id, "\n")
  preds = map_dfr(1:.folds, ~{
    if(.test) subs = which(subsetx$fold == .x)
    else subs = which(subsetx$fold != .x)
    pred = (predict(mdlx[[.x]], task = taskx, subset = subs))$data
    pred %>% mutate(fold = .x)
  })
  preds %>% mutate(rows_id = subsetx$rows_id[preds$id])
}

cat("\nCreating the models...")
tmp = foreach(lrnx = learners, lrn_id = names(learners),
              .packages = c("mlr","dplyr", "purrr"),
              .errorhandling = "remove",
              .options.multicore=list(preschedule=FALSE)) %do% {     #DOPAR!!!
  cat("learner = ", lrn_id, "...")
  mdls = map2(tasks, subsets, cv_train, lrnx = lrnx)
  preds_all_trn = pmap_dfr(list(tasks, subsets, mdls), cv_pred, .test = F, .id = "flow")
  write_csv(preds_all_trn, paste0(path_predictions, "split_train_base_", lrn_id, ".csv"))
  preds_all_tst = pmap_dfr(list(tasks, subsets, mdls), cv_pred, .test = T, .id = "flow")
  write_csv(preds_all_tst, paste0(path_predictions, "split_test_base_", lrn_id, ".csv"))
  cat("DONE\n")
  TRUE
}
  
