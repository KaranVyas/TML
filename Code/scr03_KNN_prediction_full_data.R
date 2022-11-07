#!/usr/bin/Rscript --vanilla
#  nohup ./scr03_KNN_prediction_full_data.R > ../logs/scr03_KNN_prediction_full_data.log &

library(mlr)
library(tidyverse)

library(foreach)
library(doParallel)

set.seed(123, "L'Ecuyer")

cl <- makeCluster(10)
registerDoParallel(cl)

learner_id = "KNN"

path_proj = "/home/shared/1911TML/"
path_legacy_data = paste0(path_proj, "legacy/")
path_models_full = paste0(path_proj, "models/base/full_data/",learner_id,"/")
path_predictions = paste0(path_proj, "predictions/base/full_data/",learner_id,"/")
path_predictions_tmp = paste0(path_predictions, "tmp/")
dir.create(path_predictions_tmp, recursive = T)


mdl_fnames = list.files(path_models_full)
dids = str_remove_all(mdl_fnames, "mdl_did_|.rds")

#target info
dsets_info = read_csv(paste0(path_proj, "datasets_info.csv"))
targs_id = dsets_info$target_id[dsets_info$target_id %in% dids]

# fingerprint data
dat_fingp = read_rds(paste0(path_legacy_data, "fingp_tbl_170510.rda"))
mol_ids = dat_fingp$molecule_id
dat_fingp = dat_fingp %>% select(-molecule_id) %>% as.data.frame

cat("\nmaking predictions...")
pred_all = foreach(tid = targs_id, mdl_fnx = mdl_fnames, .combine = "rbind", 
              .packages = c("mlr","dplyr", "purrr", "readr"),
              .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %dopar% {    #DOPAR !!!
    configureMlr(show.info = F, on.learner.error = "warn", show.learner.output = F)
    mdl = read_rds(paste0(path_models_full, mdl_fnx))
    preds = tibble(target_id = tid,
           molecule_id = mol_ids,
           value = (predict(mdl, newdata = dat_fingp))$data$response
    )
    #browser()
    write_rds(preds, paste0(path_predictions_tmp, "preds_targ_", tid, ".rds"))
    preds
}

pred_all = foreach(tid = targs_id, mdl_fnx = mdl_fnames, .combine = "rbind", 
                   .packages = c("mlr","dplyr", "purrr", "readr"),
                   .errorhandling = "remove",.options.multicore=list(preschedule=FALSE)) %do% {    #DOPAR !!!
                       #configureMlr(show.info = F, on.learner.error = "warn", show.learner.output = F)
                       # mdl = read_rds(paste0(path_models_full, mdl_fnx))
                       # preds = tibble(target_id = tid,
                       #                molecule_id = mol_ids,
                       #                value = (predict(mdl, newdata = dat_fingp))$data$response
                       # )
                       # #browser()
                       # write_rds(preds, paste0(path_predictions_tmp, "preds_targ_", tid, ".rds"))
                       preds = read_rds(paste0(path_predictions_tmp, "preds_targ_", tid, ".rds"))
                       preds
                   }

write_rds(pred_all, paste0(path_predictions, "preds_full_data_KNN.rds"))
cat("\nDONE!\n")