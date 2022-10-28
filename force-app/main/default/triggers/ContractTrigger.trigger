trigger ContractTrigger on Contract (before insert, after insert, before update){

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            ContractTriggerHelper.helpBeforeInsert((List<Contract>) Trigger.new);
        }else if(Trigger.isUpdate){
            ContractTriggerHelper.helpBeforeUpdate((Map<Id, Contract>) Trigger.oldMap, (Map<Id, Contract>) Trigger.newMap);
        }
    }else if(Trigger.isAfter){
        if(Trigger.isInsert){
            ContractTriggerHelper.helpAfterInsert((Map<Id, Contract>) Trigger.newMap);
        }
    }
}