const model = require("../models/index");
const { Sequelize } = require("sequelize");
const methods = require("../utils/methods");
const logger = require("../utils/logger");

const dataConversion = (reqData) => {
  let data;
  if (typeof reqData === "string") {
    return data = JSON.parse(reqData);
  }
  return reqData;
};

exports.registerChatHandlers = (socket, io) => {

  const onlineUsers = {};

  socket.on("join", (userId) => {
    socket.join(`user_${userId}`);
    onlineUsers[userId] = socket.id;
    logger.info(`User ${userId} joined chat`);
  });
  socket.on("sendMessage", async (data) => {
    data = dataConversion(data)
    const { sender_id, receiver_id, message } = data;
    if (!sender_id || !receiver_id || !message) {
      logger.warn('sendMessage: Missing required fields');
      return;
    }
    let payload = {
      sender_id,
      receiver_id,
      message,
    }
    try {
      const savedMessage = await model.tbl_messages.create(payload);
      const messagePayload = {
        ...savedMessage.dataValues,
        created_at: new Date(),
      };

      io.to(`user_${receiver_id}`).emit("receiveMessage", messagePayload);
      socket.emit("messageSent", messagePayload);

    } catch (err) {
      console.error("Message save error:", err);
      socket.emit("messageSent", {});
    }
  });
  socket.on("loadMessages", async (data) => {
    data = dataConversion(data)
    let { sender_id, receiver_id } = data
    const messages = await model.tbl_messages.getConversation(sender_id, receiver_id);
    if (!messages) {
      socket.emit("chatHistory", { success: false, messages: "No messages found", messages });
      return;
    }
    socket.emit("chatHistory", messages);
  });
  socket.on("messageSeen", async ({ sender_id, receiver_id }) => {
    await model.tbl_messages.update(
      { is_read: 1 },
      {
        where: {
          sender_id,
          receiver_id,
          is_read: 0
        }
      }
    );
    // Notify sender (optional)
    io.to(`user_${sender_id}`).emit("seenConfirmation", {
      from: receiver_id
    });
  });
};

function getRoomName(userId1, userId2, propertyId) {
  const [minId, maxId] = [userId1, userId2].sort((a, b) => a - b);
  return `negotiation_${propertyId}_${minId}_${maxId}`;
}

