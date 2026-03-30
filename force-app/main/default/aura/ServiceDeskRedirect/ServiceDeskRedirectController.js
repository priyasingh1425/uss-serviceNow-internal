({
    doInit : function(component, event, helper) {
        window.open("https://ussignal-bussystems.atlassian.net/servicedesk/customer/portals", "_blank");
        window.setTimeout($A.getCallback(function() {
            $A.get("e.force:closeQuickAction").fire();
        }), 1000);
    }
})