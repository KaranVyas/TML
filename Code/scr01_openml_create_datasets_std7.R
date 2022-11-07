rm(list = ls())
library(farff)
library(tidyverse)

data_dir = "/home/shared/openml_stdy07/"

dsets = readARFF(paste0(data_dir, "raw/study_7_area_under_roc_curve__joint.arff"))

dsets = dsets  %>% 
  mutate(flow = str_remove_all(flow, "classif.")) %>% 
  separate(col = flow, into = c("flow", "rest"), sep = "_") %>%
  filter(complete.cases(.)) %>%
  select(openml_task, flow, area_under_roc_curve, NumberOfBinaryFeatures:NumberOfNumericFeatures)


dsets1 = dsets %>% group_by(openml_task, flow) %>%
  summarise(area_under_roc_curve = mean(area_under_roc_curve)) %>% ungroup()

dsets = dsets %>% distinct(openml_task, flow, .keep_all = T) %>%
  select(-area_under_roc_curve)

dsets = inner_join(dsets1, dsets)

dir.create(paste0(data_dir, "data/"))
write_csv(dsets, paste0(data_dir, "data/original_datasets.csv"))