exports.registerNegotiationHandlers = (socket, io) => {
  socket.on("joinNegotiation", async ({ userId, propertyId, isHost }) => {
    try {
      let propWhereClause = {
        property_id: propertyId,
        is_active: 1,
        is_deleted: 0
      };
      let hostTitle = "New negotiation request";
      let notifyMessageHost = "You have received a new negotiation request ";
      const propertyData = await model.tbl_properties.getSingleProperty(propWhereClause, ["property_host_id", "property_name", "property_longitude", "property_latitude"])
      if (!propertyData) {
        console.warn(`Property ${propertyId} not found or inactive for user ${userId}`);
        // Send error back only to this socket
        socket.emit("negotiationError", {
          success: false,
          message: "Property not found or unavailable for negotiation",
        });

        return;
      }

      const room = getRoomName(userId, propertyData.property_host_id, propertyId);
      socket.join(room); // join immediately so future messages reach this user
      socket.emit("negotiationJoined", {
        success: true,
        room,
        room_id: room,
        property: {
          id: propertyId,
          name: propertyData.property_name,
          hostId: propertyData.property_host_id,
        },
      });
      let payloadData = {
        route: "/negotiation",
        type: "negotiation_request",
        propertyId: `${propertyId}`,
        userId: `${userId}`,
        receiverId: `${propertyData.property_host_id}`,
        hostId: `${propertyData.property_host_id}`,
        lat: `${propertyData["property_latitude"]}`,
        long: `${propertyData["property_longitude"]}`,
        room: `${room}`,
        room_id: `${room}`
      };
      if (String(userId) !== String(propertyData.property_host_id) && !isHost) {
        await methods.sendNotification(propertyData.property_host_id, hostTitle, notifyMessageHost, propertyId, payloadData);
      }
    } catch (error) {
      logger.error("Error in joinNegotiation:", error);
      socket.emit("negotiationError", {
        success: false,
        message: "Internal server error while joining negotiation",
      });
    }

  });

  socket.on("sendNegotiationMessage", async (data) => {
    const { property_id, sender_id, receiver_id, message_text, is_offer, offer_price } = data;

    const savedMessage = await model.tbl_nagotiate_messages.create({
      property_id,
      sender_id,
      receiver_id,
      message_text,
      is_offer,
      offer_price: is_offer ? offer_price : null,
    });

    const messagePayload = {
      ...savedMessage.dataValues,
      created_at: new Date(),
    };
    // Use consistent room naming (sorted user ids) so both parties are in same room
    const room = getRoomName(sender_id, receiver_id, property_id);
    messagePayload.room = room;
    io.to(room).emit("receiveNegotiationMessage", messagePayload);
    socket.emit("negotiationMessageSent", messagePayload);
  });

  socket.on("loadNegotiationChat", async ({ sender_id, receiver_id, property_id }) => {
    try {
      if (!sender_id || !receiver_id || !property_id) {
        return socket.emit("error", { message: "Invalid request for chat history" });
      }
      const messages = await model.tbl_nagotiate_messages.findAll({
        where: {
          property_id,
          [Sequelize.Op.or]: [
            { sender_id, receiver_id },
            { sender_id: receiver_id, receiver_id: sender_id },
          ]
        },
        order: [['created_at', 'ASC']],
        raw: true
      });
      socket.emit("negotiationChatHistory", { success: true, messages });
    } catch (error) {
      console.error("❌ loadNegotiationChat error:", error);
      socket.emit("error", { message: "Failed to load chat history" });
    }
  });
  socket.on("acceptOffer", async ({ offer_id, property_id, accepter_id }) => {
    try {
      if (!offer_id || !property_id || !accepter_id) {
        return socket.emit("negotiationError", {
          success: false,
          message: "Invalid request to accept offer",
        });
      }
      // --- Step 1: Fetch offer ---
      const offer = await model.tbl_nagotiate_messages.findOne({
        where: {
          message_id: offer_id,
          property_id,
          is_offer: 1
        },
        raw: true,
      });

      // return
      if (!offer) {
        return socket.emit("negotiationError", { success: false, message: "Offer not found", });
      }
      // --- Step 2: Update offer status ---
      await model.tbl_nagotiate_messages.update(
        { is_accepted: 1 }, // add a column `is_accepted` in DB if not present
        { where: { message_id: offer_id } }
      );
      const updatedOffer = {
        ...offer,
        is_accepted: 1,
        accepted_by: accepter_id,
        accepted_at: new Date(),
      };

      // --- Step 3: Generate room ---
      const room = getRoomName(offer.sender_id, offer.receiver_id, property_id);

      // --- Step 4: Emit to both parties in same room ---
      io.to(room).emit("offerAccepted", {
        success: true,
        offer: updatedOffer,
      });

      const propertyData = await model.tbl_properties.findOne({
        where: { property_id },
        attributes: ["property_name"],
        raw: true,
      });
      if (propertyData) {
        let notifyTitle = "Offer Accepted";
        let notifyMessage = `An offer for property ${propertyData.property_name} has been accepted.`;

        // Notify sender of the offer
        await methods.sendNotification(
          offer.sender_id,
          notifyTitle,
          notifyMessage,
          property_id,
          {
            "offer_id": `${offer_id}`,
            "accepter_id": `${accepter_id}`,
            "propertyId": `${property_id}`
          }
        );

        // Notify receiver of the offer
        await methods.sendNotification(
          offer.receiver_id,
          notifyTitle,
          notifyMessage,
          property_id,
          {
            "offer_id": `${offer_id}`,
            "accepter_id": `${accepter_id}`,
            "propertyId": `${property_id}`
          }
        );
      }
      let offerPayload = {
        property_id: offer.property_id,
        sender_id: offer.sender_id,
        receiver_id: offer.receiver_id,
        offer_price: offer.offer_price,
        offer_message_text: offer.message_text,
        offer_number: offer_id
      }
      await model.tbl_negotiation_offers.create(offerPayload);
      await model.tbl_nagotiate_messages.destroy({
        where: {
          property_id: property_id,
          sender_id: offer.sender_id,
          receiver_id: offer.receiver_id,
        }
      })
      logger.info(`Offer ${offer_id} accepted by user ${accepter_id} in room ${room}`);
    } catch (error) {
      console.error("❌ acceptOffer error:", error);
      socket.emit("negotiationError", {
        success: false,
        message: "Failed to accept offer",
      });
    }
  });
};

exports.registerNegotiationHandlerstwo = (socket, io) => {
  socket.on("joinNegotiationtesting", async ({ userId, propertyId }) => {
    try {
      // --- Step 1: Get property ---
      const propWhereClause = {
        property_id: propertyId,
        is_active: 1,
        is_deleted: 0,
      };

      const propertyData = await model.tbl_properties.getSingleProperty(
        propWhereClause,
        ["property_host_id", "property_name", "property_longitude", "property_latitude"]
      );

      // --- Step 2: Handle property not found ---
      if (!propertyData) {
        console.warn(`Property ${propertyId} not found or inactive for user ${userId}`);

        // Send error back only to this socket
        socket.emit("negotiationError", {
          success: false,
          message: "Property not found or unavailable for negotiation",
        });

        return; // stop execution
      }

      // --- Step 3: Generate room ---
      const room = getRoomName(userId, propertyData.property_host_id, propertyId);
      logger.info(`User ${userId} joining negotiation room: ${room}`);

      socket.join(room);

      // --- Step 4: Notify user that join was successful ---
      socket.emit("negotiationJoined", {
        success: true,
        room,
        property: {
          id: propertyId,
          name: propertyData.property_name,
          hostId: propertyData.property_host_id,
        },
      });

    } catch (err) {
      console.error("Error in joinNegotiation:", err);

      socket.emit("negotiationError", {
        success: false,
        message: "Internal server error while joining negotiation",
      });
    }
  });
};
