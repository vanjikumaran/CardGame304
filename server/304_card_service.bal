// 304 Game Server written based out of REST API and WebSub for Plahyer Notifications
import ballerina/http;
import ballerina/log;
import ballerina/websub;

listener http:Listener httpListener = new(9090);

//Notification topic
final string GAME_TOPIC = "http://localhost:9090/304/game/notifications";

// Player Map
map<json> gameMap = {};

//Hub
websub:WebSubHub webSubHub = startHubAndRegisterTopic();


// REST API for Notification WebSub Discovery and Game Play
@http:ServiceConfig {
    basePath: "/game"
}
service game on httpListener {

    // Discovery Service for the 304 Card Game WebSub
    @http:ResourceConfig {
        methods: ["GET", "HEAD"],
        path: "/notification"
    }
    resource function discoverGameNotificaiton(http:Caller caller, http:Request req) {
        http:Response response = new;
        websub:addWebSubLinkHeader(response, [webSubHub.hubUrl], GAME_TOPIC);
        response.statusCode = 202;
        var result = caller->respond(response);
        if (result is error) {
           log:printError("Error responding on Joining the Game", err = result);
        }
    }

    // Resource accepting Gamer Joining.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/join"
    }
    resource function playerJoinGame(http:Caller caller, http:Request req) {
        var playerJoinReq = req.getJsonPayload();
        if (playerJoinReq is json) {
            string playerId = playerJoinReq.player.ID.toString();
            gameMap[playerId] = playerJoinReq;

            // Create the response message indicating successful player creation.
            http:Response response = new;
            response.statusCode = 202;
            var result = caller->respond(response);
            if (result is error) {
               log:printError("Error responding on game Joining", err = result);
            }

            // Publish the update to the Hub, to notify subscribers.
            string gamePlayerCreatedNotification = "New Game Player Added: " + playerId;
            log:printInfo(gamePlayerCreatedNotification);
            result = webSubHub.publishUpdate(GAME_TOPIC,
                                                    gamePlayerCreatedNotification);
            if (result is error) {
                log:printError("Error publishing update", err = result);
            }
        } else {
            log:printError("Error retrieving payload", err = playerJoinReq);
            panic playerJoinReq;
        }
    }

}

// Start up a Ballerina WebSub Hub on port 9191 and register the topic against
// which updates will be published.
function startHubAndRegisterTopic() returns websub:WebSubHub {
    var hubStartUpResult = websub:startHub(new http:Listener(9191));
    websub:WebSubHub internalHub = hubStartUpResult is websub:HubStartedUpError
                    ? hubStartUpResult.startedUpHub : hubStartUpResult;

    var result = internalHub.registerTopic(GAME_TOPIC);
    if (result is error) {
        log:printError("Error registering topic", err = result);
    }
    return internalHub;
}
