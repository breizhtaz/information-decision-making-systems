# -*- coding: utf-8 -*-
"""
Created on Fri Nov 20 09:43:04 2015

Some basic use of the Sklearn library on the US postal problem 

@author: Gweltaz
"""

###############################################################################
# Imports
###############################################################################

import pdb
import csv
import numpy as np
import pandas as pd
import sklearn.decomposition as dec
import sklearn.feature_selection as fs
import sklearn.svm as svm
import sklearn.neighbors as neig
import sklearn.tree as tree
import sklearn.ensemble as ens

###############################################################################
# Global variables
###############################################################################

TRAINING = './data/train.csv'
TEST = './data/test.csv'


###############################################################################
# Import images
###############################################################################

train_data = pd.read_csv(TRAINING)
train = train_data.iloc[:, 1:].values 
label = train_data[[0]].values
test = pd.read_csv(TEST).values

#pdb.set_trace()
# Reshape if necessary training and test set in 28x28 (no single line anymore)
label = label.astype(np.uint8)
train = train.astype(np.uint8)
test = test.astype(np.uint8)
#train = np.array(train).reshape((-1,28,28)).astype(np.uint8)
print 'Training and testing data loaded'

# splitting training and test set
train1 = train[0:21000]
label1 =label[0:21000].ravel()
test1 = train[21000:]
label_test = label[21000:].ravel()

###############################################################################
# Preprocessing - Dimensionality reduction
###############################################################################

# Feature selection


## PCA : principal components analysis
#print 'Starting PCA ...'
#pca = dec.PCA(n_components=40, whiten=True)
#pca.fit(train1)
#train2 = pca.transform(train1)
#test2 = pca.transform(test1)
#print 'Principal components analysis done'

## KernelPCA (allows non-linear dimensionality reduction)
#print ' Starting KernelPCA ...'
#kpca = dec.KernelPCA(n_components=30, kernel='poly', degree=2)
#kpca.fit(train1)
#train2 = kpca.transform(train1)
#test2 = kpca.transform(test1)


###############################################################################
# SVM
###############################################################################

## SVM
#print 'SVM fitting ...'
#svm1 = svm.SVC()
#svm1.fit(train2, label1)
#print 'SVM prediction ...'
#predict = svm1.predict(test2)
## calculate score
#score = svm1.score(test2, label_test)

## 50 components in PCA : score 97.44% 
## 40 components in PCA : score 97.39%
## 30 components in PCA : score 97.31%


###############################################################################
# kNN
###############################################################################

#print 'Starting kNN ...'
#knn1 = neig.KNeighborsClassifier(5)
#knn1.fit(train2, label1)
#knn_score = knn1.score(test2, label_test)
#print 'The kNN score: %s' % knn_score
#
## kNN score with 5 neighbors and 50 principal components : 95.17%

###############################################################################
# Decision trees
###############################################################################

## Decision tree
#print 'Starting decision tree classification ...'
#dtree = tree.DecisionTreeClassifier(max_depth=10)
#dtree.fit(train1, label1)
#dtree_score = dtree.score(test1, label_test)

# no PCA, depth 10 - score : 83.65%
# no PCA, depth 20 - score : 83.99%
# PCA, depth 10 - score : 77.45%

## Random forrest
#forest = ens.RandomForestClassifier(n_estimators=300, max_depth=30)
#forest.fit(train1, label1)
#forest_score = forest.score(test1, label_test)

# no PCA, depth 10, n_trees 20, score : 93.16%
# no PCA, depth 15, n_trees 20, score : 94.72%
# no PCA, depth 30, n_trees 20, score : 94.69%
# no PCA, depth 20, n_trees 100, score : 95.91%
# no PCA, depth 30, n_trees 100, score : 95.95%
# no PCA, depth 30, n_trees 300, score : 96.05%
# no max_depth, n_trees 300, score : 96.08%

# Extremly randomized trees
extrees = ens.ExtraTreesClassifier(n_estimators=300, max_depth=30)
extrees.fit(train1, label1)
extrees_score = extrees.score(test1, label_test)

# depth 30, n_trees 20, score : 94.92%
# depth 30, n_trees 300, score : 96.35%