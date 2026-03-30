({
    //Component initialization
    doInit : function(component, event, helper) {
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component)
        
        //Define columns table
        component.set('v.columns', [
            {label: 'Phase',fieldName: 'PMT_Phase__c', editable:false, type: 'text', sortable:true,},
            {label: 'Number',fieldName: 'WorkOrderNumber', editable:false, type: 'text', sortable:true},
            {label: 'Subject',fieldName: 'Subject', editable:true, type: 'text', sortable:true},
            {label: 'Status', fieldName: 'Status', editable:false, type: 'text', sortable:true},
            {label: 'Priority', fieldName: 'Priority', editable:true, type: 'text', sortable:true},
            {label: 'Requested Delivery Date', fieldName: 'Requested_Delivery_Date__c', editable:true, type: 'date-local', initialWidth: 130, sortable:true,
             typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'} },
            {label: 'Owner', fieldName: 'Owner', editable:false, type: 'text', sortable:true, initialWidth: 160},
            {label: 'Description', fieldName: 'Description', editable:true, type: 'text'},
            {label: '', type: 'action', typeAttributes: { rowActions: actions } }
        ]);        
        
        helper.getWorkOrders(component, helper); //Get list of workorders
        
    },
    
    //handle workorder table row actions
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'View':helper.ViewRecord(component,row.Id);
                break;
            case 'Edit': helper.editRecord(component,row.Id);
                break;
            case 'Copy': helper.cloneWorkOrder(component,row);
                break;
            case 'Delete':helper.removeWorkOrder(component, row);
                break;
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
    
    //Handle multiple workorders selection
    handleWorkOrderSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedWorkOrders", selectedRows);
        var setRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            setRows.push(selectedRows[i].Id);
        }
        component.set("v.selectedIds", setRows);         
    },
    
    //Save changes to WorkOrders
    onSave: function (component, event, helper) {
        component.set("v.isRefresh",false);
        var draftValues = event.getParam('draftValues');
        helper.saveWorkOrders(component, draftValues);
        helper.getWorkOrders(component,helper);        
    },
    
    //Handle click on Change Status button
    handleStatusClick: function(component, event, helper){
        var workordersSelected = component.get("v.selectedWorkOrders");
        if(workordersSelected) 
        {
            helper.changeStatus(component, workordersSelected);
        }
        else
        {
            helper.showMessage("", "Please select atleast 1 record to update the WorkOrder.", "error");
        }
    },
    
    //Handle click on Change Status button
    handleAssigneeClick: function(component, event, helper){
        var workordersSelected = component.get("v.selectedWorkOrders");
        if(workordersSelected)
        {
            helper.changeAssignee(component, workordersSelected);
        }
        else
        {
            helper.showMessage("", "Please select atleast 1 record to update the Owner", "error");
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