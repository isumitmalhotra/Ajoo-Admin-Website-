// Shared motion vocabulary for the app — the Flutter counterpart of the web's
// redesign/lib/motion.ts, so both platforms move the same way.
//
// Same rules the web follows: 150–300ms for micro-interactions, nothing over
// ~500ms, decelerating curves on entrances (things arriving slow down), and
// opacity/transform only so the compositor does the work.
//
// Accessibility: everything here collapses to a plain fade — or nothing — when
// the visitor has asked their OS to reduce motion. Flutter surfaces that as
// MediaQuery.disableAnimations, which Android sets from
// "Remove animations" in accessibility settings.
import 'package:flutter/material.dart';

/// Duration scale, mirroring DUR in motion.ts. Keep additions on this scale.
class AajooDur {
  /// Hover/press feedback — should feel instant.
  static const micro = Duration(milliseconds: 160);

  /// Standard entrance for a card or row.
  static const base = Duration(milliseconds: 280);

  /// A whole section arriving.
  static const slow = Duration(milliseconds: 420);
}

/// Decelerating curve — the default for anything entering the screen.
/// Same control points as the web's EASE_OUT [0.22, 1, 0.36, 1].
const Curve kEaseOut = Cubic(0.22, 1, 0.36, 1);

/// True when the user has NOT asked for reduced motion.
/// Gate distance-based movement on this; keep opacity fades either way.
bool motionSafe(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Fade + rise. The workhorse for list items and section content.
///
/// Animates on first build rather than on a scroll intersection. Lists build
/// their children as those children come into view, so in practice this
/// arrives at the same moment — and unlike an intersection observer it can
/// never leave content permanently invisible because the viewport skipped it.
/// Unreadable content is a far worse outcome than a missed animation.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.distance = 16,
    this.duration = AajooDur.base,
  });

  final Widget child;

  /// Stagger offset. Use [staggerDelay] to derive one from a list index.
  final Duration delay;

  /// How far it travels. Ignored when the user has reduced motion on.
  final double distance;

  final Duration duration;

  /// A short cascade for list items. Deliberately capped: a long cascade
  /// reads as lag, not polish, so the tenth card does not wait a second.
  static Duration staggerDelay(int index, {int stepMs = 45, int maxMs = 270}) =>
      Duration(milliseconds: (index * stepMs).clamp(0, maxMs));

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      // Straight to the finished state — no fade, no travel.
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final curved = CurvedAnimation(parent: _c, curve: kEaseOut);

    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: reduced
              ? child
              : Transform.translate(
                  offset: Offset(0, (1 - t) * widget.distance),
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}

/// Press feedback for a tappable surface — a small, quick scale.
///
/// Displacement stays subtle so it reads as feedback rather than movement,
/// and the scale always returns even if the pointer leaves mid-press, so the
/// card can never stick shrunken.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = (_down && !reduced) ? widget.scale : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: target,
        duration: AajooDur.micro,
        curve: kEaseOut,
        child: widget.child,
      ),
    );
  }
}
