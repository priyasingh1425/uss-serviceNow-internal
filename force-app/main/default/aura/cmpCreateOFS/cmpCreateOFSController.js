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
				if(records != null) { cmp.set("v.accounts", records); }                
            } else {
                console.log("Failed with state: " + state);
            }
        }));
        $A.enqueueAction(action);
	},
    
    createOFS : function(cmp, event, helper) {
        let button = event.getSource();
        button.set('v.disabled',true); //disable the Create OFS button to prevent multiple calls
        
        //Get the data already available on the component, including user input
        var opp_id = cmp.get("v.recordId");
        var account_string = cmp.find('Account').get('v.value');
        if (account_string == '') {
            var picklist = cmp.find('Account');
            picklist.showHelpMessageIfInvalid();   
            button.set('v.disabled',false);
        } else {
            
            var order_type = cmp.find('OrderType').get('v.value');
            var current_user_id = $A.get("$SObjectType.CurrentUser.Id"); 
            var descr = cmp.find('OrderDescription').get('v.value');
            
            //Log to Console
            console.log('Passed into client controller from component: ' +
                        ' Opp Id: ' + opp_id + 
                        ', Account Id: ' + account_string +
                        ', Order Type: ' + order_type + 
                        ', Created By Id: ' + current_user_id + 
                        ', Description: ' + descr);
        
            var action = cmp.get('c.processWrapper');        
            action.setParams({"opp_id": opp_id, 
                              "account_string": account_string,
                              "order_type": order_type,
                              "current_user_id": current_user_id,
                              "descr": descr
                              });        
            action.setCallback(this, $A.getCallback(function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var resultMap = response.getReturnValue();  
                    
                    if(resultMap != null) { //Show logging messages in console and to end user
                        //Log console
                        console.log('Response from server controller: '); 
                        //console.log(resultMap);
                        
                        //Push Map into Array
                        var optionsList = [];
                        for (var key in resultMap) {
                            if (resultMap.hasOwnProperty(key)) {
                                optionsList.push({key: key, value: resultMap[key]});
                            }
                        };
                        
                        //Log console
                        //console.log('Converted to array in client controller: ');
                        console.log(optionsList);
                        
                        //for (var i in optionsList) {
                            if(optionsList[0].key == 'isOFSCreated') {
                                if(optionsList[0].value == 'true') {
                                    cmp.set('v.showSuccess', 'true');                                  
                                    var linkLabel = optionsList[2].value;
                                    var link = 'https://ofs.ussignal.com/ofs/orders/view/id/'+ linkLabel;
                                    cmp.set('v.ofsLink', link);
                                    cmp.set('v.linkLabel', linkLabel);
                                } else {
                                    cmp.set('v.showError', 'true');
                                }
                            } 
                        //}
                        
                    } else { //Something likely broke between client controller and server controller
                        console.log('ERROR: There was an error somewhere between client and server controllers...');
                        cmp.set('v.showError', 'true');
                    }
                    
                    button.set('v.disabled',false); //re-enable the Create OFS button for the user
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    //Log to Console
                    console.log(errors[0]);
                }   
                 
        }));
        $A.enqueueAction(action);
        } 
    } 
})