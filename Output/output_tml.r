library(Metrics)
precision_error = read.csv("/Users/karan/OneDrive/Desktop/TML/201020/predictions_tml.csv")
select = precision_error[,c(4,5,6)]

select <- within(select, precision_error <- (abs((truth - response))/truth)*100 )
#select <- within(select, RMSE <- rmse(truth,response))

write.csv(select,"/Users/karan/OneDrive/Desktop/TML/Output/output_tml_csv.csv", row.names = FALSE)

y=mean(select[,4])
print(y)
