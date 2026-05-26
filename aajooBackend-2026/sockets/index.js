const { registerChatHandlers, registerNegotiationHandlers } = require("../controllers/socketController");
const logger = require("../utils/logger");

let activeConnections = 0;
const MAX_CONNECTIONS = 1000; // Maximum concurrent connections

module.exports = (io) => {
    io.on("connection", (socket) => {
        if (activeConnections >= MAX_CONNECTIONS) {
            logger.warn(`Connection rejected: Maximum connections (${MAX_CONNECTIONS}) reached`);
            socket.emit("connectionRejected", { reason: "Server at maximum capacity" });
            socket.disconnect(true);
            return;
        }

        activeConnections++;
        logger.info(`New connection established with ID: ${socket.id}. Active connections: ${activeConnections}`);

        registerChatHandlers(socket, io);
        registerNegotiationHandlers(socket, io);

        socket.on("disconnect", () => {
            activeConnections--;
            logger.info(`Connection closed with ID: ${socket.id}. Active connections: ${activeConnections}`);
        });
    });
};
