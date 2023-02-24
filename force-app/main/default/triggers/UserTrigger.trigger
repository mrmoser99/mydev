trigger UserTrigger on User (before insert, after insert, before update,after update) {
    if(Trigger.isInsert) {
		if(Trigger.isAfter) {
			UserTriggerHelper.helperAfterInsert((List<User>) Trigger.new);
		}
	}else if(Trigger.isUpdate) {
		if(Trigger.isAfter) {
			UserTriggerHelper.helpAfterUpdate((Map<Id, User>) Trigger.oldMap, (Map<Id, User>) Trigger.newMap);
		}
	}



}