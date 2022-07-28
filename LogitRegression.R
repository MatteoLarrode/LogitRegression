# Coursework Term 2 - Part I - QUESTION A

#Prep Work & Packages ####
setwd("~/m_larrode_pols0010/")
load("Coursework_Term2_Part1/2022essay_q1.Rda")
sentences <- a

library(boot)#inv.logit
library(pROC)#roc
library(ggplot2)
library(ggthemes)
library(AICcmodavg)#aictab()
library(mfx)#marginal effects
library(arm)#sim
library(boot)
library(ggeffects)

#Model selection ####
#logit model (all initial variables)
mod0 <- glm(data=sentences, sentences~age + sex + urban + leftright + married + wclass + hincome + university,family=binomial(link="logit"))
summary(mod0)

#variable selection 1: remove 'age' & 'wclass'

#variable selection 2: AIC comparison
mod1 <- glm(data=sentences, sentences~ sex + married  + urban + leftright + hincome + university,family=binomial(link="logit"))
summary(mod1)

mod.no.sex <-  glm(data=sentences,
                   sentences~ married + urban + leftright  + hincome + university, 
                   family=binomial(link="logit"))
mod.no.married<- glm(data=sentences,
                     sentences~ sex + urban + leftright  + hincome + university, 
                     family=binomial(link="logit"))
mod.no.urban<- glm(data=sentences,
                   sentences~ sex +married  + leftright  + hincome + university, 
                   family=binomial(link="logit"))
mod.no.leftright<- glm(data=sentences,
                       sentences~sex +married  + urban + hincome + university, 
                       family=binomial(link="logit"))
mod.no.hincome<- glm(data=sentences,
                     sentences~sex + married  + urban + leftright  + university, 
                     family=binomial(link="logit"))
mod.no.university<- glm(data=sentences,
                        sentences~sex +married + urban + leftright  + hincome, 
                        family=binomial(link="logit"))

models <- list(mod1,mod.no.sex, mod.no.married, mod.no.urban, mod.no.leftright, mod.no.hincome, mod.no.university)
mod.names <- c('mod1','mod.no.sex','mod.no.married','mod.no.urban','mod.no.leftright','mod.no.hincome', 'mod.no.university')

aictab(cand.set = models, modnames = mod.names)


#variable selection 2: confusion matrix + ROC (area under the curve)

#split data 
training.rows <- sample(nrow(sentences),(nrow(sentences)/2))
training.data <- sentences[training.rows,]
test.data <- sentences[-training.rows,]

#estimate logit models on training data
mod2 <- glm(data=training.data, sentences~married + urban + leftright  + hincome + university, family=binomial(link="logit"))
summary(mod2)

mod.reduced <- glm(data=training.data,sentences~urban + leftright+ hincome + university,family=binomial(link="logit"))
summary(mod.reduced)

#predictions on test data
mod2.probs.test <- predict(mod2,test.data, type="response")
mod2.preds.test <- ifelse(mod2.probs.test>0.5,1,0)
mod.reduced.probs.test <- predict(mod.reduced, test.data, type="response")
mod.reduced.preds.test <- ifelse(mod.reduced.probs.test>0.5,1,0)

#confusion matrices
mod2.matrix<-table(mod2.preds.test, test.data$sentences)
mod2.matrix
round((mod2.matrix[1,2]+mod2.matrix[2,1])/nrow(test.data)*100,2) # Error rate
round(mod2.matrix[2,2]/(mod2.matrix[1,2]+mod2.matrix[2,2])*100,2) # Sensitivity
round(mod2.matrix[1,1]/(mod2.matrix[1,1]+mod2.matrix[2,1])*100,2) # Specificity

mod.reduced.matrix<-table(mod.reduced.preds.test, test.data$sentences)
mod.reduced.matrix
round((mod.reduced.matrix[1,2]+mod.reduced.matrix[2,1])/nrow(test.data)*100,2) # Error rate
round(mod.reduced.matrix[2,2]/(mod.reduced.matrix[1,2]+mod.reduced.matrix[2,2])*100,2) # Sensitivity
round(mod.reduced.matrix[1,1]/(mod.reduced.matrix[1,1]+mod.reduced.matrix[2,1])*100,2) # Specificity

rocplot <- roc(test.data$sentences,mod2.probs.test)
plot(rocplot,legacy.axes=T)
rocplot$auc

rocplot.reduced <- roc(test.data$sentences,mod.reduced.probs.test)
plot(rocplot.reduced,legacy.axes=T)
rocplot.reduced$auc


#with ggplot
data.roc <- data.frame("sensitivity"=rocplot$sensitivities, "one.minus.specificity"=1-rocplot$specificities)
data.roc <- data.roc[order(data.roc$sensitivity),]

ggplot(data.roc,aes(x=one.minus.specificity, y=sensitivity)) +
  geom_step(direction="vh") +
  geom_abline(slope=1,intercept=0,linetype="dotted") +
  scale_x_continuous(breaks = seq(0,1,by=0.2)) +
  scale_y_continuous(breaks = seq(0,1,by=0.2))  +
  theme_bw() +
  ylab("Sensistivity") + 
  xlab("1-Specificity") +
  ggtitle("ROC Curve")

