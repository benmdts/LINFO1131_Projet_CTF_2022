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
	StartGame
	TreatStream
	MatchHead
	PlayersStatus
	GameStatePort
	CheckNotMerging
	RemoveMineFromList

	

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
		IsDead
		NewPosition
		PlayerID
	in
		%---------------------------------------------------------------
		%Tout n'est pas à jeter mais c'est pas bon comme c'est en threads, ils ont tous des States différents or qu'ils devraient avoir les mêmes. Faut trouver une solution. Mais les fonctions sont bonnes, juste le code ici en-dessous n'est pas bon :(
		%---------------------------------------------------------------
		%Regarde s'il est en vie

		{Send StatePort isAlive(ID IsDead)}
		{Wait IsDead}
		if(IsDead==true) then 
			% S' il est mort on attend le temps de RESPAWNDELAY et ensuite on envoie le nouvel état au StatePort et on recommence la boucle depuis le début
			{Delay Input.respawnDelay}
			{Send StatePort respawn(ID Port)}
			{Main Port ID StatePort}
		else 
		{Send Port move(PlayerID NewPosition)}
		{Wait NewPosition}{Wait PlayerID}
		{Send StatePort move(PlayerID NewPosition Port)}
		{Delay 500} % Pour afficher plus lentement, à enlever après
		{Main Port ID StatePort}
		end
	end


	fun {MovePlayer Port ID State NewPosition}
		if {CheckValidMove NewPosition State ID} then 
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
% -------Vérifie la validité d'une nouvelle position-------%	
	
	%3 conditions vérifiées : Pas un mouvement statique, pas un mouvement qui n'est pas dans le range et pas un mouvement en dehors de la map
	fun {CheckValidMove NewPosition State ID}
		LastPosition
	in
		LastPosition={GetPlayerState State.playersStatus ID}.currentposition
		if({CheckNotSameMove NewPosition LastPosition}==true andthen {MoveIsNextLastPosition NewPosition LastPosition}==true andthen {MoveIsInTheMap NewPosition}==true) andthen {CheckNotMerging NewPosition State.playersStatus ID} then 
			true
		else 
			false
		end 
	end
	fun {CheckNotSameMove NewPosition LastPosition}
		if(NewPosition.x==LastPosition.x andthen LastPosition.y==NewPosition.y) then 
			{System.show 'Même move'}
			false
		else 
			true
		end 
	end

	%Autorisation move en diagonale ?
	fun {MoveIsNextLastPosition NewPosition LastPosition}
		if(NewPosition.x==LastPosition.x-1 orelse NewPosition.x==LastPosition.x+1 orelse NewPosition.x==LastPosition.x) then 
			if(NewPosition.y==LastPosition.y-1 orelse NewPosition.y==LastPosition.y+1 orelse NewPosition.y==LastPosition.y) then
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
		if(NewPosition.x=<Input.nRow andthen NewPosition.y =<Input.nColumn andthen NewPosition.x>=1 andthen NewPosition.y >=1) then
			true
		else 
			{System.show 'Pas dans la map'}
			false 
		end 
	end 
	
	fun {CheckNotMerging NewPosition State ID}
		case State of nil then true
		[] H|T then 
			if H.id\=ID andthen NewPosition==H.currentposition then
				{System.show 'Place déjà occupée'}
				false
			else
				{CheckNotMerging NewPosition T ID}
			end
		end
	end

	/*Vérifie si le player a marché sur une mine, si oui, alors : 
		- On enlève 2 de vie sur l'interface pour le joueur
		- On dit à chaque joueur que le joueur a pris des dégats 
		- Si le joueur est mort, on envoie a tout le monde qu'il est mort et on l'enlève de l'interface
		- On dit a tout le monde que la mine a explosé 
		- On enlève la mine de l'interface
		- On modifie l'état -> On enlève la mine et on update les hp du joueur
	
	Il faut encore regarder si un autre joueur est touché par la mine ou pas 
	*/
	fun {CheckMines Port ID State Position MinesList} 
		case MinesList of nil then State
		[] mine(pos:MinePos)|T then 		
			if MinePos == Position then PlayerHp in 
				PlayerHp = {GetPlayerState State.playersStatus ID}.hp 
				{Send WindowPort lifeUpdate(ID PlayerHp-2)}%Enlève 2 de vie pour le mec car il a marché dessus
				{SayToAllPlayers PlayersPorts sayDamageTaken(ID 2 PlayerHp-2)}
				if(PlayerHp-2=<0) then 
					{SayToAllPlayers PlayersPorts sayDeath(ID)}
					{Send WindowPort removeSoldier(ID)}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant
				end 
				{SayToAllPlayers PlayersPorts sayMineExplode(mine(pos:MinePos))}
				{Send WindowPort removeMine(mine(pos:MinePos))}
				% Regarder si d'autres personnes sont pas sur la mine
				{Adjoin State state(mines:{RemoveMineFromList State.mines Position} playersStatus:{ChangePlayerStatus State.playersStatus ID playerstate(hp: PlayerHp-2)})}
			else 
				{CheckMines Port ID State Position T}
			end 
		end 
	end 

	%Enlève la mine de la liste. Utile pour enlever la mine de l'état
	fun {RemoveMineFromList MinesList Position}
		case MinesList of nil then nil
		[] mine(pos:MinePos)|T then 
			if MinePos == Position then 
				T
			else 
				mine(pos:MinePos)|{RemoveMineFromList T Position}
			end
		end 
	end
	/* 
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

	end */

	% Previens tous les joueurs avec le message MESSAGE
	proc {SayToAllPlayers PlayersPorts Message}
		case PlayersPorts of nil then skip
		[] player(_ Port)|T then 
			{Send Port Message}
			{SayToAllPlayers T Message}
		end 
	end 
	

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
				state(mines:[mine(pos:pt(x:6 y:10))] flags:Input.flags playersStatus: PlayersStatus)
			}
		end
		Port
	end

    proc{TreatStream Stream State}
        case Stream
            of H|T then {System.show State} {TreatStream T {MatchHead H State}}
        end
    end
	% Head = Stream avec les messages donnés par la fonction main 
	% State = État de la partie
	fun {MatchHead Head State}
        case Head of nil then nil 
		[] isAlive(ID ?Dead) then 
			case {GetPlayerState State.playersStatus ID} of nil then skip
			[]playerstate(currentposition:PlayerPos hp:PlayerHP id:PlayerID port:PlayerPort) then 
			if PlayerHP ==0 then 
				Dead = true
				else 
					Dead = false
				end
			end
			State
		% On donne l'id et le port du joueur qui doit être respawn 
		[] respawn(ID Port) then 
			{Send WindowPort initSoldier(ID {List.nth Input.spawnPoints ID.id})}
			% Prévenir les autres
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(currentposition: {List.nth Input.spawnPoints ID.id} hp: Input.startHealth)} )}
		[] move(ID Position Port) then 
			% On vérifie s'il a marché sur une mine juste après
			MovePlayerState in 
			MovePlayerState={MovePlayer Port ID State Position} 
			{CheckMines Port ID MovePlayerState Position State.mines}
		end 
    end


    thread
		% Create port for window
		WindowPort = {GUI.portWindow}

		% Open window
		{Send WindowPort buildWindow}
		{System.show buildWindow}
		{Delay 1000}

        % Create port for players
		PlayersPorts = {DoListPlayer Input.players Input.colors 1} 
		PlayersStatus = {CreatePlayerStatus PlayersPorts}
		GameStatePort = {StartGame PlayersStatus}
		
		{InitThreadForAll PlayersPorts PlayersStatus GameStatePort}

		end
end
