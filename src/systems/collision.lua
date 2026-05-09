-- src/systems/collision.lua
-- Centralised hit-detection pass.
-- Called once per frame from game.lua AFTER all entities have updated.
--
-- ── Why a dedicated system? ───────────────────────────────────────────────────
-- Putting collision logic inside entity update() methods creates coupling:
-- the drone would need a reference to the bullet pool, the player would need
-- a reference to the drone list, etc. A separate system gets references to
-- everything at call time and owns all hit logic in one place.
--
-- ── Checks performed ──────────────────────────────────────────────────────────
--   1. Bullets vs Drones  — bullet deactivated, drone.hit() called
--   2. Drones  vs Player  — drone stays alive but player.takeDamage() called
--      (player has invincibility frames so this won't fire every frame)
--
-- ── Collision shape ───────────────────────────────────────────────────────────
-- All checks are circle vs circle: fast, no rotation needed, good enough for
-- this game. Formula: distance(a, b) < a.radius + b.radius

local Collision = {}

-- ─── Main pass ───────────────────────────────────────────────────────────────

-- bullets : BulletPool  (has .pool table)
-- drones  : table of Drone objects
-- player  : Player
function Collision.check(bullets, drones, player)
    Collision._bulletsVsDrones(bullets, drones)
    Collision._dronesVsPlayer(drones, player)
end

-- ─── Bullets vs Drones ───────────────────────────────────────────────────────

function Collision._bulletsVsDrones(bullets, drones)
    -- Only iterate active bullets against active drones.
    -- Two nested loops: O(bullets × drones). Fine for our counts.
    for bi = 1, #bullets.pool do
        local b = bullets.pool[bi]
        if b.active then
            for _, drone in ipairs(drones) do
                if drone.active then
                    local dx   = b.x - drone.x
                    local dy   = b.y - drone.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    if dist < b.radius + drone.radius then
                        -- Bullet consumed regardless of whether drone dies
                        bullets:destroy(b)
                        drone:hit(1)
                        break  -- this bullet is gone; stop checking other drones
                    end
                end
            end
        end
    end
end

-- ─── Drones vs Player ────────────────────────────────────────────────────────

function Collision._dronesVsPlayer(drones, player)
    for _, drone in ipairs(drones) do
        if drone.active then
            local dx   = drone.x - player.x
            local dy   = drone.y - player.y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Use player's half-width as an approximate circle radius
            if dist < drone.radius + player.w * 0.5 then
                player:takeDamage(drone.contactDamage or 1)
            end
        end
    end
end

return Collision