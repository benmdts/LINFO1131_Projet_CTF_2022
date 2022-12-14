functor
import
	Input
export
	portPlayer:StartPlayer
define
	% Vars
	MapWidth = {List.length Input.map}
    MapHeight = {List.length Input.map.1}

	% Functions
	StartPlayer
	TreatStream
	MatchHead

	% Message functions
	InitPosition
	Move
	SayMoved
	SayMineExplode
	SayDeath
	SayDamageTaken
	SayFoodAppeared
	SayFoodEaten
	SayFlagTaken
	SayFlagDropped
	ChargeItem
	SayCharge
	FireItem
	SayMinePlaced
	SayShoot
	TakeFlag
	DropFlag
	Respawn
	CreatePlayerStatus
	ChangePlayerStatus
	GetPlayerState
	RemoveFromList
	ChangeFlags
	GetEnemyColor
	ShortestPath
	CreatePath
	ShortestPathHelper
	Visit
	ModifyList
	ModifyListHelper
	CreateMatrix
	CreateRow
    GetFlag
	Distance
	InManhattan
    GPS
    GetEnemyWhoHaveFlag
	GetEnemyNearestFlag
	SearchFreeTile
	IsNoWall
	IsAllyAt
	
in

	% Renvoie le chemin le plus rapide de la map pour aller de StartPosition à FinalPosition. En évitant les murs et la base ennemie des ennemis
	% StartPosition et FinalPosition sont de type pt(x: y:)
	fun {ShortestPath Map StartPosition FinalPosition ID}
		Sx Sy Dx Dy Matrix Src Queue Result in 
		Sx = StartPosition.x
		Sy = StartPosition.y
		Dx = FinalPosition.x
		Dy = FinalPosition.y
		Matrix = {CreateMatrix Map 1 StartPosition (ID mod 2)}
		Src = {List.nth {List.nth Matrix Sx} Sy}
		Queue = [Src]
		Result = {ShortestPathHelper Matrix Queue Dx Dy}
		if Result == nil then 
			nil
		else
			{Reverse {CreatePath nil Result}}.2
		end
	end 
	%Renvoie le chemin 
	fun {CreatePath Path P}
		if P==nil then 
			Path
		else 
			{CreatePath {Append Path [pt(x:P.x y:P.y)]} P.prev}
		end
	end
	% Algorithme BFS
	fun{ShortestPathHelper Matrix Queue Dx Dy}
		Head P Tail in 
			{List.takeDrop Queue 1 Head Tail}
			P = Head.1
			
			if(P\=nil) then 
				if(P.x==Dx andthen P.y==Dy) then 
					P
				else 
				NewQueue1 NewQueue2 NewQueue3 NewQueue4 NewMatrix1 NewMatrix2 NewMatrix3 NewMatrix4 
				in 
					{Visit Matrix Tail P.x-1 P.y P NewQueue1 NewMatrix1}
				{Visit NewMatrix1 NewQueue1 P.x P.y-1 P NewQueue2 NewMatrix2}
					{Visit NewMatrix2 NewQueue2 P.x+1 P.y P NewQueue3 NewMatrix3}
				{Visit NewMatrix3 NewQueue3 P.x P.y+1 P NewQueue4 NewMatrix4}
					if {Length NewQueue4} >0 then 
						{ShortestPathHelper NewMatrix4 NewQueue4 Dx Dy}
					else 
						nil
					end
				end
			else 
				nil
			end
	end
	% Regarde si la disatnce de l'élément à la position X Y est à une plus petite distance que l'élément Previous
	% Si oui modifie Matrix avec l'élément à la position X Y  et l'ajoute à la queue
	proc {Visit Matrix Queue X Y Previous ?NewQueue ?NewMatrix}

		if X=<0 orelse X> {Length Matrix} orelse Y=<0 orelse Y > {Length Matrix.1} orelse {List.nth {List.nth Matrix X} Y}==nil then 
			NewQueue = Queue
			NewMatrix = Matrix
		else
			Dist P in 
				Dist = Previous.dist + 1
				P = {List.nth {List.nth Matrix X} Y}
				if Dist < P.dist then 
					NewMatrix = {ModifyList Matrix X Y tile(dist:Dist prev:Previous)}
					NewQueue = {Append Queue [{Adjoin P tile(dist:Dist prev: Previous)}]}
					%{Browse NewMatrix}
					%{Browse NewQueue}
				else 
				NewQueue = Queue
				NewMatrix = Matrix
				end
		end
	end
	%Renvoie une nouvelle matrice avec l'élement à la position X Y valant Value
	fun {ModifyList Matrix Row Column Value}
		Head Tail in
			{List.take Matrix Row-1 Head}
			{List.drop Matrix Row Tail}
			{Append{Append Head[{ModifyListHelper {List.nth Matrix Row} Column Value}]}Tail}
	end
	fun {ModifyListHelper Row Column Value}
		Head Tail in 
			{List.take Row Column-1 Head}
			{List.drop Row Column Tail}
			{Append{Append Head [{Adjoin {List.nth Row Column} Value}]}Tail}
			
	end
	% Crée une matrice avec de même taille que Map
	fun {CreateMatrix Map Row Start Team}
		if Row =< {Length Map} then 
			{CreateRow Map Row 1 Start Team}|{CreateMatrix Map Row + 1 Start Team}
		else 
			nil
		end 
	end
	%Crée une liste, si la valeur de l'élément dans Map à la position X Y vaut 3  alors on ajoute nil sinon on ajoute
	%tile(x:Row y:Column dist:999999 prev: nil) sauf si X Y vaut Start.x et Start.y alors on ajoute tile(x:Row y:Column dist:0 prev: nil). 
	fun {CreateRow Map Row Column Start Team}
		Value in 
		if Column =< {Length Map.1} then 
			Value = {List.nth {List.nth Map Row} Column}
			if Value\=3 andthen Start.x==Row andthen Start.y == Column andthen Team\=Value-1 then
				tile(x:Row y:Column dist:0 prev: nil)|{CreateRow Map Row Column+1 Start Team}
			elseif Value\=3 andthen Team\=Value-1 then 
				tile(x:Row y: Column dist:999999 prev: nil)|{CreateRow Map Row Column+1 Start Team}
			else 
				nil|{CreateRow Map Row Column+1 Start Team}
			end 
		else 
			nil 
		end
	end 
	%Initialisation du player
	fun {StartPlayer Color ID}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream
			 	Stream
				state(
					id:id(name:player059tactical color:Color id:ID)
					position:{List.nth Input.spawnPoints ID}
					hp:Input.startHealth
					flags:Input.flags
					mineReloads:0
					gunReloads:0
					startPosition:{List.nth Input.spawnPoints ID}
					mines:nil
					playersStatus : {CreatePlayerStatus 1 ID}
					food: nil
					hasflag : nil
					path : nil
					teamColor : {List.nth Input.colors ID}
                    allyHasFlag:false
					allyHolderId:0
                    enemyHasFlag:false
				)
			}
		end
		Port
	end
	%Retourne le Flag de la couleur
	fun {GetFlag Flags Color}
		case Flags of nil then nil 
		[]Flag|T then 
			if Color == Flag.color then 
				Flag
			else
				{GetFlag T Color}
			end 
		end 
	end
	%On cree la liste des autres joueurs
	fun {CreatePlayerStatus Index PlayerIndex} 
		if {Length Input.spawnPoints} ==Index-1 then nil
		else  
			if Index \= PlayerIndex then 
			playerstate(
                currentposition: {List.nth Input.spawnPoints Index}
				hp : Input.startHealth
				id : Index
				hasflag : nil
				startPosition: {List.nth Input.spawnPoints Index}
				teamColor : {List.nth Input.colors Index}
				)|{CreatePlayerStatus Index+1 PlayerIndex}
			else 
				{CreatePlayerStatus Index+1 PlayerIndex}
			end
		end 
	end 
	%Renvoie la couleure ennemie
	fun {GetEnemyColor ID}
		if(ID>1) then 
			{List.nth Input.colors ID-1}
		else 
			{List.nth Input.colors ID+1}
		end
	end
	%Renvoie le state avec la nouvelle valeure
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
	%Retourne le state du playerid
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
	%Retire le Nieme element de la liste
	fun {RemoveFromList List Position}
		case List of nil then nil
		[] H|T then 
			if H.pos == Position then 
				T
			else 
				H|{RemoveFromList T Position}
			end
		end 
	end
	%Change la pos du drapeau de la couleur Color
	fun {ChangeFlags FlagsList Color NewValue}
		case FlagsList of nil then nil
		[] FlagRecord|T then
			if FlagRecord.color == Color then
				{Adjoin FlagRecord NewValue}|T
			else 
				FlagRecord|{ChangeFlags T Color NewValue}
			end
		end
	end
	%Port Object
    proc{TreatStream Stream State}
        case Stream
            of H|T then {TreatStream T {MatchHead H State}}
        end
    end

	fun {MatchHead Head State}
        case Head 
            of initPosition(?ID ?Position) then {InitPosition State ID Position}
            [] move(?ID ?Position) then {Move State ID Position}
            [] sayMoved(ID Position) then {SayMoved State ID Position}
            [] sayMineExplode(Mine) then {SayMineExplode State Mine}
			[] sayFoodAppeared(Food) then {SayFoodAppeared State Food}
			[] sayFoodEaten(ID Food) then {SayFoodEaten State ID Food}
			[] chargeItem(?ID ?Kind) then {ChargeItem State ID Kind}
			[] sayCharge(ID Kind) then {SayCharge State ID Kind}
			[] fireItem(?ID ?Kind) then {FireItem State ID Kind}
			[] sayMinePlaced(ID Mine) then {SayMinePlaced State ID Mine} 
			[] sayShoot(ID Position) then {SayShoot State ID Position}
            [] sayDeath(ID) then {SayDeath State ID}
            [] sayDamageTaken(ID Damage LifeLeft) then {SayDamageTaken State ID Damage LifeLeft}
			[] takeFlag(?ID ?Flag) then {TakeFlag State ID Flag}
			[] dropFlag(?ID ?Flag) then {DropFlag State ID Flag}
			[] sayFlagTaken(ID Flag) then {SayFlagTaken State ID Flag}
			[] sayFlagDropped(ID Flag) then {SayFlagDropped State ID Flag}
			[] respawn() then {Respawn State}
        end
    end

	%Initialisation de la position

	fun {InitPosition State ?ID ?Position}
		ID = State.id
		Position = State.startPosition
		State
	end

	%Fonction move avec algorithme avancé de déplacement
	fun {Move State ?ID ?Position}
        NewState
    in
		ID = State.id
		if State.allyHasFlag then
			local EnemyNearFlag NewPath in
				EnemyNearFlag ={GetEnemyNearestFlag State.playersStatus State.teamColor {GetFlag State.flags State.teamColor}.pos}.2
				if EnemyNearFlag == nil then 
					NewPath=nil
				else 
					NewPath={ShortestPath Input.map State.position EnemyNearFlag.currentposition State.id.id}
				end
				if NewPath==nil then
					NewState={Adjoin State state(path :{SearchFreeTile State.position pt(x:0 y:0) State})}
				elseif {IsAllyAt State.playersStatus NewPath.1 State.teamColor} then
					NewState={Adjoin State state(path :{SearchFreeTile State.position pt(x:NewPath.1.x-State.position.x y:NewPath.1.y-State.position.y) State})}
				else
					NewState={Adjoin State state(path :NewPath)}
				end
			end
		else
			if State.path==nil orelse State.enemyHasFlag then
				NewState={Adjoin State state(path :{GPS State})}
			else
				NewState=State
			end
		end
		if NewState.path == nil then
			Position=NewState.position
		else
        	Position = NewState.path.1
		end
		NewState
	end

	%Regarde si un joueur de la couleur 'Color' est a la Position 'Position'
	fun {IsAllyAt PList Position Color}
		case PList of nil then false 
		[] H|T then
			if H.currentposition==Position andthen Color==H.teamColor then true
			else {IsAllyAt T Position Color} end
		end
	end

	%On regarde ou se mettre pour laisser passer le porteur de drapeau sachant que le porteur du drapeau se trouve en X Y par rapport a nous
	fun {SearchFreeTile Pos PosRelative State}
		if PosRelative\=pt(x:0 y:~1) andthen {IsNoWall pt(x:Pos.x+0 y:Pos.y-1)} andthen {Not {IsAllyAt State.playersStatus pt(x:Pos.x y:Pos.y-1) State.teamColor}} then [pt(x:Pos.x y:Pos.y-1)]
		elseif PosRelative\=pt(x:0 y:1) andthen {IsNoWall pt(x:Pos.x+0 y:Pos.y+1)} andthen {Not {IsAllyAt State.playersStatus pt(x:Pos.x y:Pos.y+1) State.teamColor}} then [pt(x:Pos.x y:Pos.y+1)]
		elseif PosRelative\=pt(x:~1 y:0) andthen {IsNoWall pt(x:Pos.x-1 y:Pos.y)} andthen {Not {IsAllyAt State.playersStatus pt(x:Pos.x-1 y:Pos.y) State.teamColor}} then [pt(x:Pos.x-1 y:Pos.y)]
		elseif PosRelative\=pt(x:1 y:0) andthen {IsNoWall pt(x:Pos.x+1 y:Pos.y)} andthen {Not {IsAllyAt State.playersStatus pt(x:Pos.x+1 y:Pos.y) State.teamColor}} then [pt(x:Pos.x+1 y:Pos.y)]
		else nil end
	end

	%On regarde si il y a un mur a la position 'Position'
	fun {IsNoWall Position}
		if Position.x>0 andthen Position.x<MapWidth andthen Position.y>0 andthen Position.y<MapHeight then
			{List.nth {List.nth Input.map Position.x} Position.y}\=3
		else
			false
		end
	end

    %Retourne le path a prendre ne fonction du state
    fun {GPS State}
        if State.hasflag\=nil then
            %Run base with flag
            {ShortestPath Input.map State.position State.startPosition State.id.id}
        elseif State.enemyHasFlag then
            %Try to kill enemy with flag except if we are near to take flag we continue to take it
			if {Not State.allyHasFlag} andthen {Distance State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos}=<2 then
				{ShortestPath Input.map State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos State.id.id}
			else
            	{ShortestPath Input.map State.position {GetEnemyWhoHaveFlag State.playersStatus State.teamColor}.currentposition State.id.id}
			end
        else
            %On va chercher notre flag le plus rapidement possible
            {ShortestPath Input.map State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos State.id.id}
        end
    end

	%Renvoie le state de l'ennemi qui a le state
    fun {GetEnemyWhoHaveFlag PlayersList Color}
        case PlayersList of nil then nil
		[] PlayerState|T then 
			if(PlayerState.teamColor \= Color andthen PlayerState.hasflag\=nil) then 
				PlayerState
			else 
				{GetEnemyWhoHaveFlag T Color}
			end
		end
    end

	%Renvoie le state du joueur ennemi le plus pres du flag
	fun {GetEnemyNearestFlag PlayersList Color FlagPos}
		case PlayersList of nil then 1000|nil
		[] PlayerState|T then 
			if(PlayerState.teamColor \= Color andthen PlayerState.hp>0) then 
				local 
					Second
					DistancePlayer
				in
					Second={GetEnemyNearestFlag T Color FlagPos}
					DistancePlayer={Distance PlayerState.currentposition FlagPos}
					if DistancePlayer =< Second.1 then
						DistancePlayer|PlayerState
					else
						Second
					end
				end
			else 
				{GetEnemyNearestFlag T Color FlagPos}
			end
		end
	end


	% Enregistre quand quelqun bouge, si c'est le joueur alors on avance dans le path
	fun {SayMoved State ID Position}
		NewState PlayerState in 
		if ID == State.id then 
			if(State.hasflag\=nil) then
				if State.path==nil then
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnemyColor ID.id} flag(pos:Position)} position:Position path: nil)}
				else
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnemyColor ID.id} flag(pos:Position)} position:Position path: State.path.2)}
				end
			else
				if State.path==nil then
					NewState = {Adjoin State state(position:Position path: nil)}
				else
					NewState = {Adjoin State state(position:Position path: State.path.2)}
				end
			end 
		else
			PlayerState = {GetPlayerState State.playersStatus ID.id}
			if PlayerState.hp==0 then 
				NewState = {Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:Position hp:Input.startHealth)})} 
			else 
				if(PlayerState.hasflag\=nil) then
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnemyColor ID.id} flag(pos:Position)} playersStatus:{ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:Position)})}
				else
					NewState = {Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:Position)})} 
				end 
			end
		end
		NewState
	end



	%Enregistre qu'une mine explose et la retire
	fun {SayMineExplode State Mine}
		{Adjoin State state(mines:{RemoveFromList State.mines Mine.pos})}
	end

	%Enregistre qu'une food apparait et l'enregistre
	fun {SayFoodAppeared State Food}
		{Adjoin State state(food:{Append State.food [Food]})}
	end

	%Rajoute un hp a la personne qui mange
	fun {SayFoodEaten State ID Food}
		NewPlayerState NewState in 
		if ID == State.id then 
			NewState = {Adjoin State state(food:{RemoveFromList State.food Food.pos} hp: State.hp+1)}
		else
		NewPlayerState = {ChangePlayerStatus State.playersStatus ID.id playerstate(hp: {GetPlayerState State.playersStatus ID.id}.hp+1)}
		NewState = {Adjoin State state(food:{RemoveFromList State.food Food.pos} playersStatus: NewPlayerState)}
		end
		NewState
	end

	%Choisis l'arme qu'il recharge
	fun {ChargeItem State ?ID ?Kind} 
		ID = State.id
		if (State.gunReloads\=Input.gunCharge)then
			Kind = gun
		elseif (State.mineReloads\=Input.mineCharge) then 
			Kind = mine
		else
			Kind = null
		end
		State
	end

	%Ajoute une balle en fonction de l'arme dans notre state
	fun {SayCharge State ID Kind}
		if Kind==gun then
			{Adjoin State state(gunReloads:State.gunReloads+1)}
		else
			{Adjoin State state(mineReloads:State.mineReloads+1)}
		end
	end

	%Choisis ou et avec quoi tirer
	fun {FireItem State ?ID ?Kind}
        ManRange
    in
        ID = State.id
        if (State.mineReloads==Input.mineCharge) andthen State.hasflag\=nil then
            Kind=mine(pos:pt(x:State.position.x y:State.position.y))
        elseif (State.gunReloads==Input.gunCharge) then 
			if ({Length State.path}>0 andthen {Member mine(pos:State.path.1) State.mines} andthen {Not{IsAllyAt State.playersStatus pt(State.path.1) teamColor}}) then 
				Kind = gun(pos:State.path.1)
            elseif({Length State.path}>1 andthen {Member mine(pos:State.path.2.1) State.mines} andthen {Not{IsAllyAt State.playersStatus pt(State.path.2.1) teamColor}}) then 
				Kind = gun(pos:State.path.2.1)
            elseif {InManhattan 2 player State}\=nil then 
                ManRange={InManhattan 2 player State}
                Kind =gun(pos:ManRange.1.currentposition)
            else 
                Kind = null
            end
        else 
            Kind = null
        end
        State
    end

	% Ajoute une mine a la liste et set nos charges a 0 si on tire
	fun {SayMinePlaced State ID Mine}
		if (ID == State.id) then
			{Adjoin State state(mines: {Append State.mines [Mine]} mineReloads:0)}
		else
			{Adjoin State state(mines: {Append State.mines [Mine]})}
		end
	end
	
	%On enleve une charge a gunReloads si c'est nous qui tirons
	fun {SayShoot State ID Position}
		if (ID == State.id) then
			{Adjoin State state(gunReloads:0)}
		else
			State
		end
	end

	% On enregistre que ID est mort
	fun {SayDeath State ID}
		if ID == State.id then 
			{Adjoin State state(position:State.startPosition hp:0 )}
		else
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:{GetPlayerState State.playersStatus ID.id}.startPosition hp:0)})}
		end 
	end

	%On enregistre que ID a pris des dmg
	fun {SayDamageTaken State ID Damage LifeLeft}
		if ID == State.id then 
			{Adjoin State state(hp:LifeLeft)}
		else
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hp:LifeLeft)})}
		end 
    end

	%Ramasse le flag si on est dessus
	fun {TakeFlag State ?ID ?Flag}
		Color in 
		ID = State.id
		Color = {GetEnemyColor ID.id}
		if {Member flag(pos:State.position color:Color) State.flags} then 
			Flag = flag(pos:State.position color:Color)
		else 
			Flag = null
		end
		State
	end
			
	%Drop le flag si on est dans la base
	fun {DropFlag State ?ID ?Flag}
		Team Tile in 
		ID = State.id
		Team=ID.id mod 2
		Tile={List.nth {List.nth Input.map State.position.x} State.position.y}
		if State.hasflag \=nil then 
		    if (Team == 1 andthen Tile ==1) orelse (Team == 0 andthen Tile ==2) then 
			    Flag = flag(pos: State.position color: {GetEnemyColor ID.id})
		    else
			    Flag = null
		    end
        else 
            Flag = null 
		end
		State
	end

	%On enregistre que ID a pris le Flag
	fun {SayFlagTaken State ID Flag}
		NewState in 
		if ID == State.id then
			NewState = {Adjoin State state(hasflag:Flag path:nil)}
		else
			if Flag.color \= State.teamColor then 
				NewState = {Adjoin State state(allyHolderId:ID.id allyHasFlag:true path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:Flag)})}
			else
				NewState = {Adjoin State state(enemyHasFlag:true path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:Flag)})}
			end
		end 
		NewState 
	end

	%On enregistre que ID a drop le flag
	fun {SayFlagDropped State ID Flag}
		if ID == State.id then 
			{Adjoin State state(hasflag:nil path:nil)}
		elseif Flag.color \= State.id.color then
			{Adjoin State state(allyHasFlag:false path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)})}
		else
			{Adjoin State state(enemyHasFlag:false path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)})}
		end 
	end

	%On respawn
	fun {Respawn State}
		{Adjoin State state(hp:Input.startHealth position:State.startPosition path:nil)}
	end

	%Calcule la mannhatan distance entre 2 pos
	fun {Distance Pos1 Pos2}
		{Abs Pos1.x-Pos2.x}+{Abs Pos1.y-Pos2.y}
	end

	%Renvoie la liste des items 'ToFind' en manathan distance 'N' de nous
	fun {InManhattan N ToFind State}
        fun {SearchPlayer N Pos LPlayer}
            case LPlayer of nil then nil
            [] H|T then
                if H.teamColor\=State.teamColor andthen H.currentposition\=nil andthen {Distance Pos H.currentposition}=<N andthen H.hp>0 then 
                    H|{SearchPlayer N Pos T}
                else
                    {SearchPlayer N Pos T}
                end
            end
        end
        fun {SearchMine N Pos LMine}
            case LMine of nil then nil
            [] H|T then
                if {Distance Pos H.pos}=<N then 
                    H|{SearchMine N Pos T}
                else
                    {SearchMine N Pos T}
                end
            end
        end
        fun {SearchFood N Pos LFood}
            case LFood of nil then nil
            [] H|T then
                if {Distance Pos H.pos}=<N then
                    H|{SearchFood N Pos T}
                else
                    {SearchFood N Pos T}
                end
            end
        end
    in
        case ToFind of player then
            {SearchPlayer N State.position State.playersStatus}
        [] mine then
            {SearchFood N State.position State.mines}
        [] food then
            {SearchFood N State.position State.food}
        else
            nil
        end
    end
end