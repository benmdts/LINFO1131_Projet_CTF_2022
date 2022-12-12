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
					mines:nil
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
		case State.id 
		of id(name:_ id:_ color:Color) then 
			if Color == blue then 
			CurrentPosition = State.position
			case CurrentPosition 
				of pt(x:X y:Y) then 
					if X == 3 then 
						if(Y > 2) then 
						Position = pt(x:CurrentPosition.x y:CurrentPosition.y-1)
						else
						Position = pt(x:CurrentPosition.x-1 y:CurrentPosition.y-1)
						end 
					else if X > 3 then 
						Position = pt(x:CurrentPosition.x - 1 y:CurrentPosition.y)
					else 
						Position = pt(x:CurrentPosition.x y:CurrentPosition.y)
					end 
				end 
			end 
			State
			else
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
		end  
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
		ID = State.id
		Kind = mine
		/* 
		if (State.gunReloads==0)then
			Kind = gun
		else
			Kind = mine
		end
		 */
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
		ID = State.id
		if (State.gunReloads==1) then 
			Kind =gun(pos:pt(x:State.position.x+1 y:State.position.y+1))
		elseif (State.mineReloads==5) then
			Kind=mine(pos:pt(x:State.position.x y:State.position.y))
		else 
			Kind = null
		end
		State
	end

	fun {SayMinePlaced State ID Mine}
		if (ID == State.id) then
			{Adjoin State state(mineReloads:0)}
		else
			State
		end
	end

	fun {SayShoot State ID Position}
		if (ID == State.id) then
			{Adjoin State state(gunReloads:0)}
		else
			State
		end
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
		Flag = flag(pos:State.position color:red)
		State
	end
			
	fun {DropFlag State ?ID ?Flag}
		ID = State.id
		if State.position == pt(x:3 y:3) then 
			Flag = flag(pos: State.position color: red) 
		else
		Flag = null
		end 
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
