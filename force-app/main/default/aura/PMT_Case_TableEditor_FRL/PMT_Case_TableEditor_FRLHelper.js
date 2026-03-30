({
    getCases : function(component, helper) {
        component.set("v.isLoading",true);
        
        //getPhases
        var action = component.get("c.getPhases");
        action.setParams({
            projectId : component.get("v.recordId")
        });
        action.setCallback(this,function(response){
 	    	var state = response.getState();
        if(state === 'SUCCESS'){
            
            var phases = response.getReturnValue();
            component.set("v.phaseNames",phases);
            
        }else if (state === 'ERROR') {
            console.log('Error');
             helper.showToast("Error", message);
        }
        });
        $A.enqueueAction(action);        
        
        //getCases
        var action = component.get("c.getCasePhaseJunctionsForProject");
        action.setParams({
            projectId : component.get("v.recordId") 
        });        
        action.setCallback(this,function(response){
            
            var pNames = component.get("v.phaseNames");
            
            //Create a set for status values
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
                   // if (row.Owner) row.Owner = row.Case__r.Owner.Name;
                    
                    
                    //if (row.PMT_Phase__c) row.Phase = row.PMT_Phase__r.Name;
                    //Unique phase list
                   // if(!phaseSet.has(row.PMT_Phase__r.Id)){
                   //     phaseSet.add(row.PMT_Phase__r.Id);    
                  //      phaseList.push({'label':row.PMT_Phase__r.Name, 'value':row.PMT_Phase__r.Id});
                  //  }
                    
                    //Unique status list
                    if(!statusSet.has(row.Status)){
                        statusSet.add(row.Status);    
                        statusList.push({'label':row.Status, 'value':row.Status});
                    }
                    
                    //Unique assignee list
                    if(!memberSet.has(row.CaseOwner)){
                        memberSet.add(row.CaseOwner); 
                        if(row.CaseOwner!='' && row.CaseOwner!=undefined){
                            memberList.push({'label':row.CaseOwner, 'value':row.CaseOwner});  
                        }
                    }
                    
                }
                
                for(var i = 0; i < pNames.length; i++){
                    phaseList.push({'label':pNames[i], 'value':pNames[i]});
                }
                
                //Set filters
                component.set("v.PhaseList", phaseList);
                statusList.push({'label':'Open Cases','value':'Open Cases'})
                component.set("v.statusList", statusList);
                //memberList.push({'label':'Not Assigned', 'value':'Not Assigned'})
                component.set("v.MemberList", memberList);
                
                //Set data
                component.set("v.cases", rows);
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
            
        });
        $A.enqueueAction(action);
        component.set("v.isLoading",false);
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
      /*  var deleteAction = {
       *     'label': 'Delete',
       *     'iconName': 'utility:delete',
       *     'name': 'Delete'
       * };
       *
       * if (row['Approved']) {  
       *     deleteAction['disabled'] = 'true';
       * } else {
       *     actions.push({
       *         'label': 'Submit Approval',
       *         'iconName': 'utility:approval',
       *         'name': 'Submit Approval'
       *     });
       * }
       * actions.push(deleteAction);
       */
        doneCallback(actions);
    },
    
    /* removeCase: function (component, row) {
     *   var confirmation = confirm('Are you sure you want to delete?');
     *   if(confirmation){
     *       var rows = component.get('v.cases');
     *       var rowIndex = rows.indexOf(row);
     *       rows.splice(rowIndex, 1);
     *       component.set('v.cases', rows);
     *       if(row) {
     *           var action = component.get("c.deleteRecord");
     *           action.setParams({
     *               recordToDelete : row 
     *           });
     *           action.setCallback(this,function(response){                    
     *               var result= response.getReturnValue();
     *               var state = response.getState();
     *               if(state === "SUCCESS"){
     *                   this.showMessage("", "Record deleted successfully.", "Success");
     *                   $A.get('e.force:refreshView').fire();
     *               } else if(state ==='ERROR'){            
     *                   var errors = response.getError();
     *                   var message = '';                                  
     *                   if (errors && Array.isArray(errors) && errors.length > 0) {
     *                      message += errors[0].message;
     *                   }
     *                   helper.showToast("Error", message);
     *               }else{
     *                   helper.showToast("Error", "Something went wrong, please contact system administrator.");
     *               } 
     *           });
     *           $A.enqueueAction(action);
     *       }
     *   }
     *},
     */
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
    
    /* cloneCase: function(component, caseRec, recTypeId) {
        console.log(caseRec);
        console.log(recTypeId);
        if(caseRec) {
            var createPMTCaseEvent = $A.get("e.force:createRecord");
            createPMTCaseEvent.setParams({
                "entityApiName": "Case",
                "recordTypeId" : recTypeId,
                "defaultFieldValues": {
                    'Subject' : caseRec.Subject,
                    'Owner' : caseRec.Owner,
                    'Start_Date__c' : caseRec.Start_Date__c,
                    'Support_Queue__c' : caseRec.Support_Queue__c,
                    'Case_Type__c' : caseRec.Case_Type__c,
                    'Case_Classification__c' : caseRec.Case_Classification__c,
                    'Group__c' : caseRec.Group__c,
                    'Category__c' : caseRec.Category__c,
                    'Component__c' : caseRec.Component__c,
                    'Contact' : caseRec.Contact,
                    'Status' : caseRec.Status,
                    'Priority' : caseRec.Priority,
                    'PMT_Phase__c' : caseRec.PMT_Phase__c,
                    'Account' : caseRec.Account,
                    'Account_Account_Name__c' : caseRec.Account_Account_Name__c,
                    'Service_ID__c' : caseRec.Service_ID__c,
                    'Case_Template__c' : caseRec.Case_Template__c,
                    'Employee__c' : caseRec.Employee__c,
                    'Opportunity__c' : caseRec.Opportunity__c,
                    'Product' : caseRec.Product,
                    'Business_Owner__c' : caseRec.Business_Owner__c,
                    'Soft_Dev_Approval__c' : caseRec.Soft_Dev_Approval__c,
                    'Ticket_Owner__c' : caseRec.Ticket_Owner__c,
                    'Group_Priority__c' : caseRec.Group_Priority__c,
                    'Estimated_Hours__c' : caseRec.Estimated_Hours__c,
                    'Priority_Number__c' : caseRec.Priority_Number__c,
                    'Queue__c' : caseRec.Queue__c,
                    'Soft_Dev_Approval__c' : caseRec.Soft_Dev_Approval__c,
                    'Vendor_Escalation_Level__c' : caseRec.Vendor_Escalation_Level__c,
                    'Service_Affecting__c' : caseRec.Service_Affecting__c,
                    'Escalate_Order__c' : caseRec.Escalate_Order__c,
                    'Drop_Ship_Order__c' : caseRec.Drop_Ship_Order__c,
                    'Responsible_Party__c' : caseRec.Responsible_Party__c,
                    'Severity_Level__c' : caseRec.Severity_Level__c,
                    'Escalation_Level__c' : caseRec.Escalation_Level__c,
                    'Details__c' : caseRec.Details__c,
                    'Steps_to_Reproduce__c' : caseRec.Steps_to_Reproduce__c,
                    'User_Systems_Impacted__c' : caseRec.User_Systems_Impacted__c,
                    'Comments' : caseRec.Comments,
                    'Location__c' : caseRec.Location__c,
                    'Circuit_ID__c' : caseRec.Circuit_ID__c,
                    'TOC_Owner__c' : caseRec.TOC_Owner__c,
                    'Description' : caseRec.Description,
                    'Requested_Delivery_Date__c' : caseRec.Requested_Delivery_Date__c,
                    'SuppliedEmail' : caseRec.SuppliedEmail,
                }
            });
            createPMTCaseEvent.fire();
        }
    },
    */
    
   /* submitPMTCaseForApproval: function(component, recId) {
    *    if(recId) {
    *        var action = component.get("c.submitCaseForApproval");
    *        action.setParams({
    *            taskId : recId 
    *        });
    *        action.setCallback(this,function(response){
    *            var result= response.getReturnValue();
    *            var state = response.getState(); 
    *            if(state === "SUCCESS"){
    *                this.showMessage("", "PMT Case was submitted for Approval.", "Success");
    *                $A.get('e.force:refreshView').fire();
    *            } else if(state ==='ERROR'){            
    *                var errors = response.getError();
    *                var message = '';                                  
    *                if (errors && Array.isArray(errors) && errors.length > 0) {
    *                    message += errors[0].message;
    *                }
    *                helper.showToast("Error", message);
    *            }else{
    *                helper.showToast("Error", "Something went wrong, please contact system administrator.");
    *            } 
    *        });
    *        $A.enqueueAction(action);
    *    }
    *},
    */
    
    saveCases: function(component, casesToSave) {
        if(casesToSave) {
            var action = component.get("c.updateCases");
            action.setParams({"cases" : casesToSave});
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                var state = response.getState();                
                 if(state === "SUCCESS"){
                    component.set("v.selectedCases",response.getReturnValue());
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
                    helper.showToast("Error", "Something went wrong, please contact your system administrator.");
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
    
    changeStatus: function (component, casesSelected) {
        component.set("v.showflowChangeStatus", true);
        var action = component.get("c.getCasesList");
        action.setParams({
            caseIds: component.get("v.selectedIds")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var listOfCases = response.getReturnValue();
                component.set("v.casesToUpdate", listOfCases);
                // Find the component whose aura:id is "flowChangeStatus"
                var flow = component.find("flowChangeStatus");
                var inputVariables = [
                    {
                        name: "LsPMTCasesSelected",
                        type: "SObject",
                        value: component.get("v.casesToUpdate")
                    }
                ];
                // In that component, start your flow. Reference the flow's API Name.
                flow.startFlow("PMT_Case_Mass_update_Status", inputVariables);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var message = '';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            } else {
                helper.showToast("Error", "Something went wrong, please contact your system administrator.");
            }
        });
        $A.enqueueAction(action);
    },
    
    changeAssignee: function(component, casesSelected) {
        component.set("v.showflowChangeStatus", true);        
        var action = component.get("c.getCasesList");
        action.setParams({
            taskIds : component.get("v.selectedIds") 
        });        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var listOfCases = response.getReturnValue();
                component.set("v.casesToUpdate", listOfCases);
                // Find the component whose aura:id is "flowChangeStatus"
                var flow = component.find("flowChangeStatus");
                var inputVariables = [
                    {
                        name : "InputProjectId",
                        type : "SObject",
                        value : component.get("v.recordId")
                    },
                    {
                        name : "LsPMTCasesSelected",
                        type : "SObject",
                        value :component.get("v.casesToUpdate")
                    }
                ];
                // In that component, start your flow. Reference the flow's API Name.
                flow.startFlow("PMT_Case_Mass_update_Owner",inputVariables); 
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
        var data = component.get("v.cases");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.cases", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            //Release 1.0
            //Bug Fix : Case table - Assigned to column sorting not working, blank skipping
            return a = key(a) ? key(a) : '', b = key(b) ? key(b) : '', reverse * ((a > b) - (b > a));
        }
    },
    
    updateTable: function (component) {
        var rows = JSON.parse(JSON.stringify(component.get('v.rawData')));
        var selectedPhase = component.get("v.selectedPhase");
        var selectedStatus = component.get("v.selectedStatus");
        var selectedMember = component.get("v.selectedMember");
        var filteredRows = JSON.parse(JSON.stringify(rows));
        
        if(selectedPhase == 'all'){
            var caseSet = new Set();
            var caseList = new List();

            console.log(Object.values(filteredRows));
        //    var caseList = new List();
            //for(var i = 0; i < rows.length; i++){
              //  var r = rows[i];
             //   console.log(rows[i]);
             //   console.log(r.CaseId);

               // if(i=0){
               //     caseSet.add(row.CaseNumber);
               // }
                
                //Unique case list
                // if(!caseSet.has(row.CaseNumber)){
       //          caseSet.add(row.CaseNumber);    
                 //caseList.add(row);    
               //   } 
       //         console.log(caseSet);
        //    }
            //filteredRows = caseList;
        }
        if(selectedPhase !== 'all' && selectedPhase!=='') {
            filteredRows = filteredRows.filter(row=> row.PhaseName == selectedPhase);
        }
        if(selectedStatus !== 'all' && selectedStatus!=='' && selectedStatus!=='Open Cases') {
            filteredRows = filteredRows.filter(row=> row.Status == selectedStatus);
        }
        else if(selectedStatus == 'Open Cases'){
            filteredRows = filteredRows.filter(row=> row.Status == 'Discovery' || row.Status == 'Provisioning' || row.Status == 'Implementation' || row.Status == 'New' || row.Status == 'On Hold' || row.Status == 'New' || row.Status == 'Assigned' || row.Status == 'Ready for Devl' || row.Status == 'In Progress' || row.Status == 'Design' || row.Status == 'In Development' || row.Status == 'Parked' || row.Status == 'In Transit' || row.Status == 'QA_Full' || row.Status == 'Awaiting Production Approvals' || row.Status == 'Approved for Production' || row.Status == 'Pending Case Approval');
        }
        /*
        if(selectedMember !== 'Not Assigned' && selectedMember!='all' && selectedMember!=='') {
            filteredRows = filteredRows.filter(row=> row.Owner == selectedMember);
        }
        else if(selectedMember == 'Not Assigned'){
            filteredRows = filteredRows.filter(row=> row.Owner.User == '' || row.Owner.User == undefined);
        }
        */
        component.set("v.cases", filteredRows);
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