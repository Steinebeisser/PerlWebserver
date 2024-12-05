var socket = new WebSocket("http://10.31.0.18/gameroom/memory/alone");

socket.onopen = function(event) {
    console.log("WebSocket is open now.");
    socket.send("Here's some text that the server is urgently awaiting!");
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

socket.onclose = function(event) {
    console.log("WebSocket is closed now.");
};

socket.onerror = function(error) {
    console.log("WebSocket error:", error);
};