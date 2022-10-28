/**********************************************************************************************
 * Created by Mark Moser 6/10/2022
 * Change Log:
 *
 * 6/10/2022 - MRM added before insert for dll on demaind account team sharing
 * 6/17/2022 - MRM modified where i get the end user set...now using account account relationship
 **************************************************************************************************/

public without sharing class RelatedAccountTriggerHelper {



public static void helpBeforeInsert(List<Related_Account__c> triggerNew){


	//find the end users touched

	Set<ID> siteSet = new Set<ID>();

	Set<String> endUserSet = new Set<String>();
	for (Related_Account__c r:triggerNew) {
		//if not end user then no one cares
		if (r.type__c == 'End User' )
			if (r.account__c != null)
				endUserSet.add(r.Account__c);
	}

	system.debug('end user set3: ' + endUserSet);
	//get the dealer user from the opportuntiy

	//get all the sites for the end users

	List<Account_Account_Relationship__c> r2List = new List<Account_Account_Relationship__c>();
	r2List = [select account_1__c, account_2__c
	          from Account_Account_Relationship__c
	          where account_2__c in : endUserSet
	          AND Role__c = 'End User'

	];


	//create end user to site map
	Map<ID,Set<ID> > endUserToSiteMap = new Map<ID,Set<ID> >();
	for (Account_Account_Relationship__c r:r2List) {
		siteSet.add(r.account_1__c);
		Set<ID> tempSet = new Set<ID>();
		if (endUserToSiteMap.get(r.Account_2__c) == null) {
			tempSet.add(r.account_1__c);
			endUserToSiteMap.put(r.account_2__c,tempSet);
		}
		else{
			tempSet = endUserToSiteMap.get(r.account_2__c);
			tempSet.add(r.account_1__c);
			endUserToSiteMap.put(r.account_2__c,tempSet);
		}

	}

	system.debug('end user to site map:' + endUserToSiteMap);

	Map<ID,Set<ID> > endUserToContact = new Map<ID,Set<ID> >();

	Map<ID,Set<ID> > siteToContact = new Map<ID,Set<ID> >();

	system.debug('site set is: ' + siteSet);

	List<AccountContactRelation> rList = new List<AccountContactRelation>();
	rList = [select contactId
	         ,accountId
	         ,account.name
	         from AccountContactRelation
	         where accountId in : siteSet
	         and roles = 'Partner Admin'
	];

	Set<ID> contactSet = new Set<ID>();

	system.debug('rlist is : ' + rList);

	for (AccountContactRelation r:rList) {
		Set<ID> tempIdSet = new Set<ID>();
		if (siteToContact.get(r.accountId) == null) {
			tempIdSet.add(r.contactId);
			siteToContact.put(r.accountId,tempIdSet);
		}
		else{
			tempIdSet = siteToContact.get(r.accountId);
			tempIdSet.add(r.contactId);
			siteToContact.put(r.accountId,tempIdSet);
		}

		siteToContact.put(r.accountId,tempIdSet);
		contactSet.add(r.contactId);
	}

	system.debug('siteToContact :' + siteToContact);

	//Now i have a set of each site and the list of contacts associated to that site


	List<User> uList = [select id
	                    ,contactId, isActive
	                    from User
	                    where contactId in : contactSet
                        and IsActive = true
	];

	Map<ID,ID> contactToUserIdMap = new Map<ID,ID>();

	for (User u:uList)
		contactToUserIdMap.put(u.contactId, u.id);

	system.debug('contactToUserIdMap: ' + contactToUserIdMap);

	List<AccountTeamMember> aList = new List<AccountTeamMember>();

	//for each new end user account; grab a list of contacts that need access; then insert an account team record

	for (ID endUser:endUserToSiteMap.keySet()) {   //loop thru end users added
		if (endUserToSiteMap.get(endUser) != null) {
			for (ID eus: endUserToSiteMap.get(endUser)) { //loop thru the sites for the end user
				if (siteToContact.get(eus) != null) {
					for (ID c:siteToContact.get(eus)) { //for each contact related to site

						AccountTeamMember a = new AccountTeamMember();
						a.AccountId = endUser;
						a.UserId =  contactToUserIdMap.get(c);
						a.accountAccessLevel = 'Read';
						a.TeamMemberRole = 'Partner Admin';
						if (a.UserId != null)
							aList.add(a);
					}
				}
			}
		}
	}

	upsert aList;
}
}