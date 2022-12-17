local
    CreateMapMatrix
    CreateMap
    SpawnWalls
    FillRow
    FillColumn
    BindRow
    BindColumn
    ShortestPath
    CreatePath
    ShortestPathHelper
    Visit
    ModifyList
    ModifyListHelper
    CreateMatrix
    CreateRow
    NewMap
    NewSpawns
    NewFlags
in 

fun {CreateMapMatrix Rows Columns}
		if(Rows==0) then 
			nil
		else 
			{List.make Columns}|{CreateMapMatrix Rows-1 Columns}
		end
end

proc {CreateMap NewMap NewFlags SpawnPoints}
    Side 
    StartSpawn
    Map 
    TeamFlags
    PlayersSpawnPoints
in 
    Map = {CreateMapMatrix 12 12}
    Side = 0
    StartSpawn = ({OS.rand} mod (10 - 1) + 1)
    if(Side==0) then 
        %Crée le spawn pour l'équipe 1
        {BindRow {List.nth Map 1} StartSpawn StartSpawn+3 1}
       {BindRow {List.nth Map 2} StartSpawn  StartSpawn+3 1}
       %Remplis la première ligne de 0
       {FillRow {List.nth Map 1}}
       %Crée le spawn pour l'équipe 2
        {BindRow {List.nth Map 11} 11-StartSpawn 14-StartSpawn 2}
       {BindRow {List.nth Map 12} 11-StartSpawn  14-StartSpawn 2}
       %Remplis la dernière ligne de 0
         {FillRow {List.nth Map 12}}
         %Crée une place pour le drapeau 
       {BindRow {List.nth Map 3} StartSpawn+1 StartSpawn+2 0}
        {BindRow {List.nth Map 10} 12-StartSpawn 13-StartSpawn 0}
        TeamFlags = [flag(pos:pt(x:3 y:StartSpawn+1) color:red) flag(pos:pt(x:10 y:12-StartSpawn) color:blue)]
        PlayersSpawnPoints = [pt(x:1 y:StartSpawn) pt(x:12 y:11-StartSpawn) pt(x:1 y:StartSpawn+1) pt(x:12 y:12-StartSpawn) pt(x:1 y:StartSpawn+2) pt(x:12 y:13-StartSpawn)]
      
    else 
         %Crée le spawn pour l'équipe 1
       {BindColumn Map 1 StartSpawn StartSpawn+3 1}
        {BindColumn Map 2 StartSpawn StartSpawn+3 1}
          %Remplis la première colonne de 0
        {FillColumn Map 1 1}
        %Crée le spawn pour l'équipe 2
        {BindColumn Map 11 11-StartSpawn 14-StartSpawn 2}
        {BindColumn Map 12 11-StartSpawn 14-StartSpawn 2}
         %Remplis la dernière colonne de 2
         {FillColumn Map 12 1}
          %Crée une place pour le drapeau 
        {BindColumn Map 3 StartSpawn+1 StartSpawn+2 0}
        {BindColumn Map 10 12-StartSpawn 13-StartSpawn 0}
        TeamFlags = [flag(pos:pt(x:StartSpawn+1 y:3) color:red) flag(pos:pt(x:12-StartSpawn y:10) color:blue)]
          PlayersSpawnPoints = [pt(x:StartSpawn y:1) pt(x:11-StartSpawn y:12) pt(x:StartSpawn+1 y:1) pt(x:12-StartSpawn y:12) pt(x:StartSpawn+2 y:1) pt(x:13-StartSpawn y:12)]
    end
    {SpawnWalls Map 1 1}
    if {ShortestPath Map {List.nth TeamFlags 1}.pos {List.nth TeamFlags 2}.pos 2}==nil orelse {ShortestPath Map {List.nth TeamFlags 1}.pos {List.nth TeamFlags 2}.pos 1}==nil then 
        NewMap2 NewFlags2 SpawnPoints2
    in 
        {Browse 'Soucis'}
        {CreateMap NewMap2 NewFlags2 SpawnPoints2}
        NewMap =  NewMap2
        NewFlags =  NewFlags2
        SpawnPoints = SpawnPoints2 
    else
    NewMap = Map
    NewFlags = TeamFlags
    SpawnPoints = PlayersSpawnPoints 
    end
end

proc {SpawnWalls Matrix Row Column} 
    % Fais spawn les murs
    if Column==13 then
        {SpawnWalls Matrix Row+1 1}
    elseif Row ==13 then 
        skip
    elseif {IsDet {List.nth {List.nth Matrix Row} Column}} then 
         {SpawnWalls Matrix Row Column+1}
    else 
        Value in 
        if ({OS.rand} mod 2) ==0 then Value = 3
        else 
            Value = 0
        end 
        {List.nth {List.nth Matrix Row} Column} = Value
        {SpawnWalls Matrix Row Column+1} 
    end   
end

proc {FillRow Row}
    case Row of nil then skip
    []H|T then 
        if {Not {IsDet H}}then
        H = 0
        end
        {FillRow T}
    end
end

proc {FillColumn Matrix Column Row}
    Tile
in 
    Tile = {List.nth {List.nth Matrix Row} Column}
    if  {Not {IsDet Tile}}then 
        Tile = 0
    end 
    if {Length Matrix}>=Row+1 then 
        {FillColumn Matrix Column Row+1}
    else 
        skip
    end
end

proc {BindRow Row Column Size Value}
    if Size > Column then 
    {List.nth Row Column} = Value
    {BindRow Row Column+1 Size Value}
    end
end
proc {BindColumn Matrix Column Row Size Value}
    if Size > Row then 
    {List.nth {List.nth Matrix Row} Column} = Value
    {BindColumn Matrix Column Row+1 Size Value}
    end
end

fun {ShortestPath Map StartPosition FinalPosition Tile}
    Sx Sy Dx Dy Matrix Start Src Queue Result Path in 
    Sx = StartPosition.x
    Sy = StartPosition.y
    Dx = FinalPosition.x
    Dy = FinalPosition.y
    Matrix = {CreateMatrix Map 1 StartPosition Tile}
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

fun {CreateMatrix Map Row Start Tile}
    if Row =< {Length Map} then 
        {CreateRow Map Row 1 Start Tile}|{CreateMatrix Map Row+1 Start Tile}
    else 
        nil
    end 
end

fun {CreateRow Map Row Column Start Tile}
    Value in 
    if Column =< {Length Map.1} then 
        Value = {List.nth {List.nth Map Row} Column}
        if Value\=3 andthen Start.x==Row andthen Start.y == Column andthen Value\=Tile then
            tile(x:Row y:Column dist:0 prev: nil)|{CreateRow Map Row Column+1 Start Tile}
        elseif Value\=3 andthen Value\=Tile then 
            tile(x:Row y: Column dist:999999 prev: nil)|{CreateRow Map Row Column+1 Start Tile}
        else 
            nil|{CreateRow Map Row Column+1 Start Tile}
        end 
    else 
        nil 
    end
end 

 {CreateMap NewMap NewFlags NewSpawns}
 {Browse NewMap}
end