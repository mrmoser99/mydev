trigger OpportunityTrigger on Opportunity (before insert, after insert, before update){

	new OpportunityTriggerHandler().run();

	if(Trigger.isInsert) {
		if(Trigger.isBefore) {
			OpportunityTriggerHelper.helpBeforeInsert((List<Opportunity>) Trigger.new);
		}else if(Trigger.isInsert) {
			OpportunityTriggerHelper.helpAfterInsert((Map<Id, Opportunity>) Trigger.newMap);
		}
	}else if(Trigger.isUpdate) {
		if(Trigger.isBefore) {
			OpportunityTriggerHelper.helpBeforeUpdate((Map<Id, Opportunity>) Trigger.oldMap, (Map<Id, Opportunity>) Trigger.newMap);
		}
	}

}