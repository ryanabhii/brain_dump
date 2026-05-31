/// Heuristic "smart routing" for a captured thought → a suggested destination.
/// Direct port of the prototype's `autoRoute` (Prototype.tsx line 171).
/// Returns 'grocery' | 'subscription' | 'killzone' | 'body' | null.
String? autoRoute(String text) {
  final t = text.toLowerCase();
  if (RegExp(
    r'\b(buy|pick up|grocery|groceries|milk|eggs|bread|bananas|oil|rice|coffee|pasta|cheese|water bottle)\b',
  ).hasMatch(t)) {
    return 'grocery';
  }
  if (RegExp(
    r'(\$\d|cancel.*subscription|renew|subscription|trial)',
  ).hasMatch(t)) {
    return 'subscription';
  }
  if (RegExp(
    r'\b(killzone|trade|setup|liquidity|sweep|fvg|ny am|london|asian)\b',
  ).hasMatch(t)) {
    return 'killzone';
  }
  if (RegExp(
    r'\b(workout|protein|calories|meal|gym|push day|pull day|rep|set)\b',
  ).hasMatch(t)) {
    return 'body';
  }
  return null;
}

/// Auto-pick a tag from the text. Port of `autoTag` (Prototype.tsx line 179).
String autoTag(String text) {
  final t = text.toLowerCase();
  if (RegExp(
    r'\b(trade|killzone|liquidity|setup|fvg|broker|wallet)\b',
  ).hasMatch(t)) {
    return 'trading';
  }
  if (RegExp(
    r'\b(meeting|deploy|deadline|client|sprint|standup|email)\b',
  ).hasMatch(t)) {
    return 'work';
  }
  if (RegExp(r'\b(idea|maybe|what if|concept|prototype)\b').hasMatch(t)) {
    return 'idea';
  }
  return 'personal';
}
