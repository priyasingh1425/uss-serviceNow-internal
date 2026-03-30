({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getChildAccounts');
        action.setParams({
            "recordId": cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var records = response.getReturnValue();
				//Log records to dev console for troubleshooting...
                console.log(records);
				//Generate title for card
                var childCount = 0;
                if(records != null) { childCount = records.length; }
                cmp.set("v.title", "Accounts (" + childCount + ")");
                //Load the list of Accounts
                cmp.set("v.accounts", records);                
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	}
})