declare 

fun {CreateMatrix Rows Columns}
		if(Rows==0) then 
			nil
		else 
			{List.make Columns}|{CreateMatrix Rows-1 Columns}
		end
end

fun {CreateMap}
    Side 
    StartSpawn
    Map 
in 
    Map = {CreateMatrix 12 12}
    Side = ({OS.rand} mod 2)
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
    end
    %{SpawnWalls Matrix}
    Map
end

proc {SpawnWalls Matrix Row Column} 
    if Column==12 then
        {SpawnWalls Matrix Row+1 1}
    elseif Row ==12 then 
        skip
    else 
        if ({OS.rand} mod 2) ==0 then {SpawmWalls Matrix Row Column+1}
        else 
            VorH = ({OS.rand} mod 2)
        in 
            if VorH==0 then 
                {SpawmWallsRow Matrix Row Column}
            else 
                 {SpawmWallsColumn Matrix Row Column}
            end
            {SpawnWalls Matrix Row Column+1} 
        end 
    end   
end

proc{SpawmWallsRow Matrix Row Column}
    case Row of nil then skip
    []H|T then 
        if {IsDet H} then {SpawmWallsRow T} 
        else 
end

proc {CheckTile Matrix Row Column}
    if {Not {IsDet {List.nth {List.nth Matrix Row} Column}}} then 
        true
    elseif {List.nth {List.nth Matrix Row} Column}==0 then 
        true
    else 
        false
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



{Browse {CreateMap}}