rm(list = ls())

path_proj_perf = "/home/shared/1911TML/performance/"

library(tidyverse)
perf_df = tibble(
  fname = list.files(path_proj_perf) 
  ) %>%
  mutate(meta_learner = str_remove_all(fname, "perf_|.csv")) %>%
  separate(meta_learner, into = c("meta_learner", "learner"), sep = "_", remove = F)


perf_data = map_dfr(perf_df$fname, ~ {
  paste0(path_proj_perf, .x) %>% read_csv() %>%
    mutate(fname = .x)
})
perf_data = inner_join(perf_df, perf_data)

# drop rows with NAs and infties
perf_data = perf_data %>% filter(truth_min>=0 & truth_max<15 & !is.na(nrmse) & !is.infinite(nrmse) & nrmse < 1 )


#write_csv(perf_data, "/home/shared/1911TML/outputs/2004_model_performance_qsars.csv")

#------------ base NN
#perf_data %>% filter(meta_learner == "base", learner == "DNN") %>% 
#  write_csv("/home/shared/1911TML/outputs/2004_model_performance_qsars_base_DNN.csv")
#------------ END base NN


# target_id_complete = perf_data %>% filter(learner != "Ridge" )%>% 
#   select(learner, target_id, fold, meta_learner, rmse) %>%
#   spread(meta_learner, rmse) %>% filter(complete.cases(.)) %>% 
#   distinct(target_id) %>%
#   pull(target_id)

#perf_data %>% ggplot(aes(x = nrmse)) + geom_histogram()

perf_data_sum = perf_data %>% group_by(meta_learner, learner, target_id) %>% 
  summarise(rmse_mean = mean(rmse, na.rm = T),
            rmse_sd = sd(rmse,na.rm = T),
            nrmse_mean = mean(nrmse, na.rm = T),
            nrmse_sd = sd(nrmse,na.rm = T)) %>%
  filter(!is.na(rmse_sd) & !is.na(nrmse_sd))

### BEGIN
# 15/02/21
# comparison XGB, to be removed when finsihed
#chid_xgb <- perf_data_sum %>% filter(learner == "XGB") %>% pull(target_id)
#perf_data_sum <- perf_data_sum %>% filter(target_id %in% chid_xgb)
### END

# SUmmary of model performance
perf_data_sum %>% group_by(meta_learner, learner) %>% 
  summarise(rmse_Mean = mean(rmse_mean, na.rm = T),
            rmse_SD = sd(rmse_mean,na.rm = T),
            nrmse_Mean = mean(nrmse_mean, na.rm = T),
            nrmse_SD = sd(nrmse_mean,na.rm = T)) %>% View()



#-------------- Summary for 14-4-20 meeting
perf_data_sum %>% 
  filter(!(meta_learner == "transformed" & learner == "DNN")) %>%
  group_by(meta_learner, learner) %>% 
  summarise(rmse_Mean = mean(rmse_mean, na.rm = T),
            rmse_SD = sd(rmse_mean,na.rm = T),
            nrmse_Mean = mean(nrmse_mean, na.rm = T),
            nrmse_SD = sd(nrmse_mean,na.rm = T))
#-------------- END Summary for 14-4-20 meeting

# boxplots
perf_data_sum %>% 
  ggplot(aes(x = learner, y = nrmse_mean, colour = meta_learner)) + geom_boxplot()


# perf improvement
perf_data_spread = perf_data_sum %>% 
  select(meta_learner, learner, target_id, rmse_mean) %>%
  spread(meta_learner, rmse_mean)

perf_data_spread %>%
  mutate(change_base_transformed = (base - transformed)/base * 100,
         change_base_stacked = (base - stackednnls)/base * 100,
         change_base_average = (base - average)/base * 100) %>%
  group_by(learner) %>%
  summarise(change_base_transformed_mean = mean(change_base_transformed, na.rm = T),
            change_base_stacked_mean = mean(change_base_stacked, na.rm = T),
            change_base_average_mean = mean(change_base_average, na.rm = T))

# sign test
perf_data_spread %>% 
  mutate(best_model = ifelse(base<transformed, "Baseline", "TML")) %>%
  select(learner, best_model) %>% table()

# statistics
perf_data_sta = perf_data %>% select(meta_learner, learner, target_id, fold, rmse) %>%
  spread(meta_learner, rmse)

tid_drop = perf_data_sta %>% 
  group_by(learner, target_id) %>%
  summarise(N = n()) %>% filter(N<=5) %>% pull(target_id)

perf_data_sta = perf_data_sta %>% filter(!(target_id %in% tid_drop)) %>%
  filter(learner %in% c("RF", "SVM", "KNN", "DNN") & !is.na(base) & !is.na(transformed))

perf_data_sta = perf_data_sta %>%
  group_by(learner, target_id) %>%
  summarise(pval = (t.test(x = base, y = transformed))$p.value,
            perf_diff = mean(base, na.rm = T) - mean(transformed, na.rm = T),
            best_model = factor(ifelse(pval > 0.05, "No difference", 
                                ifelse(perf_diff>0, "TML", "Baseline"))))


table(perf_data_sta$learner, perf_data_sta$best_model)


##### Tests:
#paired_t
data_pairedt = perf_data_sum %>% ungroup() %>%
  filter(meta_learner %in% c("base", "transformed") &
           learner %in% c("RF", "SVM", "KNN", "DNN")) %>% 
  mutate(newID = paste(learner, target_id, sep = "_")) %>%
  select(newID, meta_learner, rmse_mean) %>%
  spread(meta_learner, rmse_mean) %>%
  separate(newID, into = c("learner", "target_id"))

data_pairedt %>% split(., .$learner) %>%
  map(~ t.test(x = .x$base, y = .x$transformed, paired = T))

data_pairedt %>% split(., .$learner) %>%
  map(~ wilcox.test(x = .x$base, y = .x$transformed, paired = T))

# sign test
data_signt = data_pairedt %>%
  mutate(winner = ifelse(base < transformed, "base", "transformed"))

#library(BSDA)

data_signt %>% 
  select(learner, winner) %>%
  table() %>% as_tibble() %>%
  split(., .$learner) %>%
  map(~ binom.test(x = .x$n))
  


### ------------ TEST WITH DNN 15-04-20
targid_dnn = perf_data_sum %>% filter(meta_learner == "transformed", learner == "DNN") %>% pull(target_id)
perf_data_sum %>% group_by(meta_learner, learner) %>% 
  filter(target_id %in% targid_dnn) %>%
  summarise(rmse_Mean = mean(rmse_mean, na.rm = T),
            rmse_SD = sd(rmse_mean,na.rm = T),
            nrmse_Mean = mean(nrmse_mean, na.rm = T),
            nrmse_SD = sd(nrmse_mean,na.rm = T)) %>% View()
