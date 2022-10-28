/**
 * @create: by Traction Team on 04/27/2020
 * 
 */
trigger CustomContractTrigger on Contract__c(before insert, after insert){
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            CustomContractTriggerHelper.helpBeforeInsert((List<Contract__c>) Trigger.new);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            CustomContractTriggerHelper.helpAfterInsert((Map<Id, Contract__c>) Trigger.newMap);
        }
    }
}