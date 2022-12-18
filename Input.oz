functor
import 
    OS
export
    nRow:NRow
    nColumn:NColumn
    map:Map
    players:Players
    colors:Colors
    guiDelay:GUIDelay
    nbPlayer:NbPlayer
    startHealth:StartHealth
    thinkMin:ThinkMin
    thinkMax:ThinkMax
    foodDelayMin:FoodDelayMin
    foodDelayMax:FoodDelayMax
    gunCharge:GunCharge
    mineCharge:MineCharge
    respawnDelay:RespawnDelay
    spawnPoints:SpawnPoints
    flags:Flags
define
    NRow
    NColumn
    Map
    Players
    Colors
    NbPlayer
    StartHealth
    GUIDelay
    ThinkMin
    ThinkMax
    FoodDelayMin
    FoodDelayMax
    GunCharge
    MineCharge
    RespawnDelay
    SpawnPoints
    Flags
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
in
    %Crée une matrice de taille Row x Columns
    fun {CreateMapMatrix Rows Columns}
		if(Rows==0) then 
			nil
		else 
			{List.make Columns}|{CreateMapMatrix Rows-1 Columns}
		end
end

% Crée une Map de taille 12x12. Les deux bases sont à l'opposé. 
proc {CreateMap ?NewMap ?NewFlags ?SpawnPoints}
    Side 
    StartSpawn
    Map 
    TeamFlags
    PlayersSpawnPoints
in 
    Map = {CreateMapMatrix 12 12}
    Side = 0
    StartSpawn = ({OS.rand} mod (10 - 1) + 1)
    % Équipes sur les côtés droit et gauche de la map
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
    % Équipes sur les côtés haut et bas de la map
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
    % Création des murs
    {SpawnWalls Map 1 1}
    % Vérification s'il y a un chemin possible
    if {ShortestPath Map {List.nth TeamFlags 1}.pos {List.nth TeamFlags 2}.pos 2}==nil orelse {ShortestPath Map {List.nth TeamFlags 1}.pos {List.nth TeamFlags 2}.pos 1}==nil then 
        NewMap2 NewFlags2 SpawnPoints2
    in
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

% Crée les murs de la map.
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
        % Gènere un chiffre entre 0 et 4 si 0 alors on met un mur
        if ({OS.rand} mod 4) ==0 then Value = 3
        else 
            Value = 0
        end 
        {List.nth {List.nth Matrix Row} Column} = Value
        {SpawnWalls Matrix Row Column+1} 
    end   
end

%Remplis la rangée de 0
proc {FillRow Row}
    case Row of nil then skip
    []H|T then 
        if {Not {IsDet H}}then
        H = 0
        end
        {FillRow T}
    end
end

%Remplis la colonne de 0
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

%Affecte la valeur Value aux éléments dans la rangée Row de Column à Column +Size
proc {BindRow Row Column Size Value}
    if Size > Column then 
    {List.nth Row Column} = Value
    {BindRow Row Column+1 Size Value}
    end
end
%Affecte la valeur Value aux éléments dans la colonne Column de Row à Row +Size
proc {BindColumn Matrix Column Row Size Value}
    if Size > Row then 
    {List.nth {List.nth Matrix Row} Column} = Value
    {BindColumn Matrix Column Row+1 Size Value}
    end
end
% Renvoie le chemin le plus rapide de la map pour aller de StartPosition à FinalPosition. En évitant les murs et les élements de la matrice valant Tile
% StartPosition et FinalPosition sont de type pt(x: y:)
fun {ShortestPath Map StartPosition FinalPosition Tile}
    Sx Sy Dx Dy Matrix Src Queue Result in 
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
fun {CreateMatrix Map Row Start Tile}
    if Row =< {Length Map} then 
        {CreateRow Map Row 1 Start Tile}|{CreateMatrix Map Row+1 Start Tile}
    else 
        nil
    end 
end

%Crée une liste, si la valeur de l'élément dans Map à la position X Y vaut 3 ou Tile alors on ajoute nil sinon on ajoute
%tile(x:Row y:Column dist:999999 prev: nil) sauf si X Y vaut Start.x et Start.y alors on ajoute tile(x:Row y:Column dist:0 prev: nil). 
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



%%%% Description of the map %%%%

    NRow = 12
    NColumn = 12

    % 0 = Empty
    % 1 = Player 1's base
    % 2 = Player 2's base
    % 3 = Walls

    {CreateMap Map Flags SpawnPoints}

%%%% Players description %%%%

    Players = [player059tactical player059tactical player059tactical player059tactical player059tactical player059tactical]
    Colors = [red blue red blue red blue]
    NbPlayer = 6
    StartHealth = 2

%%%% Waiting time for the GUI between each effect %%%%

    GUIDelay = 500 % ms

%%%% Thinking parameters %%%%

    ThinkMin = 450
    ThinkMax = 500

%%%% Food apparition parameters %%%%

    FoodDelayMin = 25000
    FoodDelayMax = 30000

%%%% Charges
    GunCharge = 1
    MineCharge = 5
     
%%%% Respawn
    RespawnDelay = 5000

end
