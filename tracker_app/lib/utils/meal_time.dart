/// The meal timing tags, in order through the day.
const List<String> mealTags = ['breakfast', 'lunch', 'snack', 'dinner'];

/// The default timing for a meal logged at [hour] (0–23). Used to preselect the
/// timing chip; the user can override it.
String mealTagForHour(int hour) => hour < 11
    ? 'breakfast'
    : hour < 15
    ? 'lunch'
    : hour < 18
    ? 'snack'
    : 'dinner';
