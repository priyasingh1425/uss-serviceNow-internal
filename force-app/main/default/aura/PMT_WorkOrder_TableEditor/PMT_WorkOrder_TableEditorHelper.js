({
    
    getWorkOrders : function(component, helper) {
        component.set("v.isLoading",true);
        var action = component.get("c.getWorkOrdersForProject");
        action.setParams({
            projectId : component.get("v.recordId") 
        });        
        action.setCallback(this,function(response){
            //Create a set for filters
            var statusSet = new Set();
            var phaseSet = new Set();
            var memberSet = new Set();
            
            var statusList = [{'label':'All','value':'all'}];
            var phaseList = [{'label':'All','value':'all'}];
            var memberList = [{'label':'All','value':'all'}];
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                for (var i = 0; i < rows.length; i++){
                    var row = rows[i];
                    if (row.OwnerId) row.Owner = row.Owner.Name;
                    if (row.PMT_Phase__r.Id) row.PMT_Phase__c = row.PMT_Phase__r.Name;
                    
                    //Unique phase list
                    if(!phaseSet.has(row.PMT_Phase__r.Id)){
                        phaseSet.add(row.PMT_Phase__r.Id);    
                        phaseList.push({'label':row.PMT_Phase__r.Name, 'value':row.PMT_Phase__r.Id});
                    }
                    
                    //Unique status list
                    if(!statusSet.has(row.Status)){
                        statusSet.add(row.Status);    
                        statusList.push({'label':row.Status, 'value':row.Status});
                    }
                    
                    //Unique assignee list
                    if(!memberSet.has(row.Owner)){
                        memberSet.add(row.Owner); 
                        memberList.push({'label':row.Owner.Name, 'value':row.OwnerId});  
                    }
                    
                    
                }
                
                //Set filters
                component.set("v.PhaseList", phaseList);
                component.set("v.statusList", statusList);
                component.set("v.MemberList", memberList);
                
                //Set data
                component.set("v.workorders", rows);
                component.set("v.rawData", rows);
                
                //Apply default filter
                helper.updateTable(component);
                
            }else if(state ==='ERROR'){            
                var errors = response.getError();
                var message = '';                                  
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            }else{
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            } 
            component.set("v.isLoading",false);
        });
        $A.enqueueAction(action);
        
    },
    
    getRowActions: function (component, row, doneCallback) {
        var actions = [{
            'label': 'View',
            'iconName': 'utility:preview',
            'name': 'View'
        },
                       {	'label': 'Edit' ,
                        'iconName':'utility:edit',
                        'name': 'Edit'
                       },
                       {	'label': 'Copy' ,
                        'iconName':'utility:copy',
                        'name': 'Copy'
                       }
                      ];
        var deleteAction = {
            'label': 'Delete',
            'iconName': 'utility:delete',
            'name': 'Delete'
        };
        if (row['Approved']) {  
            deleteAction['disabled'] = 'true';
        } else {
            actions.push({
                'label': 'Submit Approval',
                'iconName': 'utility:approval',
                'name': 'Submit Approval'
            });
        }
        actions.push(deleteAction);
        doneCallback(actions);
    },
    
    removeWorkOrder: function (component, row) {
        var confirmation = confirm('Are you sure you want to delete?');
        if(confirmation){
            var rows = component.get('v.workorders');
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            component.set('v.workorders', rows);
            if(row) {
                var action = component.get("c.deleteRecord");
                action.setParams({
                    recordToDelete : row 
                });
                action.setCallback(this,function(response){                    
                    var result= response.getReturnValue();
                    var state = response.getState();
                    if(state === "SUCCESS"){
                        this.showMessage("", "Record deleted successfully.", "Success");
                        $A.get('e.force:refreshView').fire();
                    } else if(state ==='ERROR'){            
                        var errors = response.getError();
                        var message = '';                                  
                        if (errors && Array.isArray(errors) && errors.length > 0) {
                            message += errors[0].message;
                        }
                        helper.showToast("Error", message);
                    }else{
                        helper.showToast("Error", "Something went wrong, please contact system administrator.");
                    } 
                });
                $A.enqueueAction(action);
            }
        }
    },
    editRecord: function(component, recId)
    {
        if(recId) {
            var editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": recId
            });
            editRecordEvent.fire();
        }    
    },
    
    ViewRecord:function(component, recId)
    {
        if(recId) {
            
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": recId
            });
            urlEvent.fire();
        } 
    },
    
    cloneWorkOrder: function(component, workorderRec) {
        if(workorderRec) {
            var createWorkOrderEvent = $A.get("e.force:createRecord");
            createWorkOrderEvent.setParams({
                "entityApiName": "WorkOrder",
                "defaultFieldValues": {
                    'PMT_Phase__c' : workorderRec.PMT_Phase__c,
                    'Subject' : workorderRec.Subject,
                    'OwnerId' : workorderRec.OwnerId,
                    'Requested_Delivery_Date__c' : workorderRec.Requested_Delivery_Date__c,
                    'Service_ID__c' : workorderRec.Service_ID__c,
                    'Status' : workorderRec.Status,
                    'Description' : workorderRec.Description,
                    'Work_Category__c' : workorderRec.Work_Category__c,
                    'AccountId' : workorderRec.AccountId,
                    'CaseId' : workorderRec.CaseId
                }
            });
            createWorkOrderEvent.fire();
        }
    },
    
    saveWorkOrders: function(component, workordersToSave) {
        if(workordersToSave) {
            var action = component.get("c.updateWorkOrders");
            action.setParams({"workorders" : workordersToSave});
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                var state = response.getState();                
                 if(state === "SUCCESS"){
                    component.set("v.selectedWorkOrders",response.getReturnValue());
                    component.set("v.draftValues",null);                    
                    this.showMessage("", "Your changes are saved.", "Success");
                    
                    $A.get('e.force:refreshView').fire();
                }else if(state ==='ERROR'){            
                    var errors = response.getError();
                    var message = '';                                  
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message += errors[0].message;
                    }
                    helper.showToast("Error", message);
                }else{
                    helper.showToast("Error", "Something went wrong, please contact system administrator.");
                } 
            });
            $A.enqueueAction(action);
        }
    },
    
    showMessage: function(title, message, type) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        resultsToast.fire();
    },
    
    changeStatus: function (component, workordersSelected) {
        component.set("v.showflowChangeStatus", true);
        var action = component.get("c.getWorkOrdersList");
        action.setParams({
            workorderIds: component.get("v.selectedIds")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var listOfWorkOrders = response.getReturnValue();
                component.set("v.workordersToUpdate", listOfWorkOrders);
                // Find the component whose aura:id is "flowChangeStatus"
                var flow = component.find("flowChangeStatus");
                var inputVariables = [
                    {
                        name: "LsWorkOrderSelected",
                        type: "SObject",
                        value: component.get("v.workordersToUpdate")
                    }
                ];
                // In that component, start your flow. Reference the flow's API Name.
                flow.startFlow("PMT_WorkOrder_Mass_update_status", inputVariables);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var message = '';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            } else {
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            }
        });
        $A.enqueueAction(action);
    },
    
    changeAssignee: function(component, workordersSelected) {
        component.set("v.showflowChangeStatus", true);        
        var action = component.get("c.getWorkOrdersList");
        action.setParams({
            workorderIds : component.get("v.selectedIds") 
        });        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var listOfWorkOrders = response.getReturnValue();
                component.set("v.workordersToUpdate", listOfWorkOrders);
                // Find the component whose aura:id is "flowChangeStatus"
                var flow = component.find("flowChangeStatus");
                var inputVariables = [
                    {
                        name : "InputProjectId",
                        type : "SObject",
                        value : component.get("v.recordId")
                    },
                    {
                        name : "LsWorkOrderSelected",
                        type : "SObject",
                        value :component.get("v.workordersToUpdate")
                    }
                ];
                // In that component, start your flow. Reference the flow's API Name.
                flow.startFlow("PMT_WorkOrder_Mass_update_Owner",inputVariables); 
            }else if(state ==='ERROR'){            
                var errors = response.getError();
                var message = '';                                  
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            }else{
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            } 
        });
        $A.enqueueAction(action);
    },
    
    //Handle sort in datatable columns
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.workorders");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.workorders", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            //Release 1.0
            //Bug Fix : Task table - Assigned to column sorting not working, blank skipping
            return a = key(a) ? key(a) : '', b = key(b) ? key(b) : '', reverse * ((a > b) - (b > a));
        }
    },
    
    updateTable: function (component) {
        var rows = JSON.parse(JSON.stringify(component.get('v.rawData')));
        var selectedPhase = component.get("v.selectedPhase");
        var selectedStatus = component.get("v.selectedStatus");
        var selectedMember = component.get("v.selectedMember");
        
        var filteredRows = JSON.parse(JSON.stringify(rows));
        if(selectedPhase !== 'all' && selectedPhase!=='') {
            filteredRows = filteredRows.filter(row=> row.PMT_Phase__r.Id == selectedPhase);
        }
        if(selectedStatus !== 'all' && selectedStatus!=='') {
            filteredRows = filteredRows.filter(row=> row.Status == selectedStatus);
        }
        
        if(selectedMember!='all' && selectedMember!=='') {
            filteredRows = filteredRows.filter(row=> row.Owner == selectedMember);
        }

        component.set("v.workorders", filteredRows);
    },
    
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
})