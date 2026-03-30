({
    // Fetch the tasks from the Apex controller
    getTaskLists: function(component) {
        component.set("v.isLoading", true);

        var action = component.get('c.getTasks');
        action.setParams({
            "recordId": component.get('v.recordId')
        });

        action.setCallback(this, function(actionResult) {
            component.set("v.isLoading", false);

            component.set('v.record', component.get('v.recordId'));

            var tasks = actionResult.getReturnValue() || [];
            component.set('v.tasks', tasks);

            // Split into Open vs Completed for clean UI sections
            var openTasks = [];
            var completedTasks = [];

            tasks.forEach(function(t) {
                if (t.Status === 'Completed') {
                    completedTasks.push(t);
                } else {
                    openTasks.push(t);
                }
            });

            component.set('v.openTasks', openTasks);
            component.set('v.completedTasks', completedTasks);
        });

        $A.enqueueAction(action);
    },

    updateTaskStatus: function(component, event) {
        component.set("v.isLoading", true);

        var rowRecord = event.getSource().get('v.value');
        var tid = rowRecord.Id;

        var action = component.get('c.updateDetails');
        action.setParams({
            "lstRecordId": [ tid ]
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var toast = $A.get("e.force:showToast");
                if (toast) {
                    toast.setParams({
                        title: "Task Completed",
                        message: "The task has been marked as completed.",
                        type: "success"
                    });
                    toast.fire();
                }

                $A.get('e.force:refreshView').fire();
            } else {
                console.error(response.getError());

                var toastErr = $A.get("e.force:showToast");
                if (toastErr) {
                    toastErr.setParams({
                        title: "Error",
                        message: "Unable to update task status.",
                        type: "error"
                    });
                    toastErr.fire();
                }
            }
        });

        $A.enqueueAction(action);
    },

    updateTaskOwner: function(component, event){
        let button = event.getSource();
        button.set('v.disabled', true);

        component.set("v.isLoading", true);

        var rid = component.get('v.record');
        var action = component.get('c.updateTaskOwnerFromCaseId');
        action.setParams({
            "recordId": rid
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var toast = $A.get("e.force:showToast");
                if (toast) {
                    toast.setParams({
                        title: "Tasks Assigned",
                        message: "External Customer Support tasks have been assigned to you.",
                        type: "success"
                    });
                    toast.fire();
                }

                $A.get('e.force:refreshView').fire();
            } else {
                console.error(response.getError());

                button.set('v.disabled', false);

                var toastErr = $A.get("e.force:showToast");
                if (toastErr) {
                    toastErr.setParams({
                        title: "Error",
                        message: "Failed to assign tasks. Please try again.",
                        type: "error"
                    });
                    toastErr.fire();
                }
            }
        });

        $A.enqueueAction(action);
    },

    linkToProcedure: function(component, event){
        var link = event.getSource().get('v.name');

        component.find("navigationService").navigate({
            type: "standard__webPage",
            attributes: {
                url: link
            }
        });
    }
})