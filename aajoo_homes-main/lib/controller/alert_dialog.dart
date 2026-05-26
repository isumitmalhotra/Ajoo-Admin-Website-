import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showAlert(String title, String message, bool isError) {
  Get.dialog(
    AlertDialog(
      title: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Colors.red[900] : Colors.green[900],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("OK"),
        ),
      ],
    ),
    barrierDismissible: false, // user must tap OK
  );
}
