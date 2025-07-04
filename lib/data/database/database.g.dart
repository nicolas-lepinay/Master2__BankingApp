// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creationDateMeta = const VerificationMeta(
    'creationDate',
  );
  @override
  late final GeneratedColumn<DateTime> creationDate = GeneratedColumn<DateTime>(
    'creation_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currency,
    initialBalance,
    creationDate,
    icon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialBalanceMeta);
    }
    if (data.containsKey('creation_date')) {
      context.handle(
        _creationDateMeta,
        creationDate.isAcceptableOrUnknown(
          data['creation_date']!,
          _creationDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creationDateMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_balance'],
      )!,
      creationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creation_date'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final String currency;
  final double initialBalance;
  final DateTime creationDate;
  final String? icon;
  const Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.initialBalance,
    required this.creationDate,
    this.icon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['initial_balance'] = Variable<double>(initialBalance);
    map['creation_date'] = Variable<DateTime>(creationDate);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      initialBalance: Value(initialBalance),
      creationDate: Value(creationDate),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      creationDate: serializer.fromJson<DateTime>(json['creationDate']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'creationDate': serializer.toJson<DateTime>(creationDate),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  Account copyWith({
    int? id,
    String? name,
    String? currency,
    double? initialBalance,
    DateTime? creationDate,
    Value<String?> icon = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    initialBalance: initialBalance ?? this.initialBalance,
    creationDate: creationDate ?? this.creationDate,
    icon: icon.present ? icon.value : this.icon,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      creationDate: data.creationDate.present
          ? data.creationDate.value
          : this.creationDate,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('creationDate: $creationDate, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, currency, initialBalance, creationDate, icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.initialBalance == this.initialBalance &&
          other.creationDate == this.creationDate &&
          other.icon == this.icon);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<double> initialBalance;
  final Value<DateTime> creationDate;
  final Value<String?> icon;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.icon = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String currency,
    required double initialBalance,
    required DateTime creationDate,
    this.icon = const Value.absent(),
  }) : name = Value(name),
       currency = Value(currency),
       initialBalance = Value(initialBalance),
       creationDate = Value(creationDate);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<double>? initialBalance,
    Expression<DateTime>? creationDate,
    Expression<String>? icon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (creationDate != null) 'creation_date': creationDate,
      if (icon != null) 'icon': icon,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<double>? initialBalance,
    Value<DateTime>? creationDate,
    Value<String?>? icon,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      creationDate: creationDate ?? this.creationDate,
      icon: icon ?? this.icon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (creationDate.present) {
      map['creation_date'] = Variable<DateTime>(creationDate.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('creationDate: $creationDate, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, level, parentId, icon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String label;
  final int level;
  final int? parentId;
  final String? icon;
  const Category({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
    this.icon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      label: Value(label),
      level: Value(level),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      level: serializer.fromJson<int>(json['level']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'level': serializer.toJson<int>(level),
      'parentId': serializer.toJson<int?>(parentId),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  Category copyWith({
    int? id,
    String? label,
    int? level,
    Value<int?> parentId = const Value.absent(),
    Value<String?> icon = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    label: label ?? this.label,
    level: level ?? this.level,
    parentId: parentId.present ? parentId.value : this.parentId,
    icon: icon.present ? icon.value : this.icon,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      level: data.level.present ? data.level.value : this.level,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('level: $level, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, level, parentId, icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.label == this.label &&
          other.level == this.level &&
          other.parentId == this.parentId &&
          other.icon == this.icon);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> label;
  final Value<int> level;
  final Value<int?> parentId;
  final Value<String?> icon;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.level = const Value.absent(),
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required int level,
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
  }) : label = Value(label),
       level = Value(level);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<int>? level,
    Expression<int>? parentId,
    Expression<String>? icon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (level != null) 'level': level,
      if (parentId != null) 'parent_id': parentId,
      if (icon != null) 'icon': icon,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<int>? level,
    Value<int?>? parentId,
    Value<String?>? icon,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('level: $level, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }
}

class $CounterpartiesTable extends Counterparties
    with TableInfo<$CounterpartiesTable, Counterparty> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterpartiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counterparties';
  @override
  VerificationContext validateIntegrity(
    Insertable<Counterparty> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Counterparty map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Counterparty(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
    );
  }

  @override
  $CounterpartiesTable createAlias(String alias) {
    return $CounterpartiesTable(attachedDatabase, alias);
  }
}

class Counterparty extends DataClass implements Insertable<Counterparty> {
  final int id;
  final String name;
  final String? icon;
  const Counterparty({required this.id, required this.name, this.icon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  CounterpartiesCompanion toCompanion(bool nullToAbsent) {
    return CounterpartiesCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory Counterparty.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Counterparty(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  Counterparty copyWith({
    int? id,
    String? name,
    Value<String?> icon = const Value.absent(),
  }) => Counterparty(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
  );
  Counterparty copyWithCompanion(CounterpartiesCompanion data) {
    return Counterparty(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Counterparty(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Counterparty &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon);
}

class CounterpartiesCompanion extends UpdateCompanion<Counterparty> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> icon;
  const CounterpartiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
  });
  CounterpartiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Counterparty> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
    });
  }

  CounterpartiesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? icon,
  }) {
    return CounterpartiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterpartiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _counterpartyIdMeta = const VerificationMeta(
    'counterpartyId',
  );
  @override
  late final GeneratedColumn<int> counterpartyId = GeneratedColumn<int>(
    'counterparty_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counterparties (id)',
    ),
  );
  static const VerificationMeta _category1IdMeta = const VerificationMeta(
    'category1Id',
  );
  @override
  late final GeneratedColumn<int> category1Id = GeneratedColumn<int>(
    'category1_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _category2IdMeta = const VerificationMeta(
    'category2Id',
  );
  @override
  late final GeneratedColumn<int> category2Id = GeneratedColumn<int>(
    'category2_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _category3IdMeta = const VerificationMeta(
    'category3Id',
  );
  @override
  late final GeneratedColumn<int> category3Id = GeneratedColumn<int>(
    'category3_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _category4IdMeta = const VerificationMeta(
    'category4Id',
  );
  @override
  late final GeneratedColumn<int> category4Id = GeneratedColumn<int>(
    'category4_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountConvertedMeta = const VerificationMeta(
    'amountConverted',
  );
  @override
  late final GeneratedColumn<double> amountConverted = GeneratedColumn<double>(
    'amount_converted',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    counterpartyId,
    category1Id,
    category2Id,
    category3Id,
    category4Id,
    transactionType,
    currency,
    amount,
    amountConverted,
    title,
    comment,
    date,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('counterparty_id')) {
      context.handle(
        _counterpartyIdMeta,
        counterpartyId.isAcceptableOrUnknown(
          data['counterparty_id']!,
          _counterpartyIdMeta,
        ),
      );
    }
    if (data.containsKey('category1_id')) {
      context.handle(
        _category1IdMeta,
        category1Id.isAcceptableOrUnknown(
          data['category1_id']!,
          _category1IdMeta,
        ),
      );
    }
    if (data.containsKey('category2_id')) {
      context.handle(
        _category2IdMeta,
        category2Id.isAcceptableOrUnknown(
          data['category2_id']!,
          _category2IdMeta,
        ),
      );
    }
    if (data.containsKey('category3_id')) {
      context.handle(
        _category3IdMeta,
        category3Id.isAcceptableOrUnknown(
          data['category3_id']!,
          _category3IdMeta,
        ),
      );
    }
    if (data.containsKey('category4_id')) {
      context.handle(
        _category4IdMeta,
        category4Id.isAcceptableOrUnknown(
          data['category4_id']!,
          _category4IdMeta,
        ),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('amount_converted')) {
      context.handle(
        _amountConvertedMeta,
        amountConverted.isAcceptableOrUnknown(
          data['amount_converted']!,
          _amountConvertedMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      counterpartyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counterparty_id'],
      ),
      category1Id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category1_id'],
      ),
      category2Id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category2_id'],
      ),
      category3Id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category3_id'],
      ),
      category4Id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category4_id'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      amountConverted: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_converted'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final int accountId;
  final int? counterpartyId;
  final int? category1Id;
  final int? category2Id;
  final int? category3Id;
  final int? category4Id;
  final String transactionType;
  final String currency;
  final double amount;
  final double? amountConverted;
  final String? title;
  final String? comment;
  final DateTime date;
  final int status;
  const Transaction({
    required this.id,
    required this.accountId,
    this.counterpartyId,
    this.category1Id,
    this.category2Id,
    this.category3Id,
    this.category4Id,
    required this.transactionType,
    required this.currency,
    required this.amount,
    this.amountConverted,
    this.title,
    this.comment,
    required this.date,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || counterpartyId != null) {
      map['counterparty_id'] = Variable<int>(counterpartyId);
    }
    if (!nullToAbsent || category1Id != null) {
      map['category1_id'] = Variable<int>(category1Id);
    }
    if (!nullToAbsent || category2Id != null) {
      map['category2_id'] = Variable<int>(category2Id);
    }
    if (!nullToAbsent || category3Id != null) {
      map['category3_id'] = Variable<int>(category3Id);
    }
    if (!nullToAbsent || category4Id != null) {
      map['category4_id'] = Variable<int>(category4Id);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    map['currency'] = Variable<String>(currency);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || amountConverted != null) {
      map['amount_converted'] = Variable<double>(amountConverted);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['date'] = Variable<DateTime>(date);
    map['status'] = Variable<int>(status);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      counterpartyId: counterpartyId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyId),
      category1Id: category1Id == null && nullToAbsent
          ? const Value.absent()
          : Value(category1Id),
      category2Id: category2Id == null && nullToAbsent
          ? const Value.absent()
          : Value(category2Id),
      category3Id: category3Id == null && nullToAbsent
          ? const Value.absent()
          : Value(category3Id),
      category4Id: category4Id == null && nullToAbsent
          ? const Value.absent()
          : Value(category4Id),
      transactionType: Value(transactionType),
      currency: Value(currency),
      amount: Value(amount),
      amountConverted: amountConverted == null && nullToAbsent
          ? const Value.absent()
          : Value(amountConverted),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      date: Value(date),
      status: Value(status),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      counterpartyId: serializer.fromJson<int?>(json['counterpartyId']),
      category1Id: serializer.fromJson<int?>(json['category1Id']),
      category2Id: serializer.fromJson<int?>(json['category2Id']),
      category3Id: serializer.fromJson<int?>(json['category3Id']),
      category4Id: serializer.fromJson<int?>(json['category4Id']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      currency: serializer.fromJson<String>(json['currency']),
      amount: serializer.fromJson<double>(json['amount']),
      amountConverted: serializer.fromJson<double?>(json['amountConverted']),
      title: serializer.fromJson<String?>(json['title']),
      comment: serializer.fromJson<String?>(json['comment']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'counterpartyId': serializer.toJson<int?>(counterpartyId),
      'category1Id': serializer.toJson<int?>(category1Id),
      'category2Id': serializer.toJson<int?>(category2Id),
      'category3Id': serializer.toJson<int?>(category3Id),
      'category4Id': serializer.toJson<int?>(category4Id),
      'transactionType': serializer.toJson<String>(transactionType),
      'currency': serializer.toJson<String>(currency),
      'amount': serializer.toJson<double>(amount),
      'amountConverted': serializer.toJson<double?>(amountConverted),
      'title': serializer.toJson<String?>(title),
      'comment': serializer.toJson<String?>(comment),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<int>(status),
    };
  }

  Transaction copyWith({
    int? id,
    int? accountId,
    Value<int?> counterpartyId = const Value.absent(),
    Value<int?> category1Id = const Value.absent(),
    Value<int?> category2Id = const Value.absent(),
    Value<int?> category3Id = const Value.absent(),
    Value<int?> category4Id = const Value.absent(),
    String? transactionType,
    String? currency,
    double? amount,
    Value<double?> amountConverted = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> comment = const Value.absent(),
    DateTime? date,
    int? status,
  }) => Transaction(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    counterpartyId: counterpartyId.present
        ? counterpartyId.value
        : this.counterpartyId,
    category1Id: category1Id.present ? category1Id.value : this.category1Id,
    category2Id: category2Id.present ? category2Id.value : this.category2Id,
    category3Id: category3Id.present ? category3Id.value : this.category3Id,
    category4Id: category4Id.present ? category4Id.value : this.category4Id,
    transactionType: transactionType ?? this.transactionType,
    currency: currency ?? this.currency,
    amount: amount ?? this.amount,
    amountConverted: amountConverted.present
        ? amountConverted.value
        : this.amountConverted,
    title: title.present ? title.value : this.title,
    comment: comment.present ? comment.value : this.comment,
    date: date ?? this.date,
    status: status ?? this.status,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      counterpartyId: data.counterpartyId.present
          ? data.counterpartyId.value
          : this.counterpartyId,
      category1Id: data.category1Id.present
          ? data.category1Id.value
          : this.category1Id,
      category2Id: data.category2Id.present
          ? data.category2Id.value
          : this.category2Id,
      category3Id: data.category3Id.present
          ? data.category3Id.value
          : this.category3Id,
      category4Id: data.category4Id.present
          ? data.category4Id.value
          : this.category4Id,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      currency: data.currency.present ? data.currency.value : this.currency,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountConverted: data.amountConverted.present
          ? data.amountConverted.value
          : this.amountConverted,
      title: data.title.present ? data.title.value : this.title,
      comment: data.comment.present ? data.comment.value : this.comment,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('category1Id: $category1Id, ')
          ..write('category2Id: $category2Id, ')
          ..write('category3Id: $category3Id, ')
          ..write('category4Id: $category4Id, ')
          ..write('transactionType: $transactionType, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('amountConverted: $amountConverted, ')
          ..write('title: $title, ')
          ..write('comment: $comment, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    counterpartyId,
    category1Id,
    category2Id,
    category3Id,
    category4Id,
    transactionType,
    currency,
    amount,
    amountConverted,
    title,
    comment,
    date,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.counterpartyId == this.counterpartyId &&
          other.category1Id == this.category1Id &&
          other.category2Id == this.category2Id &&
          other.category3Id == this.category3Id &&
          other.category4Id == this.category4Id &&
          other.transactionType == this.transactionType &&
          other.currency == this.currency &&
          other.amount == this.amount &&
          other.amountConverted == this.amountConverted &&
          other.title == this.title &&
          other.comment == this.comment &&
          other.date == this.date &&
          other.status == this.status);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<int?> counterpartyId;
  final Value<int?> category1Id;
  final Value<int?> category2Id;
  final Value<int?> category3Id;
  final Value<int?> category4Id;
  final Value<String> transactionType;
  final Value<String> currency;
  final Value<double> amount;
  final Value<double?> amountConverted;
  final Value<String?> title;
  final Value<String?> comment;
  final Value<DateTime> date;
  final Value<int> status;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.counterpartyId = const Value.absent(),
    this.category1Id = const Value.absent(),
    this.category2Id = const Value.absent(),
    this.category3Id = const Value.absent(),
    this.category4Id = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.currency = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountConverted = const Value.absent(),
    this.title = const Value.absent(),
    this.comment = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    this.counterpartyId = const Value.absent(),
    this.category1Id = const Value.absent(),
    this.category2Id = const Value.absent(),
    this.category3Id = const Value.absent(),
    this.category4Id = const Value.absent(),
    required String transactionType,
    required String currency,
    required double amount,
    this.amountConverted = const Value.absent(),
    this.title = const Value.absent(),
    this.comment = const Value.absent(),
    required DateTime date,
    required int status,
  }) : accountId = Value(accountId),
       transactionType = Value(transactionType),
       currency = Value(currency),
       amount = Value(amount),
       date = Value(date),
       status = Value(status);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<int>? counterpartyId,
    Expression<int>? category1Id,
    Expression<int>? category2Id,
    Expression<int>? category3Id,
    Expression<int>? category4Id,
    Expression<String>? transactionType,
    Expression<String>? currency,
    Expression<double>? amount,
    Expression<double>? amountConverted,
    Expression<String>? title,
    Expression<String>? comment,
    Expression<DateTime>? date,
    Expression<int>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (counterpartyId != null) 'counterparty_id': counterpartyId,
      if (category1Id != null) 'category1_id': category1Id,
      if (category2Id != null) 'category2_id': category2Id,
      if (category3Id != null) 'category3_id': category3Id,
      if (category4Id != null) 'category4_id': category4Id,
      if (transactionType != null) 'transaction_type': transactionType,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (amountConverted != null) 'amount_converted': amountConverted,
      if (title != null) 'title': title,
      if (comment != null) 'comment': comment,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<int?>? counterpartyId,
    Value<int?>? category1Id,
    Value<int?>? category2Id,
    Value<int?>? category3Id,
    Value<int?>? category4Id,
    Value<String>? transactionType,
    Value<String>? currency,
    Value<double>? amount,
    Value<double?>? amountConverted,
    Value<String?>? title,
    Value<String?>? comment,
    Value<DateTime>? date,
    Value<int>? status,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      category1Id: category1Id ?? this.category1Id,
      category2Id: category2Id ?? this.category2Id,
      category3Id: category3Id ?? this.category3Id,
      category4Id: category4Id ?? this.category4Id,
      transactionType: transactionType ?? this.transactionType,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      amountConverted: amountConverted ?? this.amountConverted,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (counterpartyId.present) {
      map['counterparty_id'] = Variable<int>(counterpartyId.value);
    }
    if (category1Id.present) {
      map['category1_id'] = Variable<int>(category1Id.value);
    }
    if (category2Id.present) {
      map['category2_id'] = Variable<int>(category2Id.value);
    }
    if (category3Id.present) {
      map['category3_id'] = Variable<int>(category3Id.value);
    }
    if (category4Id.present) {
      map['category4_id'] = Variable<int>(category4Id.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (amountConverted.present) {
      map['amount_converted'] = Variable<double>(amountConverted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('category1Id: $category1Id, ')
          ..write('category2Id: $category2Id, ')
          ..write('category3Id: $category3Id, ')
          ..write('category4Id: $category4Id, ')
          ..write('transactionType: $transactionType, ')
          ..write('currency: $currency, ')
          ..write('amount: $amount, ')
          ..write('amountConverted: $amountConverted, ')
          ..write('title: $title, ')
          ..write('comment: $comment, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CounterpartiesTable counterparties = $CounterpartiesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    counterparties,
    transactions,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      required String currency,
      required double initialBalance,
      required DateTime creationDate,
      Value<String?> icon,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> currency,
      Value<double> initialBalance,
      Value<DateTime> creationDate,
      Value<String?> icon,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.transactions.accountId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> initialBalance = const Value.absent(),
                Value<DateTime> creationDate = const Value.absent(),
                Value<String?> icon = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                currency: currency,
                initialBalance: initialBalance,
                creationDate: creationDate,
                icon: icon,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String currency,
                required double initialBalance,
                required DateTime creationDate,
                Value<String?> icon = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                initialBalance: initialBalance,
                creationDate: creationDate,
                icon: icon,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      Account,
                      $AccountsTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String label,
      required int level,
      Value<int?> parentId,
      Value<String?> icon,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<int> level,
      Value<int?> parentId,
      Value<String?> icon,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.categories.parentId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool parentId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String?> icon = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                label: label,
                level: level,
                parentId: parentId,
                icon: icon,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required int level,
                Value<int?> parentId = const Value.absent(),
                Value<String?> icon = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                label: label,
                level: level,
                parentId: parentId,
                icon: icon,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable: $$CategoriesTableReferences
                                    ._parentIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._parentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool parentId})
    >;
typedef $$CounterpartiesTableCreateCompanionBuilder =
    CounterpartiesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> icon,
    });
typedef $$CounterpartiesTableUpdateCompanionBuilder =
    CounterpartiesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> icon,
    });

final class $$CounterpartiesTableReferences
    extends BaseReferences<_$AppDatabase, $CounterpartiesTable, Counterparty> {
  $$CounterpartiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.counterparties.id,
      db.transactions.counterpartyId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.counterpartyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CounterpartiesTableFilterComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.counterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CounterpartiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CounterpartiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CounterpartiesTable> {
  $$CounterpartiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.counterpartyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CounterpartiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CounterpartiesTable,
          Counterparty,
          $$CounterpartiesTableFilterComposer,
          $$CounterpartiesTableOrderingComposer,
          $$CounterpartiesTableAnnotationComposer,
          $$CounterpartiesTableCreateCompanionBuilder,
          $$CounterpartiesTableUpdateCompanionBuilder,
          (Counterparty, $$CounterpartiesTableReferences),
          Counterparty,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$CounterpartiesTableTableManager(
    _$AppDatabase db,
    $CounterpartiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CounterpartiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CounterpartiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CounterpartiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
              }) => CounterpartiesCompanion(id: id, name: name, icon: icon),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> icon = const Value.absent(),
              }) => CounterpartiesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CounterpartiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      Counterparty,
                      $CounterpartiesTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$CounterpartiesTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CounterpartiesTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.counterpartyId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CounterpartiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CounterpartiesTable,
      Counterparty,
      $$CounterpartiesTableFilterComposer,
      $$CounterpartiesTableOrderingComposer,
      $$CounterpartiesTableAnnotationComposer,
      $$CounterpartiesTableCreateCompanionBuilder,
      $$CounterpartiesTableUpdateCompanionBuilder,
      (Counterparty, $$CounterpartiesTableReferences),
      Counterparty,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int accountId,
      Value<int?> counterpartyId,
      Value<int?> category1Id,
      Value<int?> category2Id,
      Value<int?> category3Id,
      Value<int?> category4Id,
      required String transactionType,
      required String currency,
      required double amount,
      Value<double?> amountConverted,
      Value<String?> title,
      Value<String?> comment,
      required DateTime date,
      required int status,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> accountId,
      Value<int?> counterpartyId,
      Value<int?> category1Id,
      Value<int?> category2Id,
      Value<int?> category3Id,
      Value<int?> category4Id,
      Value<String> transactionType,
      Value<String> currency,
      Value<double> amount,
      Value<double?> amountConverted,
      Value<String?> title,
      Value<String?> comment,
      Value<DateTime> date,
      Value<int> status,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.transactions.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CounterpartiesTable _counterpartyIdTable(_$AppDatabase db) =>
      db.counterparties.createAlias(
        $_aliasNameGenerator(
          db.transactions.counterpartyId,
          db.counterparties.id,
        ),
      );

  $$CounterpartiesTableProcessedTableManager? get counterpartyId {
    final $_column = $_itemColumn<int>('counterparty_id');
    if ($_column == null) return null;
    final manager = $$CounterpartiesTableTableManager(
      $_db,
      $_db.counterparties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterpartyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _category1IdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.category1Id, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get category1Id {
    final $_column = $_itemColumn<int>('category1_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_category1IdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _category2IdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.category2Id, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get category2Id {
    final $_column = $_itemColumn<int>('category2_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_category2IdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _category3IdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.category3Id, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get category3Id {
    final $_column = $_itemColumn<int>('category3_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_category3IdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _category4IdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.category4Id, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get category4Id {
    final $_column = $_itemColumn<int>('category4_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_category4IdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountConverted => $composableBuilder(
    column: $table.amountConverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableFilterComposer get counterpartyId {
    final $$CounterpartiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableFilterComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get category1Id {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category1Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get category2Id {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category2Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get category3Id {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category3Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get category4Id {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category4Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountConverted => $composableBuilder(
    column: $table.amountConverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableOrderingComposer get counterpartyId {
    final $$CounterpartiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableOrderingComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get category1Id {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category1Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get category2Id {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category2Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get category3Id {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category3Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get category4Id {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category4Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get amountConverted => $composableBuilder(
    column: $table.amountConverted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CounterpartiesTableAnnotationComposer get counterpartyId {
    final $$CounterpartiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterpartyId,
      referencedTable: $db.counterparties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CounterpartiesTableAnnotationComposer(
            $db: $db,
            $table: $db.counterparties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get category1Id {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category1Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get category2Id {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category2Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get category3Id {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category3Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get category4Id {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category4Id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({
            bool accountId,
            bool counterpartyId,
            bool category1Id,
            bool category2Id,
            bool category3Id,
            bool category4Id,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int?> counterpartyId = const Value.absent(),
                Value<int?> category1Id = const Value.absent(),
                Value<int?> category2Id = const Value.absent(),
                Value<int?> category3Id = const Value.absent(),
                Value<int?> category4Id = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> amountConverted = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> status = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                accountId: accountId,
                counterpartyId: counterpartyId,
                category1Id: category1Id,
                category2Id: category2Id,
                category3Id: category3Id,
                category4Id: category4Id,
                transactionType: transactionType,
                currency: currency,
                amount: amount,
                amountConverted: amountConverted,
                title: title,
                comment: comment,
                date: date,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                Value<int?> counterpartyId = const Value.absent(),
                Value<int?> category1Id = const Value.absent(),
                Value<int?> category2Id = const Value.absent(),
                Value<int?> category3Id = const Value.absent(),
                Value<int?> category4Id = const Value.absent(),
                required String transactionType,
                required String currency,
                required double amount,
                Value<double?> amountConverted = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                required DateTime date,
                required int status,
              }) => TransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                counterpartyId: counterpartyId,
                category1Id: category1Id,
                category2Id: category2Id,
                category3Id: category3Id,
                category4Id: category4Id,
                transactionType: transactionType,
                currency: currency,
                amount: amount,
                amountConverted: amountConverted,
                title: title,
                comment: comment,
                date: date,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                counterpartyId = false,
                category1Id = false,
                category2Id = false,
                category3Id = false,
                category4Id = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (counterpartyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.counterpartyId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._counterpartyIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._counterpartyIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (category1Id) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category1Id,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._category1IdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._category1IdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (category2Id) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category2Id,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._category2IdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._category2IdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (category3Id) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category3Id,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._category3IdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._category3IdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (category4Id) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category4Id,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._category4IdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._category4IdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({
        bool accountId,
        bool counterpartyId,
        bool category1Id,
        bool category2Id,
        bool category3Id,
        bool category4Id,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CounterpartiesTableTableManager get counterparties =>
      $$CounterpartiesTableTableManager(_db, _db.counterparties);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
