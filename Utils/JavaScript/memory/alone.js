var socket = new WebSocket("http://172.17.77.9/gameroom/memory/alone");

socket.onopen = function(event) {
    console.log("WebSocket is open now.");
    socket.send(JSON.stringify({ type: "alone_start", game: "memory", game_id: game_id, wstype: "game" }));
    console.log("Sent message: Here's some text that the server is urgently awaiting!");
};

// socket.onmessage = function(event) {
//     console.log("WebSocket message received:", event.data);

//     socket.onmessage = function(event) {
//         console.log("WebSocket message received:", event.data);

//         var imageData = event.data.replace(/"/g, '');
//         if (!knownCards[card_id]) {
//             knownCards[card_id] = imageData;
//         }
//         resolve(event.data);
//     };
// };


socket.onerror = function(error) {
    console.log("WebSocket error:", error);
};