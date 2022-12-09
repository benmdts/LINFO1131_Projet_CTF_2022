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

	% Helper functions
	RandomInRange = fun {$ Min Max} Min+({OS.rand}mod(Max-Min+1)) end
in
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
					map:Input.map
					hp:Input.startHealth
					flag:null
					mineReloads:0
					gunReloads:0
					startPosition:{List.nth Input.spawnPoints ID}
					% TODO You can add more elements if you need it
				)
			}
		end
		Port
	end

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
			[] sayFlagDropped(ID Flag) then {SayFlagDropped State ID flag}
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
		CurrentPosition 
	in 
		ID = State.id
		CurrentPosition = State.position
		case CurrentPosition 
			of pt(x:X y:Y) then 
				if X < 7 then 
					Position = pt(x:CurrentPosition.x + 1 y:CurrentPosition.y)
				else if X > 7 then 
					Position = pt(x:CurrentPosition.x - 1 y:CurrentPosition.y)
				else 
					Position = pt(x:CurrentPosition.x y:CurrentPosition.y)
				end 
			end 
		end 
		State
	end

	% À modifier pas complet mais je sais pas encore quoi faire quand ce n'est pas le même id qui a bougé
	% idée : Enregistrer dans une liste, comme pour main avec playerStatus, ce qui permettra de bouger en fonction 
	fun {SayMoved State ID Position}
		NewState in 
		if ID == State.id then 
			NewState = {Adjoin State state(position:Position)}
		else
			NewState = State
		end
		NewState

	end

	%Comme pour au dessus ici il faudrait changer la liste qu'on utiliserait pour stocker l'endroit des mines
	fun {SayMineExplode State Mine}
		State
	end

	fun {SayFoodAppeared State Food}
		State
	end

	fun {SayFoodEaten State ID Food}
		State
	end

	fun {ChargeItem State ?ID ?Kind} 
		if (State.position.x==20)then
			ID = State.id
			Kind = gun
		else
			ID = State.id
			Kind = mine
		end
		State
	end

	fun {SayCharge State ID Kind}
		State
	end

	fun {FireItem State ?ID ?Kind}
		{System.show State.mineReloads}
		if (State.position.x==6) then
			ID = State.id
			%Kind =gun(pos:pt(x:State.position.x+1 y:State.position.y+1))
			Kind =mine(pos:pt(x:State.position.x y:State.position.y))
		else
			Kind=null()
		end
		State
	end

	fun {SayMinePlaced State ID Mine}
		State
	end

	fun {SayShoot State ID Position}
		State
	end

	% À modifier ici le joueur modifie son état quand on lui dit qu'il est mort mais les autres ne font rien
	fun {SayDeath State ID}
		if ID == State then 
			{Adjoin State state(position:State.startPosition hp:Input.startHealth)}
		else
			State
		end 
	end

	fun {SayDamageTaken State ID Damage LifeLeft}
		State
    end

	fun {TakeFlag State ?ID ?Flag}
		ID = State.id
		Flag = null
		State
	end
			
	fun {DropFlag State ?ID ?Flag}
		ID = State.id
		Flag = null
		State
	end

	fun {SayFlagTaken State ID Flag}
		State
	end

	fun {SayFlagDropped State ID Flag}
		State
	end
	fun {Respawn State}
		{Adjoin State state(hp:Input.startHealth position: State.startPosition)}
	end

end
