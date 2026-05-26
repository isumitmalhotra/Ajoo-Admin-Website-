const watiTemplates = {
  bookingConfirmation: (bookingId, propertyName, checkIn, checkOut, totalPrice) => ({
    template: 'booking_confirmation',
    parameters: [bookingId, propertyName, checkIn, checkOut, totalPrice]
  }),

  hostNewBooking: (bookingId, userName, propertyName, checkIn, checkOut) => ({
    template: 'host_new_booking',
    parameters: [bookingId, userName, propertyName, checkIn, checkOut]
  }),

  bookingCancellation: (bookingId, reason = 'User request') => ({
    template: 'booking_cancellation',
    parameters: [bookingId, reason]
  }),

  checkInReminder: (bookingId, propertyName, checkInDate) => ({
    template: 'checkin_reminder',
    parameters: [bookingId, propertyName, checkInDate]
  }),

  checkOutReminder: (bookingId, propertyName, checkOutDate) => ({
    template: 'checkout_reminder',
    parameters: [bookingId, propertyName, checkOutDate]
  }),

  // Text messages for chatbot responses
  bookingStatus: (bookings) => {
    if (bookings.length === 0) {
      return "You have no active bookings.";
    }
    let message = "Your active bookings:\n";
    bookings.forEach(booking => {
      message += `• ${booking.book_id}: ${booking.property_name} (${booking.bt_book_from} to ${booking.bt_book_to})\n`;
    });
    return message;
  },

  myProperties: (properties) => {
    if (properties.length === 0) {
      return "You have no properties listed.";
    }
    let message = "Your properties:\n";
    properties.forEach(prop => {
      message += `• ${prop.property_name} (${prop.property_address})\n`;
    });
    return message;
  },

  availableProperties: (properties) => {
    if (properties.length === 0) {
      return "No properties available at the moment.";
    }
    let message = "Available properties:\n";
    properties.forEach(prop => {
      message += `• ${prop.property_name} - ${prop.property_address}\n`;
    });
    return message;
  },

  cancelBooking: (bookingId) => `Booking ${bookingId} has been cancelled successfully.`,

  fallback: () => "I'm sorry, I didn't understand that. Please reply with:\n• 'booking status' for your bookings\n• 'my properties' if you're a host\n• 'available properties' to see listings\n• 'cancel booking [ID]' to cancel"
};

module.exports = watiTemplates;
