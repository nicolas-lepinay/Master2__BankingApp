import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/edit_transaction_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final viewModel = ref.read(transactionDetailViewModelProvider(transactionId).notifier);
    final state = ref.watch(transactionDetailViewModelProvider(transactionId));

    // Initialiser le ViewModel si nécessaire
    if (!state.hasTransaction && !viewModel.isLoading && !viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.initialize();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetails),
        actions: [
          // Bouton d'édition
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: viewModel.canEdit 
                ? () => _showEditTransaction(context, ref)
                : null,
          ),
          // Bouton de suivi
          IconButton(
            icon: Icon(state.isFollowed ? Icons.star : Icons.star_border),
            onPressed: viewModel.canToggleFollow
                ? () => _toggleFollowTransaction(context, viewModel)
                : null,
          ),
          // Menu avec plus d'options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                enabled: viewModel.canToggleStatus,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Text(state.isCompleted ? 'Marquer en attente' : 'Marquer comme complété'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: viewModel.canDelete,
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
      body: _buildBody(context, ref, viewModel, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    dynamic viewModel,
    dynamic state,
    AppLocalizations l10n,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('${l10n.error}: ${viewModel.errorMessage}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (!state.hasTransaction) {
      return const Center(child: Text('Transaction introuvable'));
    }

    return _buildTransactionDetail(context, ref, state.transaction!, state.account);
  }

  Widget _buildTransactionDetail(
    BuildContext context,
    WidgetRef ref,
    domain.Transaction transaction,
    domain.Account? account,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isExpense = transaction.isExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale avec montant
          _buildAmountCard(context, transaction, isExpense),

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
    domain.Transaction transaction,
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
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
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

            const SizedBox(height: AppConstants.verySmallPadding),

            // Titre
            Text(
              transaction.title ?? 'Transaction',
              style: AppTextStyles.h5,
              textAlign: TextAlign.center,
            ),

            if (transaction.comment?.isNotEmpty == true) ...[
              const SizedBox(height: AppConstants.verySmallPadding),
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
    domain.Transaction transaction,
    domain.Account? account,
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
              AppFormatters.getTransactionTypeLabel(transaction.type, context),
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
              valueColor:
                  transaction.status == domain.TransactionStatus.completed
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
    domain.Transaction transaction,
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

            if (transaction.amountBeforeConversion != null &&
                transaction.currencyBeforeConversion != null) ...[
              _buildDetailRow(
                'Montant converti',
                AppFormatters.formatCurrency(
                  transaction.amountBeforeConversion!,
                  transaction.currencyBeforeConversion!,
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
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.verySmallPadding,
      ),
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
    final viewModel = ref.read(transactionDetailViewModelProvider(transactionId).notifier);
    
    switch (action) {
      case 'toggle_status':
        await _toggleTransactionStatus(context, viewModel);
        break;
      case 'delete':
        await _deleteTransaction(context, viewModel);
        break;
    }
  }

  Future<void> _toggleTransactionStatus(
    BuildContext context,
    dynamic viewModel,
  ) async {
    final success = await viewModel.toggleTransactionStatus();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Statut de la transaction modifié'
              : 'Erreur lors de la modification du statut'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFollowTransaction(
    BuildContext context,
    dynamic viewModel,
  ) async {
    final success = await viewModel.toggleFollowTransaction();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Transaction ${viewModel.state.isFollowed ? "ajoutée aux" : "retirée des"} suivis'
              : 'Erreur lors de la modification du suivi'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTransaction(BuildContext context, dynamic viewModel) async {
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
      final success = await viewModel.deleteTransaction();

      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop(); // Retour à l'écran précédent
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
