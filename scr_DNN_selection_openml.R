rm(list = ls())

pred_vers = c("1", "2")
names(pred_vers) = pred_vers

library(tidyverse)

path_proj = "/home/shared/openml_stdy07/"

perfs = map(pred_vers, ~ read_csv(paste0(path_proj, "predictions_DNN_tmp/split_test_transformed_DNN-", .x, ".csv")))
perfs[[1]] %>% head()

perfs = inner_join(perfs[[1]], perfs[[2]], by = c("flow","rows_id", "fold"))
perfs %>% head()

perfs = perfs %>%
  mutate(response = ifelse(((truth.x - response.x)^2) < ((truth.x - response.y)^2), response.x, response.y)) %>%
  select(rows_id, fold, id = id.x, truth = truth.x, response, flow)
perfs %>% head()  

write_csv(perfs, "/home/shared/openml_stdy07/predictions/split_test_transformed_DNN.csv")

perfs = map(pred_vers, ~ read_csv(paste0(path_proj, "predictions_DNN_tmp/split_train_transformed_DNN-", .x, ".csv")))
perfs[[1]] %>% head()

perfs = inner_join(perfs[[1]], perfs[[2]], by = c("flow","rows_id", "fold"))
perfs %>% head()

perfs = perfs %>%
  mutate(response = ifelse(((truth.x - response.x)^2) < ((truth.x - response.y)^2), response.x, response.y)) %>%
  select(rows_id, fold, id = id.x, truth = truth.x, response, flow)
perfs %>% head()  

write_csv(perfs, "/home/shared/openml_stdy07/predictions/split_train_transformed_DNN.csv")
