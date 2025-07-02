import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/actions_provider.dart';
import 'package:bankapp/presentation/widgets/edit_transaction_bottom_sheet.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/data/database/database.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionAsync = ref.watch(transactionProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetails),
        actions: [
          // Bouton d'édition
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditTransaction(context, ref),
          ),
          // Menu avec plus d'options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Text('Basculer le statut'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) =>
            _buildTransactionDetail(context, ref, transaction),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDebit =
        transaction.transactionType == AppConstants.transactionTypeDebit;

    // Récupérer les informations du compte
    final accountAsync = ref.watch(accountsProvider);
    Account? account;

    accountAsync.whenData((accounts) {
      try {
        account = accounts.firstWhere((a) => a.id == transaction.accountId);
      } catch (e) {
        // Compte non trouvé
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale avec montant
          _buildAmountCard(context, transaction, isDebit),

          const SizedBox(height: AppConstants.largePadding),

          // Informations détaillées
          _buildDetailCard(context, l10n, transaction, account),

          const SizedBox(height: AppConstants.largePadding),

          // Informations techniques
          _buildTechnicalCard(context, l10n, transaction),
        ],
      ),
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    Transaction transaction,
    bool isDebit,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            // Icône de transaction
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDebit
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 30,
                color: isDebit ? AppColors.error : AppColors.success,
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Montant
            Text(
              AppFormatters.formatAmount(
                isDebit ? -transaction.amount : transaction.amount,
                transaction.currency,
                context: context,
              ),
              style: AppTextStyles.h2.copyWith(
                color: isDebit ? AppColors.error : AppColors.success,
              ),
            ),

            const SizedBox(height: AppConstants.smallPadding),

            // Titre
            Text(
              transaction.title ?? 'Transaction',
              style: AppTextStyles.h5,
              textAlign: TextAlign.center,
            ),

            if (transaction.comment?.isNotEmpty == true) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                transaction.comment!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    AppLocalizations l10n,
    Transaction transaction,
    Account? account,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Détails', style: AppTextStyles.h6),

            const SizedBox(height: AppConstants.defaultPadding),

            _buildDetailRow(
              'Compte',
              account?.name ?? 'Compte inconnu',
              Icons.account_balance,
            ),

            _buildDetailRow(
              'Type',
              AppFormatters.getTransactionTypeLabel(
                transaction.transactionType,
                context,
              ),
              Icons.swap_vert,
            ),

            _buildDetailRow(
              l10n.date,
              AppFormatters.formatDateTime(transaction.date, context),
              Icons.calendar_today,
            ),

            _buildDetailRow(
              l10n.currency,
              transaction.currency,
              Icons.monetization_on,
            ),

            _buildDetailRow(
              l10n.status,
              AppFormatters.getTransactionStatusLabel(
                transaction.status,
                context,
              ),
              Icons.info_outline,
              valueColor: transaction.status == 1
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalCard(
    BuildContext context,
    AppLocalizations l10n,
    Transaction transaction,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations techniques', style: AppTextStyles.h6),

            const SizedBox(height: AppConstants.defaultPadding),

            _buildDetailRow('ID Transaction', '#${transaction.id}', Icons.tag),

            if (transaction.amountConverted != null) ...[
              _buildDetailRow(
                'Montant converti',
                AppFormatters.formatCurrency(
                  transaction.amountConverted!,
                  transaction.currency,
                  context,
                ),
                Icons.currency_exchange,
              ),
            ],

            if (transaction.counterpartyId != null) ...[
              _buildDetailRow(
                'ID Tiers',
                '#${transaction.counterpartyId}',
                Icons.business,
              ),
            ],

            if (transaction.category1Id != null) ...[
              _buildDetailRow(
                'ID Catégorie',
                '#${transaction.category1Id}',
                Icons.category,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTransaction(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditTransactionBottomSheet(transactionId: transactionId),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'toggle_status':
        await _toggleTransactionStatus(context, ref);
        break;
      case 'delete':
        await _deleteTransaction(context, ref);
        break;
    }
  }

  Future<void> _toggleTransactionStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final transactionActions = ref.read(transactionActionsProvider);
      final transaction = await ref.read(
        transactionProvider(transactionId).future,
      );

      await transactionActions.toggleTransactionStatus(
        transactionId,
        transaction.accountId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut de la transaction modifié'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    // Confirmer la suppression
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la transaction'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final transactionActions = ref.read(transactionActionsProvider);
        final transaction = await ref.read(
          transactionProvider(transactionId).future,
        );

        await transactionActions.deleteTransaction(
          transactionId,
          transaction.accountId,
        );

        if (context.mounted) {
          Navigator.of(context).pop(); // Retour à l'écran précédent
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
