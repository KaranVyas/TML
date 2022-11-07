rm(list = ls())
library(tidyverse)

algorithms = c("RF", "SVM", "KNN", "DNN", "XGB") #, "Ridge")
meta = c("base", "transformed", "stackedridge", "nnls")

path_project = "/home/shared/openml_stdy07/"
path_predictions = paste0(path_project, "predictions/")
prefix_fnam = "split_test_"

file_names = list.files(path_predictions, pattern = prefix_fnam)

perf_df = tibble(filename = file_names) %>%
  mutate(meta_alg = str_remove_all(filename, paste0(prefix_fnam,"|.csv"))) %>%
  separate(meta_alg, into = c("meta_alg", "algorithm")) %>%
  filter(meta_alg %in% meta, algorithm %in% algorithms)

# Load predictions file
perf_df = map_dfr(perf_df$filename, ~ {
  read_csv(paste0(path_predictions, .x), col_types = cols(
    flow = col_character(),
    id = col_double(),
    truth = col_double(),
    response = col_double(),
    fold = col_double(),
    rows_id = col_character()
  )) %>%
    mutate(filename = .x)
}) %>%
  inner_join(perf_df)
head(perf_df)

# prediction error
perf_df = perf_df %>% mutate(err = (truth - response)^2)

# RMSE and NRMSE / fold
perf_df = perf_df %>% group_by(meta_alg, algorithm, flow, fold) %>%
  summarise(
    rmse = sqrt(sum(err)/n()),
    truth_max = max(truth),
    truth_min = min(truth),
    nrmse = rmse/(truth_max-truth_min)
  ) %>% 
  group_by(meta_alg, algorithm, flow) %>% 
  summarise(
    rmse = mean(rmse),
    nrmse = mean(nrmse)
  )

ggplot(perf_df, aes(x = algorithm, y = rmse, colour = meta_alg)) + geom_boxplot()
ggplot(perf_df, aes(x = algorithm, y = nrmse, colour = meta_alg)) + geom_boxplot()

# SUmmary of model performance
perf_df %>% group_by(meta_alg, algorithm) %>% 
  summarise(rmse_Mean = mean(rmse, na.rm = T),
            rmse_SD = sd(rmse,na.rm = T),
            nrmse_Mean = mean(nrmse, na.rm = T),
            nrmse_SD = sd(nrmse,na.rm = T)) %>% View()


##### Tests:
#paired_t
data_pairedt = perf_df %>% ungroup() %>%
  filter(meta_alg %in% c("base", "transformed") &
           algorithm %in% c("RF", "SVM", "KNN")) %>% 
  mutate(newID = paste(algorithm, flow, sep = "_")) %>%
  select(newID, meta_alg, rmse) %>%
  spread(meta_alg, rmse) %>%
  separate(newID, into = c("algorithm", "flow"))

data_pairedt %>% split(., .$algorithm) %>%
  map(~ t.test(x = .x$base, y = .x$transformed, paired = T))

data_pairedt %>% split(., .$algorithm) %>%
  map(~ wilcox.test(x = .x$base, y = .x$transformed, paired = T))

# sign test
data_signt = data_pairedt %>%
  mutate(winner = ifelse(base < transformed, "base", "transformed"))


data_signt %>% 
  select(algorithm, winner) %>%
  table() %>% as_tibble() %>%
  split(., .$algorithm) %>%
  map(~ binom.test(x = .x$n))
