rm(list = ls())

library(mlr)
library(tidyverse)

set.seed(123)

path_proj = "/home/shared/openml_stdy07/"

path_predictions = paste0(path_proj, "predictions/")

# learner
#learners_id = c("RF", "SVM", "KNN", "Ridge")
learners_id = "DNN"

#walk(learners_id, ~{ 
  preds = read_csv(paste0(path_predictions, "full_base_", .x, ".csv"))
  
  preds = preds %>% split(.,.$flow)
  preds = map(preds, function(predx) {
    predx %>% spread(key = flow_col, value = response)
  })
  .x = learners_id
  write_rds(preds, paste0(path_proj, "data/transformed_datasets_",.x, ".rds"))
#})



