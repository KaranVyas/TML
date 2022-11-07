# !/usr/bin/Rscript --vanilla
#  nohup ./scr02_openml_base_models.R > ../logs/scr02_openml_base_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)

set.seed(123)

path_proj = "/home/shared/openml_stdy07/"
file_splits = paste0(path_proj, "data_splits/datasets_splits.csv")

# learner
learners = list(RF = makeLearner("regr.ranger"),
                SVM = makeLearner("regr.ksvm"),
                KNN = makeLearner("regr.fnn"),
                Ridge = makeLearner("regr.cvglmnet"))

learners$Ridge = setHyperPars(learners$Ridge, alpha = 0, nfolds = 3)

dset_split = read_csv(file_splits)

#-----------Issues
dset_split = dset_split %>% filter(flow != "weka.ZeroR")

dset_split = dset_split %>% split(., .$flow)

cv_train = function(taskx, dset_splitx, lrnx, .folds = 10) {
  
  mdls = map(1:.folds, ~{
    subs_trn = which(dset_splitx$fold != .x)
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

path_predictions = paste0(path_proj, "predictions/")

cat("\nCreating the models...")
tmp = foreach(lrnx = learners, lrn_id = names(learners)) %do% {
  
  cat("learner = ", lrn_id, "...")
  dsets = read_rds(paste0(path_proj, "data/transformed_datasets_",lrn_id, ".rds"))
  
  dset_names = names(dsets)
  
  dsets = map2(dset_split, dsets, ~ {
    inner_join(.x, .y, by = c("rows_id" = "openml_task", "flow")) %>%
      rename(area_under_roc_curve = truth)
  })
  
  tasks = imap(dsets, ~ {
    .x %>% select(-c(flow, rows_id, fold)) %>% as.data.frame() %>%
      makeRegrTask(id = .y, data = ., target = "area_under_roc_curve")
  })
  names(tasks) = dset_names
  
  mdls = map2(tasks, dset_split, cv_train, lrnx = lrnx)
  
  preds_all_trn = pmap_dfr(list(tasks, dset_split, mdls),
                           cv_pred,
                           .test = F,
                           .id = "flow")
  write_csv(preds_all_trn,
           paste0(path_predictions, "split_train_transformed_", lrn_id, ".csv"))
  preds_all_tst = pmap_dfr(list(tasks, dset_split, mdls),
                           cv_pred,
                          .test = T,
                          .id = "flow")
  write_csv(preds_all_tst,
           paste0(path_predictions, "split_test_transformed_", lrn_id, ".csv"))
  cat("DONE\n")
  TRUE
}


