trigger ProgramTrigger on Program__c (before insert,before update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            ProgramTriggerHelper.helpBeforeInsert((List<Program__c>) Trigger.new);
        }
        if(Trigger.isUpdate) {
            ProgramTriggerHelper.helpBeforeUpdate((Map<Id,Program__c>)Trigger.oldMap, (List<Program__c>) Trigger.new);
        }
    }
}