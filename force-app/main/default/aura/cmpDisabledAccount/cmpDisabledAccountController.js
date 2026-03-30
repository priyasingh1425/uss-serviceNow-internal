({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getAccount');
        action.setParams({
            "recordId": cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var account = response.getReturnValue();
				//Log records to dev console for troubleshooting...
                console.log(account);
                if(account != null) {
                	cmp.set("v.disabled", account.Disabled__c);  
					cmp.set("v.type", account.Type);    
                }
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	}
})