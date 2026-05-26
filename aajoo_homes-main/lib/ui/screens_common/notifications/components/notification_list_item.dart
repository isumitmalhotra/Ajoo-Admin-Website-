import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/data/models/notification_response_model.dart';
import 'package:rent_home/ui/unused_screens/chat/chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final int index;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),

        // 🔔 Icon
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: Icon(
            notification.unIsRead == 1
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: notification.unIsRead == 1 ? kPrimaryColor : Colors.grey,
          ),
        ),

        // 🏷 Title + unread dot
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.unTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: notification.unIsRead == 1
                      ? Colors.black
                      : Colors.grey[800],
                ),
              ),
            ),
            if (notification.unIsRead == 1)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
          ],
        ),

        // 📄 Message + time
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.unMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(
                notification.createdAt?.toLocal() ?? DateTime.now(),
                locale: 'en_short',
              ),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),

        onTap: onTap,
      ),
    );
  }
}
