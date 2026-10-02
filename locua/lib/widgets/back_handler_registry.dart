// back_handler_registry.dart
// Lets a screen with its own internal multi-level navigation (Learn's
// L1/L2/L3, Origins' L1/L2) register a "step back one level" handler,
// keyed by its bottom-nav tab index. MainShell owns the ONE app-wide
// PopScope and, on a back-button press, looks up whichever tab is
// currently selected and asks IT to step back first — only showing the
// exit-confirmation dialog once that tab reports there's nowhere further
// back to go (or the current tab has no registered handler at all, e.g.
// Home/Practice/Vault/Settings, which have no internal levels).
//
// WHY THIS EXISTS (Session 7 Phase 2 bugfix): MainShell uses an
// IndexedStack, which keeps every tab's screen mounted simultaneously —
// so Learn and Origins each having their OWN PopScope (as they briefly
// did in Phase 1) meant two PopScopes were live in the tree at once with
// no way for Flutter to know which one should "win" a back-press. That
// was the root cause of back jumping straight to the exit dialog instead
// of stepping L2->L1 first. Centralizing back handling in MainShell,
// keyed by tab index, removes the ambiguity entirely.

/// Returns true if the screen stepped back one level, false if it was
/// already at its top level (nothing left to step back through).
typedef StepBackHandler = bool Function();

class BackHandlerRegistry {
  static final Map<int, StepBackHandler> _handlers = {};

  static void register(int tabIndex, StepBackHandler handler) {
    _handlers[tabIndex] = handler;
  }

  static void unregister(int tabIndex) {
    _handlers.remove(tabIndex);
  }

  static StepBackHandler? handlerFor(int tabIndex) => _handlers[tabIndex];
}