#Final model:
mod <- glm(data=sentences,
           sentences ~ urban + leftright  + hincome + university, 
           family=binomial(link="logit"))


#Logit Regression Analysis ####

#1)sign of coeff: inferences about direction of relationship btwn Pr(Y=1) & independent variable

#2)impact of independent variables: 

#Average Marginal Effects (vs. M.E at the mean)
logitmfx(data=sentences, mod, atmean = FALSE)

#Changes in Predicted Probabilities
#Statistical significance = Pseudo-Bayesian Approach (//Simulation)

sentences.sims <- sim(mod,n.sims=1000)
coefs <- coef(sentences.sims)

#types 
values.low.inc <- c(1,
                    urban=0,
                    mean(sentences$leftright, na.rm=TRUE),
                    hincome = 1,
                    university=0)

values.mid.inc <- c(1,
                    urban=0,
                    mean(sentences$leftright, na.rm=TRUE),
                    hincome = 5,
                    university=0)

values.high.inc <- c(1,
                     urban=0,
                     mean(sentences$leftright, na.rm=TRUE),
                     hincome = 10,
                     university=0)

values.left.wing <- c(1,
                      urban=0,
                      leftright = 1,
                      mean(sentences$hincome),
                      university=0)

values.right.wing <- c(1,
                       urban=0,
                       leftright = 5,
                       mean(sentences$hincome),
                       university=0)

values.rural.noeduc <- c(1,
                         urban=0,
                         mean(sentences$leftright, na.rm=TRUE),
                         mean(sentences$hincome),
                         university=0)

values.urban.noeduc <- c(1,
                         urban=1,
                         mean(sentences$leftright, na.rm=TRUE),
                         mean(sentences$hincome),
                         university=0)

values.rural.educ <- c(1,
                       urban=0,
                       mean(sentences$leftright, na.rm=TRUE),
                       mean(sentences$hincome),
                       university=1)





#predictions
pred.low.inc <- inv.logit(values.low.inc %*% t(coefs))
pred.high.inc <- inv.logit(values.high.inc %*% t(coefs))
pred.mid.inc <- inv.logit(values.mid.inc %*% t(coefs))

pred.left.wing <- inv.logit(values.left.wing %*% t(coefs))
pred.right.wing <- inv.logit(values.right.wing %*% t(coefs))

pred.rural.noeduc <- inv.logit(values.rural.noeduc %*% t(coefs))
pred.urban.noeduc <- inv.logit(values.urban.noeduc %*% t(coefs))
pred.rural.educ <- inv.logit(values.rural.educ %*% t(coefs))
pred.urban.educ <- inv.logit(values.urban.educ %*% t(coefs))


#differences (income) relative to middle 
diff.income1 <- pred.low.inc - pred.mid.inc
mean(diff.income1) #0.04
quantile(diff.income1, c(0.025,0.975))

diff.income2 <- pred.high.inc - pred.mid.inc
mean(diff.income2) #-0.06
quantile(diff.income2, c(0.025,0.975))

diff.income3 <-  pred.low.inc - pred.high.inc
mean(diff.income3) #0.10
quantile(diff.income3, c(0.025,0.975))


#plot uncertainty of differences in predicted probabilities (95% CI)
proba.changes <- data.frame(
  "characteristics" = as.factor(c('Low Income (1st decile)', 'High Income (10th decile)')),
  "diff" = c(mean(diff.income1), mean(diff.income2)),
  "ciLB" = c(quantile(diff.income1, 0.025), 
             quantile(diff.income2, 0.025)),
  "ciUB" = c(quantile(diff.income1, 0.95), 
             quantile(diff.income2, 0.95)))

ggplot(proba.changes, aes(x=diff, y=characteristics))+
  geom_point(col="red", size=2)+
  geom_errorbar(aes(xmin=ciLB, xmax=ciUB),col="red", width =0.1, size=1)+
  geom_vline(xintercept = 0, linetype="dashed")+
  theme_bw() + xlab("") + ylab("") +
  ggtitle("Fig.2 - Predicted Differences in Probabilities of Supporting Longer Prison Sentences Relative to Median Household Income")+
  theme(axis.text = element_text(size=10),plot.title = element_text(size=12))


#differences in political orientation
diff.pol <- pred.right.wing - pred.left.wing
mean(diff.pol)#0.12
quantile(diff.pol, c(0.025,0.975))


#differences relative to non-urban / not-educated
diff.urban <- pred.urban.noeduc - pred.rural.noeduc
mean(diff.urban) #0.050
quantile(diff.urban, c(0.025,0.975))

diff.educ <- pred.rural.educ - pred.rural.noeduc
mean(diff.educ) #-0.214
quantile(diff.educ, c(0.025,0.975)) 
#results for binary IV are coherent with average marginal effects


#odd ratios
summary(mod)
cbind(coef(mod), exp(coef(mod)))
#BUT odd ratios less intuitive than changes in predicted probabilities