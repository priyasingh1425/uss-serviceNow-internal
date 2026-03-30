({
    init : function (component) {
        component.set("v.record", component.get('v.recordId'));
    },
    
    onclickOne : function(component, event){
        // Find the component whose aura:id is referenced
        component.set("v.showFlowOne", true);
        var flowOne = component.find("Flow_Case_Auto_Assignment");
        var rid = component.get('v.recordId');

        var inputVariables = [
            {name : 'recordId', 
             type : 'String', 
             value : rid}
        ];
        
        // In that component, start your flow. Reference the flow's API Name.
        flowOne.startFlow("Take_Case_Ownership", inputVariables);
        
    },
    
    onclickTwo : function(component, event){
        // Find the component whose aura:id is referenced
        component.set("v.showFlowTwo", true);
		var flowTwo = component.find("Flow_Case_Transfer_or_Assistance");
        var rid = component.get('v.recordId');

        var inputVariables = [
            {name : 'recordId', 
             type : 'String', 
             value : rid}
        ];
        
        // In that component, start your flow. Reference the flow's API Name.
		flowTwo.startFlow("Case_Transfer_or_Assistance", inputVariables);
    },
    
    handleStatusChange : function (component, event) {
   if(event.getParam("status") === "FINISHED") {
       		component.set("v.showFlowOne", false);
       		component.set("v.showFlowTwo", false);
       $A.get('e.force:refreshView').fire();
   } else if(event.getParam("status") === "FINISHED_SCREEN"){
       component.set("v.showFlowOne", false);
       $A.get('e.force:refreshView').fire();
   }
    },
    closeModalBtn : function (component) {
        component.set("v.showFlowTwo", false);
    }
})