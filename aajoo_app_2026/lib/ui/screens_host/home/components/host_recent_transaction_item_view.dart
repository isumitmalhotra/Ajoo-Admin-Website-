import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/transaction_model.dart';

class HostRecentTransactionItemView extends StatelessWidget {
  const HostRecentTransactionItemView({
    super.key,
    required this.transaction,
    required this.formatDate,
  });

  final Transaction transaction;
  final String formatDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        tileColor: kcontentColor,
        leading: const CircleAvatar(
          backgroundColor: kSuccess,
          child: Icon(
            Ionicons.checkmark_done,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.payInvoice,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text("Amount: ₹${transaction.payAmount}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              transaction.paymentStatusBsTitle,
              style: TextStyle(
                color: transaction.paymentStatusBsTitle == "Paid"
                    ? kSuccess
                    : kDanger,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatDate,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
