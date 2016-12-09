# G. Lever & D. Leydier
# All rights reserved

library('neuralnet')
library('nnet')
library('rpart')
library('randomForest')
library('kernlab')

# Importation des données
zip.test.data = read.table("zip.test", header=FALSE, sep=" ", dec=".")
zip.train.data = read.table("zip.train", header=FALSE, sep=" ", dec=".")

# Concernant la première colonne on ne veut pas savoir le chiffre mais si c'est un 7 ou non
for (k in 1:7291) {
  zip.train.data[k,1] = (zip.train.data[k,1]==7)
}

for (k in 1:2007) {
  zip.test.data[k,1] = (zip.test.data[k,1]==7)
}

zip.train.data[,1] = factor(zip.train.data[,1]) # changement format resultat

# passage d'un output a 2 classes de sortie (le nombre 0 (pas un 7) et 1 (c'est un 7))
training.output = class.ind(zip.train.data[,1])
training.input = zip.train.data[,2:257]

# changement de nom des sorties
names_output = colnames(training.output)
names_output = paste('out.',sep = "", names_output )
colnames(training.output) = names_output

n <- names(zip.train.data[,2:257])
f <- as.formula(paste(paste(names_output[1:2], collapse = " + "), sep = " ~ ", paste(n[!n %in% "class"], collapse = " + ")))
fbis <- as.formula(paste("V1", sep = " ~ ", paste(n[!n %in% "class"], collapse = " + ")))
# Regroupement des donnees d'entree et de sortie
training.data <- cbind(training.input,training.output)

###########################################################################
######################### Réseau de neuronnes ############################# 
###########################################################################

# Optimisation du reseau de neuronnes a partir du training set
nnet7 = neuralnet(formula = f, data = training.data, hidden = 50, algorithm='rprop+', linear.output=FALSE, lifesign="full", lifesign.step=500)

net.prediction <- compute(nnet7, zip.test.data[,2:257]) 
net.prediction = net.prediction[[2]]
net.prediction.bis =(0:9)[apply(net.prediction,1,which.max)]
confusion.net = table(net.prediction.bis ,zip.test.data[,1])

net.test7  = (net.prediction.bis == zip.test.data[,1]) 
correct.net7 = mean(net.test7)

###########################################################################
########################## Support Vector Machine (SVM) ################### 
###########################################################################

# SVM a noyau polynomial
svm.poly7 = ksvm(fbis, data =zip.train.data ,type = "C-svc", kernel = "polydot", kpar=list(degree=4))
svm.poly.prediction7 = predict(svm.poly7, zip.test.data[,2:257])
svm.poly.test7 = (svm.poly.prediction7 == zip.test.data[,1])
correct.svmpoly7 = mean(svm.poly.test7)

confusion.svm7 = table(svm.poly.prediction7 ,zip.test.data[,1])
