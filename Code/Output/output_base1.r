library(Metrics)
precision_error = read.csv("C:/Users/karan/OneDrive/Desktop/TML/Data/201020/predictions_tml.csv")
select = precision_error[,c(4,5,6)]

select <- within(select, precision_error <- (abs((truth - response))/truth)*100 )
#select <- within(select, RMSE <- rmse(truth,response))

write.csv(select,"C:/Users/karan/OneDrive/Desktop/TML/Code/Output/output_base1_csv.csv", row.names = FALSE)

y=mean(select[,4])
#sprintf("Mean Error : %f", y)
print(y)

