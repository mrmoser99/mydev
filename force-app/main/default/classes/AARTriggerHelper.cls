/**
 * Created by samuelmeyers on 12/27/18.
 *
 * Change Log:
 * 
 * 3/1/2022 - MRM added before insert for dll on demaind account team sharing
 */ 

public class AARTriggerHelper {

public static void helpAfterInsert(Map<Id, Account_Account_Relationship__c> newAARMap){
	//!!!***************************************************************************!!!
	//!!! Inserting/Updating AARs from Insert Trigger - CAUTION for recursive logic !!!
	//!!!    - Checking that InverseRelation__c is null                             !!!
	//!!!    - Newly inserted AARs will have InverseRelation__c populated           !!!
	//!!!***************************************************************************!!!
	createInverseAARs(newAARMap);
}

public static void helpAfterDelete(List<Account_Account_Relationship__c> oldAARs){
	deleteInverseAARs(oldAARs);
}

public static void createInverseAARs(Map<Id, Account_Account_Relationship__c> aarsById){
	List<Account_Account_Relationship__c> aars = aarsById.values();

	Set<Id> acc1Ids=new Set<Id>();
	Set<Id> acc2Ids=new Set<Id>();

	List<Account_Account_Relationship__c> aarsForInverseCreation = new List<Account_Account_Relationship__c>();

	for(Account_Account_Relationship__c aar : aars) {
		//!!!***************************************************************************!!!
		//!!! Inserting/Updating AARs from Insert Trigger - CAUTION for recursive logic !!!
		//!!!    - Checking that InverseRelation__c is null                             !!!
		//!!!    - Newly inserted AARs will have InverseRelation__c populated           !!!
		//!!!***************************************************************************!!!
		if(aar.Account_1__c != null && aar.Account_2__c != null && aar.InverseRelation__c == null) {
			acc1Ids.add(aar.Account_1__c);
			acc2Ids.add(aar.Account_2__c);
			aarsForInverseCreation.add(aar);
		}
	}

	if(aarsForInverseCreation.size() > 0) {
		List<Account_Account_Relationship__c> aarList=[
			SELECT Id, Account_1__c, Account_2__c
			FROM Account_Account_Relationship__c
			WHERE Account_1__c IN : acc2Ids     //Looking for inverse relations (so acc1 = acc2)
			AND Account_2__c IN : acc1Ids       //Looking for inverse relations (so acc2 = acc1)
			AND Role__c = 'Vendor'              //End User AAR is created in OpportunityTriggerHelper
			              AND InverseRelation__c NOT IN : aarsById.keySet()
		];

		Map<String, Account_Account_Relationship__c> combinationAAR = new Map<String, Account_Account_Relationship__c>();

		if(aarList.size() > 0) {
			for (Account_Account_Relationship__c aar : aarList) {
				combinationAAR.put(aar.Account_1__c + '-' + aar.Account_2__c, aar);
			}
		}

		List<Account_Account_Relationship__c> aarsForInsert = new List<Account_Account_Relationship__c>();
		List<Account_Account_Relationship__c> aarsForUpdate = new List<Account_Account_Relationship__c>();

		for(Account_Account_Relationship__c aar : aarsForInverseCreation) {
			Account_Account_Relationship__c aarMatch = combinationAAR.get(aar.Account_2__c + '-' + aar.Account_1__c);

			if(aarMatch == null) {
				aarMatch = new Account_Account_Relationship__c(
					Account_1__c = aar.Account_2__c,
					Account_2__c = aar.Account_1__c,
					InverseRelation__c = aar.Id,
					Role__c = 'Vendor'
					);
				aarsForInsert.add(aarMatch);
				combinationAAR.put(aarMatch.Account_1__c + '-' + aarMatch.Account_2__c, aarMatch);
			}else{
				aarsForUpdate.add(new Account_Account_Relationship__c(
							  Id = aarMatch.Id,
							  InverseRelation__c =  aar.Id
							  ));
			}
		}

		//!!!***************************************************************************!!!
		//!!! Inserting/Updating AARs from Insert Trigger - CAUTION for recursive logic !!!
		//!!!    - Checking that InverseRelation__c is null                             !!!
		//!!!    - Newly inserted AARs will have InverseRelation__c populated           !!!
		//!!!***************************************************************************!!!
		if(aarsForInsert.size() > 0) {
			insert aarsForInsert;

			for(Account_Account_Relationship__c aar : aarsForInsert) {
				Account_Account_Relationship__c existingAAR = aarsById.get(aar.InverseRelation__c);
				if(existingAAR != null) {
					aarsForUpdate.add(new Account_Account_Relationship__c(
								  Id = existingAAR.Id,
								  InverseRelation__c =  aar.Id
								  ));
				}
			}
		}
		if(aarsForUpdate.size() > 0) {
			update aarsForUpdate;
		}
	}
}

public static void deleteInverseAARs(List<Account_Account_Relationship__c> aars){
	Set<Id> inverseAARIds = new Set<Id>();

	for(Account_Account_Relationship__c aar : aars) {
		if(aar.InverseRelation__c != null) {
			inverseAARIds.add(aar.InverseRelation__c);
		}
	}

	if(inverseAARIds.size() > 0) {
		List<Account_Account_Relationship__c> inverseAARs = [
			SELECT Id
			FROM Account_Account_Relationship__c
			WHERE Id IN : inverseAARIds
		];

		if(inverseAARs.size() > 0) {
			delete inverseAARs;
		}
	}
}


}