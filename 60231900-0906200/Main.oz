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

	proc {Main Port ID State}
		Result 
		NewState
	in
		%Regarde s'il est en vie
		case {GetPlayerState State.playersStatus ID} of nil then skip
		[]playerstate(currentposition:PlayerPos hp:PlayerHP id:PlayerID port:PlayerPort) then 
			if PlayerHP ==0 then 
				{System.show 'Le joueur est mort'}
				{Wait Input.respawnDelay}
				{Send Port respawn(ID)}
				{Send WindowPort moveSoldier(ID State.startPosition)}
				%NewState = {Adjoin State state(playersStatus: {Adjoin state.playersStatus playerstate(ID : ID hp: Input.startHealth currentposition: {List.nth Input.spawnPoints ID})})} 
				%Comment faire si on respawn pour changer l'état, car on le change potentiellement après, on crée plusieurs variables ?
				end 
		end
		{System.show 'Ask for move'}
		% Demande s'il veut bouger
		NewState = {MovePlayer Port ID State}
		{Delay 500}
		{Main Port ID NewState}
	end

	fun {CheckMines Port ID State Position}
		State
	end 

	fun {MovePlayer Port ID State}
		NewPosition 
	in 
		{Send Port move(ID NewPosition)}
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

	proc {InitThreadForAll Players PlayersStatus}
		case Players
		of nil then
			{Send WindowPort initSoldier(null pt(x:0 y:0))}
			{DrawFlags Input.flags WindowPort}
		[] player(_ Port)|Next then ID Position in
			{Send Port initPosition(ID Position)}
			{Send WindowPort initSoldier(ID Position)}
			{Send WindowPort lifeUpdate(ID Input.startHealth)}
			thread
			 	{Main Port ID state(mines:nil flags:Input.flags playersStatus: PlayersStatus)}
			end
			{InitThreadForAll Next PlayersStatus}
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

		{System.show 'PlayersStatus crée'}
		
		{InitThreadForAll PlayersPorts PlayersStatus}
		end
end
