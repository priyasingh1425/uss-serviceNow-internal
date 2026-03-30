({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getCase');
        action.setParams({
            "recordId": cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var c = response.getReturnValue();
				//Log records to dev console for troubleshooting...
                console.log(c);
                cmp.set("v.escalation", c.Escalation_Level__c);
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	}
})