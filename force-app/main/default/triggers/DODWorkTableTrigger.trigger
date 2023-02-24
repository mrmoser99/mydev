trigger DODWorkTableTrigger on DOD_API_Worktable__c (before insert, after insert, before update) {
if(Trigger.isInsert) {
    if(Trigger.isBefore) {
      
    }else if(Trigger.isAfter) {
		DODWorkTableTriggerHelper.helpAfterInsert((List<DOD_API_Worktable__c>) Trigger.new);
    }
  }else if(Trigger.isUpdate) {
    if(Trigger.isBefore) {
     
    }
  }

}