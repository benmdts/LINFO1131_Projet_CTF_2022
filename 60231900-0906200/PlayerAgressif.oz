functor
import
	Input
	OS
	System
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

fun {ShortestPath Map StartPosition FinalPosition}
    Sx Sy Dx Dy Matrix Start Src Queue Result Path in 
    Sx = StartPosition.x
    Sy = StartPosition.y
    Dx = FinalPosition.x
    Dy = FinalPosition.y
    Matrix = {CreateMatrix Map 1 StartPosition}
    Src = {List.nth {List.nth Matrix Sx} Sy}
    Queue = [Src]
    Result = {ShortestPathHelper Matrix Queue Dx Dy}
    if Result == nil then 
        nil
    else
        {Reverse {CreatePath nil Result}}.2
    end
end 

fun {CreatePath Path P}
    if P==nil then 
        Path
    else 
        {CreatePath {Append Path [pt(x:P.x y:P.y)]} P.prev}
    end
end

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

fun {CreateMatrix Map Row Start}
    if Row =< {Length Map} then 
        {CreateRow Map Row 1 Start}|{CreateMatrix Map Row + 1 Start}
    else 
        nil
    end 
end

fun {CreateRow Map Row Column Start}
    Value in 
    if Column =< {Length Map.1} then 
        Value = {List.nth {List.nth Map Row} Column}
        if Value\=3 andthen Start.x==Row andthen Start.y == Column then
            tile(x:Row y:Column dist:0 prev: nil)|{CreateRow Map Row Column+1 Start}
        elseif Value\=3 then 
            tile(x:Row y: Column dist:999999 prev: nil)|{CreateRow Map Row Column+1 Start}
        else 
            nil|{CreateRow Map Row Column+1 Start}
        end 
    else 
        nil 
    end
