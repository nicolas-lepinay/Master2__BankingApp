import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank App'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @incomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get incomes;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add a new account'**
  String get addAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction'**
  String get addTransaction;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @validateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm transaction'**
  String get validateTransaction;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @counterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get counterparty;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Solde'**
  String get balance;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @expectedBalance.
  ///
  /// In en, this message translates to:
  /// **'Expected Balance'**
  String get expectedBalance;

  /// No description provided for @actualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual Balance'**
  String get actualBalance;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Annulé'**
  String get canceled;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @followedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get followedTransactions;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account available'**
  String get noAccount;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transaction'**
  String get noTransactions;

  /// No description provided for @startAddingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first transaction'**
  String get startAddingTransactions;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// No description provided for @keyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get keyword;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search for transaction'**
  String get searchTransactions;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get searchResults;

  /// No description provided for @resultsFound.
  ///
  /// In en, this message translates to:
  /// **'results found'**
  String get resultsFound;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @euroCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get euroCurrencyName;

  /// No description provided for @euroCountryName.
  ///
  /// In en, this message translates to:
  /// **'European Union'**
  String get euroCountryName;

  /// No description provided for @usdCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get usdCurrencyName;

  /// No description provided for @usdCountryName.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get usdCountryName;

  /// No description provided for @gbpCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'British Pound'**
  String get gbpCurrencyName;

  /// No description provided for @gbpCountryName.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get gbpCountryName;

  /// No description provided for @jpyCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Japanese Yen'**
  String get jpyCurrencyName;

  /// No description provided for @jpyCountryName.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get jpyCountryName;

  /// No description provided for @cadCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Canadian Dollar'**
  String get cadCurrencyName;

  /// No description provided for @cadCountryName.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get cadCountryName;

  /// No description provided for @audCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Australian Dollar'**
  String get audCurrencyName;

  /// No description provided for @audCountryName.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get audCountryName;

  /// No description provided for @chfCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Swiss Franc'**
  String get chfCurrencyName;

  /// No description provided for @chfCountryName.
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get chfCountryName;

  /// No description provided for @cnyCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Chinese Yuan'**
  String get cnyCurrencyName;

  /// No description provided for @cnyCountryName.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get cnyCountryName;

  /// No description provided for @hkdCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong Dollar'**
  String get hkdCurrencyName;

  /// No description provided for @hkdCountryName.
  ///
  /// In en, this message translates to:
  /// **'Hong Kong'**
  String get hkdCountryName;

  /// No description provided for @sgdCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Singapore Dollar'**
  String get sgdCurrencyName;

  /// No description provided for @sgdCountryName.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get sgdCountryName;

  /// No description provided for @krwCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'South Korean Won'**
  String get krwCurrencyName;

  /// No description provided for @krwCountryName.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get krwCountryName;

  /// No description provided for @inrCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Indian Rupee'**
  String get inrCurrencyName;

  /// No description provided for @inrCountryName.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get inrCountryName;

  /// No description provided for @twdCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'New Taiwan Dollar'**
  String get twdCurrencyName;

  /// No description provided for @twdCountryName.
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get twdCountryName;

  /// No description provided for @thbCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Thai Baht'**
  String get thbCurrencyName;

  /// No description provided for @thbCountryName.
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get thbCountryName;

  /// No description provided for @idrCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Indonesian Rupiah'**
  String get idrCurrencyName;

  /// No description provided for @idrCountryName.
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get idrCountryName;

  /// No description provided for @phpCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Philippine Peso'**
  String get phpCurrencyName;

  /// No description provided for @phpCountryName.
  ///
  /// In en, this message translates to:
  /// **'Philippines'**
  String get phpCountryName;

  /// No description provided for @myrCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Malaysian Ringgit'**
  String get myrCurrencyName;

  /// No description provided for @myrCountryName.
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get myrCountryName;

  /// No description provided for @sekCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Swedish Krona'**
  String get sekCurrencyName;

  /// No description provided for @sekCountryName.
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get sekCountryName;

  /// No description provided for @nokCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Norwegian Krone'**
  String get nokCurrencyName;

  /// No description provided for @nokCountryName.
  ///
  /// In en, this message translates to:
  /// **'Norway'**
  String get nokCountryName;

  /// No description provided for @dkkCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Danish Krone'**
  String get dkkCurrencyName;

  /// No description provided for @dkkCountryName.
  ///
  /// In en, this message translates to:
  /// **'Denmark'**
  String get dkkCountryName;

  /// No description provided for @plnCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Polish Złoty'**
  String get plnCurrencyName;

  /// No description provided for @plnCountryName.
  ///
  /// In en, this message translates to:
  /// **'Poland'**
  String get plnCountryName;

  /// No description provided for @czkCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Czech Koruna'**
  String get czkCurrencyName;

  /// No description provided for @czkCountryName.
  ///
  /// In en, this message translates to:
  /// **'Czech Republic'**
  String get czkCountryName;

  /// No description provided for @hufCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Hungarian Forint'**
  String get hufCurrencyName;

  /// No description provided for @hufCountryName.
  ///
  /// In en, this message translates to:
  /// **'Hungary'**
  String get hufCountryName;

  /// No description provided for @ronCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Romanian Leu'**
  String get ronCurrencyName;

  /// No description provided for @ronCountryName.
  ///
  /// In en, this message translates to:
  /// **'Romania'**
  String get ronCountryName;

  /// No description provided for @tryCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira'**
  String get tryCurrencyName;

  /// No description provided for @tryCountryName.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get tryCountryName;

  /// No description provided for @rubCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Russian Ruble'**
  String get rubCurrencyName;

  /// No description provided for @rubCountryName.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get rubCountryName;

  /// No description provided for @mxnCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Mexican Peso'**
  String get mxnCurrencyName;

  /// No description provided for @mxnCountryName.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get mxnCountryName;

  /// No description provided for @brlCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Real'**
  String get brlCurrencyName;

  /// No description provided for @brlCountryName.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get brlCountryName;

  /// No description provided for @clpCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Chilean Peso'**
  String get clpCurrencyName;

  /// No description provided for @clpCountryName.
  ///
  /// In en, this message translates to:
  /// **'Chile'**
  String get clpCountryName;

  /// No description provided for @copCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Colombian Peso'**
  String get copCurrencyName;

  /// No description provided for @copCountryName.
  ///
  /// In en, this message translates to:
  /// **'Colombia'**
  String get copCountryName;

  /// No description provided for @penCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Peruvian Sol'**
  String get penCurrencyName;

  /// No description provided for @penCountryName.
  ///
  /// In en, this message translates to:
  /// **'Peru'**
  String get penCountryName;

  /// No description provided for @nzdCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'New Zealand Dollar'**
  String get nzdCurrencyName;

  /// No description provided for @nzdCountryName.
  ///
  /// In en, this message translates to:
  /// **'New Zealand'**
  String get nzdCountryName;

  /// No description provided for @zarCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'South African Rand'**
  String get zarCurrencyName;

  /// No description provided for @zarCountryName.
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get zarCountryName;

  /// No description provided for @ilsCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Israeli New Shekel'**
  String get ilsCurrencyName;

  /// No description provided for @ilsCountryName.
  ///
  /// In en, this message translates to:
  /// **'Israel'**
  String get ilsCountryName;

  /// No description provided for @aedCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'UAE Dirham'**
  String get aedCurrencyName;

  /// No description provided for @aedCountryName.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get aedCountryName;

  /// No description provided for @sarCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Saudi Riyal'**
  String get sarCurrencyName;

  /// No description provided for @sarCountryName.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get sarCountryName;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get selectCurrency;

  /// No description provided for @convertedAmount.
  ///
  /// In en, this message translates to:
  /// **'Converted amount'**
  String get convertedAmount;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get exchangeRate;

  /// No description provided for @currencyConversion.
  ///
  /// In en, this message translates to:
  /// **'Currency conversion'**
  String get currencyConversion;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion rate'**
  String get conversionRate;

  /// No description provided for @originalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original amount'**
  String get originalAmount;

  /// No description provided for @convertedTo.
  ///
  /// In en, this message translates to:
  /// **'Converted to'**
  String get convertedTo;

  /// No description provided for @exchangeRateLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate last updated'**
  String get exchangeRateLastUpdated;

  /// No description provided for @exchangeRateExpired.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate expired'**
  String get exchangeRateExpired;

  /// No description provided for @exchangeRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate unavailable'**
  String get exchangeRateUnavailable;

  /// No description provided for @currencyNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Currency not supported'**
  String get currencyNotSupported;

  /// No description provided for @conversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed'**
  String get conversionFailed;

  /// No description provided for @updatingExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Updating exchange rates...'**
  String get updatingExchangeRates;

  /// No description provided for @exchangeRatesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates updated'**
  String get exchangeRatesUpdated;

  /// No description provided for @equivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent'**
  String get equivalent;

  /// No description provided for @loadingConversion.
  ///
  /// In en, this message translates to:
  /// **'Loading conversion...'**
  String get loadingConversion;

  /// No description provided for @otherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Other currencies'**
  String get otherCurrencies;

  /// No description provided for @accountCurrency.
  ///
  /// In en, this message translates to:
  /// **'Account\'s currency'**
  String get accountCurrency;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get baseCurrency;

  /// No description provided for @paidTo.
  ///
  /// In en, this message translates to:
  /// **'Paid to...'**
  String get paidTo;

  /// No description provided for @receivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from...'**
  String get receivedFrom;

  /// No description provided for @counterpartySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Amazon'**
  String get counterpartySearchHint;

  /// No description provided for @selectCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Select counterparty'**
  String get selectCounterparty;

  /// No description provided for @createNewCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Create new counterparty'**
  String get createNewCounterparty;

  /// No description provided for @findLogo.
  ///
  /// In en, this message translates to:
  /// **'Find a logo'**
  String get findLogo;

  /// No description provided for @searchForLogo.
  ///
  /// In en, this message translates to:
  /// **'Search for a logo'**
  String get searchForLogo;

  /// No description provided for @logoSearchError.
  ///
  /// In en, this message translates to:
  /// **'Oops! An error occurred'**
  String get logoSearchError;

  /// No description provided for @searchLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Type in a company name to find their logo'**
  String get searchLogoHint;

  /// No description provided for @noLogo.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noLogo;

  /// No description provided for @removeCurrentLogo.
  ///
  /// In en, this message translates to:
  /// **'Erase the current logo'**
  String get removeCurrentLogo;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during the logo search.'**
  String get searchError;

  /// No description provided for @loadingRates.
  ///
  /// In en, this message translates to:
  /// **'Loading rates...'**
  String get loadingRates;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
