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
zip.train.data[,1] = factor(zip.train.data[,1]) # changement format resultat

# passage d'un output a 10 classes de sortie (le nombre 0,1,2,...,9)
training.output = class.ind(zip.train.data[,1])
training.input = zip.train.data[,2:257]

# changement de nom des sorties
names_output = colnames(training.output)
names_output = paste('out.',sep = "", names_output )
colnames(training.output) = names_output

n <- names(zip.train.data[,2:257])
f <- as.formula(paste(paste(names_output[1:10], collapse = " + "), sep = " ~ ", paste(n[!n %in% "class"], collapse = " + ")))
fbis <- as.formula(paste("V1", sep = " ~ ", paste(n[!n %in% "class"], collapse = " + ")))
# Regroupement des donnees d'entree et de sortie
training.data <- cbind(training.input,training.output)

###########################################################################
######################### Réseau de neuronnes ############################# 
###########################################################################

# Optimisation du reseau de neuronnes a partir du training set
nnet = neuralnet(formula = f, data = training.data, hidden = 50, linear.output=FALSE, lifesign="full", lifesign.step=500)

net.prediction <- compute(nnet, zip.test.data[,2:257]) 
net.prediction = net.prediction[[2]]
net.prediction.bis =(0:9)[apply(net.prediction,1,which.max)]
confusion.net = table(net.prediction.bis ,zip.test.data[,1])
write.table(confusion.net, "confusion.net", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

net.test  = (net.prediction.bis == zip.test.data[,1]) 
correct.net = mean(net.test)

###########################################################################
######################### Approche Bayesienne ############################# 
###########################################################################

num.pixels <- 256

# Apprentissage : calcul de la moyenne et de l'écart type pour les gaussiennes
mea = matrix(data=0, nr=num.pixels, nc=10)
std = matrix(data=0, nr=num.pixels, nc=10)
for (k in 1:10) {
  belong = (zip.train.data[,1]==(k-1))
  aux = zip.train.data[belong, 2:257]
  for (i in 1:num.pixels) {
    mea[i,k] = mean(aux[,i])
    std[i,k] = sd(aux[,i])+0.0001
  }  
}

# Test
nb.tests <- 2007
proba = matrix(data=1, nr=nb.tests, nc=10)
for (t in 1:nb.tests) {
  for (i in 1:num.pixels) {
    proba[t,] = proba[t,] * pnorm(zip.test.data[t,i+1],mean=mea[i,],sd=std[i,])
  } 
}  

# Recuperation des valeurs estimees
m <- apply(proba,1,max)
res = matrix(data=-1, nr=nb.tests, nc=1)
for (t in 1:nb.tests) {
  res[t] = which (proba[t,] == m[t]) - 1
}
# Calcul de l'erreur
bay.test = (res == zip.test.data[,1])
correct.bay = mean(comparaison)

###########################################################################
########################## Decision Tree / Random Forest ################## 
###########################################################################

## Decision tree 
# Generation de l'arbre
tree = rpart(fbis,zip.train.data,method = "class")

printcp(tree)
#visualisation de l'arbre
plot(tree) 
text(tree)

# Test des donnees de la base de test
tree.prediction = predict(tree, zip.test.data[,2:257], type = "class")
# Calcul de l'erreur
tree.test = (tree.prediction == zip.test.data[,1])
correct.tree = mean(tree.test)

# Affichage matrice de confusion
confusion.tree = table(tree.prediction, zip.test.data[,1])
#write.table(confusion.tree, "confusion.tree", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

## Random Forest
forest = randomForest(fbis, zip.train.data ,method = "class", ntree = 200)

forest.prediction = predict(forest, zip.test.data[,2:257])
forest.test = (forest.prediction == zip.test.data[,1])
correct.forest = mean(forest.test)
# Confusion
confusion.forest = table(forest.prediction, zip.test.data[,1])
#write.table(confusion.forest, "confusion.forest", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

# Foret plus grande
forest1 = randomForest(fbis, zip.train.data ,method = "class", ntree = 500)
forest1.prediction = predict(forest1, zip.test.data[,2:257])
forest1.test = (forest1.prediction == zip.test.data[,1])
correct.forest1 = mean(forest1.test)
confusion.forest1 = table(forest1.prediction, zip.test.data[,1])
#write.table(confusion.forest1, "confusion.forest1", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

###########################################################################
########################## Support Vector Machine (SVM) ################### 
###########################################################################

# SVM a noyau lineaire
svm.lineaire = ksvm(fbis, data =zip.train.data ,type = "C-svc", kernel = "vanilladot")
svm.lineaire.prediction = predict(svm.lineaire, zip.test.data[,2:257])
svm.lineaire.test = (svm.lineaire.prediction == zip.test.data[,1])
correct.svmlin = mean(svm.lineaire.test)

confusion.svm.lineaire = table(svm.lineaire.prediction ,zip.test.data[,1])
write.table(confusion.svm.lineaire, "confusion.svm.lineaire", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

# SVM a noyau polynomial
svm.poly = ksvm(fbis, data =zip.train.data ,type = "C-svc", kernel = "polydot", kpar=list(degree=4))
svm.poly.prediction = predict(svm.poly, zip.test.data[,2:257])
svm.poly.test = (svm.poly.prediction == zip.test.data[,1])
correct.svmpoly = mean(svm.poly.test)

correct.svmpoly2 = correct.svmpoly
correct.svmpoly3 = correct.svmpoly

confusion.svm.poly = table(svm.poly.prediction ,zip.test.data[,1])
write.table(confusion.svm.poly, "confusion.svm.poly", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

# SVM a noyau gaussien
svm.gaussian = ksvm(fbis, data =zip.train.data ,type = "C-svc", kernel = "rbfdot", kpar=list(sigma=0.002))
svm.gaussian.prediction = predict(svm.gaussian, zip.test.data[,2:257])
svm.gaussian.test = (svm.gaussian.prediction == zip.test.data[,1])
correct.svmgaus = mean(svm.gaussian.test)

confusion.svm.gauss = table(svm.gaussian.prediction ,zip.test.data[,1])
write.table(confusion.svm.gauss, "confusion.svm.gauss", row.names = FALSE, col.names = FALSE, sep="&", dec=".")

# SVM a noyau bessel
svm.bessel = ksvm(fbis, data =zip.train.data ,type = "C-svc", kernel = "besseldot", kpar=list(sigma=0.1, order = 1, degree = 1))
svm.bessel.prediction = predict(svm.bessel, zip.test.data[,2:257])
svm.bessel.test = (svm.bessel.prediction == zip.test.data[,1])
correct.svmbes = mean(svm.bessel.test)

confusion.svm.bess = table(svm.bessel.prediction ,zip.test.data[,1])
write.table(confusion.svm.bess, "confusion.svm.bess", row.names = FALSE, col.names = FALSE, sep="&", dec=".")