end 
	fun {StartPlayer Color ID}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream
			 	Stream
				state(
					id:id(name:basic color:Color id:ID)
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
	fun {GetEnemyColor ID}
		if(ID>1) then 
			{List.nth Input.colors ID-1}
		else 
			{List.nth Input.colors ID+1}
		end
	end
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
    proc{TreatStream Stream State}
        case Stream
            of H|T then{TreatStream T {MatchHead H State}}
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

	%%%% TODO Message functions

	fun {InitPosition State ?ID ?Position}
		ID = State.id
		Position = State.startPosition
		State
	end

	fun {Move State ?ID ?Position}
        NewState
    in
		ID = State.id
		if State.allyHasFlag then
			local X Y Holder EnemyNearFlag NewPath in
				EnemyNearFlag ={GetEnemyNearestFlag State.playersStatus State.teamColor {GetFlag State.flags State.teamColor}.pos}.2
				if EnemyNearFlag == nil then 
					NewPath=nil
				else 
					NewPath={ShortestPath Input.map State.position EnemyNearFlag.currentposition}
				end
				Holder={GetPlayerState State.playersStatus State.allyHolderId}
				if NewPath==nil orelse NewPath.1==Holder.currentposition then
					X=Holder.currentposition.x-State.position.x
					Y=Holder.currentposition.y-State.position.y
					if {Abs X}+{Abs Y} ==1 then
						NewState={Adjoin State state(path :[{SearchFreeTile State.position pt(x:X y:Y)}])}
					elseif {Abs X}+{Abs Y} ==2 then
						if X==0 then
							NewState={Adjoin State state(path :[{SearchFreeTile State.position pt(x:X y:{Int.'div' Y 2})}])}
						elseif Y==0 then
							NewState={Adjoin State state(path :[{SearchFreeTile State.position pt(x:{Int.'div' X 2} y:Y)}])}
						else
							if {IsAllyAt State.playersStatus pt(x:X y:0) State.teamColor} then
								NewState={Adjoin State state(path :[{SearchFreeTile State.position pt(x:X y:0)}])}
							else
								NewState={Adjoin State state(path :[{SearchFreeTile State.position pt(x:0 y:Y)}])}
							end
						end
					else
						NewState={Adjoin State state(path :NewPath)}
					end
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


	fun {IsAllyAt PList Position Color}
		case PList of nil then false 
		[] H|T then
			if H.currentposition==Position andthen Color==H.teamColor then true
			else {IsAllyAt T Position Color} end
		end
	end

	%On regarde ou se mettre pour laisser passer le porteur de drapeau sachant que le porteur du drapeau se trouve en X Y par rapport a nous
	fun {SearchFreeTile Pos PosRelative}
		if PosRelative\=pt(x:0 y:~1) andthen {IsNoWall pt(x:Pos.x+0 y:Pos.y-1)} then pt(x:Pos.x y:Pos.y-1)
		elseif PosRelative\=pt(x:0 y:1) andthen {IsNoWall pt(x:Pos.x+0 y:Pos.y+1)} then pt(x:Pos.x y:Pos.y+1)
		elseif PosRelative\=pt(x:~1 y:0) andthen {IsNoWall pt(x:Pos.x-1 y:Pos.y)} then pt(x:Pos.x-1 y:Pos.y)
		elseif PosRelative\=pt(x:1 y:0) andthen {IsNoWall pt(x:Pos.x+1 y:Pos.y)} then pt(x:Pos.x+1 y:Pos.y)
		else nil end
	end

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
            {ShortestPath Input.map State.position State.startPosition}
        elseif State.enemyHasFlag then
            %Try to kill enemy with flag except if we are near to take flag we continue to take it
			if {Not State.allyHasFlag} andthen {Distance State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos}=<2 then
				{ShortestPath Input.map State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos}
			else
            	{ShortestPath Input.map State.position {GetEnemyWhoHaveFlag State.playersStatus State.teamColor}.currentposition}
			end
        else
            %On va chercher notre flag le plus rapidement possible
            {ShortestPath Input.map State.position {GetFlag State.flags {GetEnemyColor State.id.id}}.pos}
        end
    end

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


	% À modifier pas complet mais je sais pas encore quoi faire quand ce n'est pas le même id qui a bougé
	% idée : Enregistrer dans une liste, comme pour main avec playerStatus, ce qui permettra de bouger en fonction 
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



	%Comme pour au dessus ici il faudrait changer la liste qu'on utiliserait pour stocker l'endroit des mines
	fun {SayMineExplode State Mine}
		{Adjoin State state(mines:{RemoveFromList State.mines Mine.pos})}
	end

	fun {SayFoodAppeared State Food}
		{Adjoin State state(food:{Append State.food [Food]})}
	end

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

	fun {ChargeItem State ?ID ?Kind} 
		ID = State.id
		if (State.gunReloads\=1)then
			Kind = gun
		elseif (State.mineReloads\=5) then 
			Kind = mine
		else
			Kind = null
		end
		State
	end

	fun {SayCharge State ID Kind}
		if Kind==gun then
			{Adjoin State state(gunReloads:State.gunReloads+1)}
		else
			{Adjoin State state(mineReloads:State.mineReloads+1)}
		end
	end

	fun {FireItem State ?ID ?Kind}
        ManRange
    in
        ID = State.id
        if (State.mineReloads==5) andthen State.hasflag\=nil then
            Kind=mine(pos:pt(x:State.position.x y:State.position.y))
        elseif (State.gunReloads==1) then 
            if({Length State.path}>=2) then 
                if {Member mine(pos:{List.nth State.path 2}) State.mines} then 
                    Kind = gun(pos:{List.nth State.path 2})
                else 
                    if {InManhattan 2 player State}\=nil then 
                    ManRange={InManhattan 2 player State}
                    Kind =gun(pos:ManRange.1.currentposition)
                    else 
                        Kind = null
                    end
                end 
            else
                if {InManhattan 2 player State}\=nil then 
                ManRange={InManhattan 2 player State}
                Kind =gun(pos:ManRange.1.currentposition)
                else 
                    Kind = null
                end
            end
        else 
            Kind = null
        end
        State
    end

	% Est-ce qu'on stocke plus que ça ou pas ? Par exemple que le joueur n'a plus de munitions pour les mines. Mais je vois pas d'utilité
	fun {SayMinePlaced State ID Mine}
		if (ID == State.id) then
			{Adjoin State state(mines: {Append State.mines [Mine]} mineReloads:0)}
		else
			{Adjoin State state(mines: {Append State.mines [Mine]})}
		end
	end
	
	% Même question que pour la fonction SayMinePlaced
	fun {SayShoot State ID Position}
		if (ID == State.id) then
			{Adjoin State state(gunReloads:0)}
		else
			State
		end
	end

	% À modifier ici le joueur modifie son état quand on lui dit qu'il est mort mais les autres ne font rien
	fun {SayDeath State ID}
		if ID == State.id then 
			{Adjoin State state(position:State.startPosition hp:0 )}
		else
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:{GetPlayerState State.playersStatus ID.id}.startPosition hp:0)})}
		end 
	end

	fun {SayDamageTaken State ID Damage LifeLeft}
		if ID == State.id then 
			{Adjoin State state(hp:LifeLeft)}
		else
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hp:LifeLeft)})}
		end 
    end

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

	fun {SayFlagDropped State ID Flag}
		if ID == State.id then 
			{Adjoin State state(hasflag:nil path:nil)}
		elseif Flag.color \= State.id.color then
			{Adjoin State state(allyHasFlag:false path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)})}
		else
			{Adjoin State state(enemyHasFlag:false path:nil playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)})}
		end 
	end

	fun {Respawn State}
		{Adjoin State state(hp:Input.startHealth position:State.startPosition path:nil)}
	end

	fun {Distance Pos1 Pos2}
		{Abs Pos1.x-Pos2.x}+{Abs Pos1.y-Pos2.y}
	end

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