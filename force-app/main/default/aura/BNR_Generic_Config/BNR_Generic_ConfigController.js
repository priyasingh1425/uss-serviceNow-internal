({
    init : function(cmp, event, helper) {
        if(cmp.get("v.fieldAPIname1") != '1'){
            var action = cmp.get('c.getFieldValue');
            action.setParams({
                "objectAPIName": cmp.get("v.objectAPIname"),
                "fieldAPIName" : cmp.get("v.fieldAPIname1"),
                "recordId": cmp.get("v.recordId")
            });
            action.setCallback(this, $A.getCallback(function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    //Log records to dev console for troubleshooting...
                    console.log(res);
                    cmp.set("v.fieldValue1", res);
                } else {
                    console.log("Failed with state: " + state);
                }
            }));
            $A.enqueueAction(action);
        } else {
            cmp.set("v.fieldValue1", "");
        }
        
        if(cmp.get("v.fieldAPIname2") != '2'){
            var action = cmp.get('c.getFieldValue');
            action.setParams({
                "objectAPIName": cmp.get("v.objectAPIname"),
                "fieldAPIName" : cmp.get("v.fieldAPIname2"),
                "recordId": cmp.get("v.recordId")
            });
            action.setCallback(this, $A.getCallback(function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    //Log records to dev console for troubleshooting...
                    console.log(res);
                    cmp.set("v.fieldValue2", res);
                } else {
                    console.log("Failed with state: " + state);
                }
            }));
            $A.enqueueAction(action);
        } else {
            cmp.set("v.fieldValue2", "");
        }
        
        if(cmp.get("v.fieldAPIname3") != '3'){
            var action = cmp.get('c.getFieldValue');
            action.setParams({
                "objectAPIName": cmp.get("v.objectAPIname"),
                "fieldAPIName" : cmp.get("v.fieldAPIname3"),
                "recordId": cmp.get("v.recordId")
            });
            action.setCallback(this, $A.getCallback(function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    //Log records to dev console for troubleshooting...
                    console.log(res);
                    cmp.set("v.fieldValue3", res);
                } else {
                    console.log("Failed with state: " + state);
                }
            }));
            $A.enqueueAction(action);
        } else {
            cmp.set("v.fieldValue3", "");
        }
        
        helper.handleColorsInit(cmp, event, helper);
        helper.handleTextColorsInit(cmp, event, helper);
    }
})