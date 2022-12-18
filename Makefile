# ----------------------------
# group number 059
# 60231900 : Wery Arthur
# 09062000 : Moedts Benoît
# ----------------------------

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

INPUT = "Input.oz"
PLAYERTACTICAL = "Player059Tactical.oz"
PLAYERATTACKSIMPLE = "Player059SimpleAttack.oz"
PLAYERDEFENSESIMPLE = "Player059SimpleDefence.oz"
PLAYEROFFENSIVE = "Player059OffensiveUpgraded.oz"

all:
	$(OZC) -c ${INPUT} -o "Input.ozf"
	$(OZC) -c ${PLAYERTACTICAL} -o "Player059Tactical.ozf"
	$(OZC) -c ${PLAYERATTACKSIMPLE} -o "Player059SimpleAttack.ozf"
	$(OZC) -c ${PLAYERDEFENSESIMPLE} -o "Player059SimpleDefence.ozf"
	$(OZC) -c ${PLAYEROFFENSIVE} -o "Player059OffensiveUpgraded.ozf"
	$(OZC) -c PlayerManager.oz
	$(OZC) -c GUI.oz
	$(OZC) -c Main.oz
	$(OZENGINE) Main.ozf

run:
	$(OZENGINE) Main.ozf

clean:
	rm *.ozf