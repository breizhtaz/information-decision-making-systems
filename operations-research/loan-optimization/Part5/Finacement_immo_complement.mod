/*********************************************
 * OPL 12.5.1.0 Model
 * Author: g.lever
 * All rights reserved
 * Creation Date: Nov 16, 2014 at 6:25:39 PM
 *********************************************/

 
 
// Paramètres
float montantTotal = ... ;
int nbDurees = ...;
int nbTaux = ...;
float cMin = ... ;
int dMax = 180 ;
int dMax_an = 15 ;
int nbPrets = ... ;
int nbPaliers = ... ;

// Intervales
range DureesPossibles = 1..nbDurees;
range TauxPossibles = 1..nbTaux;
range DureeMax = 1..dMax;
range Prets = 1..nbPrets;
range Paliers = 1..nbPaliers;
range DureeAn = 0..dMax_an-1;

// Tableaux
int nbMois[DureesPossibles] = ... ;
float Taux[Prets][TauxPossibles] = ... ;
float Ej[1..2] = ... ;

// Variables
dvar boolean   d[i in Prets][j in DureesPossibles] ; // Choix du prêt
dvar boolean   p_rem[i in Prets][j in DureeMax] ; // 1 si le mois fait partie de la periode de remboursement, 0 sinon
dvar float+    m[i in Prets] ; // Montant de chaque pret
dvar float+    e[i in Prets][j in DureeMax] ;
dvar float+    etotal[j in DureeMax] ;
dvar float+    c[i in Prets][j in DureeMax] ; 
dvar float+    it[i in Prets][j in DureeMax] ; 
dvar float+    interets ; // Interets totaux payés

dvar float+    p_ech[i in Prets][k in Paliers] ; // Echeance constante du palier k

/* Le fait d'avoir les c sur les années et non sur les mois
nous permet de supprimer approximativement 1000 contraintes et 2500 variables binaires 
passant de 3000 à 500. Cela a un impact considérable sur les performances
puisque le temps de calcul passe de 1h30 à 5s */

dvar boolean   c1[i in Prets][j in DureeAn] ; 
dvar boolean   c2[i in Prets][j in DureeAn] ;

// Un max de remboursement variable
dvar float+    ej[j in DureeMax] ;


/* TODO
 + A remplacer par une variable binaire : 800 + 50 * ej avec ej binaire
 + Revoir les paliers : pourquoi on ne change qu'une fois et pourquoi on n'emplafonne pas la limite ?
 + Pourquoi il n'y a pas de 1 / 799 ?? Pour rembourser le pret A plus vite ?
 + Pour les paliers, il y a des multiplications de variables. Non linéaire.
*/

// Definition fonction objectif et contraintes : 1 seul pret
minimize 
	sum( p in Prets ) 
		sum( j in DureeMax ) e[p][j]  ;

