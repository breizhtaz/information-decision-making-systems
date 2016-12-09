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

// Intervales
range DureesPossibles = 1..nbDurees;
range TauxPossibles = 1..nbTaux;
range DureeMax = 1..dMax;

// Tableaux
int nbMois[DureesPossibles] = ... ;
float TauxA[TauxPossibles] = ... ;

// Variables
dvar boolean   dA[i in DureesPossibles] ; // Choix du prêt
dvar boolean   p_rem[j in DureeMax] ; // 1 si le mois fait partie de la periode de remboursement, 0 sinon
dvar float+    e ; // Echeance constante = e
dvar float+    eA[j in DureeMax] ;
dvar float+    cA[j in DureeMax] ; 
dvar float+    iA[j in DureeMax] ; 

// Definition fonction objectif et contraintes : 1 seul pret
minimize 
	sum( j in DureeMax ) eA[j]  ;

subject to {
    // Choix de la duree du pret
    sum( i in DureesPossibles ) dA[i] == 1 ;
    
	// Initialisation periode remboursement (p_rem)
	forall( j in 1..nbMois[1] ){
		p_rem[j] == 1;
	}
 	forall( i in 2..nbDurees ){
 		forall(j in nbMois[i-1]+1..nbMois[i]){
			// p_rem[j] = 1 si mois choisi >= i  
        	p_rem[j] == sum(k in i..nbDurees) dA[k]; 
     	}
	}  
	
	forall( j in DureeMax ) {
		// Si p_rem = 0 alors eA[j] = 0, sinon min et max
		eA[j] <= Ej * p_rem[j] ;
     	eA[j] >= cMin * p_rem[j] ;

		eA[j] <= e + cMin * (1 - p_rem[j]) ; 
     	eA[j] >= e - Ej * (1 - p_rem[j]) ;  
		
		// Contraintes min amortissement 
		cA[j] <= p_rem[j] * Ej;
     	cA[j] >= p_rem[j] * cMin;

		// Calcul eA[j]
     	eA[j] == cA[j] + iA[j] ;
	}
	
	// Calcul mA
	montantTotal == sum (j in DureeMax) cA[j] ;
		
	// Calcul des interets
	iA[1] == sum( i in DureesPossibles ) dA[i] * (TauxA[i]/100) * montantTotal / 12 ;
	forall( j in 2..dMax ) {
		// iA[j]=0 si p_rem = 0
		iA[j] <= p_rem[j] * Ej ;
		iA[j] >= 0 ;
		
		// Sinon relation de recurrence iA[j]
     	forall( i in DureesPossibles ) {
     	  	// 2 types de contraintes :
     	  	//  	+ La relation de recurrence pour le i choisi
     	  	//  	+ Des contraintes obsolètes (trop larges) pour les autres i
     	  	
			iA[j] <= iA[j-1] - (TauxA[i]/100) * cA[j-1] / 12 + Ej * (1 - dA[i]) ;  
			iA[j] >= iA[j-1] - (TauxA[i]/100) * cA[j-1] / 12 - Ej * (1 - dA[i]) - Ej * (1 - p_rem[j]) ;
		}
	}	
}