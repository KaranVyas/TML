rm(list = ls())

pred_vers = c("200415", "200427")
names(pred_vers) = pred_vers

library(tidyverse)

path_proj = "/home/shared/1911TML/"
path_predictions = paste0(path_proj, "predictions/transformed/split_data/")

learner_id = "DNN"

path_models_split = paste0(path_proj, "models/transformed/split_data/",learner_id,"/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))

walk(data_info$target_id, ~ {
  pred1 = read_csv(paste0(path_predictions, "DNN_200415/test/preds_did_", .x, ".csv"), 
                   col_types = cols(
                     molecule_id = col_character(),
                     .default = col_double()
                   ))
  pred2 = read_csv(paste0(path_predictions, "DNN_200427/test/preds_did_", .x, ".csv"), 
                   col_types = cols(
                     molecule_id = col_character(),
                     .default = col_double()
                   ))
  pred = inner_join(pred1, pred2, by = "molecule_id") %>%
    #mutate(response = (response.x + response.y)/2) %>%
    mutate(response = ifelse(((truth.x - response.x)^2) < ((truth.x - response.y)^2), response.x, response.y)) %>%
    select(molecule_id, fold = fold.x, id = id.x, truth = truth.x, response) %>%
    write_csv(paste0(path_predictions, "DNN/test/preds_did_", .x, ".csv"))
})

walk(data_info$target_id, ~ {
  pred1 = read_csv(paste0(path_predictions, "DNN_200415/train/preds_did_", .x, ".csv"), 
                   col_types = cols(
                     molecule_id = col_character(),
                     .default = col_double()
                   ))
  pred2 = read_csv(paste0(path_predictions, "DNN_200427/train/preds_did_", .x, ".csv"), 
                   col_types = cols(
                     molecule_id = col_character(),
                     .default = col_double()
                   ))
  pred = inner_join(pred1, pred2, by = "molecule_id") %>%
    #mutate(response = (response.x + response.y)/2) %>%
    mutate(response = ifelse(((truth.x - response.x)^2) < ((truth.x - response.y)^2), response.x, response.y)) %>%
    select(molecule_id, fold = fold.x, id = id.x, truth = truth.x, response) %>%
    write_csv(paste0(path_predictions, "DNN/train/preds_did_", .x, ".csv"))
})
