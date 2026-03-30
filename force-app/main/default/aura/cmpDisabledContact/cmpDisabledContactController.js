({
    doInit : function(cmp, event, helper) {
        var action = cmp.get('c.getContact');
        var rid = cmp.get("v.recordId");
        action.setParams({
            "recordId": cmp.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var contact = response.getReturnValue();
                //Log records to dev console for troubleshooting...
                console.log(contact);
                cmp.set("v.isDisabled", "false");
                cmp.set("v.isRestricted", "false");
                if(contact != null) {
                    if(contact.Disabled__c != null) {
                        cmp.set("v.disabled", contact.Disabled__c);
                        cmp.set("v.isDisabled", "true");
                    } else {
                        if(contact.Restricted_Roles__c != null && contact.Restricted_Roles__c > 0) {
                            cmp.set("v.restricted", contact.Restricted_Roles__c);
                            cmp.set("v.isRestricted", "true");   
                            var action = cmp.get('c.getContactChangeEmail');
                            action.setParams({
                                "recordId": rid
                            })
                            action.setCallback(this, function(actionResult) {
                                cmp.set('v.contactChangeEmails', actionResult.getReturnValue()); 
                            })
                            
                            $A.enqueueAction(action);
                        }
                    }
                }
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
    }
})