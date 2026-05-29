import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';

class TransactionCard extends StatelessWidget {
  final String transactionName;
  final String transactionDate;
  final String amount;
  final bool isIncome;

  TransactionCard({
    this.transactionName = "Unnamed Transaction",
    this.transactionDate = "Unknown Date",
    this.amount = "₹2,299",
    this.isIncome = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: kLine),
      ),
      elevation: 1,
      shadowColor: const Color(0xFF1B2447).withOpacity(0.08),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Circular icon for transaction type
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isIncome ? Colors.green[100] : Colors.red[100],
              ),
              padding: EdgeInsets.all(10),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    transactionDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Transaction amount
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
