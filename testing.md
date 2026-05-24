# Testing methods.


1. Lobby / menu system

##### Success parameters:

Main menu screen should include all of the relevant information that the user needs to know, such as the key-bindings, different options they have to choose from.
The main menu is expected to be working as usual without any glitches. Upon death, it should reset the character and all of the systems. The design is built on key input, so clicking with a mouse wont do anything. The game mustn't freeze when multiple keys are pressed.

##### Testing methods:

*Main menu*
1. Open the game
2. Confirm the main menu is the first thing that appears on the screen
3. Restart the game
	1. Confirm no stats are carried over and a save is beginning as a fresh one

*Game over menu*
1. From the main scene, get killed by the droids.
2. Confirm that Game Over screen appears afterwards.
3. Confirm that Game Over screen is different to the first screen.
4. Confirm that you are able to restart/quit from the screen

*Stress Testing*
1. Smash different keys repeatedly to make sure that there are no freezes or crashes.

---


2.  Character moving


###### Success parameters:

Character must closely react to the users input on the keys. This means that the character must be able to move to any direction whenever the user wants to. Due to the complexity of the game, I've only implemented the WAD movement, with the S. The player must follow the cursor whenever "W" is pressed


###### Testing Methods:

*Regular movement*
1. Start a normal game from the main menu
2. Point where you want to go, and press W

*Strafing*
1. Start a normal game from the main menu. 
2. Point where you want to go, and press W
3. While moving forward, press A, then D, then both.


---

3.  GUI & Backend testing


###### Success parameters: 

Player must be able to see all the relevant information on the screen at any given time. This includes the health and the energy as primary. Then it can also include points such as kills. Must have a developer mode, which shows a debug screen with all of the information, such as amount of players spawned, etc.


###### Testing methods:

*Player HUD*
1. Enter a game
2. Make sure that the two bars at the bottom and the counter actually correspond to what is actually happening in game, by 
	1. Holding LMB until all bullets are shot, the energy bar must be empty.
	2. Letting the droids damage you. The health bar must decrease by about 15-25%.
	3. Whenever you get a kill, make sure that the counter stars counting up
3. Leave the game and rejoin. The stats must be reset to default.


*Developer HUD*
1. Enter the game
2. Press F1 to open the menu
3. Make sure that the menu contains all the relevant real time information


---


4. Enemy & Buffs testing & Shooting


###### Success parameters:

The enemies must spawn consistently, with a maximum cap applied of 15 enemies. Whenever a bullet hits an enemy, it must take 1 of the 3 total health points from it. Once all are depleted, enemy dies and increases the counter for the player. Also, there must be energy buffs scattered around the map for users to collect.



###### Testing methods:

*Enemies*
1. Enter the game & developer GUI
2. Look for the enemy counter to go up, and wait for the enemy to appear
3. Shoot the enemy 3 times to kill it, watch the counter to go up



*Buffs testing*
1. Enter the game & developer GUI
2. Look for the energy bar counter to go up, and search for it.
3. Once you pick it up, you should have about 33% energy restored.