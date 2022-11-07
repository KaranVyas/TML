
library(tidyverse)
data_top = read_rds("/home/shared/1911TML/outputs/2007_molecules_top.rds")

# 1% 384123 = 3841
top_1 = data_top %>% slice(1:3841)

top_1 = top_1 %>% pivot_wider(id_cols = molecule_id,
                              names_from = target_id,
                              values_from = pred_act,
                              values_fill = list(pred_act = 0))
top_1 %>% write_csv("/home/shared/1911TML/outputs/200716_molecules_top1.csv")


## top10

top_10 = data_top %>% slice(1:38412)

#########################
# Code added the 20/10/20
top_10 %>% write_csv('/home/shared/1911TML/outputs/201020_top10_long.csv')
#
########################

top_10 = top_10 %>% pivot_wider(id_cols = molecule_id,
                              names_from = target_id,
                              values_from = pred_act,
                              values_fill = list(pred_act = 0))
top_10 %>% write_csv("/home/shared/1911TML/outputs/200922_molecules_top10.csv")
