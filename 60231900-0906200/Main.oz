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
	TryShootPlayer
	ValidHit
	FlagTaken
	SamePositionAsFlag
	ChangeFlags
	Time
	CheckFreeTile
	SpawnFood 
		CheckFreeTileHelper 
		RemoveFood
		CheckIfFoodOnPosition

	

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
	proc {SpawnFood StatePort}
		ListFreeTiles
		Pos
	in 
		{Delay ({OS.rand} mod (Input.foodDelayMax - Input.foodDelayMin) + Input.foodDelayMin)}
		ListFreeTiles = {CheckFreeTile Input.map 1}
		Pos = {List.nth ListFreeTiles ({OS.rand} mod ({Length ListFreeTiles} - 1 ) + 1 )}
		{Send StatePort spawnfood(food(pos:Pos))}
		{SpawnFood StatePort}
	end 
	fun {CheckIfFoodOnPosition Food NewPosition}
		%{System.show 'CheckIfFoodOnPosition\n\n'}
		%{System.show 'NewPosition'|NewPosition|nil}
		case Food of nil then false
		[] food(pos:Pos)|T then 
			if Pos == NewPosition then 
				%{System.show '---TRUE---\n\n'}
				true
			else
				{CheckIfFoodOnPosition T NewPosition}
			end
		end
	end 
	fun {RemoveFood Food Position}
		case Food of nil then nil
		[] food(pos:Pos)|T then 
			if Pos == Position then 
				T
			else
				food(pos:Pos)|{RemoveFood T Position}
			end
		end
	end 

	fun {CheckFreeTile Map RowNum}
		ResultRow in 
		case Map of nil then nil
		[] Row|T then
			ResultRow = {CheckFreeTileHelper Row RowNum 1}
			{Append ResultRow {CheckFreeTile Map.2 RowNum+1}}
		end 
	end

	fun {CheckFreeTileHelper List Row Column} 
		case List of nil then nil
			[] Tile|NextTile then 
				if(Tile == 0) then 
					pt(x:Row y: Column)|{CheckFreeTileHelper NextTile Row Column+1}
				else 
					{CheckFreeTileHelper NextTile Row Column+1}
				end
			end 
	end 

	proc {Main Port ID StatePort}
		Result 
		NewStateMove
		NewStateMine
		TestState
		IsDead
		IsDead2
		NewPosition
		PlayerID
        Kind
		HasMoved
		Fire
		TakeFlag
		Flag
		PlayerHasFlag
		PlayerHasFlagDead
		
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
		{System.show '2'}
		{Send StatePort move(PlayerID NewPosition Port HasMoved)}
		{Wait HasMoved}
		{System.show '3'}


        {Send Port chargeItem(ID Kind)}
		{Wait Kind}
		{Send StatePort playerCharge(ID Kind Port)}% Est-ce qu'on vérifie s'il est pas au max ?

		{Send Port fireItem(ID Fire)}
		{Wait Fire}
		{Send StatePort useWeapon(ID Fire Port)}% Est-ce qu'on vérifie s'il est pas au max ?

		{Send StatePort playerCanTakeFlag(ID TakeFlag)}
		{Wait TakeFlag}
		if TakeFlag then 
			{Send Port takeFlag(ID Flag)}
			{Wait Flag} 
			if Flag \=null then 
			{Send StatePort playerTakeFlag(ID Flag Port)}
			end 
		else
			{Send StatePort playerHasFlag(ID PlayerHasFlag)}
			{Wait PlayerHasFlag} 
			if PlayerHasFlag then
				PlayerDropFlag in 
				{Send Port dropFlag(ID PlayerDropFlag)}
				{Wait PlayerDropFlag}
				if(PlayerDropFlag\=null) then 
					{Send StatePort playerDroppedFlag(ID)}
				end
			end 
		end
		% On regarde s'il est mort, s'il est mort on enlève le drapeau 
		{Send StatePort isAlive(ID IsDead2)}
		if IsDead2 then 
			{Send StatePort playerHasFlag(ID PlayerHasFlagDead)}
			{Wait PlayerHasFlagDead} 
			if PlayerHasFlagDead then
			{Send StatePort playerDroppedFlag(ID)}
		end
	end 
		{Delay 500} % Pour afficher plus lentement, à enlever après
		{Main Port ID StatePort}
	end
	

	fun {MovePlayer Port ID State NewPosition}
		PlayerState Food NewStateFood NewHP NewPlayerState in 
		PlayerState = {GetPlayerState State.playersStatus ID}
		if {CheckValidMove NewPosition State ID PlayerState} then 
			% Bouge le player
			{Send WindowPort moveSoldier(ID NewPosition)}
			% Dis à tout le monde que le player a bougé 
			{SayToAllPlayers PlayersPorts sayMoved(ID NewPosition)}
			Food = {CheckIfFoodOnPosition State.food NewPosition}
			if Food then 
				{SayToAllPlayers PlayersPorts sayFoodEaten(ID food(pos:NewPosition))}
				{Send WindowPort removeFood(food(pos:NewPosition))}
				NewHP = {GetPlayerState State.playersStatus ID}.hp
				%{System.show 'Food'|Food|'NewPosition :'|NewPosition|'Hp'|NewHP|nil}
				{Send WindowPort lifeUpdate(ID NewHP+1)}
				NewStateFood = {Adjoin State state(food:{RemoveFood State.food NewPosition} playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hp:NewHP+1)})}
					NewPlayerState = {GetPlayerState NewStateFood.playersStatus ID}
				%{System.show 'NewStateFood'|NewStateFood|'NewHp :'|NewPlayerState.hp|nil}
			else 
				NewStateFood = State
				NewPlayerState = PlayerState
			end
			%{System.show 'NewPlayerState'|NewPlayerState|nil}
			% On merge 2 records pour ajouter la nouvelle position {ChangePlayerStatus} retourne une nouvelle liste avec la nouvelle position
			if NewPlayerState.hasflag\=nil then 
				NewFlags NewPlayerStatus in 
				%{System.show 'NewPlayerState.hasflag'|NewPlayerState.hasflag|'NewPosition :'|NewPosition|nil}
				{Send WindowPort removeFlag(NewPlayerState.hasflag)}
				{Send WindowPort putFlag({Adjoin NewPlayerState.hasflag flag(pos: NewPosition)})}
				NewFlags = {ChangeFlags NewStateFood.flags NewPlayerState.hasflag flag(pos:NewPosition)}
				NewPlayerStatus = {ChangePlayerStatus NewStateFood.playersStatus ID playerstate(currentposition:NewPosition hasflag:{Adjoin NewPlayerState.hasflag flag(pos: NewPosition)})}
				{Adjoin NewStateFood state(flags:NewFlags playersStatus: NewPlayerStatus)}
			else 
				{Adjoin NewStateFood state(playersStatus: {ChangePlayerStatus NewStateFood.playersStatus ID playerstate(currentposition:NewPosition)})}
				end 
			else 
			State
		end
	end
