/// The set of free-text fields across the app that offer suggestions.
///
/// Each value's [name] is also the storage key for the user's learned history
/// in `AppData.suggestions`, so renaming an enum entry would orphan old data —
/// keep these stable.
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

/// Curated, offline starter suggestions bundled with the app. The user's own
/// entries are layered on top of these at runtime (most-recent first) — see
/// `lib/utils/suggestions.dart`. No network is ever involved.
const Map<SuggestionField, List<String>> kSuggestionCatalog = {
  SuggestionField.broker: [
    'Binance',
    'Coinbase',
    'Kraken',
    'Bybit',
    'OKX',
    'Interactive Brokers',
    'MetaTrader 5',
    'FTMO',
    'Personal Live',
    'Ledger',
    'Trust Wallet',
    'MetaMask',
    'Robinhood',
    'Zerodha',
  ],
  SuggestionField.currency: [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'SGD',
    'BTC',
    'ETH',
    'USDT',
    'USDC',
  ],
  SuggestionField.subscription: [
    'Netflix',
    'Spotify',
    'YouTube Premium',
    'Amazon Prime',
    'Disney+',
    'iCloud+',
    'Google One',
    'ChatGPT Plus',
    'OpenAI API',
    'Anthropic API',
    'GitHub Copilot',
    'Notion',
    'Figma',
    'Adobe Creative Cloud',
    'Dropbox',
  ],
  SuggestionField.spendCategory: [
    'Entertainment',
    'Productivity',
    'AI / API',
    'Cloud',
    'Utilities',
    'Health',
    'Education',
    'News',
    'Other',
  ],
  SuggestionField.grocery: [
    'Milk',
    'Eggs',
    'Bread',
    'Butter',
    'Rice',
    'Pasta',
    'Bananas',
    'Apples',
    'Coffee',
    'Tea',
    'Chicken',
    'Onions',
    'Tomatoes',
    'Potatoes',
    'Cheese',
    'Yogurt',
    'Oil',
    'Sugar',
    'Salt',
    'Water bottle',
  ],
  SuggestionField.groceryCategory: [
    'Produce',
    'Dairy',
    'Bakery',
    'Meat',
    'Pantry',
    'Frozen',
    'Beverages',
    'Household',
    'Snacks',
    'Other',
  ],
  SuggestionField.unit: [
    'unit',
    'bottle',
    'can',
    'box',
    'bag',
    'pack',
    'dozen',
    'kg',
    'g',
    'L',
    'ml',
  ],
  SuggestionField.meal: [
    'Chicken rice bowl',
    'Oatmeal',
    'Greek yogurt',
    'Protein shake',
    'Salad',
    'Eggs & toast',
    'Grilled chicken',
    'Salmon',
    'Banana',
    'Apple',
    'Rice & dal',
    'Paneer wrap',
  ],
  SuggestionField.session: [
    'Asian',
    'London',
    'NY AM',
    'London Close',
    'NY PM',
    'Frankfurt',
    'Sydney',
    'Tokyo',
  ],
  SuggestionField.workout: [
    'Push',
    'Pull',
    'Legs',
    'Upper',
    'Lower',
    'Full Body',
    'Chest & Back',
    'Arms',
    'Shoulders',
    'Cardio',
    'HIIT',
    'Mobility',
    'Rest',
  ],
  SuggestionField.workoutFocus: [
    'Chest · Shoulders · Triceps',
    'Back · Biceps',
    'Quads · Hamstrings · Glutes',
    'Full body',
    'Conditioning',
    'Core',
  ],
};
