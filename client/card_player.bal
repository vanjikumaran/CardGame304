import ballerina/log;
import ballerina/websub;

listener websub:Listener websubEP = new(8181);


@websub:SubscriberServiceConfig {
    path: "/playinggame",
    subscribeOnStartUp: true,
    resourceUrl: "http://localhost:9090/game/notification",
    leaseSeconds: 3600
}
service websubSubscriber on websubEP {
    // Define the resource that accepts the content delivery requests.
    resource function onNotification(websub:Notification notification) {
        var payload = notification.getTextPayload();
        if (payload is string) {
            log:printInfo("WebSub Notification Received: " + payload);
        } else {
            log:printError("Error retrieving payload as string", err = payload);
        }
    }
}
