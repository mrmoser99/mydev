({

    /*

     * This methid takes recordTypeId and entityTypeName parameters

     * and invoke standard force:createRecord event to create record

     * if recordTypeIs is blank, this will create record under master recordType

     * */

    showCreateRecordModal : function(component, recordTypeId, entityApiName) {

        debugger;

        var createRecordEvent = $A.get("e.force:createRecord");

        if(createRecordEvent){ //checking if the event is supported

            if(recordTypeId){//if recordTypeId is supplied, then set recordTypeId parameter

                    var myRecord = component.get("v.recordId");
                                
                if(myRecord.startsWith('001')){
                
                    createRecordEvent.setParams({
    
                        "entityApiName": entityApiName,
    
                        "recordTypeId": recordTypeId,
    
                        "defaultFieldValues": {
                            
                            "AccountId": myRecord,
                            "Name": "System Generated"               

                    }                    

                });
                }
                    
                else if(myRecord.startsWith('003')){
                
                    var accountId = component.get("v.recordDetail").AccountID;
                                                     
                    createRecordEvent.setParams({
    
                        "entityApiName": entityApiName,
    
                        "recordTypeId": recordTypeId,
    
                        "defaultFieldValues": {
                            
                            "Contact__c": myRecord,
                            "Name": "System Generated",
                            "AccountId": component.get("v.record.fields.AccountId.value")
                        }
                        });
                }
                            
                    else{
                
                        createRecordEvent.setParams({
        
                            "entityApiName": entityApiName,
        
                            "recordTypeId": recordTypeId,
        
                            "defaultFieldValues": {
                                
                                "Name": "System Generated"
                                
                            } 

                });
                }

            } else{//else create record under master recordType

                createRecordEvent.setParams({

                    "entityApiName": entityApiName,

                    "defaultFieldValues": {

                          "AccountId": component.get("v.recordId")

                    }

                });

            }

            createRecordEvent.fire();

        } else{

            alert('This event is not supported');

        }

    },

    

    /*

     * closing quickAction modal window

     * */

    closeModal : function(){

        var closeEvent = $A.get("e.force:closeQuickAction");

        if(closeEvent){

        closeEvent.fire();

        } else{

            alert('force:closeQuickAction event is not supported in this Ligthning Context');

        }

    },

})