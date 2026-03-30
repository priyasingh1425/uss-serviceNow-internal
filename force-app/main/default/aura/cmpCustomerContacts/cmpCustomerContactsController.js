({
	doInit : function(cmp, event, helper) {
		var action = cmp.get('c.getParentContacts');
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
                var contactCount = 0;
                if(records != null) { contactCount = records.length; }
                cmp.set("v.title", "Customer Contacts (" + contactCount + ")");
                //Load the list of Contacts
                cmp.set("v.contacts", records);                
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	}
})