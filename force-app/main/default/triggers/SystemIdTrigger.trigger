trigger SystemIdTrigger on System_ID__c (before insert, before update){

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            SystemIdTriggerHelper.helpBeforeInsert((List<System_ID__c>) Trigger.new);
        }else if(Trigger.isUpdate){
            SystemIdTriggerHelper.helpBeforeUpdate((Map<Id, System_ID__c>) Trigger.oldMap, (Map<Id, System_ID__c>) Trigger.newMap);
        }
    }
}