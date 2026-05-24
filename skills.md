### The 5 core skills that have been used in the creation of this game. 



---


1. Gameplay loop mechanics.


I had made the game have all the basic mechanics it would need in order to be minimally functionable, however still more than playable for an average player. These include the point to walk system, friction on the ground, health points, energy, buffs, enemy spawning, debug information and shaders all using Lua + glsl coding languages.




2. Object oriented programming, or OOP

As I like to do, I have split up my game into multiple of different files. This had allowed me to code oriented functions separate from each other, and then pull them all in when required, therefore saving on the performance of the game, and the time spent troubleshooting (Oh damn i spent about 7 hours troubleshooting in total)


3. Mathematic movement

This was done with the help of gemini 3.1 pro llm, to help figure out the best mathematic equations for smooth and friction movement across the surface. This includes the mouse pointing, gradual acceleration and decceleration, distance calculations for the droid traveling. Once I implemented this update, the game became a whole lot smoother.


4. Performance and lag optimization

Inside of the game, there are multiple hard limits imposed on objects. For example, there may ONLY be up to 128 bullets present at any given time, to make sure that the shader doesn't get overloaded with the shader cache. The system is failsafe, and will make the game stop running the function to shoot once the pool is reached. However, I tried my best to ake it so bullets destroy themselves when they are off the screen, or collide with each other. Also, theree may  only be up to 15 enemies at the same time, not to overwhelm the player. There also can only be up to 3 energy boosts scattered on the ground at the same time, to increase the intensity of the game.


5. UI elements.

In the last update, I've tried my best to bring good UI elements to the game. These included the Health and energy indicators, an actual OSD with a debug mode, A main menu / game over screen. In my opinion, the UI is NOT great however it does the job for a fully coded game with no use of external assets.