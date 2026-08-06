import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';

class TransactionCard extends StatelessWidget {
  final String transactionName;
  final String transactionDate;
  final String amount;
  final bool isIncome;

  const TransactionCard({super.key, 
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
        side: const BorderSide(color: kLine),
      ),
      elevation: 1,
      shadowColor: const Color(0xFF1F2937).withOpacity(0.08),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Circular icon for transaction type
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isIncome ? Colors.green[100] : Colors.red[100],
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
