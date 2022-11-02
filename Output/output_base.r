library(Metrics)
precision_error = read.csv("/Users/karan/OneDrive/Desktop/TML/201020/predictions_base.csv")
select = precision_error[,c(4,5,6)]

select <- within(select, precision_error <- (abs((truth - response))/truth)*100 )
#select <- within(select, RMSE <- rmse(truth,response))

write.csv(select,"/Users/karan/OneDrive/Desktop/TML/Output/output_select.csv", row.names = FALSE)

x = mean(select[,4])
print(x)
#sprintf("Mean Error is %f", x)
