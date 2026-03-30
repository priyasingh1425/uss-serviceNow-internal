({
    //Component initialization
    doInit : function(component, event, helper) {
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component)
        
        //Define columns table
        component.set('v.columns', [
            //{label: 'Phase',fieldName: 'Phase', editable:false, type: 'text', sortable:true,},

            {label: 'Case #',fieldName: 'CaseNumber', editable:false, type: 'text', sortable:true},
            {label: 'Subject',fieldName: 'Subject', editable:true, type: 'text', sortable:true},
            {label: 'Status', fieldName: 'Status', editable:false, type: 'text', initialWidth: 160, sortable:true},
            {label: 'Priority', fieldName: 'Priority', editable:true, type: 'text', initialWidth: 90},
            {label: 'Opened', fieldName: 'CaseStartDate', editable:false, type: 'date-local', initialWidth: 130, sortable:true,
             typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'} },
            {label: 'Closed', fieldName: 'CaseCloseDate', editable:false, type: 'date-local', initialWidth: 130, sortable:true,
             typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'} },
            {label: 'Owner', fieldName: 'CaseOwner', editable:false, type: 'text', sortable:true, initialWidth: 160},
            {label: '', type: 'action', typeAttributes: { rowActions: actions } }
        ]);        
        
        helper.getCases(component, helper); //Get list of cases
        
    },
    
    //handle case table row actions
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        switch (action.name) {
            case 'View':helper.ViewRecord(component,row.Id);
                break;
            case 'Edit': helper.editRecord(component,row.Id);
                break;
            //case 'Copy': helper.cloneCase(component,row,recTypeId);
            //    break;
            //case 'Delete':helper.removeCase(component, row);
            //    break;
            //case 'Submit Approval':helper.submitPMTCaseForApproval(component,row.Id);
            //    break;
            default:
                console.log('Invalid Action');
                break;
        }
    },
    
    //Handle sorting on datatable columns
    handleSort: function (component, event, helper){
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);  
    },
    
    //Handle multiple case selection
    handleCaseSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedCases", selectedRows);
        var setRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            setRows.push(selectedRows[i].Id);
        }
        component.set("v.selectedIds", setRows);         
    },
    
    //Save changes to Cases
    onSave: function (component, event, helper) {
        component.set("v.isRefresh",false);
        var draftValues = event.getParam('draftValues');
        helper.saveCases(component, draftValues);
        helper.getCases(component,helper);  
        helper.getPhases(component,helper);
    },
    
    //Handle click on Change Status button
    handleStatusClick: function(component, event, helper){
        var casesSelected = component.get("v.selectedCases");
        if(casesSelected) 
        {
            helper.changeStatus(component, casesSelected);
        }
        else
        {
            helper.showMessage("", "Please select at least 1 record to update the Case Status.", "error");
        }
    },
    
    //Handle click on Change Owner button
    handleAssigneeClick: function(component, event, helper){
        var casesSelected = component.get("v.selectedCases");
        if(casesSelected)
        {
            helper.changeAssignee(component, casesSelected);
        }
        else
        {
            helper.showMessage("", "Please select at least 1 record to update the Case Owner.", "error");
        } 
    },
    
    //Close flow modal
    closemodal:function (component, event, helper) {
        component.set("v.showflowChangeStatus",false);
    },
    
    //Navigation
    handleStatusChange : function (component, event,helper) {
        if(event.getParam("status") === "FINISHED") {
            component.set("v.showflowChangeStatus", false);
            var projectId = component.get("v.recordId") ;
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": projectId
            });
            urlEvent.fire();
        } 
    },
    
    //Handle filters for datatable
    handlefilters: function (component, event, helper) {
        helper.updateTable(component);
    }
})