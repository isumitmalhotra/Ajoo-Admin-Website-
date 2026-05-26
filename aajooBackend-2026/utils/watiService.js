const axios = require('axios');

class WatiService {
  constructor() {
    this.baseUrl = process.env.WATI_API_URL || 'https://live-mt-server.wati.io/1034836';
    this.apiToken = process.env.WATI_API_TOKEN;
    this.headers = {
      'Authorization': `Bearer ${this.apiToken}`,
      'Content-Type': 'application/json'
    };
  }

  async sendMessage(phoneNumber, message) {
    try {
      const payload = {
        phone: phoneNumber,
        message: message
      };

      const response = await axios.post(
        `${this.baseUrl}/api/v1/sendMessage`,
        payload,
        { headers: this.headers }
      );

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('WATI send message error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  async sendTemplateMessage(phoneNumber, templateName, parameters = []) {
    try {
      const payload = {
        phone: phoneNumber,
        template_name: templateName,
        broadcast_name: 'booking_notification',
        parameters: parameters
      };

      const response = await axios.post(
        `${this.baseUrl}/api/v1/sendTemplateMessage`,
        payload,
        { headers: this.headers }
      );

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('WATI send template message error:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  validateWebhookSignature(payload, signature) {
    // Implement signature validation if WATI provides webhook signatures
    // For now, return true
    return true;
  }
}

module.exports = new WatiService();
