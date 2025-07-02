// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Banque App';

  @override
  String get loading => 'Chargement...';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get tomorrow => 'Demain';

  @override
  String get expenses => 'Dépenses';

  @override
  String get incomes => 'Revenus';

  @override
  String get addAccount => 'Ajouter un compte';

  @override
  String get accountName => 'Nom du compte';

  @override
  String get initialBalance => 'Solde initial';

  @override
  String get currency => 'Devise';

  @override
  String get save => 'Sauvegarder';

  @override
  String get cancel => 'Annuler';

  @override
  String get addTransaction => 'Ajouter une transaction';

  @override
  String get transactionDetails => 'Détails de la transaction';

  @override
  String get amount => 'Montant';

  @override
  String get title => 'Titre';

  @override
  String get comment => 'Commentaire';

  @override
  String get date => 'Date';

  @override
  String get category => 'Catégorie';

  @override
  String get counterparty => 'Tiers';

  @override
  String get debit => 'Débit';

  @override
  String get credit => 'Crédit';

  @override
  String get status => 'Statut';

  @override
  String get pending => 'En attente';

  @override
  String get confirmed => 'Confirmé';

  @override
  String get unknown => 'Inconnu';
}
