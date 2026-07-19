import RedECS

/// Identifies one animatable modifier's slot: the structural path of the
/// modifier in the view tree plus a kind discriminator, so `scaleEffect`
/// and `opacity` chained on the same view keep separate slots. (Stacking
/// two modifiers of the same kind at the same position is unsupported.)
struct AnimationKey: Hashable {
    var path: [IdentityToken]
    var kind: String
}

struct AnimationSlot {
    var start: Double
    var target: Double
    var elapsed: Double
    /// Legs left to play including the current one; nil = forever.
    var legsRemaining: Int?
    var strategy: LoopStrategy
    var settled: Bool
    var displayed: Double
    var lastTrigger: AnyHashable?
}

extension HUDCache {
    func beginAnimationFrame() {
        touchedAnimationKeys.removeAll(keepingCapacity: true)
    }

    /// Drops slots whose modifiers didn't resolve this frame, so vanished
    /// nodes release their state (and `.appear` replays on rebirth).
    func endAnimationFrame() {
        animationSlots = animationSlots.filter { touchedAnimationKeys.contains($0.key) }
    }

    /// Advances (or installs) the slot for one animatable modifier and
    /// returns the value to display this frame.
    ///
    /// - `singleTarget` is the `.targetChange` form's per-frame target;
    ///   `range` is the explicit `from:to:` form required by `.appear` and
    ///   `.change(of:)`. Exactly one should be non-nil for the trigger in
    ///   use; a mismatched form applies instantly (asserting in debug).
    func stepAnimation(
        key: AnimationKey,
        singleTarget: Double?,
        range: (from: Double, to: Double)?,
        animation: HUDAnimation,
        delta: Double
    ) -> Double {
        touchedAnimationKeys.insert(key)

        guard animation.duration > 0 else {
            let instant = singleTarget ?? range?.to ?? 0
            animationSlots[key] = AnimationSlot.settled(at: instant)
            return instant
        }

        switch animation.trigger {
        case .targetChange:
            guard let target = singleTarget else {
                assertionFailure("`.targetChange` animates the single-value modifier form")
                return range?.to ?? 0
            }
            return stepTargetChange(key: key, target: target, animation: animation, delta: delta)

        case .appear:
            guard let range = range else {
                assertionFailure("`.appear` requires the explicit from:to: modifier form")
                return singleTarget ?? 0
            }
            return stepAppear(key: key, range: range, animation: animation, delta: delta)

        case .change(let trigger):
            guard let range = range else {
                assertionFailure("`.change(of:)` requires the explicit from:to: modifier form")
                return singleTarget ?? 0
            }
            return stepChange(key: key, trigger: trigger, range: range, animation: animation, delta: delta)
        }
    }

    private func stepTargetChange(
        key: AnimationKey, target: Double, animation: HUDAnimation, delta: Double
    ) -> Double {
        guard var slot = animationSlots[key] else {
            // First appearance installs at the target without animating.
            animationSlots[key] = AnimationSlot.settled(at: target)
            return target
        }
        if target != slot.target {
            slot.begin(from: slot.displayed, to: target, repeats: animation.repeats)
            animationSlots[key] = slot
            return slot.displayed
        }
        return advance(&slot, key: key, animation: animation, delta: delta)
    }

    private func stepAppear(
        key: AnimationKey, range: (from: Double, to: Double), animation: HUDAnimation, delta: Double
    ) -> Double {
        guard var slot = animationSlots[key] else {
            var slot = AnimationSlot.settled(at: range.from)
            slot.begin(from: range.from, to: range.to, repeats: animation.repeats)
            animationSlots[key] = slot
            return slot.displayed
        }
        return advance(&slot, key: key, animation: animation, delta: delta)
    }

    private func stepChange(
        key: AnimationKey, trigger: AnyHashable, range: (from: Double, to: Double),
        animation: HUDAnimation, delta: Double
    ) -> Double {
        guard var slot = animationSlots[key] else {
            // Install silent at rest; the first *change* plays.
            var slot = AnimationSlot.settled(at: range.from)
            slot.lastTrigger = trigger
            animationSlots[key] = slot
            return slot.displayed
        }
        if trigger != slot.lastTrigger {
            slot.begin(from: slot.displayed, to: range.to, repeats: animation.repeats)
            slot.lastTrigger = trigger
            animationSlots[key] = slot
            return slot.displayed
        }
        return advance(&slot, key: key, animation: animation, delta: delta)
    }

    private func advance(
        _ slot: inout AnimationSlot, key: AnimationKey, animation: HUDAnimation, delta: Double
    ) -> Double {
        defer { animationSlots[key] = slot }
        guard !slot.settled else { return slot.displayed }

        slot.elapsed += delta
        while slot.elapsed >= animation.duration {
            if var legs = slot.legsRemaining {
                legs -= 1
                slot.legsRemaining = legs
                if legs <= 0 {
                    slot.settled = true
                    slot.displayed = slot.target
                    return slot.displayed
                }
            }
            switch slot.strategy {
            case .restart:
                slot.elapsed -= animation.duration
            case .pingPong:
                swap(&slot.start, &slot.target)
                slot.elapsed -= animation.duration
            }
        }
        let eased = animation.timing(slot.elapsed / animation.duration)
        slot.displayed = slot.start + (slot.target - slot.start) * eased
        return slot.displayed
    }
}

extension AnimationSlot {
    static func settled(at value: Double) -> AnimationSlot {
        AnimationSlot(
            start: value, target: value, elapsed: 0,
            legsRemaining: nil, strategy: .restart,
            settled: true, displayed: value, lastTrigger: nil
        )
    }

    /// Starts (or restarts) the pattern from the currently displayed value,
    /// so retargeting and retriggering mid-flight never snap.
    mutating func begin(from: Double, to: Double, repeats: Repetition) {
        start = from
        target = to
        elapsed = 0
        settled = false
        displayed = from
        switch repeats {
        case .once:
            legsRemaining = 1
            strategy = .restart
        case .count(let n, let loopStrategy):
            legsRemaining = max(1, n)
            strategy = loopStrategy
        case .forever(let loopStrategy):
            legsRemaining = nil
            strategy = loopStrategy
        }
    }
}
