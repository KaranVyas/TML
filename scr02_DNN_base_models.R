#!/usr/bin/Rscript --vanilla
#  nohup ./scr02_DNN_base_models.R > ../logs/scr02_DNN_base_models.log &

rm(list = ls())

library(mlr)
library(tidyverse)
library(keras)

learner_id = "DNN"

path_proj = "/home/shared/1911TML//"
path_datasets = paste0(path_proj, "datasets/originals/")
path_splits = paste0(path_proj, "data_splits/")
path_models_full = paste0(path_proj, "models/base/full_data/",learner_id,"/")
dir.create(path_models_full, recursive = T)
path_models_split = paste0(path_proj, "models/base/split_data/",learner_id,"/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/base/split_data/",learner_id,"/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/base/split_data/",learner_id,"/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))


build_net = function(nvars = 1024) {
  mdl = keras_model_sequential() %>%
    layer_dense(units = 700, activation = "relu",
                input_shape = nvars) %>%
    layer_dropout(rate = 0.3) %>%
    layer_dense(units = 100, activation = "relu") %>%
    layer_dropout(rate = 0.4) %>%
    layer_dense(units = 1)
  
  mdl %>% compile(
    loss = "mse",
    optimizer = "rmsprop",
    metrics = list("mean_squared_error")
  )
  mdl
}

do_everything = function(did) {
  cat("Dataset : ", did, "...")
  dset = read_csv(
    paste0(path_datasets, "data_", did, ".csv"),
    col_types = cols(
      .default = col_double(),
      target_id = col_character(),
      molecule_id = col_character()
    )
  )
  dsplit = read_csv(
    paste0(path_splits, "data-split_", did, ".csv"),
    col_types = cols(rows_id = col_character(),
                     fold = col_double())
  ) %>% rename(molecule_id = rows_id)
  
  dsplit = dset %>% select(molecule_id) %>%
    mutate(id = 1:n()) %>%
    inner_join(dsplit, .)
  
  resp = dset %>% pull(pXC50)
  dset = dset %>% select(starts_with("b")) %>% as.matrix()
  
  # model - full data
  mdl = build_net()
  batch_size = ifelse(nrow(dset) < 50, nrow(dset), 40)
  epochs = 40
  mdl_full_fname = paste0(path_models_full, "mdl_did_", did, ".h5") #weights only?
  save_best_model = callback_model_checkpoint(
    filepath = mdl_full_fname,
    save_best_only = T,
    save_weights_only = T
  )
  mdl %>% fit(
    dset,
    resp,
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2,
    shuffle = TRUE,
    callbacks = list(save_best_model),
    verbose = 0
  )
  
  preds = map(1:10, function(foldi) {
    trn = dsplit %>% filter(fold != foldi)
    tst = dsplit %>% filter(fold == foldi)
    resp_trn = resp[(trn %>% pull(id))]
    dset_trn = dset[(trn %>% pull(id)), ]
    resp_tst = resp[(tst %>% pull(id))]
    dset_tst = dset[(tst %>% pull(id)), ]
    #browser()
    mdl = build_net()
    
    mdl_split_fname = paste0(path_models_split, "XXXmdl_did_", did, ".h5") #weights only?
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
    
    mdl %>% load_model_weights_hdf5(mdl_split_fname)
    
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
  
  preds %>% map_dfr( ~ .x$train) %>%
    write_csv(paste0(path_predictions_train, "preds_did_", did, ".csv"))
  
  preds %>% map_dfr( ~ .x$test) %>%
    write_csv(paste0(path_predictions_test, "preds_did_", did, ".csv"))
  
  cat("DONE\n")
}

walk(data_info$target_id, do_everything)

cat("All done!")
