library(Metrics)
precision_error = read.csv("/Users/karan/OneDrive/Desktop/TML/Data/201020/prediction_mtl_tml.csv")
select = precision_error[,c(4,5,6,7)]

select <- within(select, precision_error <- (abs((truth - response))/truth)*100 )
#select <- within(select, RMSE <- rmse(truth,response))

write.csv(select,"C:/Users/karan/OneDrive/Desktop/TML/Code/Output/output_mtl+tmls1_csv.csv", row.names = FALSE)

x = mean(select[,4])
print(x)
#sprintf("Mean Error : %f", x)
#sprintf("Mean Error is %f", x)