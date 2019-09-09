import ballerina/log;
import ballerina/websub;
import ballerina/math;



listener http:Listener httpListener = new(9090);

// The topic against which the publisher will publish updates, and the subscribers
// need to subscribe to, to receive notifications when an order is placed
final string ORDER_TOPIC = "http://localhost:9090/game/";

// An in-memory `map` to which orders will be added for demonstration
map<json> orderMap = {};




function cardShuffling(int n) {
   
    for (int i = 0; i < n; i++) 
        { 
            int r = i + rand.nextInt(n - i); 
            
            
            int temp = card[r]; 
            card[r] = card[i]; 
            card[i] = temp; 
        } 
}



websub:WebSubHub webSubHub = startHubAndRegisterTopic();

@http:ServiceConfig {
    basePath: "/game"
}
service cardgame304 on httpListener {


    // Placing a bet for Game
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/bet"
    }
    resource function placeBet(http:Caller caller, http:Request req) {

        var betReq = req.getJsonPayload();
        
        if (betReq is json) {
            string  = orderReq.Order.ID.toString();
            orderMap[orderId] = orderReq;

            // Create the response message indicating successful order creation.
            http:Response response = new;
            response.statusCode = 202;
            var result = caller->respond(response);
            if (result is error) {
               log:printError("Error responding on ordering", err = result);
            }

            // Publish the update to the Hub, to notify subscribers.
            string orderCreatedNotification = "New Order Added: " + orderId;
            log:printInfo(orderCreatedNotification);
            result = webSubHub.publishUpdate(ORDER_TOPIC,
                                                    orderCreatedNotification);
            if (result is error) {
                log:printError("Error publishing update", err = result);
            }
        } else {
            log:printError("Error retrieving payload", err = betReq);
            panic betReq;
        }
    }

}

// Start up a Ballerina WebSub Hub on port 9191 and register the topic against
// which updates will be published.
function startHubAndRegisterTopic() returns websub:WebSubHub {
    var hubStartUpResult = websub:startHub(new http:Listener(9191));
    websub:WebSubHub internalHub = hubStartUpResult is websub:HubStartedUpError
                    ? hubStartUpResult.startedUpHub : hubStartUpResult;

    var result = internalHub.registerTopic(ORDER_TOPIC);
    if (result is error) {
        log:printError("Error registering topic", err = result);
    }
    return internalHub;
}
