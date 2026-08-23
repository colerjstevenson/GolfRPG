# Shot Mechanics — Implementation Plan

## 0. Original Spec (source of truth for behavior)

1. When you click on the ball, the player walks over to it and enters shot mode. In shot mode you cannot click away and walk elsewhere until you've taken your shot. Entering shot mode stops the sprite's movement and the camera zooms in a little to show you're in shot mode.
2. Once in shot mode, click-and-drag back to aim your shot. As you drag back, an indicator extends forward from the ball to show roughly where the ball would hit the ground if released (not counting roll after it hits the ground). As the player pulls back, the camera zooms out so they can see where the ball will land. If the player has pulled back too far, the indicator sways back and forth and affects shot accuracy. How far back is "too far" is determined by the terrain the ball is on: fairway starts swaying at 90%, rough at 75%, sand at 50%.
3. Once the ball is released, it launches as though making an arc in the air (even though this is a 2D overhead view). The ball's speed and size should act as though it's being shot through the air like a real golf ball. Once it "lands," how much it rolls or bounces is affected by the terrain it lands on. The camera should follow the ball as it moves.
4. Once the ball stops moving, the player is released from shot mode and the camera goes back to focusing on them.

## 1. Goal

Rebuild the shot loop into four explicit phases matching the spec above:

1. **Approach** — click ball → player walks to it → enters Shot Mode (movement locked, camera zooms in).
2. **Aim** — click-drag to aim; landing indicator shown; camera zooms out as power increases; over-pulling causes terrain-dependent sway that hurts accuracy.
3. **Flight** — ball launches on a simulated arc (height via scale/shadow, not real Z), terrain-dependent bounce/roll on landing, camera follows the ball.
4. **Recovery** — once ball stops, player is released from Shot Mode, camera returns to following the player.

## 2. Current State Assessment

