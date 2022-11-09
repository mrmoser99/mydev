/*******************************************************************************************************************
 *   Async Apex Sharing - if the old owner was a partner admin then share this record with them.  interface changes
 *						the owner to the salesperson.  
 *
 *
 *	Change Log:
 *	10/29/2022 - MRM Created 
 *
 ********************************************************************************************************************/
public without sharing class  AsyncApexSharing implements Queueable {

Map<ID,ID> oppOwnerMap = new Map<ID,ID>();
Set<ID> oldOwner = new Set<ID>();
Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();

public AsyncApexSharing(Map<ID,ID> oppOwnerMap, Set<ID> oldOwner,Map<Id, Opportunity> oldOppMap)
{
	this.oppOwnerMap = oppOwnerMap;
	this.oldOwner = oldOwner;
	this.oldOppMap = oldOppMap;
}

public void execute(QueueableContext context) {
	try{
		Set<ID> dodUser = new Set<ID>();

		List<User> uList = [select profile.name from User where id in : oldOwner];
		for (User u:uList) {
			if (u.profile.name == 'Partner Admin'){
				dodUser.add(u.id);
			}
		}

		List<OpportunityShare> oppShares = new List<OpportunityShare>();

		for (ID oppId : oldOppMap.keySet()) {
			if (dodUser.contains(oppOwnerMap.get(oppId))) {

				OpportunityShare oppShare = new OpportunityShare();
				oppshare.opportunityId = oppId;
				oppShare.UserOrGroupId = oppOwnerMap.get(oppId);
		 		oppShare.OpportunityAccessLevel = 'Edit';
				oppShares.add(oppShare);

			}
		}

		if (!oppShares.isEmpty()) {
			insert oppShares;
		}

	}
	catch (Exception e) {

		Error_Log__c el = new Error_Log__c();
		el.callout_name__c = 'AsyncApexSharing';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'AsyncApexSharing';
		el.Request_body__c = string.valueOf(oldOppMap);
		el.Method_Name__c = 'AsyncApexSharing';
		el.status_code__c = 900;
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = string.valueOf(e) + '-' + e.getMessage();
		insert el;

	}


}

}