functor
import
	GUI
	Input
	PlayerManager
	System
	OS
	Application
define
	DoListPlayer
	InitThreadForAll
	PlayersPorts
	PlayersStatus
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
	ChangeFlags
	CheckFreeTile
	SpawnFood 
	CheckFreeTileHelper 
	RemoveFood
	CheckDead
	CheckAround
	
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

	% Fais spawn la food
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

	%Supprime la food à la position Position dans la liste Food et renvoie une nouvelle liste
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

	%Retourne toutes les cases qui sont vides (contiennent un 0)
	fun {CheckFreeTile Map RowNum}
		ResultRow in 
		case Map of nil then nil
		[] Row|T then
			ResultRow = {CheckFreeTileHelper Row RowNum 1}
			{Append ResultRow {CheckFreeTile T RowNum+1}}
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
		
		%Regarde s'il est en vie


		local 
			IsDead
		in
			{Send StatePort isAlive(ID IsDead)}
			if(IsDead==true) then 
				% S' il est mort on attend le temps de RESPAWNDELAY et ensuite on envoie le nouvel état au StatePort et on recommence la boucle depuis le début
				{Send StatePort playerDropFlag(ID)}
				{Delay Input.respawnDelay}
				{Send StatePort respawn(ID Port)}
			end
		end
		
		%Ask where the player want to go and move if its valid, if he walked on a mine then BOOM
		local
			NewPosition
			PlayerID
			IsDead
		in
			{Send Port move(PlayerID NewPosition)}
			{SimulatedThinking}% Il réfléchis
			{Wait NewPosition}{Wait PlayerID}
			{Send StatePort move(PlayerID NewPosition IsDead)}
			if IsDead then {Main Port ID StatePort} end
		end

		%Ask what weapon does the player want to charge
		local 
			Kind
			IsDead
		in
			{Send Port chargeItem(ID Kind)}
			{SimulatedThinking}% Il réfléchis
			{Wait Kind}
			{Send StatePort playerCharge(ID Kind Port IsDead)}% Est-ce qu'on vérifie s'il est pas au max ?
			if IsDead then {Main Port ID StatePort} end
		end

		%Ask what to shoot
		local 
			Fire
			IsDead
		in
			{Send Port fireItem(ID Fire)}
			{SimulatedThinking}% Il réfléchis
			{Wait Fire}
			{Send StatePort useWeapon(ID Fire IsDead)}
			if IsDead then {Main Port ID StatePort} end
		end

		%Ask if wether or not player want to take the flag
		local
			Flag
			IsDead
		in
			{Send Port takeFlag(ID Flag)}
			{SimulatedThinking}% Il réfléchis
			if Flag \=null then 
				{Send StatePort playerTakeFlag(ID Flag IsDead)}
			else
				{Send StatePort isAlive(ID IsDead)}
			end
			if IsDead then {Main Port ID StatePort} end
		end

		%Ask if wether or not player want to drop flag
		local 
			PlayerDroppedFlag
			IsDead
		in
			{Send StatePort isAlive(ID IsDead)}
			if {Not IsDead} then
				{Send Port dropFlag(ID PlayerDroppedFlag)}
				{SimulatedThinking}% Il réfléchis
				if PlayerDroppedFlag\=null then
					{Send StatePort playerDropFlag(ID)}
				end 
			end
		end

		{Main Port ID StatePort}
	end
	
	%Bouge le joueur si toutes les conditions sont vérifiées
	fun {MovePlayer ID State NewPosition ?Moved}
		PlayerState Food NewStateFood NewHP NewPlayerState 
	in 
		PlayerState = {GetPlayerState State.playersStatus ID}
		if {CheckValidMove NewPosition State ID PlayerState} then 
			% Bouge le player
			{Send WindowPort moveSoldier(ID NewPosition)}
			% Dis à tout le monde que le player a bougé 
			{SayToAllPlayers PlayersPorts sayMoved(ID NewPosition)}
			Food = {List.member food(pos:NewPosition) State.food}
			if Food then 
				{SayToAllPlayers PlayersPorts sayFoodEaten(ID food(pos:NewPosition))}
				{Send WindowPort removeFood(food(pos:NewPosition))}
				NewHP = {GetPlayerState State.playersStatus ID}.hp
				{Send WindowPort lifeUpdate(ID NewHP+1)}
				NewStateFood = {Adjoin State state(food:{RemoveFood State.food NewPosition} playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hp:NewHP+1)})}
				NewPlayerState = {GetPlayerState NewStateFood.playersStatus ID}
			else 
				NewStateFood = State
				NewPlayerState = PlayerState
			end
			% On merge 2 records pour ajouter la nouvelle position {ChangePlayerStatus} retourne une nouvelle liste avec la nouvelle position
			Moved=true
			if NewPlayerState.hasflag\=nil then 
				%Si il a le drapeau, on bouge le drapeau dans le state et sur le GUI
				NewFlags NewPlayerStatus in 
				{Send WindowPort removeFlag(NewPlayerState.hasflag)}
				{Send WindowPort putFlag({Adjoin NewPlayerState.hasflag flag(pos: NewPosition)})}
				NewFlags = {ChangeFlags NewStateFood.flags NewPlayerState.hasflag flag(pos:NewPosition)}
				NewPlayerStatus = {ChangePlayerStatus NewStateFood.playersStatus ID playerstate(currentposition:NewPosition hasflag:{Adjoin NewPlayerState.hasflag flag(pos: NewPosition)})}
				{Adjoin NewStateFood state(flags:NewFlags playersStatus: NewPlayerStatus)}
			else 
				{Adjoin NewStateFood state(playersStatus: {ChangePlayerStatus NewStateFood.playersStatus ID playerstate(currentposition:NewPosition)})}
			end 
		else 
			Moved=false
			State
		end
	end

