({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getNewOwnerAccount');
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
                	cmp.set("v.newowner", account.New_Owner__c);  
					cmp.set("v.newownertext", account.New_Owner_Text__c);    
                }
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	}
})