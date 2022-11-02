rm(list = ls())

library(tidyverse)
library(mlr)

algorithms = c("RF", "SVM", "KNN", "DNN")
algorithms = c("DNN")
algorithms = c("XGB")

meta = c("base", "transformed")
names(meta) = meta

path_project = "/home/shared/openml_stdy07/"
path_predictions = paste0(path_project, "predictions/")

lrn = makeLearner("regr.cvglmnet")
lrn = setHyperPars(lrn, alpha = 0, nfolds = 3)

get_data = function(algorithm, subset = "test") {
  map_dfr(meta,
          ~ read_csv(
            paste0(path_predictions, "split_", subset, "_", .x, "_", algorithm, ".csv"),
            col_types = cols(
              flow = col_character(),
              id = col_double(),
              truth = col_double(),
              response = col_double(),
              fold = col_double(),
              rows_id = col_character()
            )
          ), .id = "meta_alg") %>%
    spread(key = "meta_alg", value = "response") %>%
    split(., .$flow)
}


pred_model = function(train_df, test_df) {
  cat("dataset = ", train_df$flow[1], "\n")
  train_df = train_df %>% split(., .$fold)
  test_df = test_df %>% split(., .$fold)
  map2_dfr(train_df, test_df, ~{
    tsk = makeRegrTask(data = (.x %>% select(base, transformed, truth) %>% as.data.frame()), target = "truth")
    mdl = train(lrn, tsk)
    newx = .y %>%  select(c(base, transformed)) %>% as.data.frame()
    .y %>% mutate(response = predict(mdl, newdata = newx)$data$response) 
  })
}

walk(algorithms, function(algox){
  train_lst = get_data(algorithm = algox, subset = "train")
  test_lst = get_data(algorithm = algox, subset = "test")
  preds = map2_dfr(train_lst, test_lst, pred_model)
  preds %>% 
    select(-c(base, transformed)) %>%
    write_csv(paste0(path_predictions, "split_test_stackedridge_", algox, ".csv"))
})

#------ RIDGE DIDN'T WORK AS BASE PREDICTIONS ARE CONSTANT!!!!

