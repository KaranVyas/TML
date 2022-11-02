rm(list = ls())

library(tidyverse)

learner = "DNN"
strategy = "stackednnls"

path_proj = "/home/shared/1911TML/"
path_predictions = paste0(path_proj, "predictions/")
pathx = paste0(path_predictions, strategy, "/split_data/", learner, "/test/")
did_files = list.files(pathx)
names(did_files) = str_remove_all(did_files, "preds_did_|.csv")
pred_data = map_dfr(did_files, function(filx){
  paste0(path_predictions, strategy, "/split_data/", learner, "/test/", filx) %>% 
    read_csv(col_types = cols(
      molecule_id = col_character(),
      fold = col_double(),
      id = col_double(),
      truth = col_double(),
      response = col_double()
    ))
}, .id = "target_id")

pred_data = pred_data %>% mutate(sqerr = (truth - response)^2)

path_perf = paste0(path_proj, "performance/")
dir.create(path_perf, recursive = T)

pred_data %>% group_by(target_id, fold) %>%
  summarise(rmse = sqrt(sum(sqerr)/n()),
            truth_max = max(truth),
            truth_min = min(truth),
            nrmse = rmse / (truth_max - truth_min)) %>%
  write_csv(paste0(path_perf, "perf_", strategy, "_", learner, ".csv"))
