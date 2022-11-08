/*******************************************************************************************************************
 *   Async Apex Sharing
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

}