functor
import
	GUI
	Input
	PlayerManager
	System
	OS
define
	DoListPlayer
	InitThreadForAll
	PlayersPorts
	PlayersStatus
	SendToAll
	SimulatedThinking
	Main
	WindowPort
	CheckValidMove
	CheckNotSameMove
	MoveIsInTheMap
	MoveIsNextLastPosition
	SayToAllPlayers
	CheckMines
	MovePlayer
	CreatePlayerStatus
	GetPlayerState
	ChangePlayerStatus
	CheckOtherPlayersNearMines
	AjoutMineFictive
	

	proc {DrawFlags Flags Port}
		case Flags of nil then skip 
		[] Flag|T then
			{Send Port putFlag(Flag)}
			{DrawFlags T Port}
		end
	end
in
    fun {DoListPlayer Players Colors ID}
		case Players#Colors
		of nil#nil then nil
		[] (Player|NextPlayers)#(Color|NextColors) then
			player(ID {PlayerManager.playerGenerator Player Color ID})|
			{DoListPlayer NextPlayers NextColors ID+1}
		end
	end

	SimulatedThinking = proc{$} {Delay ({OS.rand} mod (Input.thinkMax - Input.thinkMin) + Input.thinkMin)} end

	proc {Main Port ID StatePort}
		Result 
		NewStateMove
		NewStateMine
		TestState
		isDead
		NewPosition
	in
		%---------------------------------------------------------------
		%Tout n'est pas à jeter mais c'est pas bon comme c'est en threads, ils ont tous des States différents or qu'ils devraient avoir les mêmes. Faut trouver une solution. Mais les fonctions sont bonnes, juste le code ici en-dessous n'est pas bon :(
		%---------------------------------------------------------------
		%Regarde s'il est en vie

		{Send StatePort isAlive(ID isDead)}
		{Wait isDead}
		if(isDead==true) then 
			{Wait Input.respawnDelay}
			{Send StatePort respawn(ID Port)}
		end
		{Send Port move(ID NewPosition)}
		{Wait NewPosition}{Wait ID}
		{Send StatePort move(ID NewPosition Port)}
		{Delay 500}
		{Main Port ID StatePort}
	end
