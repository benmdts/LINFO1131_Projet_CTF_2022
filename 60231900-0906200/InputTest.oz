functor
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
    mines:Mine
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
    Mine
in

%%%% Description of the map %%%%

    NRow = 6
    NColumn = 6

    % 0 = Empty
    % 1 = Player 1's base
    % 2 = Player 2's base
    % 3 = Walls

    Map = [[1 0 0 0 0 0]
	       [0 0 0 0 0 0]
	       [0 0 0 3 0 0]
	       [0 0 0 0 0 0]
	       [0 0 0 0 0 0]
	       [0 0 0 0 0 2]]

    Mine = [mine(pos:pt(x:2 y:1)) mine(pos:pt(x:3 y:1))  mine(pos:pt(x:4 y:1)) mine(pos:pt(x:5 y:1)) mine(pos:pt(x:6 y:1)) mine(pos:pt(x:6 y:2)) mine(pos:pt(x:6 y:3)) mine(pos:pt(x:6 y:4)) mine(pos:pt(x:6 y:5))]
%%%% Players description %%%%

    Players = [player1 player2]
    Colors = [red blue]
    SpawnPoints = [pt(x:1 y:1) pt(x:6 y:6)]
    NbPlayer = 2
    StartHealth = 10

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
    RespawnDelay = 1000

%%%% Flags
    Flags = [flag(pos:pt(x:2 y:2) color:red) flag(pos:pt(x:5 y:5) color:blue)]

end
