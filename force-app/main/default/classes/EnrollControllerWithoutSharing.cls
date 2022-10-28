public without sharing class EnrollControllerWithoutSharing {
@AuraEnabled
public static String saveNewBillingAddress(String opportunityId, List<Map<String,String>> dataToSave){

	try {
		Id accountId = [SELECT End_User__c, Id FROM Opportunity WHERE Id = : opportunityId LIMIT 1].End_User__c;
		Account accToSave = new Account();
		accToSave.Id = accountId;
		if (dataToSave[0].get('addressLineOne') != null && dataToSave[0].get('addressLineOne') != '') {
			accToSave.ShippingStreet = dataToSave[0].get('addressLineOne');
		}
		if (dataToSave[0].get('addressLineTwo') != null && dataToSave[0].get('addressLineTwo') != '') {
			accToSave.ShippingStreet += dataToSave[0].get('addressLineTwo');
		}
		if (dataToSave[0].get('city') != null && dataToSave[0].get('city') != '') {
			accToSave.ShippingCity = dataToSave[0].get('city');
		}
		if (dataToSave[0].get('state') != null && dataToSave[0].get('state') != '') {
			accToSave.ShippingState = dataToSave[0].get('state');
		}
		if (dataToSave[0].get('country') != null && dataToSave[0].get('country') != '') {
			accToSave.ShippingCountry = dataToSave[0].get('country');
		}
		if (dataToSave[0].get('ZIPCode') != null && dataToSave[0].get('ZIPCode') != '') {
			accToSave.ShippingPostalCode = dataToSave[0].get('ZIPCode');
		}
		update accToSave;
	} catch (Exception e) {
		return e.getMessage();
	}
	
	return 'true';
}
}