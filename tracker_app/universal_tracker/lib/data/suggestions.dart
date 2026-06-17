/// The set of free-text fields across the app that offer suggestions.
///
/// Each value's [name] is also the storage key for the user's learned history
/// in `AppData.suggestions`, so renaming an enum entry would orphan old data —
/// keep these stable.
///
/// The app used to ship a bundled offline catalog of starter strings here.
/// That's been removed: explicit user-defined templates (see
/// `models/templates.dart`) plus learned history (`AppData.suggestions`,
/// written whenever the user types a value) are now the only sources.
enum SuggestionField {
  broker, // trading account name
  currency, // trading account currency
  subscription, // spend item name
  spendCategory, // spend category
  grocery, // grocery / pantry item name
  groceryCategory, // grocery category
  unit, // pantry unit
  meal, // logged meal name
  session, // killzone session name
  workout, // workout name
  workoutFocus, // workout focus / muscle groups
}
