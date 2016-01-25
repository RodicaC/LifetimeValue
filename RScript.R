getwd()
setwd("C:/Users/rodica.coderie/Documents/Rodica/SIEN")

# exploring the data
summaryTrain<- read.csv("summaryTrain.csv", header = T)
head(summaryTrain)
names(summaryTrain)
nrow(summaryTrain)
ncol(summaryTrain)
str(summaryTrain)
head(summaryTrain)
tail(summaryTrain)
table(summaryTrain$country_code)
table(summaryTrain$os)
library(dplyr)
select(summaryTrain, country_code) %>% unique %>% nrow
summary(summaryTrain$no_features)

ranking <- group_by(summaryTrain, country_code) %>%
  summarize(usersN = sum(users)) %>%
  as.data.frame %>%
  arrange(desc(usersN))
head(ranking,10)

# Questions
# 1. Which countries generate the majority of events?
# 2. Is the average lifetime influenced by the no of events?
# 3. Is the no of times a features has been active correlated with the no of websites?


TrainData<- read.csv("train2.csv", header = T)
# basic statistic about the training data
dim(TrainData)
class(TrainData)
names(TrainData)
head(TrainData)
nrow(TrainData)
ncol(TrainData)
str(TrainData)

## extract version
substrLast <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x)-1)
}
substrLast(as.character(head(TrainData$os)), 2)

is.null(TrainData[TrainData$userid=='00095067-A385-42A4-91B7-0CE49AFBE0D2',]$os)
TrainData[TrainData$userid=='00095067-A385-42A4-91B7-0CE49AFBE0D2',]$os=='NULL'
nrow(TrainData[TrainData$os=='NULL',])

#remove NULL os values from training data
TrainData <- TrainData[!(TrainData$os=='NULL'),]
TrainData <- TrainData[!(TrainData$os=='NULL'),]
select(TrainData, userid) %>% unique %>% nrow

#adding os version
TrainData$os_version <- as.factor(substrLast(as.character(TrainData$os), 2))

# exploratory analysis
summary(TrainData$range)
fivenum(TrainData$range)

boxplot(TrainData$range, col="blue")
abline(h=10.27)
#no outliners

summary(TrainData$no_website)
fivenum(TrainData$no_website)
boxplot(TrainData$no_website, col="red")
abline(h=24.52)
#some outliners over 1000
filter(TrainData, no_website > 1000)


hist(TrainData$range, col="green")
rug(TrainData$range)
abline(v=10.27, lwd=2)
abline(v=median(TrainData$range), col="magenta", lwd=4)

#relationship between os_version and no of users
barplot(table(TrainData$os_version), col="wheat", main="No of users in each win version")
# most popular versions are 4 and 5

#relationship between os_version and lifetime
boxplot(range ~ os_version, data = TrainData, col = "red")


# relationship between lifetime and no of events
with(TrainData, plot(range, no_events))
 abline(h = 12, lwd = 2, lty = 2)

# relationship between no_websites and active features
with(TrainData, plot(no_website, active_features))
abline(h = 12, lwd = 2, lty = 2)

with(TrainData, plot(range, no_events, col = os_version))
abline(h = 12, lwd = 2, lty = 2)

#Multiple Scatterplots
par(mfrow = c(2, 2), mar = c(5, 4, 2, 1))
with(subset(TrainData, os_version == '6'), plot(range, no_website, main = "Version 6"))
with(subset(TrainData, os_version == '5'), plot(range, no_website, main = "Version 5"))
with(subset(TrainData, os_version == '4'), plot(range, no_website, main = "Version 4"))
with(subset(TrainData, os_version == '2'), plot(range, no_website, main = "Version 2"))

#clustering the data using kmeans
set.seed(1234)
kmeansObj <- kmeans(TrainData[,c(3:6)], centers=3)
names(kmeansObj)
kmeansObj$size
kmeansObj$centers


set.seed(1234)
kmeansObj <- kmeans(TrainData[,c(3:6)], centers=5)
names(kmeansObj)
kmeansObj$size
kmeansObj$centers

# Pearson correlation
cor(TrainData[,c(3:6)], use="complete.obs")
#cor(TrainData[,c(3:6)], use="complete.obs", method="kendall")

# check correlation between lifetime and os version
model.lm <- lm(TrainData$range ~ TrainData$os_version, data = TrainData)
summary(model.lm)
# version2 has a lifetime with 3.76 days smaller than the estimated intercept (we can consider intercept as average lifetime)
# version6 has a iifetime with 2.8 days larger than the estimated intercept
# we can see this variation also in the boxplot above (line 84)
# still, becase R-squared is almost null, we can say that os version is not explaining the model


# estimate relationship betwwen lifetime and no of websites visites
library(ggplot2)
g = ggplot(TrainData, aes(x = no_website , y = range))
g = g + xlab("No of websites")
g = g + ylab("Lifetime")
g = g + geom_point(size = 5, colour = "black", alpha=0.5)
g = g + geom_point(size = 3, colour = "blue", alpha=0.2)
g = g + geom_smooth(method = "lm", colour = "black")
g

fit <- lm(range ~ no_website, data = TrainData)
coef(fit)
# we expect 1 day increase in lifetime for each new website visit

fit2 <- lm(range ~ active_features, data = TrainData)
coef(fit2)
# there is almost no influence between lifetime and no of time a features has been active

fit3 <- lm(range ~ no_events, data = TrainData)
coef(fit3)
# there is almost no influence between lifetime and no of time a features has been active

TestData <- read.csv("test.csv", header = T)
TestData <- TestData[!(TestData$os=='NULL'),]
#adding os version
TestData$os_version <- as.factor(substrLast(as.character(TestData$os), 2))

TestData$rangePredict <- predict(fit, newdata = data.frame(no_website = TestData$no_website))
head(TestData)
