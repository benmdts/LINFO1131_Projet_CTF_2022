Commentaires Benoît To Arthur :

1. (Redraw ou pas mettre si superposition) -- pas encore fait
   Commentaires Arthur To Benoît :
1. Si tu vois des joueurs qui tankent les mines c'est pas un bug, ils ont juste mangé un food avant
2. Normalement ca saute le tour :)
---

Game controller (Main oz) :

1.  DONE
2.  DONE
3.  DONE
4.  DONE juste comment skip le tour d'une personne qui est morte car elle était à côté de la mine
5.  DONE
6.  DONE
7.  DONE
8.  DONE
9.  If a player has died, notify everyone and also notify them if the flag has been dropped as a result. DONE pour la partie flag (juste voir commentaire ) mais jsp s'il faut vérifier que la personne soit morte ?
10. The game Controller is also responsible for spawning food randomly on the map after a random time

Idées pour le player :

- Charger le fusil si un adversaire peut potentiellement être à 2 cases de nous sinon charger la mine car on ne va pas tirer alors. Car le fusil peut être chargé et utilisé sur le même "tour"

- Stocker tout ce qu'on peut sur les joueurs, vies, weapon, postion.

- Analyser la carte et faire le meilleur 'move'

- Si le drapeau adverse est proche de notre base, on fait que rush le drapeau

- Si 3 persos différents alors on fait un qui rush le drapeau, un qui défend et un autre qui rush les ennemis

- Si il y a de la bouffe et qu'on est le plus proche on rush la nouriture

- Fonction qui calcule le joueur le plus proche d'une case

- Fonction qui calcule le nombre de tours pour aller à une case.

Questions :

    - Fusil et Mine chargés dès le début ?
    - Dans la fonction InitThreadForAll, on initialise la position du joueur par une position qu'il nous donne, il faut vérifier la position donnée non ?
