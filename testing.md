# Manual Testing Guide

This document walks through how to manually verify every major system in the game. Written for your first LÖVE 2D project — each section explains what to do, what to watch for, and what a pass/fail looks like.

---

## How to run the game

```
love .
```

Run from the project root. The window opens at 1280×720 with V-Sync on.

---

## 1. State transitions (Menu → Game → Game Over)

These are the skeleton of the whole experience. Test them first so you know you can reach every other system.

### Steps

1. Launch the game. Confirm the **main menu** appears.
2. Press the key shown on screen to start. Confirm the **game world** loads — background shader, player ship, and HUD visible.
3. Let drones kill you (or force it by standing still). Confirm the **game over screen** appears with a kill count.
4. From game over, restart and confirm you return to a fresh game (kill counter at 0, full HP, full energy).
5. From game over, quit and confirm the window closes.

### Pass criteria

- No state ever freezes or shows a blank screen
- Kill count displayed on game over matches what you scored
- Restarting fully resets all state — no leftover drones, bullets, or depleted HP carrying over

### Common failure

If the game over screen shows 0 kills every time, the kill counter is not being passed to the game over state correctly.

---

## 2. WASD Movement

**What to test:** feel, responsiveness, rotation, and the low-energy speed penalty.

### Steps

1. **Basic movement** — press W. The ship should thrust forward toward the mouse cursor. Move the mouse to different positions and confirm the ship always points toward it before thrusting.
2. **Strafing** — hold A or D without touching W. The ship should slide sideways relative to its facing direction, noticeably slower than full-forward thrust.
3. **Friction** — tap W briefly then release. The ship should coast to a stop in roughly half a second, not snap-stop instantly and not drift forever.
4. **Diagonal** — hold W + A simultaneously. Movement should feel natural, not faster than holding W alone (the thrust vector is normalized).
5. **Speed cap** — hold W in a straight line as long as possible. Confirm the ship reaches a top speed and stops accelerating, rather than building speed forever.
6. **Low energy penalty** — fire continuously until energy is nearly empty (watch the energy bar). Confirm the ship visibly slows compared to full energy. At 0 energy, it should feel sluggish but still controllable.
7. **Arrow keys** — confirm they work as an alternative to WASD.

### Pass criteria

- Ship always faces the mouse cursor
- W = forward thrust, A/D = sideways strafe, no S
- Movement feels smooth, not jittery or teleporting
- Clear speed difference between full energy and empty energy
- Ship decelerates naturally when input is released

### What "good enough" looks like for a first game

The physics model here uses exponential friction, which is a step above basic linear deceleration. If it feels like piloting a small spaceship with a bit of momentum rather than a character walking, it's working correctly.

---

## 3. Shooting & Bullet Pool

**What to test:** fire rate, bullet behaviour, pool limits, and visual rendering.

### Steps

1. **Basic firing** — hold left-click. A stream of glowing bolts should fire toward the mouse cursor at roughly 10 per second.
2. **Direction tracking** — while holding left-click, move the mouse in a wide arc. Bullets should leave in the updated direction each frame, not all fly toward where the mouse started.
3. **Bullet travel** — watch a bullet travel. It should move fast (900 px/s), stay visible for about 1.8 seconds, and disappear on its own if it hits nothing.
4. **Muzzle position** — the bolt should emerge from the front tip of the ship, not the center or rear.
5. **Pool stress test** — fire continuously for 10+ seconds without stopping. The game should not slow down, crash, or throw an error. The oldest bullets should silently expire and be reused.
6. **Glow rendering** — bolts should have a bright core with a soft glow halo around them. On overlapping bolts, the glow should bloom brighter (additive blending). If they look like plain white rectangles, the shader failed to load.
7. **Fade-out** — watch a bullet that misses everything. It should fade in its last fraction of a second before disappearing, not pop out instantly.

### Pass criteria

- Bolts fire at a steady 10/sec rhythm with no stuttering
- Bullets travel in the direction the ship faces at fire time
- No performance degradation after extended firing
- Visual glow effect visible (not flat rectangles)
- Bullets fade before expiring

### Common failure

If bullets all go to the same fixed point regardless of mouse position, the world-space muzzle coordinate calculation is wrong. If the pool appears to run out (no new bullets fire), the pool cap of 128 is being hit — this should not happen in normal play.

---

## 4. Enemy Spawning & Drone AI

**What to test:** spawning reliability, homing behaviour, cap enforcement, and death feedback.

### Steps

