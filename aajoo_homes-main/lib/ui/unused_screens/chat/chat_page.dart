import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';

const kPrimaryColor = kprimaryColor;

// Data models
class Message {
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isHost;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.isHost,
  });
}

class Customer {
  final String id;
  final String name;
  final String bookingId;
  final DateTime checkIn;
  final DateTime checkOut;

  Customer({
    required this.id,
    required this.name,
    required this.bookingId,
    required this.checkIn,
    required this.checkOut,
  });
}

// Provider for managing state
class ChatProvider with ChangeNotifier {
  List<Customer> _customers = [
    Customer(
      id: '1',
      name: 'Alice Smith',
      bookingId: 'B001',
      checkIn: DateTime(2025, 4, 15),
      checkOut: DateTime(2025, 4, 20),
    ),
    Customer(
      id: '2',
      name: 'Bob Johnson',
      bookingId: 'B002',
      checkIn: DateTime(2025, 4, 16),
      checkOut: DateTime(2025, 4, 18),
    ),
    Customer(
      id: '3',
      name: 'Clara Lee',
      bookingId: 'B003',
      checkIn: DateTime(2025, 4, 17),
      checkOut: DateTime(2025, 4, 19),
    ),
  ];

  List<Message> _messages = [
    Message(
      sender: 'Alice Smith',
      content: 'Hi, can I get a vegetarian breakfast option during my stay?',
      timestamp: DateTime(2025, 4, 17, 9, 30),
      isHost: false,
    ),
    Message(
      sender: 'Host',
      content:
          'Hello Alice! Yes, we offer vegetarian breakfast options. Would you like us to arrange that for your stay?',
      timestamp: DateTime(2025, 4, 17, 9, 35),
      isHost: true,
    ),
    Message(
      sender: 'Alice Smith',
      content:
          'That would be great, thanks! Also, is there a shuttle from the train station?',
      timestamp: DateTime(2025, 4, 17, 9, 40),
      isHost: false,
    ),
    Message(
      sender: 'Host',
      content:
          'We don’t have a shuttle, but the train station is just a 10-minute walk. Alternatively, you can take a taxi for about Rs.5.',
      timestamp: DateTime(2025, 4, 17, 9, 45),
      isHost: true,
    ),
  ];

  List<Customer> get customers => _customers;
  List<Message> get messages => _messages;

  String _selectedCustomerId = '1'; // Default to first customer
  String get selectedCustomerId => _selectedCustomerId;

  void selectCustomer(String customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void sendMessage(String content, bool isHost) {
    _messages.add(Message(
      sender: isHost
          ? 'Host'
          : _customers.firstWhere((c) => c.id == _selectedCustomerId).name,
      content: content,
      timestamp: DateTime.now(),
      isHost: isHost,
    ));
    notifyListeners();
  }
}

class ChatPage extends StatelessWidget {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Sidebar: List of customers with ongoing bookings
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ongoing Bookings',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      return ListView.builder(
                        itemCount: provider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = provider.customers[index];
                          final isSelected =
                              provider.selectedCustomerId == customer.id;
                          return ListTile(
                            title: Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? kPrimaryColor : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Booking ID: ${customer.bookingId}\nCheck-in: ${DateFormat('MMM dd').format(customer.checkIn)}',
                              style: const TextStyle(fontSize: 7),
                            ),
                            selected: isSelected,
                            selectedTileColor: kPrimaryColor.withOpacity(0.1),
                            onTap: () {
                              provider.selectCustomer(customer.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chat area
          Expanded(
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      final selectedCustomer = provider.customers.firstWhere(
                        (c) => c.id == provider.selectedCustomerId,
                        orElse: () => provider.customers[0],
                      );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Chat with ${selectedCustomer.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: provider.messages.length,
                              itemBuilder: (context, index) {
                                final message = provider.messages[index];
                                final isHost = message.isHost;
                                return Align(
                                  alignment: isHost
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isHost
                                          ? kPrimaryColor
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isHost
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isHost
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, hh:mm a')
                                              .format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isHost
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Message input
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: kPrimaryColor),
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            Provider.of<ChatProvider>(context, listen: false)
                                .sendMessage(
                                    _messageController.text.trim(), true);
                            _messageController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