subject to {

	// Contrainte des 30% sur le pret A (1)
 	sum (j in DureeMax) c[1][j] >= montantTotal * 30/100 ;

	// Calcul montant
	montantTotal == sum( p in Prets ) sum (j in DureeMax) c[p][j] ;
	
	forall( j in DureeMax ) etotal[j] == sum ( p in Prets ) e[p][j] ;
		
	// Calcul interets
	interets == sum( p in Prets ) sum (j in DureeMax) it[p][j] ;

	// Montant de chaque pret
	forall ( p in Prets )  
		m[p] == sum (j in DureeMax) c[p][j] ;

	// Contraintes remboursement max
	forall ( j in DureeMax )
		sum ( p in Prets ) e[p][j] <= ej[j] ; // Cette contrainte est en conflit avec une autre

	// Contraintes Max remboursement possible
	forall( j in 1..60){
		ej[j] == Ej[1];  
 	}	  

	forall(j in 61..dMax){
		ej[j] == Ej[2];  
 	}	  

 	// Pour chaque prêt
 	forall ( p in Prets ) {
	   // Choix de la duree du pret
	    sum( i in DureesPossibles ) d[p][i] == 1 ;
	    
		// Initialisation periode remboursement (p_rem)
		forall( j in 1..nbMois[1] ){
			p_rem[p][j] == 1;
		}		
	 	forall( i in 2..nbDurees ) {
	 		forall(j in nbMois[i-1]+1..nbMois[i]){
				// p_rem[j] = 1 si mois choisi >= i  
	        	p_rem[p][j] == sum(k in i..nbDurees) d[p][k]; 
	     	}
		}  
		
		// Bornes sur les l'amortissement et calcul des echeances
		forall( j in DureeMax ) {
			// Contraintes min amortissement 
			c[p][j] <= p_rem[p][j] * ej[j];
	     	c[p][j] >= p_rem[p][j] * cMin;
	
			// Calcul e[p][j]
	     	e[p][j] == c[p][j] + it[p][j] ;
		}

		forall(k in Paliers) { // Bornes echeances
			forall(j in DureeMax){
				p_ech[p][k] <= ej[j] ;
				p_ech[p][k] >= cMin ;			
			}		
		}
	
		// Il faut que c1 soit < c2 !!!!
		sum (j in DureeAn) (c2[p][j] - c1[p][j]) >= 1 ;
		
		// Il faut que la serie de 1 soit continue
		forall(j in 1..dMax_an-1) c1[p][j-1] >= c1[p][j] ; 
		forall(j in 1..dMax_an-1) c2[p][j-1] >= c2[p][j] ; 
		
		//On fixe les valeurs de ej
		
		
		// Definition des paliers
		forall(j in 0..dMax_an-1){ //j correspond aux annees
			forall(i in 1..12){ // i aux mois
			  e[p][12*j+i] <= p_ech[p][1] + ej[12*j+i] * (1 - c1[p][j]) ; 
			  e[p][12*j+i] >= p_ech[p][1] - ej[12*j+i] * (1 - c1[p][j]) ;
			  e[p][12*j+i] <= p_ech[p][2] + ej[12*j+i] * (1 - c2[p][j]) + ej[12*j+i] * c1[p][j] ; 
			  e[p][12*j+i] >= p_ech[p][2] - ej[12*j+i] * (1 - c2[p][j]) - ej[12*j+i] * c1[p][j] ;  
			  e[p][12*j+i] <= p_ech[p][3] + ej[12*j+i] * c2[p][j] ; 
			  e[p][12*j+i] >= p_ech[p][3] - ej[12*j+i] * c2[p][j] ; 
	  		}		  
		}		
					
		// Calcul des interets
     	forall( i in DureesPossibles ) {
			it[p][1] >= (Taux[p][i]/100) * m[p] / 12 - ej[i] * (1 - d[p][i]) ;
			it[p][1] <= (Taux[p][i]/100) * m[p] / 12 + ej[i] * (1 - d[p][i]) ;
		}		
		forall( j in 2..dMax ) {
			// iA[j]=0 si p_rem = 0
			it[p][j] <= p_rem[p][j] * ej[j] ;
			it[p][j] >= 0 ;
					 
			// Sinon relation de recurrence it[p][j]
	     	forall( i in DureesPossibles ) {
	     	  	// 2 types de contraintes :
	     	  	//  	+ La relation de recurrence pour le i choisi
	     	  	//  	+ Des contraintes obsolètes (trop larges) pour les autres i
	     	  	
				it[p][j] <= it[p][j-1] - (Taux[p][i]/100) * c[p][j-1] / 12 + ej[i] * (1 - d[p][i]) ;  
				it[p][j] >= it[p][j-1] - (Taux[p][i]/100) * c[p][j-1] / 12 - ej[i] * (1 - d[p][i]) - ej[i] * (1 - p_rem[p][j]) ;
			}
		}
	}		 
} 