({

    getTeamList : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Team Member', fieldName: 'UserName', type: 'text', class: 'boldme'},
            {label: 'Role', fieldName: 'TeamMemberRole', type: 'text', cellAttributes:{class: 'boldme'}},
          //  {label: 'Title', fieldName: 'Title', type: 'text', class: 'table-test'},
            {label: '', type: 'button', initialWidth: 50, typeAttributes:
             { label: { fieldName: 'actionLabel'},variant:"base", title: 'Edit', name: 'edit_member', iconName: 'action:edit'}},
            {label: '', type: 'button', initialWidth: 50, typeAttributes:
             { label: { fieldName: 'actionLabel'},variant:"base", type: 'submit', title: 'Delete', name: 'delete_member', iconName: 'action:delete'}},
                    
            ]);
                            
        var action = component.get("c.getAccountTeamsList");
        action.setParams({
            accountId: component.get("v.recordId")
        });
        // Callback function to get the response
        action.setCallback(this, function(response) {
            // Getting the response state
            var state = response.getState();
            // Check if response state is success
            if(state === 'SUCCESS') {
                // Getting the list of account team members from response and storing in js variable
                var teamList = response.getReturnValue();
                // Set the list attribute in component with the value returned by function
                for (var i = 0; i< teamList.length; i++) {
                    var row = teamList[i];
                    if (row.UserId) row.UserName = row.User.Name;
                   
            }
            
                 component.set("v.accountteammembers",teamList);
            }
            else {
                // Show an alert if the state is incomplete or error
                alert('Error in getting data');
            }
        });
        // Adding the action variable to the global action queue
        $A.enqueueAction(action);
     
    },
        
        refresh : function(component, event, helper) {
            var action = component.get('c.getAccountTeamsList');
            action.setParams({
                    accountId: component.get("v.recordId")
                });
            action.setCallback(this, function(response) {
            // Getting the response state
            var state = response.getState();
            // Check if response state is success
            if(state === 'SUCCESS') {
                // Getting the list of account team members from response and storing in js variable
                var teamList = response.getReturnValue();
                // Set the list attribute in component with the value returned by function
                for (var i = 0; i< teamList.length; i++) {
                    var row = teamList[i];
                    if (row.UserId) row.UserName = row.User.Name;
                   
            }
            
                 component.set("v.accountteammembers",teamList);
            }
            else {
                // Show an alert if the state is incomplete or error
                alert('Error in getting data');
            }
        });
        // Adding the action variable to the global action queue
        $A.enqueueAction(action);
        }

})