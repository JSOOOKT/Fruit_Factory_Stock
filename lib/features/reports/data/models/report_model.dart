class ReportSummary {
  final int totalProducts;
  final int totalStockIn;
  final int totalStockOut;
  final int currentStock;
  final List<ProductReport> productReports;
  final List<DailyReport> dailyReports;

  ReportSummary({
    required this.totalProducts,
    required this.totalStockIn,
    required this.totalStockOut,
    required this.currentStock,
    required this.productReports,
    required this.dailyReports,
  });
}

class ProductReport {
  final String id;
  final String name;
  final String code;
  final int stockIn;
  final int stockOut;
  final int balance;
  final String unit;

  ProductReport({
    required this.id,
    required this.name,
    required this.code,
    required this.stockIn,
    required this.stockOut,
    required this.balance,
    required this.unit,
  });
}

class DailyReport {
  final DateTime date;
  final int stockIn;
  final int stockOut;
  final int netChange;

  DailyReport({
    required this.date,
    required this.stockIn,
    required this.stockOut,
    required this.netChange,
  });
}