1. **First spawn** — after starting the game, wait about 2 seconds. A drone should appear moving toward you from off-screen.
2. **Spawn direction** — watch where drones come from over several spawns. They should arrive from varied angles (all around the player), not always from one side.
3. **Off-screen entry** — at the moment a drone first becomes visible, it should be entering the screen, not appearing already in the center. If drones pop into existence near you, the spawn radius is wrong.
4. **Homing** — move around and confirm drones steer toward your current position, not where you were when they spawned.
5. **Speed and feel** — drones should feel threatening but not impossibly fast. They have momentum, so they overshoot slightly when you dodge.
6. **Spawn cap** — survive long enough that many drones are active. Confirm the count never exceeds 16. The easiest way is to kite them without killing any and watch the HUD or count visually.
7. **Death burst** — shoot a drone until it dies (3 hits). Confirm: a hit flash (white flicker), a particle burst on death, and the drone disappearing. The kill counter on the HUD should increment.
8. **HP pips** — drones should display small indicators showing their remaining HP. After 1 hit it should show 2, after 2 hits it should show 1.
9. **Spawn escalation** — the spawn interval is random (1.8–3.2 s). Play for 2+ minutes and confirm drones keep arriving consistently.

### Pass criteria

- Drones always home on the player's current position
- Spawning occurs consistently from all directions at distance
- Max 16 active drones at any time
- Clear hit flash + particle burst on death
- Kill counter correctly increments

### What "good enough" looks like for a first game

Enemy AI doesn't need pathfinding or complex behaviour — consistent homing with a slight overshoot due to momentum makes enemies feel alive enough. If you can outmanoeuvre them by strafing at right angles to their approach vector, the AI is working correctly.

---

## 5. Health System & Invincibility Frames

**What to test:** damage, iframes, visual feedback, and game over trigger.

### Steps

1. **Taking damage** — let a drone touch you. The ship should flash white briefly, the Hull bar should drop by one segment (1 of 5 HP).
2. **Invincibility frames** — immediately after being hit, run into another drone. You should not take damage while the ship is still flickering. Iframes last 1.2 seconds.
3. **Hull bar** — confirm the HUD bar animates down smoothly rather than jumping instantly. It should drain quickly then settle.
4. **Critical state** — at 1 HP, confirm "CRITICAL" appears or flickers on the HUD near the hull bar.
5. **Death trigger** — take 5 hits total. The game should switch to the game over screen. Confirm this happens exactly at 0 HP, not before or after.
6. **Energy refund on hit** — watch the energy bar at the moment you take damage. It should tick up by a small amount (4 units) — this is intentional.

### Pass criteria

- Exactly 5 hits to die
- No double-damage during iframe window
- Visual feedback on every hit (flash + bar animation)
- Game over triggers reliably at 0 HP

### Common failure

If you die in one hit, iframes are not applying. If you seem to take damage very rapidly in sequence, `takeDamage` is being called before the iframe timer is set.

---

## 6. Energy System

**What to test:** cost, regen, delay, and interaction with movement speed.

### Steps

1. **Cost per shot** — watch the energy bar while firing. Each shot should drain a small, consistent amount (4 units). At 10 shots/sec, the full bar (100 units) should last 2.5 seconds of continuous fire.
2. **Regen delay** — fire a short burst then stop. The energy bar should not refill immediately — wait roughly 1.2 seconds before regen starts.
3. **Regen rate** — after the delay, confirm energy refills at a visible but not instant rate (3.5 units/sec means ~28 seconds to go from 0 to full).
4. **Firing cuts off regen** — start regenerating, then fire one shot. Confirm the regen delay resets and regen stops until 1.2 s pass again.
5. **Empty energy** — fire until the bar is completely empty. Confirm you cannot fire further shots even while holding left-click.
6. **Speed penalty** — with energy below 25%, compare movement speed to full energy. At 0 energy, top speed should feel noticeably reduced (40% of normal).
7. **Energy bar HUD** — the bar should animate to reflect the current value. Below the firing threshold, "EMPTY" should flicker on the HUD.

### Pass criteria

- Full bar depleted in ~2.5 s of sustained fire
- No regen while recently fired
- Cannot fire with empty energy
- Speed visibly reduced at low energy
- HUD bar animates correctly

### What "good enough" looks like for a first game

The energy system creates a fire-discipline loop — spam until empty, wait to regen, or stay close to drones for faster pickups. If all three of those feel like real decisions, the system is working.

---

## 7. Battery Pickups

**What to test:** spawning, collection, and energy restoration.

### Steps

1. **Spawning** — play for ~10–15 seconds. A glowing hexagon pickup should appear somewhere in the world.
2. **Visual pulse** — the battery should visibly pulse (alpha oscillates). If it's a flat static shape, the pulse timer is broken.
3. **Collection** — move within ~28 px of a battery. It should disappear and the energy bar should jump upward by a noticeable amount (40 units).
4. **No overfill** — collect a battery with a nearly full energy bar. Confirm energy does not exceed 100.
5. **Multiple pickups** — up to 4 batteries can be active at once. After collecting one, another should eventually spawn within 10–15 seconds.
6. **Spawn spread** — batteries should not stack on top of each other. The spawner avoids placing one within 60 px of another.

