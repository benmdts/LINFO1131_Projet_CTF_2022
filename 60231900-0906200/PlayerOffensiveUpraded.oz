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
	NewTurn
	Move
	IsDead
	AskHealth
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
	GetEnnemyColor
	ShortestPath
	CreatePath
	ShortestPathHelper
	Visit
	ModifyList
	ModifyListHelper
	CreateMatrix
	CreateRow
	GetEnnemyFlag
	Distance
	InManhattan
	CheckIfSomeoneHasFlag
	

	% Helper functions
	RandomInRange = fun {$ Min Max} Min+({OS.rand}mod(Max-Min+1)) end
in

fun {ShortestPath Map StartPosition FinalPosition ID}
    Sx Sy Dx Dy Matrix Start Src Queue Result Path in 
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

fun {CreateMatrix Map Row Start Team}
    if Row =< {Length Map} then 
        {CreateRow Map Row 1 Start Team}|{CreateMatrix Map Row + 1 Start Team}
    else 
        nil
    end 
end

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
					path : {ShortestPath Input.map {List.nth Input.spawnPoints ID} {GetEnnemyFlag Input.flags {GetEnnemyColor ID}}.pos ID}
					teamColor : {List.nth Input.colors ID}
					rand:false
				)
			}
		end
		Port
	end
	%ICI ID est juste le chiffre
	fun {GetEnnemyFlag Flags Color}
		case Flags of nil then nil 
		[]Flag|T then 
			if Color == Flag.color then 
				Flag
			else 
				{GetEnnemyFlag T Color}
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
	fun {GetEnnemyColor ID}
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
		ID = State.id
		if State.rand then 
			case ({OS.rand} mod 4) of 0 then Position = pt(x:State.position.x+1 y:State.position.y)
			[] 1 then Position = pt(x:State.position.x-1 y:State.position.y)
			[] 2 then Position = pt(x:State.position.x y:State.position.y+1)
			[] 3 then Position = pt(x:State.position.x y:State.position.y-1)
			end
		elseif {Length State.path} >0 then 
			Position = {List.nth State.path 1}
		else
			Position = State.position
		end
		State
	end



	% À modifier pas complet mais je sais pas encore quoi faire quand ce n'est pas le même id qui a bougé
	% idée : Enregistrer dans une liste, comme pour main avec playerStatus, ce qui permettra de bouger en fonction 
	fun {SayMoved State ID Position}
		
		NewState PlayerState in 
		if ID == State.id then 
			if(State.hasflag\=nil) then
				if {Length State.path} >0 then 
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnnemyColor ID.id} flag(pos:Position)} position:Position path: State.path.2)}
				else
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnnemyColor ID.id} flag(pos:Position)} position:Position path: nil)}
				end
			else
				if {Length State.path} >0 then 
					NewState = {Adjoin State state(position:Position path: State.path.2)}
				else
					NewState = {Adjoin State state(position:Position path: nil)}
				end
			end 
		else
			PlayerState = {GetPlayerState State.playersStatus ID.id}
			if PlayerState.hp==0 then 
				NewState = {Adjoin State state(playersStatus:{ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:Position hp:Input.startHealth)})} 
			else 
				if(PlayerState.hasflag\=nil) then
					NewState = {Adjoin State state(flags:{ChangeFlags State.flags {GetEnnemyColor ID.id} flag(pos:Position)} playersStatus:{ChangePlayerStatus State.playersStatus ID.id playerstate(currentposition:Position)})}
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
			{System.show 'test1'}
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
			{Adjoin State state(position:State.startPosition hp:0)}
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
		Color = {GetEnnemyColor ID.id}
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
			Flag = flag(pos: State.position color: {GetEnnemyColor ID.id})
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
			NewState = {Adjoin State state(hasflag:Flag path:{ShortestPath Input.map State.position State.startPosition ID.id})}
		else
			if Flag.color \= State.teamColor then 
				NewState = {Adjoin State state(rand:true path:{ShortestPath Input.map State.position State.startPosition ID.id} playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:Flag)})}
			else
				NewState = {Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:Flag)})}
			end
		end 
		NewState 
	end

	fun {SayFlagDropped State ID Flag}
		if ID == State.id then 
			{Adjoin State state(hasflag:nil)}
		elseif Flag.color \= State.id.color then
			{Adjoin State state(rand:false playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)} path:{ShortestPath Input.map State.position {GetEnnemyFlag State.flags {GetEnnemyColor ID.id}}.pos ID.id})}
		else
			{Adjoin State state(playersStatus: {ChangePlayerStatus State.playersStatus ID.id playerstate(hasflag:nil)})}
		end 
	end

	fun {Respawn State}
		if {CheckIfSomeoneHasFlag State.playersStatus State.teamColor} then 
			{Adjoin State state(hp:Input.startHealth)}
		else 
			{Adjoin State state(hp:Input.startHealth path: {ShortestPath Input.map State.startPosition {GetEnnemyFlag Input.flags {GetEnnemyColor State.id.id}}.pos State.id.id})}
		end 
	end

	fun {Distance Pos1 Pos2}
		{Abs Pos1.x-Pos2.x}+{Abs Pos1.y-Pos2.y}
	end

	fun {CheckIfSomeoneHasFlag PlayersStatus Color}
		case PlayersStatus of nil then false
		[] Player|T then 
			if Player.hasflag\=nil andthen Player.teamColor == Color then 
				true
			else
				{CheckIfSomeoneHasFlag T Color}
			end 
		end
	end

	fun {InManhattan N ToFind State}
        fun {SearchPlayer N Pos LPlayer}
            case LPlayer of nil then nil
            [] H|T then
                if H.teamColor\=State.teamColor andthen {Distance Pos H.currentposition}=<N andthen H.hp>0 then 
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