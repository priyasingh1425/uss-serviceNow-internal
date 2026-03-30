public class TriggerBypass {
    
    private static Boolean bypassFeedItemTrigger = false;
    
    public static void setBypassFeedItemTrigger(Boolean bypass) {
        bypassFeedItemTrigger = bypass;
    }
    
    public static Boolean isFeedItemTriggerBypassed() {
        return bypassFeedItemTrigger;
    }

    private static Boolean bypassChangeRequestHandler = false;

    public static void setBypassChangeRequestHandler(Boolean bypass) {
        bypassChangeRequestHandler = bypass;
    }

    public static Boolean isChangeRequestHandlerBypassed() {
        return bypassChangeRequestHandler;
    }
}