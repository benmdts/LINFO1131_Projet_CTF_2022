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
	CheckNotWallSpawn

	

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
	%ICI ID est un record
	proc {Main Port ID StatePort}
		Result 
		NewStateMove
		NewStateMine
		TestState
		IsDead
		NewPosition
		PlayerID
        Kind
		HasMoved
		Fire
	in
		%---------------------------------------------------------------
		%Tout n'est pas à jeter mais c'est pas bon comme c'est en threads, ils ont tous des States différents or qu'ils devraient avoir les mêmes. Faut trouver une solution. Mais les fonctions sont bonnes, juste le code ici en-dessous n'est pas bon :(
		%---------------------------------------------------------------
		%Regarde s'il est en vie

		{Send StatePort isAlive(ID IsDead)}
		if(IsDead==true) then 
			% S' il est mort on attend le temps de RESPAWNDELAY et ensuite on envoie le nouvel état au StatePort et on recommence la boucle depuis le début
			{Delay Input.respawnDelay}
			{Send StatePort respawn(ID Port)}
		end

		%PLAYERID aussi un record
		{Send Port move(PlayerID NewPosition)}
		{Wait NewPosition}{Wait PlayerID}
		{Send StatePort move(PlayerID NewPosition Port HasMoved)}
		{Wait HasMoved}

        {Send Port chargeItem(ID Kind)}
		{Wait Kind}
		{Send StatePort playerCharge(ID Kind Port)}% Est-ce qu'on vérifie s'il est pas au max ? 

		
		{Send Port fireItem(ID Fire)}
		{Wait Fire}
		{Send StatePort useWeapon(ID Fire Port)}% Est-ce qu'on vérifie s'il est pas au max ? 
		

		{Delay 500} % Pour afficher plus lentement, à enlever après
		{Main Port ID StatePort}
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
	% TO DO : VÉRIFIER SI PAS DANS LA BASE ADVERSE
	fun {CheckValidMove NewPosition State ID}
		LastPosition
	in
		LastPosition={GetPlayerState State.playersStatus ID}.currentposition
		({CheckNotSameMove NewPosition LastPosition} andthen {MoveIsNextLastPosition NewPosition LastPosition} andthen {MoveIsInTheMap NewPosition} andthen {CheckNotMerging NewPosition State.playersStatus ID} andthen {CheckNotWallSpawn NewPosition ID.id+1})
	end
	fun {CheckNotSameMove NewPosition LastPosition}
		(NewPosition.x\=LastPosition.x orelse NewPosition.y\=LastPosition.y)
	end

	fun {MoveIsNextLastPosition NewPosition LastPosition}
		(NewPosition.x==LastPosition.x-1 orelse NewPosition.x==LastPosition.x+1 orelse NewPosition.x==LastPosition.x) andthen (NewPosition.y==LastPosition.y-1 orelse NewPosition.y==LastPosition.y+1 orelse NewPosition.y==LastPosition.y)
	end 
	
	fun {MoveIsInTheMap NewPosition}
		(NewPosition.x=<Input.nRow andthen NewPosition.y =<Input.nColumn andthen NewPosition.x>=1 andthen NewPosition.y >=1)
	end 
	
	fun {CheckNotMerging NewPosition State ID}
		case State of nil then true
		[] H|T then 
			if H.id\=ID andthen NewPosition==H.currentposition then
				false
			else
				{CheckNotMerging NewPosition T ID}
			end
		end
	end

	%Check si on rentre pas dans la base adverse ou dans un mur comme un teu teu
	fun {CheckNotWallSpawn NewPosition ID}
		Tile
		Team
	in
		Team=ID mod 2
		Tile={List.nth {List.nth Input.map NewPosition.x} NewPosition.y}-1
		(Tile==~1 orelse Tile==Team)
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
		StatePlayerAfterMines in
		case MinesList of nil then State
		[] mine(pos:MinePos)|T then 		
			if MinePos == Position then PlayerHp in 
				StatePlayerAfterMines = {CheckOtherPlayersNearMines State State.playersStatus Position}
				{Send WindowPort removeMine(mine(pos:MinePos))}
				% Regarder si d'autres personnes sont pas sur la mine
				{Adjoin StatePlayerAfterMines state(mines:{RemoveMineFromList State.mines Position})}
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

	fun {CheckOtherPlayersNearMines State PlayersList Position}
		RemoveHP in
		case PlayersList 
		of nil then 
			State
		[] PlayerState|T then
			if(Position == PlayerState.currentposition) then
				RemoveHP = 2 
			else if {MoveIsNextLastPosition PlayerState.currentposition Position} then 
				RemoveHP = 1
			else 
				RemoveHP = 0
			end 
		end 
			if RemoveHP >0 then 
				{Send WindowPort lifeUpdate(PlayerState.id PlayerState.hp-RemoveHP)}
				{SayToAllPlayers PlayersPorts sayDamageTaken(PlayerState.id RemoveHP PlayerState.hp-RemoveHP)}
				if(PlayerState.hp-RemoveHP=<0) then 
					{Send WindowPort removeSoldier(PlayerState.id)}
					{SayToAllPlayers PlayersPorts sayDeath(PlayerState.id)}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant
				end
				{CheckOtherPlayersNearMines {Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus PlayerState.id playerstate(hp:PlayerState.hp-RemoveHP)})} T Position}
			else
				{CheckOtherPlayersNearMines State T Position}
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
	

	%Crée la liste de record qui nous permet de savoir la position des joueurs sur la map et leur vie
	fun {CreatePlayerStatus PlayerPorts} 
		case PlayerPorts of nil then nil 
		[]player(PlayerID PlayerPort)|T then 
			playerstate(
                currentposition: {List.nth Input.spawnPoints PlayerID}
				hp : Input.startHealth
				id : PlayerID 
				port : PlayerPort
				chargegun : 0
				chargemine : 0
				currentweapon : nil
				)|{CreatePlayerStatus T}
		end 
	end 

	% Change le record playerState() du player avec l'id PLAYERID
	fun {ChangePlayerStatus PlayersList PlayerID NewValue}
		case PlayersList of nil then nil
		[] PlayerState|T then
			if PlayerState.id == PlayerID then
				{Adjoin PlayerState NewValue}|T
			else 
				PlayerState|{ChangePlayerStatus T PlayerID NewValue}
			end
		end
	end

	% Retourne le record playerstate() du player avec l'id PLAYERID
	fun {GetPlayerState PlayersList PlayerID}
		case PlayersList of nil then nil
		[] PlayerState|T then 
			if(PlayerState.id == PlayerID) then 
				PlayerState
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
			% Correct ? le joueur dit oui il arrive ? Faut vérifier si on est bien au point de spawn non ?
			{Send Port initPosition(ID Position)}
			{Send GameStatePort changeID(ID)}
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
            of H|T then {System.show State} {TreatStream T {MatchHead H State}}
        end
    end
	% Head = Stream avec les messages donnés par la fonction main 
	% State = État de la partie
	fun {MatchHead Head State}
        case Head of nil then nil 
		[] changeID(ID) then 
			{System.show 'ok'}
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(id: ID)})}
		[] isAlive(ID ?Dead) then
			Dead = {GetPlayerState State.playersStatus ID}.hp =< 0 
			State
		% On donne l'id et le port du joueur qui doit être respawn 
		[] respawn(ID Port) then 
			{Send WindowPort initSoldier(ID {List.nth Input.spawnPoints ID.id})}
            {Send Port respawn()}
			% Prévenir les autres
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(currentposition: {List.nth Input.spawnPoints ID.id} hp: Input.startHealth)} )}
		[] move(ID Position Port ?HasMoved) then 
			%I est un record
			% On vérifie s'il a marché sur une mine juste après
			MovePlayerState in 
			MovePlayerState={CheckMines Port ID {MovePlayer Port ID State Position} Position State.mines}
			HasMoved=true
			MovePlayerState
        [] playerCharge(ID Weapon Port) then
            ActualGunCharge ActualMineCharge 
		in 
			if (Weapon == mine) then 
				ActualMineCharge = {GetPlayerState State.playersStatus ID}.chargemine
                if ActualMineCharge < Input.mineCharge then 
					{Send Port sayCharge(ID mine)}
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargemine:ActualMineCharge+1)} )}
				else 
					State
				end
			elseif (Weapon == gun) then 
				ActualGunCharge = {GetPlayerState State.playersStatus ID}.chargegun
                if ActualGunCharge < Input.gunCharge then 
					{Send Port sayCharge(ID gun)}
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargegun:ActualGunCharge+1)})}
				else 
					State
                end 
			else 
				State
			end
		[] useWeapon(ID Weapon Port) then
			TempState
		in
			if ({Record.label Weapon}==mine andthen ({GetPlayerState State.playersStatus ID}.chargemine == Input.mineCharge)) then 
				%On regarde que le player qui pose la mine est pas sur le flag (J'imagine qu'on peut pas poser sur un flag ?)
				if ({List.member {GetPlayerState State.playersStatus ID}.currentposition State.flags}==false andthen {GetPlayerState State.playersStatus ID}.currentposition == Weapon.pos) then
					%Dis a tous les joueurs qu'il a posé une mine
					{SayToAllPlayers PlayersPorts sayMinePlaced(ID Weapon)}
					%Display de mine
					{Send WindowPort putMine(Weapon)}
					TempState={Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargemine:0)})}
					% On merge 2 records pour ajouter la nouvelle mine
					{Adjoin TempState state(mines: {List.append State.mines [Weapon]})}
				else
					State
				end
			elseif ({Record.label Weapon}==gun andthen ({GetPlayerState State.playersStatus ID}.chargegun == Input.gunCharge)) then
				State
			else
				State
			end
		end 
    end


    thread
		% Create port for window
		WindowPort = {GUI.portWindow}

		% Open window
		{Send WindowPort buildWindow}
		{System.show buildWindow}
		{Delay 3000}

        % Create port for players
		PlayersPorts = {DoListPlayer Input.players Input.colors 1} 
		PlayersStatus = {CreatePlayerStatus PlayersPorts}
		GameStatePort = {StartGame PlayersStatus}
		
		{InitThreadForAll PlayersPorts PlayersStatus GameStatePort}

	end
end