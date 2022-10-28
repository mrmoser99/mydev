trigger AccountTrigger on Account (before insert, after insert, after update, after delete) {
    if(Trigger.isInsert && Trigger.isBefore){
        AccountTriggerHelper.helperBeforeInsert(Trigger.new);
    }
    if(Trigger.isInsert && Trigger.isAfter){
        AccountTriggerHelper.helperAfterInsert(Trigger.newMap.values());
    }
    if(Trigger.isUpdate) {
        AccountTriggerHelper.helpAfterUpdate((Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
    }
    
    if(Trigger.isDelete) {
        System.debug('test');
        AccountTriggerHelper.helperAfterDelete((Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
    }
    
}