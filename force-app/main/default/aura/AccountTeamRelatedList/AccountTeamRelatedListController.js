({
      getList : function(component, event, helper) {
                       
 			helper.getTeamList(component, event, helper);
    },
    
    refreshView : function(component, event, helper){
        helper.refresh(component, event, helper);
    },

    handleRowAction : function(component, event, helper) {
        var recId = event.getParam('row').Id;
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
         if ( actionName == 'edit_member' ) {
            var editMember = $A.get("e.force:editRecord");
            editMember.setParams({
                "recordId": recId
            });
            
            editMember.fire();            
           
        } else if(actionName == 'delete_member'){
            	component.set("v.isModalOpen", true);
            	event.preventDefault();
                var toastEvent = $A.get('e.force:showToast');                
                var deleteRecord = component.get("c.deleteTeamList");
                   deleteRecord.setParams({
                        "memberId": recId,
                        "acctId": component.get("v.recordId")
                    });
                var answer = confirm('Are you sure you want to remove ' + row.User.Name + ' from the Account Team? ');
            	if(answer){$A.enqueueAction(deleteRecord);
                       toastEvent.fire();
                       window.location.reload();}
        }
        },     
 
           
        newMember: function(component, event, helper){
        var createRecordEvent = $A.get("e.force:createRecord");
        var acctIds = component.get("v.recordId");
    	createRecordEvent.setParams({
        "entityApiName": "AccountTeamMember",
        "defaultFieldValues": {'AccountId': acctIds},
        
        });
        createRecordEvent.fire();
        }
    
    })