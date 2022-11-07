# QSAR models

n_dat <- list.files('/home/shared/1911TML/models/base/full_data/RF/')
n_lrns <- list.files('/home/shared/1911TML/models/base/full_data/')

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

dsets %>% distinct(flow) %>% nrow()
