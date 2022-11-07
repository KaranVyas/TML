#!/usr/bin/Rscript --vanilla
#  nohup ./scr05_create_DNN_transf_models.R > ../logs/scr05_create_DNN_transf_models.log &

rm(list = ls())

library(tidyverse)
library(keras)

learner_id = "DNN"

path_proj = "/home/shared/1911TML/"
path_datasets = paste0(path_proj, "datasets/transformed/",learner_id,"/")
path_splits = paste0(path_proj, "data_splits/")
path_models_full = paste0(path_proj, "models/transformed/full_data/",learner_id,"/")
dir.create(path_models_full, recursive = T)
path_models_split = paste0(path_proj, "models/transformed/split_data/",learner_id,"/")
dir.create(path_models_split, recursive = T)
path_predictions_train = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/train/")
dir.create(path_predictions_train, recursive = T)
path_predictions_test = paste0(path_proj, "predictions/transformed/split_data/",learner_id,"/test/")
dir.create(path_predictions_test, recursive = T)

data_info = read_csv(paste0(path_proj, "datasets_info.csv"))


build_net = function(nvars = 1024) {    #NVARS
  mdl = keras_model_sequential() %>%
    layer_dense(units = 700, activation = "relu",
                input_shape = nvars) %>%
    #layer_activity_regularization(l1=0.0001) %>%
    layer_dropout(rate = 0.4) %>%
    #layer_dense(units = 350, activation = "relu") %>%
    #layer_activity_regularization(l1=0.0001) %>%
    #layer_dropout(rate = 0.3) %>%
    layer_dense(units = 1)
  
  mdl %>% compile(
    loss = "mse",
    optimizer = "adam",
    metrics = list("mean_squared_error")
  )
  mdl
}

do_everything = function(did) {
  timestamp()
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
  
  #browser()
  resp = dset %>% pull(pXC50)
  dset = dset %>% select(starts_with("CHEMBL")) %>% as.matrix()
  
    batch_size = ifelse(nrow(dset) < 100, nrow(dset), 100)
  epochs = 300
  
  k_clear_session()
  preds = map(1:10, function(foldi) {
    trn = dsplit %>% filter(fold != foldi)
    tst = dsplit %>% filter(fold == foldi)
    resp_trn = resp[(trn %>% pull(id))]
    dset_trn = dset[(trn %>% pull(id)), ]
    resp_tst = resp[(tst %>% pull(id))]
    dset_tst = dset[(tst %>% pull(id)), ]
    
    # normalisation
    #dset_trn = scale(dset_trn)
    #col_means_train = attr(dset_trn, "scaled:center")
    #col_stddevs_train = attr(dset_trn, "scaled:scale")
    #dset_tst = scale(dset_tst, center = col_means_train, scale = col_stddevs_train)
    
    dset_trn = dset_trn / 12
    dset_tst = dset_tst /12
    #browser()
    
    mdl = build_net(nvars = ncol(dset))
    
    mdl_split_fname = paste0(path_models_split, "mdl_did_", did, ".h5") #weights only?
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
  
  preds %>% map_dfr( ~ .x$train) %>%
    write_csv(paste0(path_predictions_train, "preds_did_", did, ".csv"))
  
  preds %>% map_dfr( ~ .x$test) %>%
    write_csv(paste0(path_predictions_test, "preds_did_", did, ".csv"))
  
  cat("DONE\n")
}

# timestamp()
#do_everything(data_info$target_id[100])
# timestamp()

walk(data_info$target_id, do_everything)

cat("All done!")