% -------Vérifie la validité d'une nouvelle position-------%	
	
	%5 conditions vérifiées : Pas un mouvement statique, pas un mouvement qui n'est pas dans le range, pas un mouvement en dehors de la map, pas un mouvement qui rentre dans un autre joueur et check si on rentre pas dans un wall/spawn
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
			if H.id\=ID andthen NewPosition==H.currentposition andthen H.hp>0 then
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
	fun {CheckMines State Position}
		StatePlayerAfterMines 
		fun {IterateInMines State Position LMine}
			case LMine of nil then State
			[] mine(pos:MinePos)|T then
				if MinePos == Position then
					StatePlayerAfterMines = {CheckOtherPlayersNearMines State State.playersStatus Position}
					{Send WindowPort removeMine(mine(pos:MinePos))}
					{SayToAllPlayers PlayersPorts sayMineExplode(mine(pos:MinePos))}
					% Regarder si d'autres personnes sont pas sur la mine
					{CheckAround {Adjoin StatePlayerAfterMines state(mines:{RemoveMineFromList State.mines Position})} Position}
				else
					{IterateInMines State Position T}
				end
			end
		end
	in
		{IterateInMines State Position State.mines}
	end

	%Implémenation des réaction en chaine des mines
	fun {CheckAround State Position}
		fun {CheckEachSide N State Position}
			X
			Y
		in
			if N<3 then
				X=Position.x+(N mod 2)
				Y=Position.y+((N-1) mod 2)
				%On regarde si c'est pas sur un bord pour eviter le calcul pour rien
				{CheckEachSide N+1 {CheckMines State pt(x:X y:Y)} Position}
			else
				State
			end
		end
	in 
		{CheckEachSide ~1 State Position}
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

	%Regarde pour infliger des dégats aux joueurs a coté des mines
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
					%Si le joueur a le drapeau alors on dit a tout le monde que le drapeau est drop car il est mort
					if(PlayerState.hasflag\=nil) then 
						{SayToAllPlayers PlayersPorts sayFlagDropped(PlayerState.id PlayerState.hasflag)}
					end
					{SayToAllPlayers PlayersPorts sayDeath(PlayerState.id)}
					% On met hasflag: nil dans tous les cas c'est plus facile
					NewPlayerState = playerstate(currentposition:pt(x:~1 y:~1) hp:PlayerState.hp-RemoveHP hasflag:nil)
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

	%Regarde si un shoot de gun est valide en distance de manhattan, et que l'on ne tire pas a travers un mur
	fun {ValidHit PlayerPos WeaponPos}
		Distance
		X
		Y
	in
		if WeaponPos.x=<Input.nRow andthen WeaponPos.y=<Input.nColumn andthen WeaponPos.x>0 andthen WeaponPos.y>0 then
			X={Abs PlayerPos.x-WeaponPos.x}
			Y={Abs PlayerPos.y-WeaponPos.y}
			Distance=X+Y
			if Distance==2 then
				if {Abs X-Y}==0 then 
					{Not ({List.nth {List.nth Input.map PlayerPos.x} WeaponPos.y}==3) andthen ({List.nth {List.nth Input.map WeaponPos.x} PlayerPos.y}==3)}
				else
					{List.nth {List.nth Input.map {Int.'div' (PlayerPos.x+WeaponPos.x) 2}} {Int.'div' (PlayerPos.y+WeaponPos.y) 2}}\=3
				end
			else
				Distance==1
			end
		else
			false
		end
	end

	%TryToShootPlayer renvoie le nouvel état des joueurs (si personne n'a été touché ca reste le meme)
	fun {TryShootPlayer ID State WeaponPos Players} 
		case Players of nil then State
		[] H|T then
			if H.currentposition==WeaponPos then
				{Send WindowPort lifeUpdate(H.id H.hp-1)}
				if(H.hp-1=<0) then 
					{Send WindowPort removeSoldier(H.id)}
					%Si le joueur a le drapeau alors on dit a tout le monde que le drapeau est drop car il est mort
					if(H.hasflag\=nil) then 
						{SayToAllPlayers PlayersPorts sayFlagDropped(H.id H.hasflag)}
					end
					{SayToAllPlayers PlayersPorts sayDeath(H.id)}
					% On met hasflag: nil dans tous les cas c'est plus facile
					{Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus H.id playerstate(currentposition:pt(x:~1 y:~1) hp:H.hp-1 hasflag:nil)})}
					% SKIP LE RESTE DE SON TOUR. Je vois pas comment faire pour l'instant 
				else
					{Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus H.id playerstate(hp:H.hp-1)})}
				end
			else
				{TryShootPlayer ID State WeaponPos T} 
			end
		end
	end

	%Regarde si le player ID est mort 
	fun {CheckDead State ID}
		{GetPlayerState State.playersStatus ID}.hp =< 0 
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

	%Change le Flag 'Flag' de la liste pour lui donner une nouvelle pos en général
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

	%Début de la partie
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

	%Port object
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
			%Change les ID du format <idnum> a <id> nécéssaire pour les dégats des mines
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(id: ID)})}
		[] isAlive(ID ?Dead) then
			Dead = {CheckDead State ID}
			State
		% On donne l'id et le port du joueur qui doit être respawn 
		[] respawn(ID Port) then 
			{Send WindowPort initSoldier(ID {List.nth Input.spawnPoints ID.id})}
            {Send Port respawn()}
			% Prévenir les autres
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(currentposition: {List.nth Input.spawnPoints ID.id} hp: Input.startHealth)} )}
		[] move(ID Position ?Dead) then
			% On vérifie s'il a marché sur une mine juste après
			MovePlayerState
			MineState
			Replaced
		in
			if {CheckDead State ID} then 
				Dead=true 
				State
			else
				MovePlayerState={MovePlayer ID State Position Replaced}
				if Replaced then
					MineState={CheckMines MovePlayerState Position}
				else
					MineState=MovePlayerState
				end
				Dead=false
				MineState
			end
        [] playerCharge(ID Weapon Port ?Dead) then
            ActualGunCharge ActualMineCharge 
		in 
			%Recharge munitions
			if {CheckDead State ID} then 
				Dead=true  
				State
			else
				if (Weapon == mine) then 
					ActualMineCharge = {GetPlayerState State.playersStatus ID}.chargemine
					if ActualMineCharge < Input.mineCharge then 
						{Send Port sayCharge(ID mine)}
						Dead=false
						{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargemine:ActualMineCharge+1)} )}
					else 
						Dead=false
						State
					end
				elseif (Weapon == gun) then 
					ActualGunCharge = {GetPlayerState State.playersStatus ID}.chargegun
					if ActualGunCharge < Input.gunCharge then 
						{Send Port sayCharge(ID gun)}
						Dead=false
						{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargegun:ActualGunCharge+1)})}
					else 
						Dead=false
						State
					end 
				else 
					Dead=false
					State
				end
			end
		[] useWeapon(ID Weapon ?Dead) then
			TempState
		in
			if {CheckDead State ID} then 
				Dead=true  
				State
			else
				%Type=mine & Assez de charge pour placer & Pas de mine la ou on veut poser & Pas sur le drapeau & La position souhaitée est en dessous du joueur 
				if ({Record.label Weapon}==mine andthen ({GetPlayerState State.playersStatus ID}.chargemine == Input.mineCharge) andthen  {List.member Weapon State.mines}==false andthen {List.member {GetPlayerState State.playersStatus ID}.currentposition State.flags}==false andthen {GetPlayerState State.playersStatus ID}.currentposition == Weapon.pos) then 
					%Dis a tous les joueurs qu'il a posé une mine
					{SayToAllPlayers PlayersPorts sayMinePlaced(ID Weapon)}
					%Display de mine
					{Send WindowPort putMine(Weapon)}
					Dead=false
					% On merge 2 records pour ajouter la nouvelle mine
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(chargemine:0)} mines: {List.append State.mines [Weapon]})}
				%Type=mine & Assez de charge pour tirer & Tire Valide
				elseif ({Record.label Weapon}==gun andthen ({GetPlayerState State.playersStatus ID}.chargegun == Input.gunCharge) andthen {ValidHit {GetPlayerState State.playersStatus ID}.currentposition Weapon.pos}) then
					{SayToAllPlayers PlayersPorts sayShoot(ID Weapon.pos)}
					TempState={TryShootPlayer ID {CheckMines State Weapon.pos} Weapon.pos State.playersStatus}
					Dead=false
					{Adjoin TempState state(playersStatus:{ChangePlayerStatus TempState.playersStatus ID playerstate(chargegun:0)})}
				else
					Dead=false
					State
				end
			end
		[]playerTakeFlag(ID Flag ?Dead) then 
			PlayerState
		in
			%Essaye de prendre le drapeau
			if {CheckDead State ID} then
				Dead=true
				State
			else
				PlayerState={GetPlayerState State.playersStatus ID} 
				if ((PlayerState.hasflag == nil) andthen (PlayerState.currentposition==Flag.pos) andthen (PlayerState.id.color\=Flag.color) andthen {List.member Flag State.flags}) then
					{SayToAllPlayers PlayersPorts sayFlagTaken(ID Flag)}
					Dead=false
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hasflag:Flag)})}
				else
					Dead=false
					State
				end
			end
		[] playerDropFlag(ID) then
			if {GetPlayerState State.playersStatus ID}.hasflag \= nil then 
				Player
				Case
			in
				%Drop le drapeau
				Player={GetPlayerState State.playersStatus ID}
				Case={List.nth {List.nth Input.map Player.currentposition.x} Player.currentposition.y}
				if Case\=0 andthen Player.id.color=={List.nth Input.colors Case} then
					{System.show 'La team '|Player.id.color|' remporte la partie !'}
					{Delay 3000}
					{Application.exit 0}
					State
				else
					{SayToAllPlayers PlayersPorts sayFlagDropped(ID Player.hasflag)}
					{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID playerstate(hasflag:nil)})}
				end
			else
				State
			end
		[] spawnfood(Food) then
			%Ajoute une food a la liste et la fait apparaitre
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
		{Delay 5000}
        % Create port for players
		PlayersPorts = {DoListPlayer Input.players Input.colors 1} 
		PlayersStatus = {CreatePlayerStatus PlayersPorts}
		GameStatePort = {StartGame PlayersStatus}
		{InitThreadForAll PlayersPorts PlayersStatus GameStatePort}

	end
end