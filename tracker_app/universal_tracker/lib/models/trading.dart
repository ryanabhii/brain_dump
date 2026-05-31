/// A trading account or wallet with a current balance.
class TradingAccount {
  final String id;
  final String name;
  final String type; // broker | wallet | prop
  final String currency;
  final num balance;

  const TradingAccount({
    required this.id,
    required this.name,
    this.type = 'broker',
    this.currency = 'USD',
    this.balance = 0,
  });

  factory TradingAccount.fromJson(Map<String, dynamic> j) => TradingAccount(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String? ?? 'broker',
    currency: j['currency'] as String? ?? 'USD',
    balance: (j['balance'] as num?) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'currency': currency,
    'balance': balance,
  };

  TradingAccount copyWith({
    String? name,
    String? type,
    String? currency,
    num? balance,
  }) => TradingAccount(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    balance: balance ?? this.balance,
  );
}

/// A deposit or withdrawal against an account.
class Flow {
  final String id;
  final String accountId;
  final String type; // deposit | withdrawal
  final num amount;
  final String date; // ISO-8601
  final String note;

  const Flow({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Flow.fromJson(Map<String, dynamic> j) => Flow(
    id: j['id'] as String,
    accountId: j['accountId'] as String,
    type: j['type'] as String,
    amount: (j['amount'] as num?) ?? 0,
    date: j['date'] as String,
    note: j['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'type': type,
    'amount': amount,
    'date': date,
    'note': note,
  };
}

/// The "trading" section: accounts and their cash flows.
class Trading {
  final List<TradingAccount> accounts;
  final List<Flow> flows;

  const Trading({this.accounts = const [], this.flows = const []});

  factory Trading.fromJson(Map<String, dynamic> j) => Trading(
    accounts: (j['accounts'] as List? ?? const [])
        .map((e) => TradingAccount.fromJson(e as Map<String, dynamic>))
        .toList(),
    flows: (j['flows'] as List? ?? const [])
        .map((e) => Flow.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'accounts': accounts.map((e) => e.toJson()).toList(),
    'flows': flows.map((e) => e.toJson()).toList(),
  };

  Trading copyWith({List<TradingAccount>? accounts, List<Flow>? flows}) =>
      Trading(accounts: accounts ?? this.accounts, flows: flows ?? this.flows);
}
