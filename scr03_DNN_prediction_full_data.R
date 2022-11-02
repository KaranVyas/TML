#!/usr/bin/Rscript --vanilla
#  nohup ./scr03_DNN_prediction_full_data.R > ../logs/scr03_DNN_prediction_full_data.log &

rm(list = ls())

library(tidyverse)
library(keras)

learner_id = "DNN"

path_proj = "/home/shared/1911TML/"
path_legacy_data = paste0(path_proj, "legacy/")
path_models_full = paste0(path_proj, "models/base/full_data/", learner_id, "/")
path_predictions = paste0(path_proj, "predictions/base/full_data/", learner_id, "/")
path_predictions_tmp = paste0(path_predictions, "tmp/")
dir.create(path_predictions_tmp, recursive = T)


mdl_fnames = list.files(path_models_full)
dids = str_remove_all(mdl_fnames, "mdl_did_|.h5")

#target info
dsets_info = read_csv(paste0(path_proj, "datasets_info.csv"))
targs_id = dsets_info$target_id[dsets_info$target_id %in% dids]

# fingerprint data
dat_fingp = read_rds(paste0(path_legacy_data, "fingp_tbl_170510.rda"))
mol_ids = dat_fingp$molecule_id
dat_fingp = dat_fingp %>% select(-molecule_id) %>% as.matrix

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

mdl = build_net()

make_predict = function(didx) {
  cat("Dataset : ", didx, "...")
  mdl %>% load_model_weights_hdf5(paste0(path_models_full, "mdl_did_", didx, ".h5"))
  preds = tibble(target_id = didx,
                 molecule_id = mol_ids,
                 value = (mdl %>% predict(dat_fingp))[, 1]
  )
  write_rds(preds, paste0(path_predictions_tmp, "preds_targ_", didx, ".rds"))
  cat("DONE\n")
  preds
}

preds_all = map_dfr(dids, make_predict)

#---------------
#file_names = list.files(path_predictions_tmp, full.names = T)
#preds_all = map_dfr(file_names, read_rds)
#---------------
write_rds(preds_all, paste0(path_predictions, "preds_full_data_", learner_id, ".rds"))
cat("\nDONE!\n")
