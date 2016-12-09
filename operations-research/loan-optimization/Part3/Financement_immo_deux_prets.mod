/*********************************************
 * OPL 12.5.1.0 Model
 * Author: g.lever
 * All rights reserved
 * Creation Date: Nov 14, 2014 at 1:35:52 PM
 *********************************************/

 
// Paramètres
float montantTotal = ... ;
float Ej = ... ;
int nbDurees = ...;
int nbTaux = ...;
float cMin = ... ;
int dMax = 180 ;
int nbPrets = ... ;

// Intervales
range DureesPossibles = 1..nbDurees;
range TauxPossibles = 1..nbTaux;
range DureeMax = 1..dMax;
range Prets = 1..nbPrets;

// Tableaux
int nbMois[DureesPossibles] = ... ;
float Taux[Prets][TauxPossibles] = ... ;

// Variables
dvar boolean   d[i in Prets][j in DureesPossibles] ; // Choix du prêt
dvar boolean   p_rem[i in Prets][j in DureeMax] ; // 1 si le mois fait partie de la periode de remboursement, 0 sinon
dvar float+    m[i in Prets] ; // Montant de chaque pret
dvar float+    e[i in Prets][j in DureeMax] ;
dvar float+    c[i in Prets][j in DureeMax] ; 
dvar float+    it[i in Prets][j in DureeMax] ; 
dvar float+    interets ; // Interets totaux payés

// Definition fonction objectif et contraintes : 1 seul pret
minimize 
	sum( p in Prets ) 
		sum( j in DureeMax ) e[p][j]  ;

subject to {

	// Contrainte des 30% sur le pret A (1)
 	sum (j in DureeMax) c[1][j] >= montantTotal * 30/100 ;

	// Calcul montant
	montantTotal == sum( p in Prets ) m[p] ;

	// Montant de chaque pret
	forall ( p in Prets )  
		m[p] == sum (j in DureeMax) c[p][j] ;

	// Calcul interets
	interets == sum( p in Prets ) sum (j in DureeMax) it[p][j] ;

	// Contraintes remboursement max
	forall ( j in DureeMax )
		sum ( p in Prets ) e[p][j] <= Ej ; // Cette contrainte est en conflit avec une autre

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
		
		forall( j in DureeMax ) {
			// Contraintes min amortissement 
			c[p][j] <= p_rem[p][j] * Ej;
	     	c[p][j] >= p_rem[p][j] * cMin;
	
			// Calcul e[p][j]
	     	e[p][j] == c[p][j] + it[p][j] ;
		}
					
		// Calcul des interets
     	forall( i in DureesPossibles ) {
			it[p][1] >= (Taux[p][i]/100) * m[p] / 12 - Ej * (1 - d[p][i]) ;
			it[p][1] <= (Taux[p][i]/100) * m[p] / 12 + Ej * (1 - d[p][i]) ;
		}		
		forall( j in 2..dMax ) {
			// iA[j]=0 si p_rem = 0
			it[p][j] <= p_rem[p][j] * Ej ;
			it[p][j] >= 0 ;
			
			// Sinon relation de recurrence it[p][j]
	     	forall( i in DureesPossibles ) {
	     	  	// 2 types de contraintes :
	     	  	//  	+ La relation de recurrence pour le i choisi
	     	  	//  	+ Des contraintes obsolètes (trop larges) pour les autres i
	     	  	
				it[p][j] <= it[p][j-1] - (Taux[p][i]/100) * c[p][j-1] / 12 + Ej * (1 - d[p][i]) ;  
				it[p][j] >= it[p][j-1] - (Taux[p][i]/100) * c[p][j-1] / 12 - Ej * (1 - d[p][i]) - Ej * (1 - p_rem[p][j]) ;
			}
		}
	}		
}