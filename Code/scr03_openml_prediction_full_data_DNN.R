rm(list = ls())

library(keras)
library(tidyverse)

build_net = function(nvars = 1024) {    #NVARS
  mdl = keras_model_sequential() %>%
    layer_dense(units = 20, activation = "relu",
                input_shape = nvars) %>%
    #layer_activity_regularization(l1=0.01) %>%
    layer_dropout(rate = 0.4) %>%
    #layer_dense(units = 10, activation = "relu") %>%
    #layer_activity_regularization(l1=0.0001) %>%
    #layer_dropout(rate = 0.3) %>%
    #layer_dense(units = 10, activation = "relu") %>%
    #layer_activity_regularization(l1=0.0001) %>%
    #layer_dropout(rate = 0.3) %>%
    layer_dense(units = 1)
  
  mdl %>% compile(
    loss = "mse",
    optimizer = optimizer_adam(lr = 0.1),
    metrics = list("mean_squared_error")
  )
  mdl
}

set.seed(123)

path_proj = "/home/shared/openml_stdy07/"
file_datasets = paste0(path_proj, "data/original_datasets.csv")

dsets = read_csv(file_datasets)

#-----------Issues
dsets = dsets %>% filter(flow != "weka.ZeroR")

path_predictions = paste0(path_proj, "predictions/")
dir.create(path_predictions, recursive = T)

cat("\nCreating the models...")

dsets_id = dsets %>% pull(flow) %>% unique(.)
names(dsets_id) = dsets_id


preds = map_dfr(dsets_id, function(x){
  cat(x, "\n")
  dset = dsets %>% filter(flow == x)
  resp = dset %>% pull(area_under_roc_curve)
  dset = dset %>% select(-c(flow, openml_task, area_under_roc_curve)) %>% as.matrix()
  
  dset = scale(dset)
  cent = attr(dset, "scaled:center")
  scl = attr(dset, "scaled:scale")
  
 # browser()
  todrop = apply(dset, 2, function(x) all(is.nan(x)))
  dset = dset[, !todrop]
  cent = cent[!todrop]
  scl = scl[!todrop]
  
  dset_f = dsets %>% filter(flow != x)
  resp_f = dset_f %>% pull(area_under_roc_curve)
  
  predx = dset_f %>% select(flow, openml_task)
  
  dset_f = dset_f %>% select(-c(flow, openml_task, area_under_roc_curve)) %>% as.matrix()
  dset_f = dset_f[, !todrop]
  dset_f = scale(dset_f, center = cent, scale = scl)
  
  batch_size = ifelse(nrow(dset) < 100, nrow(dset), 100)
  epochs = 80
  
  k_clear_session()
  
  mdl = build_net(nvars = ncol(dset))
  
  mdl_split_fname = "tmp_mdl.h5" #weights only?
  save_best_model = callback_model_checkpoint(
    filepath = mdl_split_fname,
    save_best_only = T,
    save_weights_only = T
  )
  
  mdl %>% fit(
    dset,
    resp,
    batch_size = batch_size,
    epochs = epochs,
    validation_data = list(dset_f, resp_f),
    callbacks = list(save_best_model),
    verbose = 0
  )
  #browser()
  mdl %>% load_model_weights_hdf5(mdl_split_fname)
  
  predx = predx %>%
    mutate(truth = resp_f, 
           response = (mdl %>% predict(dset_f))[, 1]
           )
 
  }, .id = "flow_col")

write_csv(preds, paste0(path_predictions, "full_base_DNN.csv"))
cat("DONE\n")

