/**
 * @description       : 
 * @author            : Mark Moser
 * @group             : 
 * @last modified on  : 03-29-2023
 * @last modified by  : Mark Moser
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   03-29-2023   Mark Moser   Initial Version
**/

trigger RecentPartnerUser on Recent_Partner_User__c (after insert, after update){
    
    if (RecentPartnerUserTriggerHelper.RecentPartnerUserHelperRunning == true){  //check static variable of helper class to preven recursion
        return;
    }
    
    if(Trigger.isInsert) {
		if(Trigger.isAfter) {
        	RecentPartnerUserTriggerHelper.helpAfterInsert(Trigger.new);
		}
	}else if(Trigger.isUpdate) {
		if(Trigger.isAfter) {
        	RecentPartnerUserTriggerHelper.helpAfterUpdate(Trigger.oldMap, Trigger.newMap);
		}
	}
    
}