### Pass criteria

- Batteries appear reliably within ~15 seconds of play starting
- Collection is responsive (no need to be pixel-perfect)
- Energy bar visibly increases on pickup
- No more than 4 active at any time

---

## 8. Collision Detection

**What to test:** accuracy, consistency, and edge cases.

### Steps

1. **Bullet hits drone** — fire directly at a drone. It should take damage and flash white on contact. The bullet should disappear on impact.
2. **Near miss** — fire a shot that grazes past a drone without center-hitting it. Confirm the threshold feels fair — not too generous, not too tight. (Bullet radius 3 px + drone radius 18 px = 21 px combined.)
3. **Drone hits player** — let a drone make contact. The player should take damage; the drone should continue existing (drone contact damage doesn't destroy the drone).
4. **Multiple drones** — stand still and let several drones pile on. The iframe system should prevent rapid multi-hit — you should take at most one hit per 1.2 seconds.
5. **Bullet vs multiple drones** — fire through a cluster of drones. Each bullet should stop on the first drone it hits, not punch through to hit multiple.

### Pass criteria

- Hits feel accurate and consistent
- Bullets disappear on contact
- No phantom hits or missed contacts on clear collisions
- Bullets do not pass through drones

---

## 9. Camera

**What to test:** follow smoothing, and mouse-aim accuracy in world space.

### Steps

1. **Follow** — move around. The camera should lag behind the player slightly (smooth follow), not lock rigidly to the player center.
2. **World-space aim** — move to the edge of the screen while aiming at a drone on the opposite side. Bullets should travel toward the drone in world space, not toward where the mouse cursor is on screen. If bullets fly in the wrong direction when the camera is offset, the screen→world coordinate conversion in `Camera:toWorld` is broken.
3. **No jitter** — fast directional changes should not cause the camera to stutter or shake.

### Pass criteria

- Smooth follow at all times
- Aim always corresponds to the correct world-space position
- No camera jitter

---

## 10. Visuals & Shaders

**What to test:** all three GLSL shaders and the particle system.

### Steps

1. **Background shader** — the background should be an animated starfield with pulsating rings and jets (the pulsar effect). If it's a flat colour or black, the shader failed to compile.
2. **Screen shader** — look at the screen corners. They should be visibly darker than the center (vignette). The overall image should have a slight blue-cool tint.
3. **Bullet glow** — covered in section 3 above. Confirm glowing bolts, not flat rectangles.
4. **Death particles** — covered in section 4 above. Confirm particle burst on drone death. Particles should fade out quadratically (sharp tail-off, not linear fade).
5. **Drone glow ring** — living drones should have a soft glow ring around them, not just a plain triangle shape.
6. **HUD visibility** — confirm the HUD bars are visible on top of the post-processing shader. (This was a known bug — the HUD should render outside the shader canvas.)

### Pass criteria

- Animated procedural background (not static)
- Visible vignette + tint from screen shader
- Glowing bullets and drones
- Particle bursts on death with soft fade
- HUD clearly readable at all times

---

## 11. Full playthrough checklist

Use this as a final end-to-end check before considering the game "done" for a version.

```
[ ] Game launches without console errors
[ ] Main menu displays and is navigable
[ ] Game world loads with all visuals (background, HUD, player)
[ ] Player moves and rotates correctly with WASD + mouse
[ ] Player fires bullets toward the cursor on left-click
[ ] Energy depletes on fire, regens after delay
[ ] Drones spawn from off-screen within a few seconds
[ ] Drones home on player position
[ ] Bullets register hits on drones (flash + death)
[ ] Kill counter increments on drone death
[ ] Player takes damage on drone contact
[ ] Hull bar decreases and "CRITICAL" appears at low HP
[ ] Iframes prevent rapid multi-hit
[ ] Dying triggers game over screen with correct kill count
[ ] Battery pickups appear and restore energy on collection
[ ] Restarting from game over resets everything cleanly
[ ] No crashes or freezes over a 5-minute play session
```

---

## What "good enough for a first LÖVE 2D game" means

There is no automated test suite here — and that's fine for a first project. Manual testing with clear criteria is exactly the right approach at this scale.

A pass on this checklist means:

- Every system does what it's supposed to when used normally
- The game can be played from start to game over without errors
- The core loop (move, shoot, survive) feels responsive and fair

Things that are **out of scope** for a first game and do not need to pass any test:

- Extreme edge cases (e.g. drone spawning exactly on top of a battery)
- Performance at very high drone counts beyond the 16-cap
- Balancing (the numbers can always be tuned later)
- Sound (not implemented — not a failure)
- Saving high scores (not implemented — not a failure)