/* 
	fun {AjoutMineFictive Port ID State }
		TestState in 
		if State.mines==nil andthen ID.id == 1 then 
		{Send WindowPort putMine(mine(pos:pt(x:6 y:10)))}
		{Adjoin State state(mines:{Append State.mines [mine(pos:pt(x:6 y:10))]})}
		else 
			State
		end 
	end 
*/
	fun {CheckMines Port ID State Position MinesList}
		case MinesList of nil then State
		[] mine(pos:MinePos)|T then 
			if MinePos == Position then 
				{Send WindowPort lifeUpdate(State.hp-2)}%Enlève 2 de vie pour le mec car il a marché dessus
				{SayToAllPlayers PlayersPorts sayDamageTaken(ID 2 State.hp-2)}
				if(State.hp-2==0) then 
					{SayToAllPlayers PlayersPorts sayDeath(ID)}
					{Send WindowPort removeSoldier(ID)}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant
				end 
				{SayToAllPlayers PlayersPorts sayMineExplode(mine(pos:MinePos))}
				{Send WindowPort mine(pos:MinePos)}
				{Adjoin {CheckOtherPlayersNearMines Port ID State Position mine(pos:MinePos)} state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hp:State.hp-1)})}
				else 
					{CheckMines Port ID State Position T}
			end 
		end 
		
	end 
	fun {CheckOtherPlayersNearMines Port ID State PlayersList Position}
		case PlayersList 
		of nil then 
			State
		[] playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port)|T then 
			if {MoveIsNextLastPosition Pos Position} then 
				{Send WindowPort lifeUpdate(HP-1)}
				{SayToAllPlayers PlayersPorts sayDamageTaken(ID 1 HP-1)}
				if(HP-1==0) then 
					{SayToAllPlayers PlayersPorts sayDeath(ThisPlayerID)}
					{Send WindowPort removeSoldier(ThisPlayerID)}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant
				end
				{CheckOtherPlayersNearMines Port ID {Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ThisPlayerID playerstate(hp:HP-1)})} T Position}
				else
					{CheckOtherPlayersNearMines Port ID State T Position}
			end 
		
		end

	end 

	fun {MovePlayer Port ID State}
		NewPosition
	in 
		if {CheckValidMove NewPosition {GetPlayerState State.playersStatus ID}.currentposition} ==true then 
			% Bouge le player
			{Send WindowPort moveSoldier(ID NewPosition)}
			% Dis à tout le monde que le player a bougé 
			{SayToAllPlayers PlayersPorts sayMoved(ID NewPosition)}
			% On merge 2 records pour ajouter la nouvelle position {ChangePlayerStatus} retourne une nouvelle liste avec la nouvelle position
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(currentposition:NewPosition)})}
			else 
			State
		end
	end

	% Change le record playerState() du player avec l'id PLAYERID
	fun {ChangePlayerStatus PlayersList PlayerID NewValue}
		case PlayersList of nil then nil
		[] playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port)|T then 
			if ThisPlayerID == PlayerID.id then 
				{Adjoin playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port) NewValue}|T
			else 
				playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port)|{ChangePlayerStatus T PlayerID NewValue}
			end
		end
	end

	% Retourne le record playerstate() du player avec l'id PLAYERID
	fun {GetPlayerState PlayersList PlayerID}
		case PlayersList of nil then nil
		[] playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port)|T then 
			if(ThisPlayerID == PlayerID.id) then 
				playerstate(currentposition:Pos hp:HP id:ThisPlayerID port:Port)
			else 
				{GetPlayerState T PlayerID}
			end
		end
	end

	% Previens tous les joueurs avec le message MESSAGE
	proc {SayToAllPlayers PlayersPorts Message}
		case PlayersPorts of nil then skip
		[] player(_ Port)|T then 
			{Send Port Message}
			{SayToAllPlayers T Message}
		end 
	end 


	% -------Vérifie la validité d'une nouvelle position-------%	
	
	%3 conditions vérifiées : Pas un mouvement statique, pas un mouvement qui n'est pas dans le range et pas un mouvement en dehors de la map
	fun {CheckValidMove NewPosition LastPosition}
		if({CheckNotSameMove NewPosition LastPosition}==true andthen {MoveIsNextLastPosition NewPosition LastPosition}==true andthen {MoveIsInTheMap NewPosition}==true) then 
			{System.show 'Nouvelle position acceptée'}
			true
		else 
			{System.show 'Nouvelle position pas acceptée'}
			false
		end 
	end
	fun {CheckNotSameMove NewPosition LastPosition}
		{System.show '1ère condition'}
		if(NewPosition.x==LastPosition.x andthen LastPosition.y==NewPosition.y) then 
			{System.show 'Même move'}
			false
		else 
			{System.show 'Pas la même position'}
			true
		end 
	end

	%Autorisation move en diagonale ?
	fun {MoveIsNextLastPosition NewPosition LastPosition}
		{System.show '2ème condition'}
		if(NewPosition.x==LastPosition.x-1 orelse NewPosition.x==LastPosition.x+1 orelse NewPosition.x==LastPosition.x) then 
			if(NewPosition.y==NewPosition.y-1 orelse NewPosition.y==NewPosition.y+1 orelse NewPosition.y==NewPosition.y) then
				{System.show 'Bien une position qui est à côté'}
				true
				else 
					{System.show 'Pas à côté de l ancienne position'}
					false
			end 
		else 
			false
		end 
	end 
	
	fun {MoveIsInTheMap NewPosition}
		{System.show '3ème condition'}
		if(NewPosition.x=<Input.nRow andthen NewPosition.y =<Input.nColumn andthen NewPosition.x>=1 andthen NewPosition.y >=1) then
			{System.show 'Position dans la Map'} 
			true
		else 
			{System.show 'Pas dans la map'}
			false 
		end 
	end 

	%Ajouter pas aller dans la même case qu'un autre joueur

	% Pas aller dans les murs

	%----------------------------------------------%
	
	%Crée la liste de record qui nous permet de savoir la position des joueurs sur la map et leur vie
	fun {CreatePlayerStatus PlayerPorts} 
		case PlayerPorts of nil then nil 
		[]player(PlayerID PlayerPort)|T then 
			playerstate(
				currentposition: {List.nth Input.spawnPoints PlayerID}
				hp : Input.startHealth
				id : PlayerID 
				port : PlayerPort
				)|{CreatePlayerStatus T}
		end 
	end 

	proc {InitThreadForAll Players PlayersStatus GameStatePort}
		case Players
		of nil then
			{Send WindowPort initSoldier(null pt(x:0 y:0))}
			{DrawFlags Input.flags WindowPort}
		[] player(_ Port)|Next then ID Position in
			{Send Port initPosition(ID Position)}
			{Send WindowPort initSoldier(ID Position)}
			{Send WindowPort lifeUpdate(ID Input.startHealth)}
			thread
			 	{Main Port ID GameStatePort}
			end
			{InitThreadForAll Next PlayersStatus GameStatePort}
		end
	end

	fun {StartGame PlayersStatus}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream
			 	Stream
				state(mines:nil flags:Input.flags playersStatus: PlayersStatus)
			}
		end
		Port
	end

    proc{TreatStream Stream State}
        case Stream
            of H|T then {TreatStream T {MatchHead H State}}
        end
    end

	% Head = Stream avec les messages donnés par la fonction main 
	% State = État de la partie
	fun {MatchHead Head State}
        case Head of nil then nil 
		[] isAlive(ID ?Dead) then 
			in 
			case {GetPlayerState State.playersStatus ID} of nil then skip
			[]playerstate(currentposition:PlayerPos hp:PlayerHP id:PlayerID port:PlayerPort) then 
			if PlayerHP ==0 then 
				{System.show 'Le joueur est mort'}
				Dead = true
				%Comment faire si on respawn pour changer l'état, car on le change potentiellement après, on crée plusieurs variables ?
				else 
					Dead = false
				end
			end
			State
		% On donne l'id et le port du joueur qui doit être respawn 
		[] respawn(ID Port) then 
			{Send Port respawn(ID)}
			{Send WindowPort moveSoldier(ID State.startPosition)}
			% Prévenir les autres
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(currentposition: {List.nth spawnPoints ID} hp: Input.startHealth)} )}
		[] move(ID Position Port) then 
			{MovePlayer Port ID State}
		end 
    end


    thread
		% Create port for window
		WindowPort = {GUI.portWindow}

		% Open window
		{Send WindowPort buildWindow}
		{System.show buildWindow}

        % Create port for players
		PlayersPorts = {DoListPlayer Input.players Input.colors 1} 
			{System.show 'PlayersPorts crée'}
		PlayersStatus = {CreatePlayerStatus PlayersPorts}
		GameStatePort = {StartGame PlayerStatus}
		{System.show 'PlayersStatus crée'}
		
		{InitThreadForAll PlayersPorts PlayersStatus GameStatePort}

		end
end
