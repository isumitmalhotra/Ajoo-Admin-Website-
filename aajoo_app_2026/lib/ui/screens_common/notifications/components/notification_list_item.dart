import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/notification_response_model.dart';
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
    // Backend convention: un_is_read == 1 means READ. Earlier UI inverted
    // this; corrected here so unread notifications attract attention (bold +
    // accent icon + unread dot) and read ones recede (muted icon, lighter
    // text, no dot).
    final bool isUnread = notification.unIsRead != 1;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 0,
      color: isUnread ? kCream : kSand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? kLine : kLine.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),

        // 🔔 Icon — accent fill when unread, muted outline when read
        leading: CircleAvatar(
          backgroundColor:
              isUnread ? kIndigo.withOpacity(0.10) : kSand,
          child: Icon(
            isUnread ? Icons.notifications_active : Icons.notifications_none,
            color: isUnread ? kIndigo : kMuted,
          ),
        ),

        // 🏷 Title + unread dot
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.unTitle,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16,
                  color: isUnread ? kInk : kInk2,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kClay,
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
                color: isUnread ? kInk2 : kMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(
                notification.createdAt?.toLocal() ?? DateTime.now(),
                locale: 'en_short',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: kMuted,
              ),
            ),
          ],
        ),

        onTap: onTap,
      ),
    );
  }
}
