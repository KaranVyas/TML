#!/usr/bin/Rscript --vanilla
#  nohup ./scr02_openml_base_models_DNN.R > ../logs/scr02_openml_base_models_DNN.log &

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
file_splits = paste0(path_proj, "data_splits/datasets_splits.csv")

path_predictions = paste0(path_proj, "predictions/")
#dir.create(path_predictions, recursive = T)

dsets = inner_join(
  read_csv(file_splits),
  read_csv(file_datasets),
  by = c("rows_id" = "openml_task", "flow")
)

#-----------Issues
dsets = dsets %>% filter(flow != "weka.ZeroR")

dsets = split(dsets, dsets$flow)

do_everything = function(dset, did) {
  timestamp()
  cat("Dataset : ", did, "...")
  
  dsplit = dset %>% select(rows_id, fold) %>%
     mutate(id = 1:n())
  
  resp = dset %>% pull(area_under_roc_curve)
  dset = dset %>% select(-c(flow, rows_id, fold, area_under_roc_curve)) %>% as.matrix()
  
  # dirty normalisation
  # dset = apply(dset, 2, function(cl) {
  #   maxr = max(cl)
  #   if(maxr == 0) return(cl)
  #   cl/maxr
  # })
  
  #browser()
  dset = scale(dset)
  dset = dset[, !apply(dset, 2, function(x) all(is.nan(x)))]
  
  # dset = apply(dset, 2, function(cl) {
  #   meanr = mean(cl)
  #   sdr = sd(cl)
  #   
  #   cl/maxr
  # })
  
  batch_size = ifelse(nrow(dset) < 100, nrow(dset), 100)
  epochs = 100
  
  k_clear_session()
  preds = map(1:10, function(foldi) {
    trn = dsplit %>% filter(fold != foldi)
    tst = dsplit %>% filter(fold == foldi)
    resp_trn = resp[(trn %>% pull(id))]
    dset_trn = dset[(trn %>% pull(id)), ]
    resp_tst = resp[(tst %>% pull(id))]
    dset_tst = dset[(tst %>% pull(id)), ]
    
    mdl = build_net(nvars = ncol(dset))
    
    mdl_split_fname = "tmp_mdl.h5" #weights only?
    save_best_model = callback_model_checkpoint(
      filepath = mdl_split_fname,
      save_best_only = T,
      save_weights_only = T
    )
    
    mdl %>% fit(
      dset_trn,
      resp_trn,
      batch_size = batch_size,
      epochs = epochs,
      validation_data = list(dset_tst, resp_tst),
      callbacks = list(save_best_model),
      verbose = 0
    )
    #browser()
    mdl %>% load_model_weights_hdf5(mdl_split_fname)
    #browser()
    list(
      train = trn %>% mutate(
        fold = foldi,
        truth = resp_trn,
        response = (mdl %>% predict(dset_trn))[, 1]
      ),
      test = tst %>% mutate(
        fold = foldi,
        truth = resp_tst,
        response = (mdl %>% predict(dset_tst))[, 1]
      )
    )
    
  })
  
  res = bind_rows(
      preds %>% map_dfr( ~ .x$train) %>% mutate(set = "train"),
      preds %>% map_dfr( ~ .x$test) %>% mutate(set = "test")
    ) %>% mutate(flow = did)
    #write_csv(paste0(path_predictions_train, "preds_did_", did, ".csv"))
  
   #%>%
    #write_csv(paste0(path_predictions_test, "preds_did_", did, ".csv"))
  
  cat("DONE\n")
  #browser()
  res
}

preds_all = imap_dfr(dsets, do_everything)
preds_all %>% filter(set == "train") %>% select(-set) %>%
  write_csv(paste0(path_predictions, "split_train_base_DNN.csv"))
preds_all %>% filter(set == "test") %>% select(-set) %>%
  write_csv(paste0(path_predictions, "split_test_base_DNN.csv"))
