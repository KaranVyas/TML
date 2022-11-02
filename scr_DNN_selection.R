rm(list = ls())

pred_vers = c("200415", "200427")
names(pred_vers) = pred_vers

library(tidyverse)

path_proj = "/home/shared/1911TML/"

perfs = map(pred_vers, ~ read_csv(paste0(path_proj, "DNN_perfs/perf_transformed_DNN_", .x, ".csv")))
perfs[[1]] %>% head()

perfs = inner_join(perfs[[1]], perfs[[2]], by = c("target_id", "fold"))
perfs %>% head()

perfs = perfs %>%
  mutate(rmse = ifelse(rmse.x < rmse.y, rmse.x, rmse.y),
         nrmse = ifelse(rmse.x < rmse.y, nrmse.x, nrmse.y)) %>%
  select(target_id, fold, rmse, truth_max = truth_max.x, truth_min = truth_min.x, nrmse)
perfs %>% head()  

path_perf = paste0(path_proj, "performance/")
learner = "DNN"
strategy = "transformed"
write_csv(perfs, paste0(path_perf, "perf_", strategy, "_", learner, ".csv"))
