library(Metrics)
precision_error = read.csv("C:/Users/karan/OneDrive/Desktop/TML/Data/201020/prediction_tml_base.csv")
select = precision_error[,c(4,5,6,7)]
#print(select)

select <- within(select, precision_error <- (abs((truth - response))/truth)*100 )
#select <- within(select, RMSE <- rmse(truth,response))

write.csv(select,"C:/Users/karan/OneDrive/Desktop/TML/Code/Output/output_tml+base1_csv.csv", row.names = FALSE)

x = mean(select[,4])
print(x)
#sprintf("Mean Error : %f", x)
#sprintf("Mean Error is %f", x)