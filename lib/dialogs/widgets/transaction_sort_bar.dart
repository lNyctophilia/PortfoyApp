import 'package:flutter/material.dart';
import '../../models/portfolio_transaction.dart';
import '../../theme/app_theme.dart';

/// İşlem geçmişi sıralama kriterleri
enum TransactionSortCriterion {
  date('Tarihe Göre'),
  fund('Fona Göre'),
  type('İşleme Göre'),
  profitLoss('K/Z\'ye Göre'),
  amount('Tutara Göre');

  final String label;
  const TransactionSortCriterion(this.label);
}

/// Sıralama karşılaştırıcı yardımcısı
List<PortfolioTransaction> sortPortfolioTransactions(
  List<PortfolioTransaction> transactions,
  TransactionSortCriterion criterion,
  bool isAscending, {
  bool showNetValues = false,
}) {
  final list = List<PortfolioTransaction>.from(transactions);
  list.sort((a, b) {
    int comparison = 0;
    switch (criterion) {
      case TransactionSortCriterion.date:
        comparison = a.date.compareTo(b.date);
        break;
      case TransactionSortCriterion.fund:
        comparison = a.symbol.toLowerCase().compareTo(b.symbol.toLowerCase());
        if (comparison == 0) {
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        break;
      case TransactionSortCriterion.type:
        comparison = a.type.index.compareTo(b.type.index);
        break;
      case TransactionSortCriterion.profitLoss:
        final aProfit = a.type == TransactionType.satis
            ? (showNetValues ? a.netRealizedProfit : a.realizedProfit)
            : 0.0;
        final bProfit = b.type == TransactionType.satis
            ? (showNetValues ? b.netRealizedProfit : b.realizedProfit)
            : 0.0;
        comparison = aProfit.compareTo(bProfit);
        break;
      case TransactionSortCriterion.amount:
        final aAmount = a.price * a.quantity;
        final bAmount = b.price * b.quantity;
        comparison = aAmount.compareTo(bAmount);
        break;
    }

    if (comparison != 0) {
      return isAscending ? comparison : -comparison;
    }

    // İkincil kriter (eşitlik durumunda): her zaman en yeni tarihten en eskiye
    return b.date.compareTo(a.date);
  });
  return list;
}

/// Apple Minimalist İşlem Geçmişi Sıralama ve Yön Seçici Çubuğu
class TransactionSortBar extends StatelessWidget {
  final TransactionSortCriterion selectedCriterion;
  final bool isAscending;
  final ValueChanged<TransactionSortCriterion> onCriterionChanged;
  final VoidCallback onToggleDirection;
  final bool isMobile;

  const TransactionSortBar({
    super.key,
    required this.selectedCriterion,
    required this.isAscending,
    required this.onCriterionChanged,
    required this.onToggleDirection,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownWidget = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TransactionSortCriterion>(
          value: selectedCriterion,
          dropdownColor: AppTheme.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          borderRadius: BorderRadius.circular(8),
          isDense: true,
          items: TransactionSortCriterion.values.map((criterion) {
            return DropdownMenuItem<TransactionSortCriterion>(
              value: criterion,
              child: Text(
                criterion.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onCriterionChanged(val);
            }
          },
        ),
      ),
    );

    final toggleWidget = Tooltip(
      message: isAscending ? 'Artan Sıralama' : 'Azalan Sıralama',
      child: InkWell(
        onTap: onToggleDirection,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: isAscending ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isAscending ? 'Artan' : 'Azalan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: dropdownWidget),
            const SizedBox(width: 8),
            toggleWidget,
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dropdownWidget,
        const SizedBox(width: 8),
        toggleWidget,
      ],
    );
  }
}
