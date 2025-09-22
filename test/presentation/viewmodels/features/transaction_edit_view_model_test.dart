import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/viewmodels/features/transaction_edit_view_model.dart';

import 'transaction_edit_view_model_test.mocks.dart';

@GenerateMocks([TransactionRepository])
void main() {
  late MockTransactionRepository mockTransactionRepository;
  late TransactionEditViewModel viewModel;
  late AppEventBus eventBus;

  const int testTransactionId = 1;

  final testTransaction = domain.Transaction(
    id: testTransactionId,
    accountId: 1,
    type: domain.TransactionType.expense,
    amount: 100.0,
    currency: 'EUR',
    title: 'Test Transaction',
    comment: 'Test comment',
    date: DateTime.now(),
    status: domain.TransactionStatus.completed,
  );

  final modifiedTransaction = testTransaction.copyWith(
    amount: 150.0,
    title: 'Modified Transaction',
  );

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    eventBus = AppEventBus.instance;
    eventBus.reset();
    
    viewModel = TransactionEditViewModel(
      testTransactionId,
      mockTransactionRepository,
    );
  });

  tearDown(() {
    viewModel.dispose();
    eventBus.reset();
  });

  group('TransactionEditViewModel - Initialization', () {
    test('should initialize with correct default state', () {
      expect(viewModel.state.originalTransaction, isNull);
      expect(viewModel.state.editingTransaction, isNull);
      expect(viewModel.state.isUpdating, false);
      expect(viewModel.state.isSaved, false);
      expect(viewModel.state.validationMessage, isNull);
      expect(viewModel.state.hasTransaction, false);
      expect(viewModel.state.hasChanges, false);
      expect(viewModel.state.canSave, false);
      expect(viewModel.transactionId, testTransactionId);
    });

    test('should load transaction on initialize', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.state.originalTransaction, equals(testTransaction));
      expect(viewModel.state.editingTransaction, equals(testTransaction));
      expect(viewModel.state.hasTransaction, true);
      expect(viewModel.state.hasChanges, false);
      expect(viewModel.state.isSaved, false);
      
      verify(mockTransactionRepository.getTransactionById(testTransactionId)).called(1);
    });

    test('should handle transaction not found error', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => null);

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains('Transaction non trouvée'));
      expect(viewModel.state.hasTransaction, false);
    });
  });

  group('TransactionEditViewModel - Field Updates', () {
    setUp(() async {
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      await viewModel.initialize();
    });

    test('should update type', () {
      // Act
      viewModel.updateType(domain.TransactionType.income);

      // Assert
      expect(viewModel.state.editingTransaction?.type, domain.TransactionType.income);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentType, domain.TransactionType.income);
    });

    test('should update amount with validation', () {
      // Act
      viewModel.updateAmount(200.0);

      // Assert
      expect(viewModel.state.editingTransaction?.amount, 200.0);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.state.validationMessage, isNull);
      expect(viewModel.currentAmount, 200.0);
    });

    test('should validate negative amount', () {
      // Act
      viewModel.updateAmount(-50.0);

      // Assert
      expect(viewModel.state.validationMessage, 'Le montant doit être supérieur à 0');
      expect(viewModel.state.canSave, false);
    });

    test('should validate zero amount', () {
      // Act
      viewModel.updateAmount(0.0);

      // Assert
      expect(viewModel.state.validationMessage, 'Le montant doit être supérieur à 0');
      expect(viewModel.state.canSave, false);
    });

    test('should validate very large amount', () {
      // Act
      viewModel.updateAmount(1000000000.0);

      // Assert
      expect(viewModel.state.validationMessage, 'Le montant est trop élevé');
      expect(viewModel.state.canSave, false);
    });

    test('should update currency', () {
      // Act
      viewModel.updateCurrency('USD');

      // Assert
      expect(viewModel.state.editingTransaction?.currency, 'USD');
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentCurrency, 'USD');
    });

    test('should update title', () {
      // Act
      viewModel.updateTitle('New Title');

      // Assert
      expect(viewModel.state.editingTransaction?.title, 'New Title');
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentTitle, 'New Title');
    });

    test('should update comment', () {
      // Act
      viewModel.updateComment('New comment');

      // Assert
      expect(viewModel.state.editingTransaction?.comment, 'New comment');
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentComment, 'New comment');
    });

    test('should update date', () {
      // Arrange
      final newDate = DateTime.now().add(Duration(days: 1));

      // Act
      viewModel.updateDate(newDate);

      // Assert
      expect(viewModel.state.editingTransaction?.date, newDate);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentDate, newDate);
    });

    test('should update account', () {
      // Act
      viewModel.updateAccount(2);

      // Assert
      expect(viewModel.state.editingTransaction?.accountId, 2);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentAccountId, 2);
    });

    test('should update counterparty', () {
      // Act
      viewModel.updateCounterparty(5);

      // Assert
      expect(viewModel.state.editingTransaction?.counterpartyId, 5);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentCounterpartyId, 5);
    });

    test('should update categories', () {
      // Act
      viewModel.updateCategories([1, 2, 3]);

      // Assert
      expect(viewModel.state.editingTransaction?.deepestCategoryId, 3);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentCategoryIds, [1, 2, 3]);
    });

    test('should update status', () {
      // Act
      viewModel.updateStatus(domain.TransactionStatus.pending);

      // Assert
      expect(viewModel.state.editingTransaction?.status, domain.TransactionStatus.pending);
      expect(viewModel.state.hasChanges, true);
      expect(viewModel.currentStatus, domain.TransactionStatus.pending);
    });
  });

  group('TransactionEditViewModel - Save Operations', () {
    setUp(() async {
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      await viewModel.initialize();
    });

    test('should save transaction successfully', () async {
      // Arrange
      viewModel.updateAmount(200.0);
      when(mockTransactionRepository.updateTransaction(any))
          .thenAnswer((_) async => viewModel.state.editingTransaction!);

      // Act
      final result = await viewModel.saveTransaction();

      // Assert
      expect(result, true);
      expect(viewModel.state.isSaved, true);
      expect(viewModel.state.isUpdating, false);
      expect(viewModel.state.hasChanges, false); // No changes because original was updated
      
      verify(mockTransactionRepository.updateTransaction(any)).called(1);
    });

    test('should not save when no changes', () async {
      // Act
      final result = await viewModel.saveTransaction();

      // Assert
      expect(result, false);
      verifyNever(mockTransactionRepository.updateTransaction(any));
    });

    test('should not save when validation errors', () async {
      // Arrange
      viewModel.updateAmount(-50.0); // Invalid amount

      // Act
      final result = await viewModel.saveTransaction();

      // Assert
      expect(result, false);
      verifyNever(mockTransactionRepository.updateTransaction(any));
    });

    test('should handle save errors', () async {
      // Arrange
      viewModel.updateAmount(200.0);
      when(mockTransactionRepository.updateTransaction(any))
          .thenThrow(Exception('Save failed'));

      // Act
      final result = await viewModel.saveTransaction();

      // Assert
      expect(result, false);
      expect(viewModel.state.isUpdating, false);
      expect(viewModel.hasError, true);
    });

    test('should cancel changes successfully', () {
      // Arrange
      viewModel.updateAmount(200.0);
      viewModel.updateTitle('Modified Title');
      expect(viewModel.state.hasChanges, true);

      // Act
      viewModel.cancelChanges();

      // Assert
      expect(viewModel.state.editingTransaction, equals(testTransaction));
      expect(viewModel.state.hasChanges, false);
      expect(viewModel.state.isSaved, false);
      expect(viewModel.state.validationMessage, isNull);
    });
  });

  group('TransactionEditViewModel - Event Bus Integration', () {
    setUp() async {
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      await viewModel.initialize();
    }

    test('should handle transaction updated events', () {
      // Arrange
      final updatedTransaction = testTransaction.copyWith(title: 'Updated Externally');
      final event = TransactionUpdatedEvent(
        updatedTransaction: updatedTransaction,
        accountId: testTransaction.accountId,
        timestamp: DateTime.now(),
        eventId: 'test_update',
      );

      // Act
      eventBus.fire(event);

      // Assert
      expect(viewModel.state.originalTransaction?.title, 'Updated Externally');
      expect(viewModel.state.editingTransaction?.title, 'Updated Externally');
      expect(viewModel.state.isSaved, false);
    });

    test('should handle transaction deleted events', () {
      // Arrange
      final event = TransactionDeletedEvent(
        transactionId: testTransactionId,
        accountId: testTransaction.accountId,
        deletedTransaction: testTransaction,
        timestamp: DateTime.now(),
        eventId: 'test_delete',
      );

      // Act
      eventBus.fire(event);

      // Assert
      expect(viewModel.state.originalTransaction, isNull);
      expect(viewModel.state.editingTransaction, isNull);
      expect(viewModel.state.hasTransaction, false);
    });

    test('should ignore events for other transactions', () {
      // Arrange
      const otherTransactionId = 999;
      final initialState = viewModel.state;
      
      final event = TransactionUpdatedEvent(
        updatedTransaction: testTransaction.copyWith(id: otherTransactionId),
        accountId: testTransaction.accountId,
        timestamp: DateTime.now(),
        eventId: 'test_other',
      );

      // Act
      eventBus.fire(event);

      // Assert - State should remain unchanged
      expect(viewModel.state.originalTransaction, equals(initialState.originalTransaction));
      expect(viewModel.state.editingTransaction, equals(initialState.editingTransaction));
    });
  });

  group('TransactionEditViewModel - Validation', () {
    setUp() async {
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      await viewModel.initialize();
    }

    test('should validate transaction successfully', () {
      // Arrange
      viewModel.updateAmount(150.0);
      viewModel.updateCurrency('EUR');

      // Act
      final result = viewModel.validateTransaction();

      // Assert
      expect(result, isNull); // No validation errors
    });

    test('should validate empty currency', () {
      // Arrange
      viewModel.updateCurrency('');

      // Act
      final result = viewModel.validateTransaction();

      // Assert
      expect(result, 'La devise est requise');
    });

    test('should validate invalid amount in validateTransaction', () {
      // Arrange
      viewModel.updateAmount(-50.0);

      // Act
      final result = viewModel.validateTransaction();

      // Assert
      expect(result, 'Le montant doit être supérieur à 0');
    });
  });

  group('TransactionEditViewModel - State Properties', () {
    test('should return correct utility getters when no transaction loaded', () {
      expect(viewModel.originalTransaction, isNull);
      expect(viewModel.editingTransaction, isNull);
      expect(viewModel.currentType, isNull);
      expect(viewModel.currentAmount, isNull);
      expect(viewModel.currentCurrency, isNull);
      expect(viewModel.currentTitle, isNull);
      expect(viewModel.currentComment, isNull);
      expect(viewModel.currentDate, isNull);
      expect(viewModel.currentAccountId, isNull);
      expect(viewModel.currentCounterpartyId, isNull);
      expect(viewModel.currentCategoryIds, isEmpty);
      expect(viewModel.currentStatus, isNull);
    });

    test('should return correct utility getters with transaction loaded', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);
      await viewModel.initialize();

      // Assert
      expect(viewModel.originalTransaction, equals(testTransaction));
      expect(viewModel.editingTransaction, equals(testTransaction));
      expect(viewModel.currentType, testTransaction.type);
      expect(viewModel.currentAmount, testTransaction.amount);
      expect(viewModel.currentCurrency, testTransaction.currency);
      expect(viewModel.currentTitle, testTransaction.title);
      expect(viewModel.currentComment, testTransaction.comment);
      expect(viewModel.currentDate, testTransaction.date);
      expect(viewModel.currentAccountId, testTransaction.accountId);
      expect(viewModel.currentCounterpartyId, testTransaction.counterpartyId);
      expect(viewModel.currentStatus, testTransaction.status);
    });
  });

  group('TransactionEditViewModel - Refresh', () {
    test('should refresh transaction details', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionById(testTransactionId))
          .thenAnswer((_) async => testTransaction);

      // Act
      await viewModel.refresh();

      // Assert
      expect(viewModel.state.hasTransaction, true);
      expect(viewModel.state.originalTransaction, equals(testTransaction));
      verify(mockTransactionRepository.getTransactionById(testTransactionId)).called(1);
    });
  });
}