What already exists (reuse, don't rewrite from scratch):

- [`ball.gd`](../scripts/ball.gd): `Area2D` with click detection, drag-based `launch(direction, power_ratio)`, friction-based rolling, terrain lookup via `ground_layer` (`get_terrain_name()`), and terrain-based **wobble** (fairway 90% / rough 75% / sand 50% thresholds) — this already matches the sway spec in step 2.
- [`player.gd`](../scripts/player.gd): state machine `FREE / WALK_TO_BALL / AIMING / LOCKED`, walk-to-ball, drag-to-aim-and-launch on mouse release.
- [`hole_1.gd`](../scripts/hole_1.gd): `FollowCamera` parented under the player sprite, camera limits set from tilemap bounds, fixed zoom multiplier.

What's missing relative to the spec:

- No **shot-mode lock** preventing the player from walking elsewhere before taking the shot (currently `_unhandled_input` only ignores clicks when not `FREE`, but ball clicks always work; also nothing stops a ball click mid-`WALK_TO_BALL`/`AIMING`).
- No **camera zoom-in on entering shot mode**, and no **zoom-out while dragging**.
- No **landing-point indicator** — `ball._draw()` shows a straight aim line, not a predicted landing position.
- No **flight arc** — ball only slides along the ground (2D velocity + friction); no height/arc simulation.
- No **camera follow during ball flight** — camera stays parented to the player, which stops moving during the shot.
- No **terrain-dependent bounce/roll on landing** — friction is constant; terrain only affects wobble currently.
- Ball currently reparents nothing to camera; camera can't "follow the ball" since it's a child of the player sprite.

## 3. Architecture Changes

### 3.1 Camera ownership

Move `FollowCamera` out from under the player sprite so it can be independently retargeted:

- Reparent `FollowCamera` to `Hole1` (root) instead of `Player/AnimatedSprite2D`.
- Add a small camera controller (either a new `camera.gd` or logic in `hole_1.gd`) with:
  - `follow_target: Node2D` (player or ball)
  - `target_zoom: Vector2`
  - `_process`/`_physics_process` lerps `global_position` toward `follow_target.global_position` and `zoom` toward `target_zoom`.
- Expose functions: `set_follow(target: Node2D)`, `set_zoom_level(z: float)` (smoothed).

### 3.2 Shot Mode lock

Introduce a single shot-mode owner instead of relying only on `player.state`:

- Add `signal shot_mode_entered` / `shot_mode_exited` on the player, or a simple `is_in_shot_mode()` check.
- In `player._unhandled_input`, ignore **all** movement clicks whenever `state != FREE` (already true) **and** make `on_ball_clicked` a no-op unless `state == FREE` (already true) — confirm ball itself also blocks re-click via `Ball.State` guard (already present: `if state != State.IDLE: return`).
- Add explicit re-entrancy guard: once `state` leaves `FREE`, do not allow another `on_ball_clicked` until back to `FREE`/`IDLE` (already effectively true, just needs verification/tests).

### 3.3 Ball state machine extension

Extend `ball.gd`'s `State` enum:

```gdscript
enum State {
    IDLE,
    FLYING,   # in the air, following arc
    ROLLING,  # bounced/landed, rolling with friction
}
```

Add fields:

- `flight_height: float` — current simulated height (0 = ground).
- `flight_time: float`, `flight_duration: float` — progress along arc.
- `launch_distance: float` — predicted flat-ground travel distance (used for both the aim indicator and the actual flight).
- `shadow: Node2D` (child `Sprite2D`, dark ellipse) representing ground position; ball sprite offsets upward by `flight_height` while shadow stays on the ground plane.

## 4. Phase 1 — Approach & Enter Shot Mode

1. Player clicks ball (`Ball._on_input_event` → `clicked` signal), only accepted if player `state == FREE` and ball `state == IDLE`.
2. Player state → `WALK_TO_BALL`; player walks to `stand_distance` from ball (existing logic).
3. On arrival: player state → `AIMING`.
   - Stop sprite animation (already done via `pause()`).
   - Call `camera_controller.set_follow(ball)` (camera should focus near the ball/player boundary — simplest: keep following player but zoom in) and `set_zoom_level(SHOT_MODE_ZOOM_IN)` (e.g. 1.5–1.8x current zoom).
4. While `state != FREE`, `_unhandled_input` must swallow movement clicks (already correct) — add a quick regression test/manual check.

## 5. Phase 2 — Aim & Drag

Replace direct `launch()`-on-release with a proper aim-preview → confirm-on-release flow (already close, just needs indicator + camera changes):

1. On mouse-down over drag start: begin drag tracking (existing).
2. On mouse-move while dragging:
   - Compute `pull = mouse - drag_start`, `power_ratio = clamp(pull.length()/max_drag_px, 0, 1)`, `dir = -pull.normalized()`.
   - Compute terrain sway threshold from `ball.get_terrain_name()` (90/75/50 — reuse existing `_get_wobble_angle`).
   - Apply wobble to `dir` for **preview only** if over threshold (already implemented in `ball.set_aim_preview` + `_get_wobble_angle`), but also **degrade accuracy on launch** by re-rolling/increasing wobble randomness at release time (see 5.4).
   - Call `ball.set_aim_preview(dir, power_ratio)` which now also computes and draws:
     - The aim line (existing).
     - A **landing marker** at `dir * predicted_distance(power_ratio)` (new — see 5.2), rendered as a small X/ring on the ground, distinct from the pull-line.
   - Call `camera_controller.set_zoom_level(lerp(ZOOM_IN, ZOOM_OUT, power_ratio))` so the camera pulls back as power increases, giving visibility of the predicted landing spot.
3. On mouse-up:
   - If drag was negligible (< 2px): cancel aim, return player to `FREE`, camera zoom back to normal follow (existing cancel path, just add camera reset).
   - Otherwise: call `ball.launch(dir, power_ratio)` (updated signature/behavior below), player state → `LOCKED`, camera → `set_follow(ball)` with a "flight" zoom level (zoomed out enough to track the shot, e.g. same as max drag zoom).

### 5.1 Predicted distance function (shared by preview + launch)

Add to `ball.gd`:

```gdscript
func predicted_distance(power_ratio: float) -> float:
    return power_ratio * max_flight_distance
```

`max_flight_distance` (new `@export`, e.g. 400.0) replaces reliance on `max_speed` for distance; keep `max_speed` only if still used for rolling.

### 5.2 Landing indicator

- In `_draw()`, alongside the existing pull-line, draw the predicted landing point at `preview_dir * predicted_distance(aim_power)` (in local/ball space, since ball hasn't moved yet) — a ring plus a small drop-shadow icon so it visually reads as "where it lands before roll".
- Indicator only reflects **flight** landing spot, explicitly excluding post-land roll, per spec.

### 5.3 Sway thresholds (already implemented, keep as source of truth)

| Terrain | Sway starts at power |
|---|---|
| Fairway | 90% |
| Rough | 75% |
| Sand | 50% |

Reuse `_get_wobble_angle(power_ratio)`, driven by `get_terrain_name()` under the ball's current position (ball hasn't moved yet at aim time, so this is the tee/current lie terrain — correct, since sway is about how hard it is to control the club from the current lie).

### 5.4 Accuracy penalty on release

At the moment of `launch()`, if `power_ratio` is above the current terrain's threshold:
- Compute `over` as in `_get_wobble_angle`.
- Add a **random** error term (not just the deterministic sine oscillation used for the preview) so the actual launch direction is less predictable than what was last previewed: `final_dir = direction.rotated(randf_range(-max_wobble, max_wobble) * over)`.
- This keeps the preview's oscillation as "the indicator sways so you can't predict exactly where it'll land," while the real shot samples a random point within that swayed range — matching "affects the player's ability to shoot accurately."

## 6. Phase 3 — Flight & Landing

### 6.1 Arc simulation (2D overhead, faux-height)

Add to `ball.gd`:

```gdscript
@export var max_arc_height: float = 40.0     # px, visual apex offset
@export var flight_duration_base: float = 0.9 # seconds at full power

var flight_start: Vector2
var flight_end: Vector2
var flight_time: float = 0.0
var flight_duration: float = 0.0
```

On `launch()`:

- `flight_start = global_position`
- `flight_end = flight_start + final_direction * predicted_distance(power_ratio)`
- `flight_duration = flight_duration_base * clamp(power_ratio, 0.35, 1.0)` (short chips still take some time, not instant)
- `state = State.FLYING`, `flight_time = 0.0`

`_physics_process` while `FLYING`:

```gdscript
flight_time += delta
var t: float = clamp(flight_time / flight_duration, 0.0, 1.0)
position = flight_start.lerp(flight_end, t)          # ground-plane XY (the "shadow" position)
var arc: float = sin(t * PI) * max_arc_height * clamp(power_ratio, 0.2, 1.0)
sprite.position.y = -arc                              # visual-only vertical offset
sprite.scale = base_scale * (1.0 + arc / max_arc_height * 0.25)  # grow slightly at apex
if shadow:
    shadow.scale = base_shadow_scale * (1.0 - arc / max_arc_height * 0.4) # shrink shadow at apex
if t >= 1.0:
    _land()
```

`_land()`:

- Reset `sprite.position.y = 0`, `sprite.scale = base_scale`, `shadow` reset.
- Determine landing terrain via `get_terrain_name()` at the new position.
- Enter `State.ROLLING` with an initial roll velocity derived from terrain:

| Terrain | Roll behavior |
|---|---|
| Fairway | Normal roll: `roll_speed = incoming_speed * 0.5`, `friction = 350` (current default) |
| Rough | Short roll: `roll_speed = incoming_speed * 0.2`, `friction = 600` (stops fast) |
| Sand | Minimal roll/plugs: `roll_speed = incoming_speed * 0.05`, `friction = 900`, optionally zero roll + small bounce damping |

- `incoming_speed` derived from `predicted_distance(power_ratio) / flight_duration` (i.e., the flight's average speed) so harder shots roll further.
- Keep existing `_physics_process` ROLLING branch (friction-based deceleration) but source `friction` from a per-terrain lookup instead of the fixed `@export var friction`.

### 6.2 Camera follow during flight

- On `launch()`, `hole_1`/camera controller already set to `set_follow(ball)` (from Phase 2 step 3).
- Camera controller's `_process` continuously re-targets `ball.global_position` each frame while `ball.state != IDLE`.
- Keep zoom at the "flight" level (zoomed out) throughout `FLYING` + `ROLLING`.

## 7. Phase 4 — Recovery

1. `ball` emits `stopped` when velocity ~0 (existing signal, fires from ROLLING → IDLE transition).
2. `player.gd`'s existing check (`state == LOCKED and current_ball.state == IDLE`) transitions `state → FREE`.
3. On this transition:
   - `camera_controller.set_follow(player)`.
   - `camera_controller.set_zoom_level(DEFAULT_ZOOM)`.
   - Resume player idle animation (already handled elsewhere) — no change needed unless idle-anim regressed.

## 8. New/Changed Exports Summary (for tuning in the editor)

`ball.gd`:
- `max_flight_distance: float = 400.0`
- `max_arc_height: float = 40.0`
- `flight_duration_base: float = 0.9`
- Per-terrain dictionaries/constants for `roll_speed_factor` and `friction` (fairway/rough/sand).
- Keep `max_drag_px`, `wobble_max_angle_deg`, `wobble_frequency` as-is.

New camera controller (in `hole_1.gd` or a new `camera_controller.gd`):
- `zoom_default: float`
- `zoom_shot_mode: float` (aim-in, low power)
- `zoom_flight: float` (aim-out / ball tracking)
- `zoom_lerp_speed: float`
- `follow_lerp_speed: float`

## 9. Task Checklist

1. [ ] Reparent `FollowCamera` to `Hole1` root; add camera-follow/zoom controller logic in `hole_1.gd`.
2. [ ] Wire `player` shot-mode transitions to camera zoom-in (`AIMING` entered) and zoom-out-with-power (during drag).
3. [ ] Add landing-point prediction + drawing in `ball._draw()` / `set_aim_preview`.
4. [ ] Add `max_flight_distance`, replace distance math to use it instead of `max_speed` directly for flight.
5. [ ] Implement `FLYING` state with arc height (sprite offset + scale) and shadow scaling in `ball.gd`.
6. [ ] Implement `_land()` with per-terrain roll speed/friction table; transition to `ROLLING`.
7. [ ] Add random accuracy-error term applied only at `launch()` time when over sway threshold.
8. [ ] Wire camera to follow the ball during `FLYING`/`ROLLING`, and back to the player on `stopped`.
9. [ ] Verify shot-mode input lock: no player movement clicks accepted between ball-click and shot completion.
10. [ ] Manual playtest pass per terrain (fairway/rough/sand) tee positions to confirm sway thresholds and roll feel.
11. [ ] Tune exported constants (arc height, flight duration, zoom levels, per-terrain friction) for feel.

## 10. Testing Notes

Since this is a physics-feel system, prioritize manual playtesting over automated tests:

- Test each terrain type as the tee lie (sway threshold trigger at correct power %).
- Test each terrain type as the landing spot (roll distance differences).
- Confirm camera never leaves shot-follow target of `FollowCamera.limit_*` bounds (may need to clamp `camera.global_position` to camera limits manually since it's no longer parented to a physically-limited node).
- Confirm clicking the ball mid-walk-to-ball or mid-aim is a no-op (no re-trigger, no state corruption).
- Confirm releasing a near-zero drag cancels cleanly and returns camera/state to normal.