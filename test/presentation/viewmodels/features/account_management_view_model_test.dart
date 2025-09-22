import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/services/smart_exchange_rate_service.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/viewmodels/features/account_management_view_model.dart';

import 'account_management_view_model_test.mocks.dart';

@GenerateMocks([AccountRepository, SmartExchangeRateService])
void main() {
  late MockAccountRepository mockAccountRepository;
  late MockSmartExchangeRateService mockSmartExchangeRateService;
  late AccountManagementViewModel viewModel;
  late AppEventBus eventBus;

  final testAccount = domain.Account(
    id: 1,
    name: 'Test Account',
    currency: 'EUR',
    initialBalance: 1000.0,
    creationDate: DateTime.now(),
    icon: 'bank',
  );

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    mockSmartExchangeRateService = MockSmartExchangeRateService();
    eventBus = AppEventBus.instance;
    eventBus.reset();
    
    viewModel = AccountManagementViewModel(
      mockAccountRepository,
      mockSmartExchangeRateService,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    // Small delay to let any pending events process
    await Future.delayed(const Duration(milliseconds: 10));
    eventBus.reset();
  });

  group('AccountManagementViewModel - Initialization', () {
    test('should initialize with correct default state', () {
      expect(viewModel.state.currentAccount, isNull);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.isCompleted, false);
      expect(viewModel.state.validationMessage, isNull);
      expect(viewModel.state.tempName, isNull);
      expect(viewModel.state.tempCurrency, isNull);
      expect(viewModel.state.tempInitialBalance, isNull);
      expect(viewModel.state.tempIcon, isNull);
      expect(viewModel.state.hasAccount, false);
      expect(viewModel.state.canSave, false);
      expect(viewModel.state.hasValidData, false);
      expect(viewModel.state.hasChanges, false);
    });

    test('should initialize for creation correctly', () {
      // Act
      viewModel.initializeForCreation();

      // Assert
      expect(viewModel.isCreating, true);
      expect(viewModel.isEditing, false);
      expect(viewModel.state.currentAccount, isNull);
      expect(viewModel.state.isCompleted, false);
    });

    test('should initialize for edit successfully', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);

      // Act
      await viewModel.initializeForEdit(1);

      // Assert
      expect(viewModel.isEditing, true);
      expect(viewModel.isCreating, false);
      expect(viewModel.currentAccount, equals(testAccount));
      expect(viewModel.currentName, testAccount.name);
      expect(viewModel.currentCurrency, testAccount.currency);
      expect(viewModel.currentInitialBalance, testAccount.initialBalance);
      expect(viewModel.currentIcon, testAccount.icon);
      expect(viewModel.state.isProcessing, false);
      
      verify(mockAccountRepository.getAccountById(1)).called(1);
    });

    test('should handle account not found during edit initialization', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(999))
          .thenAnswer((_) async => null);

      // Act
      await viewModel.initializeForEdit(999);

      // Assert
      expect(viewModel.state.currentAccount, isNull);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.validationMessage, 'Compte non trouvé');
    });

    test('should handle errors during edit initialization', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenThrow(Exception('Database error'));

      // Act
      await viewModel.initializeForEdit(1);

      // Assert
      expect(viewModel.state.currentAccount, isNull);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.validationMessage, 'Erreur lors du chargement du compte');
    });
  });

  group('AccountManagementViewModel - Field Updates', () {
    test('should update name correctly', () {
      // Arrange - set valid data first to avoid validation errors
      viewModel.updateName('New Account Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Assert
      expect(viewModel.currentName, 'New Account Name');
      expect(viewModel.state.validationMessage, isNull); // Should clear validation
    });

    test('should update currency correctly', () {
      // Arrange - set valid data first to avoid validation errors
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('USD');
      viewModel.updateInitialBalance(1000.0);

      // Assert
      expect(viewModel.currentCurrency, 'USD');
      expect(viewModel.state.validationMessage, isNull); // Should clear validation
    });

    test('should update initial balance correctly', () {
      // Arrange - set valid data first to avoid validation errors
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(2500.0);

      // Assert
      expect(viewModel.currentInitialBalance, 2500.0);
      expect(viewModel.state.validationMessage, isNull); // Should clear validation
    });

    test('should update icon correctly', () {
      // Act
      viewModel.updateIcon('credit_card');

      // Assert
      expect(viewModel.currentIcon, 'credit_card');
    });

    test('should clear icon when set to null', () {
      // Arrange
      viewModel.updateIcon('bank');
      expect(viewModel.currentIcon, 'bank');

      // Act
      viewModel.updateIcon(null);

      // Assert
      expect(viewModel.currentIcon, isNull);
    });

    test('should detect valid data state', () {
      // Act
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Assert
      expect(viewModel.state.hasValidData, true);
      expect(viewModel.state.canSave, true);
    });
  });

  group('AccountManagementViewModel - Validation', () {
    test('should validate empty name', () {
      // Arrange
      viewModel.updateName('');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le nom du compte est requis');
    });

    test('should validate short name', () {
      // Arrange
      viewModel.updateName('A');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le nom du compte doit contenir au moins 2 caractères');
    });

    test('should validate long name', () {
      // Arrange
      viewModel.updateName('A' * 51); // 51 characters
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le nom du compte ne peut pas dépasser 50 caractères');
    });

    test('should validate empty currency', () {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('');
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'La devise est requise');
    });

    test('should validate invalid currency length', () {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EURO'); // 4 characters instead of 3
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'La devise doit être un code à 3 lettres (ex: EUR, USD)');
    });

    test('should validate null initial balance', () {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      // Don't set initial balance

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le solde initial est requis');
    });

    test('should validate very low initial balance', () {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(-1000000000); // Below limit

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le solde initial ne peut pas être inférieur à -999,999,999');
    });

    test('should validate very high initial balance', () {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000000000); // Above limit

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, 'Le solde initial ne peut pas être supérieur à 999,999,999');
    });

    test('should validate correct data', () {
      // Arrange
      viewModel.updateName('Valid Account');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1500.0);

      // Act
      final result = viewModel.validateAccount();

      // Assert
      expect(result, isNull); // No validation errors
    });
  });

  group('AccountManagementViewModel - Create Account', () {
    test('should create account successfully', () async {
      // Arrange
      viewModel.updateName('New Account');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(2000.0);
      viewModel.updateIcon('savings');

      final expectedAccount = domain.Account(
        id: 0,
        name: 'New Account',
        currency: 'EUR',
        initialBalance: 2000.0,
        creationDate: DateTime.now(),
        icon: 'savings',
      );

      final createdAccount = expectedAccount.copyWith(id: 1);

      when(mockAccountRepository.createAccount(any))
          .thenAnswer((_) async => createdAccount);
      when(mockSmartExchangeRateService.ensureCurrencyAvailable(any))
          .thenAnswer((_) async => ExchangeRateUpdateResult.success(
                updatedCurrencies: ['EUR'],
                duration: const Duration(milliseconds: 100),
                strategy: UpdateStrategy.noneNeeded,
              ));

      // Act
      final result = await viewModel.createAccount();

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.currentAccount, equals(createdAccount));

      verify(mockAccountRepository.createAccount(any)).called(1);
      // Note: SmartExchangeRateService call is asynchronous and non-blocking
    });

    test('should not create account with validation errors', () async {
      // Arrange
      viewModel.updateName(''); // Invalid name
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Act
      final result = await viewModel.createAccount();

      // Assert
      expect(result, false);
      expect(viewModel.state.validationMessage, 'Le nom du compte est requis');
      verifyNever(mockAccountRepository.createAccount(any));
    });

    test('should handle creation errors', () async {
      // Arrange
      viewModel.updateName('Valid Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      when(mockAccountRepository.createAccount(any))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await viewModel.createAccount();

      // Assert
      expect(result, false);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.validationMessage, 'Erreur lors de la création du compte');
    });

    test('should complete creation operation successfully', () async {
      // Arrange
      viewModel.updateName('Event Test');
      viewModel.updateCurrency('USD');
      viewModel.updateInitialBalance(500.0);

      final createdAccount = testAccount.copyWith(
        name: 'Event Test',
        currency: 'USD',
        initialBalance: 500.0,
      );

      when(mockAccountRepository.createAccount(any))
          .thenAnswer((_) async => createdAccount);
      when(mockSmartExchangeRateService.ensureCurrencyAvailable(any))
          .thenAnswer((_) async => ExchangeRateUpdateResult.success(
                updatedCurrencies: ['USD'],
                duration: const Duration(milliseconds: 100),
                strategy: UpdateStrategy.noneNeeded,
              ));

      // Act
      final result = await viewModel.createAccount();

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.currentAccount?.name, 'Event Test');
      expect(viewModel.currentAccount?.currency, 'USD');
      
      // Verify repository was called
      verify(mockAccountRepository.createAccount(any)).called(1);
    });
  });

  group('AccountManagementViewModel - Update Account', () {
    setUp(() async {
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      await viewModel.initializeForEdit(1);
    });

    test('should update account successfully', () async {
      // Arrange
      viewModel.updateName('Updated Name');
      viewModel.updateCurrency('USD');
      viewModel.updateInitialBalance(1500.0);

      when(mockAccountRepository.updateAccount(any))
          .thenAnswer((_) async => viewModel.currentAccount!.copyWith(
            name: 'Updated Name',
            currency: 'USD',
            initialBalance: 1500.0,
          ));

      // Act
      final result = await viewModel.updateAccount();

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.currentAccount?.name, 'Updated Name');
      expect(viewModel.currentAccount?.currency, 'USD');
      expect(viewModel.currentAccount?.initialBalance, 1500.0);

      verify(mockAccountRepository.updateAccount(any)).called(1);
    });

    test('should not update account without changes', () async {
      // Act - No changes made
      final result = await viewModel.updateAccount();

      // Assert
      expect(result, false);
      verifyNever(mockAccountRepository.updateAccount(any));
    });

    test('should not update account with validation errors', () async {
      // Arrange
      viewModel.updateName(''); // Invalid name

      // Act
      final result = await viewModel.updateAccount();

      // Assert
      expect(result, false);
      expect(viewModel.state.validationMessage, 'Le nom du compte est requis');
      verifyNever(mockAccountRepository.updateAccount(any));
    });

    test('should handle update errors', () async {
      // Arrange
      viewModel.updateName('Updated Name');
      when(mockAccountRepository.updateAccount(any))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await viewModel.updateAccount();

      // Assert
      expect(result, false);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.validationMessage, 'Erreur lors de la modification du compte');
    });

    test('should complete update operation successfully', () async {
      // Arrange
      viewModel.updateName('Event Updated');

      when(mockAccountRepository.updateAccount(any))
          .thenAnswer((_) async => viewModel.currentAccount!.copyWith(
            name: 'Event Updated',
          ));

      // Act
      final result = await viewModel.updateAccount();

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.currentAccount?.name, 'Event Updated');
      
      // Verify repository was called correctly
      verify(mockAccountRepository.updateAccount(any)).called(1);
    });
  });

  group('AccountManagementViewModel - Delete Account', () {
    test('should delete account successfully', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      when(mockAccountRepository.deleteAccount(1))
          .thenAnswer((_) async {});

      // Act
      final result = await viewModel.deleteAccount(1);

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);

      verify(mockAccountRepository.getAccountById(1)).called(1);
      verify(mockAccountRepository.deleteAccount(1)).called(1);
    });

    test('should handle account not found during deletion', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await viewModel.deleteAccount(999);

      // Assert
      expect(result, false);
      expect(viewModel.state.validationMessage, 'Compte non trouvé');
      verifyNever(mockAccountRepository.deleteAccount(any));
    });

    test('should handle deletion errors', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      when(mockAccountRepository.deleteAccount(1))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await viewModel.deleteAccount(1);

      // Assert
      expect(result, false);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.validationMessage, 'Erreur lors de la suppression du compte');
    });

    test('should complete deletion operation successfully', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      when(mockAccountRepository.deleteAccount(1))
          .thenAnswer((_) async {});

      // Act
      final result = await viewModel.deleteAccount(1);

      // Assert
      expect(result, true);
      expect(viewModel.state.isCompleted, true);
      expect(viewModel.state.isProcessing, false);
      
      // Verify repository calls were made correctly
      verify(mockAccountRepository.getAccountById(1)).called(1);
      verify(mockAccountRepository.deleteAccount(1)).called(1);
    });
  });

  group('AccountManagementViewModel - Utility Methods', () {
    test('should cancel changes for editing account', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      await viewModel.initializeForEdit(1);

      // Make some changes
      viewModel.updateName('Changed Name');
      viewModel.updateCurrency('USD');
      expect(viewModel.hasChanges, true);

      // Act
      viewModel.cancelChanges();

      // Assert
      expect(viewModel.currentName, testAccount.name);
      expect(viewModel.currentCurrency, testAccount.currency);
      expect(viewModel.currentInitialBalance, testAccount.initialBalance);
      expect(viewModel.state.isCompleted, false);
      expect(viewModel.state.validationMessage, isNull);
    });

    test('should cancel changes for new account creation', () {
      // Arrange
      viewModel.initializeForCreation();
      viewModel.updateName('New Name');
      viewModel.updateCurrency('EUR');
      viewModel.updateInitialBalance(1000.0);

      // Act
      viewModel.cancelChanges();

      // Assert
      expect(viewModel.currentName, isNull);
      expect(viewModel.currentCurrency, isNull);
      expect(viewModel.currentInitialBalance, isNull);
      expect(viewModel.state.isCompleted, false);
      expect(viewModel.state.validationMessage, isNull);
    });

    test('should detect changes correctly', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      await viewModel.initializeForEdit(1);

      // Initially no changes
      expect(viewModel.hasChanges, false);

      // Make a change
      viewModel.updateName('Different Name');
      expect(viewModel.hasChanges, true);

      // Revert change
      viewModel.updateName(testAccount.name);
      expect(viewModel.hasChanges, false);
    });

    test('should reset to initial state correctly', () {
      // Arrange
      viewModel.updateName('Some Name');
      viewModel.updateCurrency('USD');

      // Act
      viewModel.resetToInitialState();

      // Assert
      expect(viewModel.state.currentAccount, isNull);
      expect(viewModel.state.tempName, isNull);
      expect(viewModel.state.tempCurrency, isNull);
      expect(viewModel.state.isProcessing, false);
      expect(viewModel.state.isCompleted, false);
    });
  });

  group('AccountManagementViewModel - State Properties', () {
    test('should return correct utility getters when no account loaded', () {
      expect(viewModel.currentAccount, isNull);
      expect(viewModel.currentName, isNull);
      expect(viewModel.currentCurrency, isNull);
      expect(viewModel.currentInitialBalance, isNull);
      expect(viewModel.currentIcon, isNull);
      expect(viewModel.isProcessing, false);
      expect(viewModel.isCompleted, false);
      expect(viewModel.canSave, false);
      expect(viewModel.hasChanges, false);
      expect(viewModel.validationMessage, isNull);
      expect(viewModel.isCreating, true);
      expect(viewModel.isEditing, false);
    });

    test('should return correct utility getters with account loaded', () async {
      // Arrange
      when(mockAccountRepository.getAccountById(1))
          .thenAnswer((_) async => testAccount);
      await viewModel.initializeForEdit(1);

      // Assert
      expect(viewModel.currentAccount, equals(testAccount));
      expect(viewModel.currentName, testAccount.name);
      expect(viewModel.currentCurrency, testAccount.currency);
      expect(viewModel.currentInitialBalance, testAccount.initialBalance);
      expect(viewModel.currentIcon, testAccount.icon);
      expect(viewModel.isCreating, false);
      expect(viewModel.isEditing, true);
    });
  });
}