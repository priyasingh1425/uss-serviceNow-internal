({
    doInit : function(component, event, helper) {
        helper.getTaskLists(component);
    },

    updateStatus : function(component, event, helper) {
        helper.updateTaskStatus(component, event);
    },

    buttonAction : function(component, event, helper) {
        helper.updateTaskOwner(component, event);
    },

    goToProcedure : function(component, event, helper) {
        helper.linkToProcedure(component, event);
    },
openCreateTaskFlow : function(component, event, helper) {
    // Prefer v.record (you set it in helper), fallback to v.recordId
    var caseId = component.get("v.record") || component.get("v.recordId");

    if (!caseId) {
        var toastErr = $A.get("e.force:showToast");
        if (toastErr) {
            toastErr.setParams({
                title: "Error",
                message: "No Case Id found on this page, cannot launch the flow.",
                type: "error"
            });
            toastErr.fire();
        }
        return;
    }
    var inputVars = [
        { name: "recordid", type: "String", value: caseId }
    ];

    component.set("v.flowInputVariables", inputVars);
    component.set("v.showCreateFlow", true);

    window.setTimeout($A.getCallback(function() {
        var flow = component.find("createTaskFlow");
        flow.startFlow("Case_Subflow_Create_TOC_Tasks", inputVars);
    }), 0);
},

    closeCreateTaskFlow : function(component, event, helper) {
        component.set("v.showCreateFlow", false);
    },

    handleFlowStatusChange : function(component, event, helper) {
        var status = event.getParam("status");
        if (status === "FINISHED" || status === "FINISHED_SCREEN") {
            component.set("v.showCreateFlow", false);
            $A.get('e.force:refreshView').fire();
        }
    }
})