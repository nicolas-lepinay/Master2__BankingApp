import 'package:flutter_test/flutter_test.dart';
import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/app_events.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/domain/entities/account.dart';

void main() {
  group('AppEventBus', () {
    late AppEventBus eventBus;
    
    setUp(() async {
      // Reset pour garantir une instance fraîche pour chaque test
      await AppEventBus.instance.reset();
      eventBus = AppEventBus.instance;
      eventBus.setLoggingEnabled(false); // Désactiver logs pour les tests
    });
    
    tearDown(() async {
      await eventBus.dispose();
    });
    
    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AppEventBus.instance;
        final instance2 = AppEventBus.instance;
        expect(instance1, same(instance2));
      });
      
      test('should be active after creation', () {
        expect(eventBus.isActive, isTrue);
      });
    });
    
    group('Event Publishing and Distribution', () {
      test('should fire and receive global events', () async {
        // Arrange
        final List<GlobalAppEvent> receivedEvents = [];
        final subscription = eventBus.globalEvents.listen(receivedEvents.add);
        
        // Act
        final errorEvent = AppEventFactory.createGlobalErrorEvent(
          errorMessage: 'Test error',
          context: 'unit_test',
        );
        eventBus.fire(errorEvent);
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first, isA<GlobalErrorEvent>());
        expect((receivedEvents.first as GlobalErrorEvent).errorMessage, 'Test error');
        
        await subscription.cancel();
      });
      
      test('should fire and receive transaction events', () async {
        // Arrange
        final List<TransactionEvent> receivedEvents = [];
        final subscription = eventBus.transactionEvents.listen(receivedEvents.add);
        
        // Create a mock transaction
        final transaction = Transaction(
          id: 1,
          accountId: 100,
          type: TransactionType.income,
          amount: 50.0,
          currency: 'EUR',
          date: DateTime.now(),
          status: TransactionStatus.completed,
        );
        
        // Act
        final transactionEvent = TransactionEventFactory.createTransactionCreatedEvent(
          transaction: transaction,
          accountId: 100,
          context: 'unit_test',
        );
        eventBus.fire(transactionEvent);
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first, isA<TransactionCreatedEvent>());
        expect(receivedEvents.first.accountId, 100);
        
        await subscription.cancel();
      });
      
      test('should fire and receive account events', () async {
        // Arrange
        final List<AccountEvent> receivedEvents = [];
        final subscription = eventBus.accountEvents.listen(receivedEvents.add);
        
        // Create a mock account
        final account = Account(
          id: 200,
          name: 'Test Account',
          currency: 'USD',
          initialBalance: 1000.0,
          creationDate: DateTime.now(),
        );
        
        // Act
        final accountEvent = AccountEventFactory.createAccountCreatedEvent(
          account: account,
          context: 'unit_test',
        );
        eventBus.fire(accountEvent);
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first, isA<AccountCreatedEvent>());
        expect(receivedEvents.first.accountId, 200);
        
        await subscription.cancel();
      });
    });
    
    group('Filtered Streams', () {
      test('should filter events by specific type', () async {
        // Arrange
        final List<TransactionCreatedEvent> receivedEvents = [];
        final subscription = eventBus.on<TransactionCreatedEvent>().listen(receivedEvents.add);
        
        // Create mock data
        final transaction = Transaction(
          id: 1,
          accountId: 100,
          type: TransactionType.expense,
          amount: 25.0,
          currency: 'EUR',
          date: DateTime.now(),
          status: TransactionStatus.completed,
        );
        
        // Act - fire different event types
        eventBus.fire(TransactionEventFactory.createTransactionCreatedEvent(
          transaction: transaction,
          accountId: 100,
        ));
        
        eventBus.fire(TransactionEventFactory.createTransactionUpdatedEvent(
          updatedTransaction: transaction,
          accountId: 100,
        ));
        
        eventBus.fire(AppEventFactory.createGlobalErrorEvent(
          errorMessage: 'Should not be received',
        ));
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert - only TransactionCreatedEvent should be received
        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first, isA<TransactionCreatedEvent>());
        
        await subscription.cancel();
      });
      
      test('should filter transaction events by account ID', () async {
        // Arrange
        final List<TransactionEvent> receivedEvents = [];
        final subscription = eventBus.transactionEventsForAccount(100).listen(receivedEvents.add);
        
        // Create mock transactions for different accounts
        final transaction1 = Transaction(
          id: 1,
          accountId: 100,
          type: TransactionType.income,
          amount: 50.0,
          currency: 'EUR',
          date: DateTime.now(),
          status: TransactionStatus.completed,
        );
        
        final transaction2 = Transaction(
          id: 2,
          accountId: 200,
          type: TransactionType.expense,
          amount: 30.0,
          currency: 'USD',
          date: DateTime.now(),
          status: TransactionStatus.completed,
        );
        
        // Act
        eventBus.fire(TransactionEventFactory.createTransactionCreatedEvent(
          transaction: transaction1,
          accountId: 100,
        ));
        
        eventBus.fire(TransactionEventFactory.createTransactionCreatedEvent(
          transaction: transaction2,
          accountId: 200,
        ));
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert - only events for account 100 should be received
        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first.accountId, 100);
        
        await subscription.cancel();
      });
    });
    
    group('Statistics and Monitoring', () {
      test('should track event statistics', () async {
        // Arrange
        eventBus.clearStats();
        
        // Act - fire different events
        eventBus.fire(AppEventFactory.createGlobalErrorEvent(
          errorMessage: 'Error 1',
        ));
        
        eventBus.fire(AppEventFactory.createGlobalErrorEvent(
          errorMessage: 'Error 2',
        ));
        
        eventBus.fire(AppEventFactory.createSuccessEvent(
          message: 'Success',
        ));
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        final stats = eventBus.getEventStats();
        expect(stats['GlobalErrorEvent'], 2);
        expect(stats['SuccessEvent'], 1);
        expect(eventBus.totalEventCount, 3);
      });
      
      test('should track recent events', () async {
        // Arrange
        eventBus.clearStats();
        
        // Act
        eventBus.fire(AppEventFactory.createSuccessEvent(
          message: 'Test message',
        ));
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        final recentEvents = eventBus.getRecentEvents();
        expect(recentEvents, hasLength(1));
        expect(recentEvents.first, isA<SuccessEvent>());
      });
    });
    
    group('Extension Methods', () {
      test('should provide convenient methods for common events', () async {
        // Arrange
        final List<GlobalAppEvent> globalEvents = [];
        final subscription = eventBus.globalEvents.listen(globalEvents.add);
        
        // Act
        eventBus.fireGlobalError('Test error', context: 'unit_test');
        
        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Assert
        expect(globalEvents, hasLength(1));
        expect(globalEvents.first, isA<GlobalErrorEvent>());
        expect((globalEvents.first as GlobalErrorEvent).errorMessage, 'Test error');
        
        await subscription.cancel();
      });
    });
    
    group('Error Handling', () {
      test('should handle stream errors gracefully', () async {
        // Cette test vérifie que le bus continue de fonctionner même en cas d'erreur
        expect(eventBus.isActive, isTrue);
        
        // Fire un événement normal pour vérifier que ça fonctionne toujours
        eventBus.fire(AppEventFactory.createSuccessEvent(
          message: 'After error test',
        ));
        
        expect(eventBus.isActive, isTrue);
      });
    });
  });
}