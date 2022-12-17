functor
import
	Player1
	Player018Tactical
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {Player018Tactical.portPlayer Color ID}
		[] player1 then {Player1.portPlayer Color ID}
		end
	end
end
