var flippedCards = [];
var cardStates = {};
var flippedCardsAmount = 0;
var solvedCards = [];
var knownCards = {};
var moves = 0;
var player1 = "placeholder";
var player2 = "placeholder";
var myUsername = "placeholder";
var currentPlayer = player1;

function flipCard(card_id) {
    console.log("CURRENT PLAYER: " + decodeURIComponent(currentPlayer));
    console.log("MY USERNAME: " + decodeURIComponent(myUsername));
    if (currentPlayer !== myUsername) {
        console.log("NOT YOUR TURN");
        return;
    }

    if (cardStates[card_id] !== "flipped" && solvedCards.includes(card_id) === false && flippedCards.includes(card_id) === false) {
        sendMoves(card_id);
    } else {
        console.log("already flipped card " + card_id);
        return;
    }
    
}

function checkForSolvedCards() {
    var firstCard = flippedCards[0];
    var secondCard = flippedCards[1];
    if (knownCards[firstCard] === knownCards[secondCard]) {
        solvedCards.push(firstCard, secondCard);
        console.log("cards " + firstCard + " and " + secondCard + " are solved");
        console.log("solved cards: " + solvedCards.length);
        if (solvedCards.length === 16) {
            console.log("all cards are solved");
            var url = "/gameroom/memory/win/" + moves;
            window.location.href = url;
        }
        return true;
    }
}

function resetFlippedCards(card_id) {
    flippedCards.splice(0, flippedCards.length-1).forEach(function(card_id) {
        if (solvedCards.includes(card_id)) {
            return;
        }
        var card = document.getElementById("memory_field" + card_id);
        cardStates[card_id] = "back";
        card.getElementsByTagName("img")[0].src = "src/deckblatt.png";
    });

    flippedCardsAmount = 1;
    flippedCards = [card_id];
    return;
}

function moveUtils(card_id) {
    cardStates[card_id] = "flipped";
    flippedCardsAmount++;
    flippedCards.push(card_id);
    console.log("flipped card " + card_id);
    
    if (flippedCardsAmount === 2) {
        moves++;
        console.log("moves: " + moves);
        if (checkForSolvedCards()) {

        } 
        console.log("checked for solved cards");

        currentPlayer = currentPlayer === player1 ? player2 : player1;
        console.log("Player turn: " + currentPlayer);
    }


    if (flippedCardsAmount > 2) {
        console.log("flipped cards amount = " + flippedCardsAmount + ", resetting flipped cards");
        resetFlippedCards(card_id);
        console.log("reset flipped cards to " + flippedCardsAmount);
    }
}


// function sendAndReceiveImg(card_id) {
//     var url = "/gameroom/memory/src/card/" + card_id;

//     return fetch(url)
//     .then(response => response.text())
//     .then(data => {
//         var card = document.getElementById("memory_field" + card_id).getElementsByTagName("img")[0];
//         card.src = data;
//         knownCards[card_id] = data;
        
//     })
//     .catch(error => console.error('Error:', error));
// }

function setImage(card_id) {
    var card = document.getElementById("memory_field" + card_id);
    if (knownCards[card_id]) {
        card.getElementsByTagName("img")[0].src = knownCards[card_id];
    }
}

function sendMoves(card_id) {
    return new Promise((resolve, reject) => {
        if (socket.readyState === WebSocket.OPEN) {
            var game_id = document.cookie.split('; ').find(row => row.startsWith('memory=')).split('=')[1];
            socket.send(JSON.stringify({ type: "flip_card", card_id: card_id, game: "memory", game_id: game_id }));
            console.log("Sent moves: " + card_id);
            
            resolve();
            
        } else {
            console.log("WebSocket is not open. Ready state: " + socket.readyState);
            reject("WebSocket is not open");
        }
    });
}

socket.onmessage = function(event) {
    console.log("WebSocket message received:", event.data);

    var data = JSON.parse(event.data);

    if (!data) {
        return;
    }

    console.log(data.type);
    
    if (data.type === "flipped_card") {
        var card_id = data.card_flipped;
        var card_name = data.card_name;
        var imageData = card_name.replace(/"/g, '');

        console.log("Received card: " + card_id + " with image: " + imageData + "\nCard Name: " + card_name);


        var card = document.getElementById("memory_field" + card_id);
        card.getElementsByTagName("img")[0].src = imageData;
        knownCards[card_id] = imageData;
        setImage(card_id);
        moveUtils(card_id);
    }

};