% -------Vérifie la validité d'une nouvelle position-------%	
	
	%3 conditions vérifiées : Pas un mouvement statique, pas un mouvement qui n'est pas dans le range et pas un mouvement en dehors de la map
	% TO DO : VÉRIFIER SI PAS DANS LA BASE ADVERSE
	fun {CheckValidMove NewPosition State ID PlayerState}
		LastPosition
	in
		LastPosition=PlayerState.currentposition
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
				NewPlayerState in 
				{Send WindowPort lifeUpdate(PlayerState.id PlayerState.hp-RemoveHP)}
				{SayToAllPlayers PlayersPorts sayDamageTaken(PlayerState.id RemoveHP PlayerState.hp-RemoveHP)}
				if(PlayerState.hp-RemoveHP=<0) then 
					{Send WindowPort removeSoldier(PlayerState.id)}
					{SayToAllPlayers PlayersPorts sayDeath(PlayerState.id)}
					%Si le joueur a le drapeau alors on dit a tout le monde que le drapeau est drop car il est mort
					if(PlayerState.hasflag\=nil) then 
						{SayToAllPlayers PlayersPorts sayFlagDropped(PlayerState.id PlayerState.hasflag)}
					end
					% On met hasflag: nil dans tous les cas c'est plus facile
					NewPlayerState = playerstate(hp:PlayerState.hp-RemoveHP hasflag:nil)
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant 
				else 
					NewPlayerState = playerstate(hp:PlayerState.hp-RemoveHP)
				end 
				{CheckOtherPlayersNearMines {Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus PlayerState.id NewPlayerState})} T Position}
				
			else
				{CheckOtherPlayersNearMines State T Position}
			end
		end
	end 

	%Regarde si un shoot de gun est valide en distance de manhattan
	fun {ValidHit PlayerPos WeaponPos}
		Distance
	in
		Distance={Abs PlayerPos.x-WeaponPos.x}+{Abs PlayerPos.y-WeaponPos.y}
		Distance==2 orelse Distance==1
	end

	%TryToShootPlayer renvoie le nouvel état des joueurs (si personne n'a été touché ca reste le meme)
	fun {TryShootPlayer Port ID State WeaponPos Players} 
		case Players of nil then State
		[] H|T then
			if H.currentposition==WeaponPos then
				{Send WindowPort lifeUpdate(H.id H.hp-1)}
				if(H.hp-1=<0) then 
					{Send WindowPort removeSoldier(H.id)}
					{SayToAllPlayers PlayersPorts sayDeath(H.id)}
					%Si le joueur a le drapeau alors on dit a tout le monde que le drapeau est drop car il est mort
					if(H.hasflag\=nil) then 
						{SayToAllPlayers PlayersPorts sayFlagDropped(H.id H.hasflag)}
					end
					% On met hasflag: nil dans tous les cas c'est plus facile
					{Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus H.id playerstate(hp:H.hp-1 hasflag:nil)})}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant 
				else
					{Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus H.id playerstate(hp:H.hp-1)})}
				end
			else
				{TryShootPlayer Port ID State WeaponPos T} 
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
				hasflag : nil
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


	fun {ChangeFlags FlagsList Flag NewValue}
		case FlagsList of nil then nil
		[] FlagRecord|T then
			if FlagRecord == Flag then
				{Adjoin FlagRecord NewValue}|T
			else 
				FlagRecord|{ChangeFlags T Flag NewValue}
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

	fun{SamePositionAsFlag Flags Color Position}
		case Flags of nil then false
		[]flag(pos:FlagPos color:FlagColor)|T then
			if FlagPos == Position andthen FlagColor \= Color then
				true
			else 
				{SamePositionAsFlag T Color Position}
			end
		end
	end 

	% Regarde si le flag est pris par un joueur et si la couleur est opposée à celle du joueur
	fun {FlagTaken PlayersList Color ID}
		case PlayersList of nil then false
		[] PlayerState|T then 
			if(PlayerState.hasflag \=nil andthen PlayerState.id \= ID) then 
				ColorPlayer 
				in 
				case PlayerState.id of nil then {FlagTaken T Color ID}
				[]id(name: _ id:_ color:ColorPlayer) then 
					if ColorPlayer\=Color then 
						true
					else 
						{FlagTaken T Color ID}
					end
				end
			else 
				{FlagTaken T Color ID}
			end
		end
	end

	proc {InitThreadForAll Players PlayersStatus GameStatePort}
		case Players
		of nil then
			{Send WindowPort initSoldier(null pt(x:0 y:0))}
			{DrawFlags Input.flags WindowPort}
			thread {SpawnFood GameStatePort} end
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
				state(mines:nil flags:Input.flags playersStatus:PlayersStatus food:nil)
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
		[] changeID(ID) then 
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
					% On merge 2 records pour ajouter la nouvelle mine
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargemine:0)} mines: {List.append State.mines [Weapon]})}
				else
					State
				end
			elseif ({Record.label Weapon}==gun andthen ({GetPlayerState State.playersStatus ID}.chargegun == Input.gunCharge)) then
				if {ValidHit {GetPlayerState State.playersStatus ID}.currentposition Weapon.pos} then
					{SayToAllPlayers PlayersPorts sayShoot(ID Weapon.pos)}
					TempState={TryShootPlayer Port ID {CheckMines Port ID State Weapon.pos State.mines} Weapon.pos State.playersStatus}
					{Adjoin TempState state(playersStatus:{ChangePlayerStatus TempState.playersStatus ID playerstate(chargegun:0)})}
				else
					State
				end
			else
				State
			end
		[]playerCanTakeFlag(ID Flag) then 
			PlayerState in
			PlayerState = {GetPlayerState State.playersStatus ID}
			Flag = (PlayerState.hasflag == nil) andthen {SamePositionAsFlag State.flags ID.color PlayerState.currentposition} andthen {Not {FlagTaken State.playersStatus ID ID.color} }
			State
		[]playerTakeFlag(ID Flag Port) then 
			{SayToAllPlayers PlayersPorts sayFlagTaken(ID Flag)}
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hasflag:Flag)})}
		[]playerHasFlag(ID PlayerHasFlag) then 
			if {GetPlayerState State.playersStatus ID}.hasflag \= nil then 
				PlayerHasFlag = true 
			else 
				PlayerHasFlag = false
			end
			State
		[] playerDroppedFlag(ID) then 
			{SayToAllPlayers PlayersPorts sayFlagDropped(ID {GetPlayerState State.playersStatus ID}.hasflag)}
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hasflag:nil)})}
		[] spawnfood(Food) then 
			{Send WindowPort putFood(Food)}
			{SayToAllPlayers PlayersPorts sayFoodAppeared(Food)}
			{Adjoin State state(food:{Append State.food [Food]})}
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