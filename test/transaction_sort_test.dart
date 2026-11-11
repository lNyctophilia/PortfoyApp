import 'package:flutter_test/flutter_test.dart';
import 'package:portfoy_app/models/asset_category.dart';
import 'package:portfoy_app/models/portfolio_transaction.dart';
import 'package:portfoy_app/dialogs/widgets/transaction_sort_bar.dart';

void main() {
  group('TransactionSortBar & sortPortfolioTransactions Tests', () {
    final tx1 = PortfolioTransaction(
      id: 'tx1',
      portfolioId: 'p1',
      type: TransactionType.alis,
      symbol: 'TLY',
      name: 'TEB Kısa Vadeli Kira Sertifikası Fonu',
      category: AssetCategory.fon,
      date: DateTime(2025, 1, 10),
      quantity: 100,
      price: 10.0, // total: 1,000 TL, profit: 0.0
    );

    final tx2 = PortfolioTransaction(
      id: 'tx2',
      portfolioId: 'p1',
      type: TransactionType.satis,
      symbol: 'AFT',
      name: 'Ak Portföy Yeni Teknolojiler Yabancı Hisse Fonu',
      category: AssetCategory.fon,
      date: DateTime(2025, 2, 15),
      quantity: 50,
      price: 25.0,
      costPrice: 20.0, // total: 1,250 TL, profit: +250.0
    );

    final tx3 = PortfolioTransaction(
      id: 'tx3',
      portfolioId: 'p1',
      type: TransactionType.satis,
      symbol: 'ZRE',
      name: 'Ziraat Portföy BIST 30 Fonu',
      category: AssetCategory.fon,
      date: DateTime(2025, 3, 20),
      quantity: 200,
      price: 5.0,
      costPrice: 8.0, // total: 1,000 TL, profit: -600.0
    );

    final txList = [tx1, tx2, tx3];

    test('Date sorting: Descending (default: newest first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.date,
        false,
      );
      expect(sorted.map((t) => t.id).toList(), ['tx3', 'tx2', 'tx1']);
    });

    test('Date sorting: Ascending (oldest first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.date,
        true,
      );
      expect(sorted.map((t) => t.id).toList(), ['tx1', 'tx2', 'tx3']);
    });

    test('Fund sorting: Ascending (A-Z)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.fund,
        true,
      );
      expect(sorted.map((t) => t.symbol).toList(), ['AFT', 'TLY', 'ZRE']);
    });

    test('Fund sorting: Descending (Z-A)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.fund,
        false,
      );
      expect(sorted.map((t) => t.symbol).toList(), ['ZRE', 'TLY', 'AFT']);
    });

    test('Type sorting: Ascending (Alış first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.type,
        true,
      );
      expect(sorted.first.type, TransactionType.alis);
      expect(sorted.map((t) => t.type).toList(), [
        TransactionType.alis,
        TransactionType.satis,
        TransactionType.satis,
      ]);
    });

    test('Type sorting: Descending (Satış first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.type,
        false,
      );
      expect(sorted.last.type, TransactionType.alis);
    });

    test('Profit/Loss sorting: Descending (Highest profit first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.profitLoss,
        false,
      );
      // tx2: +250, tx1: 0 (alis), tx3: -600
      expect(sorted.map((t) => t.id).toList(), ['tx2', 'tx1', 'tx3']);
    });

    test('Profit/Loss sorting: Ascending (Lowest profit/highest loss first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.profitLoss,
        true,
      );
      // tx3: -600, tx1: 0 (alis), tx2: +250
      expect(sorted.map((t) => t.id).toList(), ['tx3', 'tx1', 'tx2']);
    });

    test('Amount sorting: Descending (Highest amount first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.amount,
        false,
      );
      // tx2: 1250 TL, tx1 & tx3: 1000 TL each (tx3 is newer so tiebreaker picks tx3)
      expect(sorted.first.id, 'tx2');
      expect(sorted.map((t) => t.id).toList(), ['tx2', 'tx3', 'tx1']);
    });

    test('Amount sorting: Ascending (Lowest amount first)', () {
      final sorted = sortPortfolioTransactions(
        txList,
        TransactionSortCriterion.amount,
        true,
      );
      // tx1 & tx3: 1000 TL, tx2: 1250 TL
      expect(sorted.last.id, 'tx2');
    });
  });
}

