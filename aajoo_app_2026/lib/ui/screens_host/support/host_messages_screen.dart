import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/motion/aajoo_motion.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/utils/fonts.dart';

/// Messages (A-75/A-76).
///
/// This tab was "Support": a phone number, an email address and an FAQ. A host
/// talking to a guest had nowhere to do it — the negotiation thread existed on
/// the server and the only way in was a push notification.
///
/// So: Aajoo support stays, pinned at the top where it was the whole tab
/// before, and the guest conversations sit under it. The conversations ARE the
/// negotiation threads — `/host/negotiations/list` already returns one row per
/// property/guest pair, which is exactly a conversation list. No second
/// messaging system, and nothing new on the server.
class HostMessagesScreen extends StatefulWidget {
  const HostMessagesScreen({super.key});

  @override
  State<HostMessagesScreen> createState() => _HostMessagesScreenState();
}

class _HostMessagesScreenState extends State<HostMessagesScreen> {
  final hostController = Get.put(HostController());

  @override
  void initState() {
    super.initState();
    hostController.getNegotiations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kCream,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Messages',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: RefreshIndicator(
        color: kIndigo,
        onRefresh: hostController.getNegotiations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _supportCard(),
            const SizedBox(height: 22),
            Text('Guest conversations',
                style: fraunces(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 10),
            Obx(() {
              if (!hostController.negotiationsFetched.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child:
                      Center(child: CircularProgressIndicator(color: kIndigo)),
                );
              }
              final threads = hostController.negotiations.toList();
              if (threads.isEmpty) return _emptyThreads();
              return Column(
                children: [
                  for (int i = 0; i < threads.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == threads.length - 1 ? 0 : 10),
                      child: Reveal(
                        delay: Reveal.staggerDelay(i),
                        child: _threadTile(threads[i]),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Aajoo support, on top — the spec is explicit about the order, and it is
  /// the right order: a host in trouble should not have to scroll past their
  /// guests to find us.
  Widget _supportCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.to(() => const HostSupportScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kIndigo600, kIndigo],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aajoo Support',
                      style: fraunces(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Call, email, or read the host FAQ',
                      style: inter(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _emptyThreads() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined,
              size: 36, color: kMuted.withOpacity(0.45)),
          const SizedBox(height: 10),
          Text('No guest conversations yet',
              style: inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 4),
          Text('When a guest negotiates on one of your stays, the thread appears here.',
              textAlign: TextAlign.center,
              style: inter(fontSize: 12.5, color: kMuted)),
        ],
      ),
    );
  }

  Widget _threadTile(HostNegotiation n) {
    final name = n.renterName.trim().isEmpty ? 'Guest' : n.renterName.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openThread(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.isPending ? kClay : kLine),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kIndigo,
              child: Text(name.characters.first.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                      ),
                      if (n.isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kClay.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Awaiting you',
                              style: inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: kClay)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(fontSize: 12.5, color: kMuted)),
                  const SizedBox(height: 4),
                  Text(
                    n.message.trim().isEmpty
                        ? 'Offered ₹${n.offerPrice.round()}'
                        : n.message.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(fontSize: 12.5, color: kInk2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: kMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openThread(HostNegotiation n) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null) {
      Fluttertoast.showToast(msg: 'Please login again to open this chat.');
      return;
    }
    final hostId = Get.find<AuthController>().userData.value?.userId;
    if (hostId == null) {
      Fluttertoast.showToast(msg: 'Please login again to open this chat.');
      return;
    }
    final property = Property(
      propertyId: n.propertyId,
      propertyName: n.propertyName,
      propertyAddress: '',
      propertyDesc: '',
      propertyPrice: n.originalPrice.toStringAsFixed(0),
      propertyCity: '',
      propertyLongitude: '0',
      propertyLatitude: '0',
      propertyHostId: hostId,
      propertyZip: null,
      images: const [],
      categoryTitles: const [],
    );
    if (!mounted) return;
    Get.to(() => PriceNegotiationPage(
          userId: hostId.toString(),
          senderId: hostId.toString(),
          receiverId: n.renterId.toString(),
          hostId: hostId.toString(),
          propertyId: n.propertyId.toString(),
          serverUrl: Apiconstants.serverUrl,
          token: token,
          property: property,
          lat: '0',
          long: '0',
        ));
  }
}
