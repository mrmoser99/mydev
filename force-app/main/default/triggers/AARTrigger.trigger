/*************************************************************************************
 * AATRIGGER
 *
 * Change log:
 *
 * 3/1/2022 - MRM added before insert for account teams
 * 6/10/2022 - MRM removed code to maintain account teams; moved to related account trigger.
 *
 *
 */
trigger AARTrigger on Account_Account_Relationship__c (before insert, after insert, after delete){



	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			//!!!***************************************************************************!!!
			//!!! Inserting/Updating AARs from Insert Trigger - CAUTION for recursive logic !!!
			//!!!    - Checking that InverseRelation__c is null                             !!!
			//!!!    - Newly inserted AARs will have InverseRelation__c populated           !!!
			//!!!***************************************************************************!!!
			AARTriggerHelper.helpAfterInsert(Trigger.newMap);
		}else if(Trigger.isDelete) {
			AARTriggerHelper.helpAfterDelete(Trigger.old);
		}
	}
}