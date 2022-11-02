rm(list = ls())

library(tidyverse)

learners = c("RF/") #, "SVM/")
names(learners) = c("RF") #, "SVM")

strategies = c("base/", "transformed/")
names(strategies) = c("Baseline", "TML")

path_proj = "/home/shared/1911TML/"
path_predictions = paste0(path_proj, "predictions/")
path_predictions_test = paste0(path_predictions, "average/split_data/RF/test/")
dir.create(path_predictions_test, recursive = T)

pred_data = map_dfr(strategies, function(strx){
  map_dfr(learners, function(lrnx){
    pathx = paste0(path_predictions, strx, "split_data/", lrnx, "test/")
    did_files = list.files(pathx)
    names(did_files) = str_remove_all(did_files, "preds_did_|.csv")
    map_dfr(did_files, function(filx){
      paste0(path_predictions, strx, "split_data/", lrnx, "test/", filx) %>% 
        read_csv(col_types = cols(
          molecule_id = col_character(),
          fold = col_double(),
          id = col_double(),
          truth = col_double(),
          response = col_double()
        ))
    }, .id = "dataset_id")
    
  }, .id = "learner")
}, .id = "strategy")

pred_data = pred_data %>% spread(key = "strategy", value = "response") %>% 
  mutate(response = (Baseline + TML) / 2)

pred_data = pred_data %>% split(., .$dataset_id)

iwalk(pred_data, ~ {
  .x %>% select(molecule_id, fold, id, truth, response) %>%
    write_csv(paste0(path_predictions_test, "preds_did_", .y, ".csv"))
})
