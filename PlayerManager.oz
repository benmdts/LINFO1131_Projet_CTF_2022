functor
import
	Player059OffensiveUpgraded
	Player059SimpleAttack
	Player059SimpleDefence
	Player059Tactical
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player059offensiveupgraded then {Player059OffensiveUpgraded.portPlayer Color ID}
		[] player059simpleattack then {Player059SimpleAttack.portPlayer Color ID}
		[] player059simpledefence then {Player059SimpleDefence.portPlayer Color ID}
		[] player059tactical then {Player059Tactical.portPlayer Color ID}
		end
	end
end
