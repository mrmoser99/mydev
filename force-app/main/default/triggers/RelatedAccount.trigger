/*************************************************************************************
 * Related Account Trigger
 *
 * Change log:
 *
 * 6/10/2022 - MRM removed code to maintain account teams from aar trigger to here;
 * 6/17/2022 - MRM added before update to care of changes to end user account;rare but true
 *
 ********************************************************************************************/

trigger RelatedAccount on Related_Account__c (before insert, before update) {

	if(Trigger.isBefore) {
		RelatedAccountTriggerHelper.helpBeforeInsert(Trigger.new);
	}

}