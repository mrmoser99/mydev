/*****************************************************************************************************************
 * Dll on Demaind (DD) CUSTOMER UTILITY CLASS (searches, add...)
 *
 * Change Log:
 *
 *  3/10/2022-  MRM Created class made a without sharing option
 *  4/07/2022 - MRM if opp updated then update quotes with end user
 *******************************************************************************************************************/
public without sharing class CustomerUtilsWithoutSharing {


/************************************************************************************************************************************************
 * udpateCustomerId
 *
 * change log:
 *
 * 12/2/2021 - MRM Created a
 *
 *****************************************************************************************************************************************************/
@AuraEnabled
public static String updateCustomerId(Boolean isOpportunity, String recordId, String customerId){
	Quote q;
	Opportunity o;

	try{
		system.debug('record id is: ' + recordId + '-' + isOpportunity);
		addTeamMember(customerId);
		if (isOpportunity) {
			o = [select id
			     From Opportunity
			     where id = : recordId
			];


			o.end_user__c = customerId;

			List<Quote> qList = [select end_user__c
			                     from Quote
			                     where opportunityId = : o.id
			];

			for (Quote q2:qList) {
				q2.end_user__c = customerId;
			}
			update o;
			update qList;

		}
		else{
			q = [select opportunity.End_User__c, opportunityId
			     from Quote
			     where id = : recordId ];

			List<Opportunity> oList = [select end_user__c
			                           from Opportunity
			                           where id = : q.opportunityId];
			for(Opportunity o2:oLIst) {
				o2.end_user__c = customerId;
			}
			q.end_user__c = customerId;
			update oList;
			update q;

		}



	}
	catch (exception e) {
		return null;
	}

	return 'ok';
}

/************************************************************************************************************************************************
 * manual share edit
 *
 * change log:
 *
 * 2/2/22 - MRM Created
 *
 ****************************************************************************************************************************************************/

public static void addTeamMember(Id customerId){

	AccountTeamMember a = new AccountTeamMember();
	a.AccountId = customerId;
	a.UserId =  UserInfo.getUserId();
	a.accountAccessLevel = 'Read';
	a.TeamMemberRole = 'Partner Admin';
	upsert a;

}




}