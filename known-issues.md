# Known Issues

Tracked, diagnosed issues across the RedECS ecosystem (engine, sibling
packages, and dungeon-cleaners). Maintained alongside CLAUDE.md: add entries
when new issues are diagnosed, and move entries to the Resolved section (with
the fixing commit) when they are addressed.

## Open

### Combat: travel destinations are stale by the time attackers arrive
- **Where:** `dungeon-cleaners/DungeonCleanersKit/Sources/Game/RPGComponents/AnimationSequence/AnyRPSequence.swift` (`generateTravelAction`)
- **Symptom:** attackers walk to where their target *was* and swing at air.
- **Cause:** the destination node is chosen once from the target's transform at
  event start and never re-evaluated. `isInCombat` serializes event
  *generation* (`RPReducer`), but pathing/movement reducers keep running, so
  the target of event N is often still walking out its travel from event N-1.
- **Mitigation in progress:** combat-entry "hard stop + reserve" state (see
  below); full fix would re-evaluate travel when the target's gridBody moves.

### Combat: occupancy clearing derives from the lerping transform
- **Where:** `AnyRPSequence.swift` (`generateTravelAction`, "Clear current position")
- **Symptom:** phantom blocked cells; entities' real cells unmarked and
  steal-able; pile-ups.
- **Cause:** the entity's "current node" is computed from its mid-walk
  transform rather than from its actual reservation (`gridBody`). If the
  entity is >1 cell from its reserved node, the stale `.occupied` cell is
  never freed.

### Combat: node-conflict displacement is arbitrary
- **Where:** `DungeonCleanersLevel/GridPosition/MovableGridBodyReducer.swift`
- **Symptom:** characters shuffle sideways through each other.
- **Cause:** when an entity's node is occupied by someone else it is moved to
  the *first* adjacent visitable node — unsorted, direction arbitrary, can
  churn every tick.

### Combat: no transit collision between moving entities
- **Where:** `PathingReducer` (RedECS) + `MovementReducer` (RedECS)
- **Symptom:** entities walk through each other mid-path.
- **Cause:** occupancy exists only at reserved destinations; nothing checks
  cells being passed through. Related: spawn placement has a `FIXME` for
  entity collision (`DungeonPopulator.swift:116`).

### Combat: "nowhere to go" deadlocks all combat
- **Where:** `AnyRPSequence.swift:130-133` (existing TODO)
- **Symptom:** combat silently freezes for the rest of the session.
- **Cause:** when a travel target is fully surrounded, release builds return
  `.none`, but the sequence's `waitFor(.pathingComplete)` never fires, so
  `isInCombat` remains `true` forever and no further events are generated.

### Facing: asymmetric direction quantization on un-normalized diagonals
- **Where:** `RedECS/Sources/RedECSBasicComponents/Pathing/PathingReducer.swift`
  (velocity axes each clamped to ±1) + `Geometry/Sources/Geometry/Direction.swift`
  (`fromPoint`, half-open 45° boundaries)
- **Symptom:** characters face the wrong way while walking; mirror-image
  movement produces different facings; twitchy direction flips near waypoints.
- **Cause:** diagonal velocity `(±1, ±1)` lands exactly on the quantization
  boundaries (NE → `.right`, NW → `.up`); no hysteresis, so jitter near
  waypoints flips the dominant axis tick to tick. Sprites also hold their
  attack-start facing for the whole animation while targets keep moving.

### Combat: `pathingComplete` matching is not travel-specific
- **Where:** `Travel.completedWhen` (`RoleplayAnimationSequence.swift`) +
  `GameStore.sendAction` pending-effect matching
- **Symptom (potential):** an attack can fire early if an unrelated path for
  the same entity completes while a combat travel is pending.
- **Cause:** `waitFor` matches any `.pathingComplete(entityId)`, with no
  identity linking it to the specific travel that was issued.

## Resolved

_(move entries here with the commit hash that fixed them)_
