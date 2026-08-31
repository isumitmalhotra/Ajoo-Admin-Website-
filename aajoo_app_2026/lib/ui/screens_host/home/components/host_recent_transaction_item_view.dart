import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/transaction_model.dart';
import 'package:rent_home/utils/fonts.dart';

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
      elevation: 0,
      color: kCream,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kLine),
      ),
      child: ListTile(
        tileColor: kCream,
        leading: const CircleAvatar(
          backgroundColor: kSuccess,
          child: Icon(
            Ionicons.checkmark_done,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.payInvoice,
          style: inter(fontWeight: FontWeight.w600, color: kInk),
        ),
        subtitle: Text("Amount: ${rupeesFrom(transaction.payAmount)}",
            style: inter(fontSize: 13, color: kMuted)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              transaction.paymentStatusBsTitle,
              style: inter(
                color: transaction.paymentStatusBsTitle == "Paid"
                    ? kSuccess
                    : kDanger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              formatDate,
              style: inter(fontSize: 12, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}
