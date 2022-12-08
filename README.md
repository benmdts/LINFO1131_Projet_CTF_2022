Game controller (Main oz) :

1.  DONE juste remettre le message respawn
2.  DONE
3.  DONE juste regarder si c'est pas dans la base
4.  DONE juste comment skip le tour d'une personne qui est morte car elle était à côté de la mine
5.  Ask the player what weapon it wants to charge (gun or mine).
6.  Ask the player what weapon it wants to use (place a mine or shoot at something). Check if the player
    can indeed use that weapon, and if so send a message notifying everyone, then reset the charge counter
    to 0 for that weapon. If a mine is exploded as a result, notify everyone that it has exploded and apply
    the damage. If a player has been shot, notify everyone.
7.  Ask the player if it wants to grab the flag (only if it is possible). Notify everyone if the flag has been
    picked up.
8.  If applicable, ask the player if they want to drop the flag. Notify everyone if they do.
9.  If a player has died, notify everyone and also notify them if the flag has been dropped as a result.
10. The game Controller is also responsible for spawning food randomly on the map after a random time

Idées pour le player :

- Charger le fusil si un adversaire peut potentiellement être à 2 cases de nous sinon charger la mine car on ne va pas tirer alors. Car le fusil peut être chargé et utilisé sur le même "tour"

- Stocker tout ce qu'on peut sur les joueurs, vies, weapon, postion.

- Analyser la carte et faire le meilleur 'move'

- Si le drapeau adverse est proche de notre base, on fait que rush le drapeau

- Si 3 persos différents alors on fait un qui rush le drapeau, un qui défend et un autre qui rush les ennemis

- Si il y a de la bouffe et qu'on est le plus proche on rush la nouriture

- Fonction qui calcule le joueur le plus proche d'une case

- Fonction qui calcule le nombre de tours pour aller à une case. s
