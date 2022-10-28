/**
 * @description       : Apex class for Enrolment.
 * @author            : Kritika Sharma : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 15-06-2022
 * @last modified by  : Kritika Sharma
 *
 *  change log:
 *   07/21/2022 - MRM - Added class to support displaying files from sales support
 *   08/09/2022 - MRM - Fixed null error in get docusign
 *   08/28/2022 - MRM - Added upload document logic
 *   08/29/2022 - MRM - Added delete document method
 * 	 08/30/2022 - MRM - Added logic to download all documents in a package
 *   09/02/2022 - MRM - Added save of passed to funding date
 **/
public with sharing class EnrollController {

@AuraEnabled(cacheable=true)
public static Opportunity getOpportunityData(Id opportunityId){
	Opportunity opp = [
		SELECT Id,
		Account.BillingCity,
		Account.BillingCountry,
		Account.BillingCounty__c,
		Account.BillingPostalCode,
		Account.BillingStreet,
		Account.Email__c,
		Account.Name,
		Account.Phone,
		Account.Primary_Contact_Name__c,
		Account.Tax_ID__c,
		Advance_Payments__c,
		Amount,
		Application_Number__c,
		Beneficial_Owner_Type__c,
		Business_Structure__c,
		Customer_Authorization__c,
		Customer_Name__c,
		Customer_Story__c,
		Passed_To_Funding_Date__c,
		End_User__c,
		End_User__r.BillingStreet,
		End_User__r.BillingCity,
		End_User__r.BillingCountry,
		End_User__r.BillingCounty__c,
		End_User__r.BillingState,
		End_User__r.BillingPostalCode,
		End_User__r.ShippingStreet,
		End_User__r.ShippingCity,
		End_User__r.ShippingCountry,
		End_User__r.ShippingState,
		End_User__r.ShippingPostalCode,
		End_User__r.Email__c,
		End_User__r.Name,
		End_User__r.Phone,
		End_User__r.Primary_Contact_Name__c,
		End_User__r.Tax_ID__c,
		Enrollment_Steps__c,
		Frequency__c,
		Interest_Rate__c,
		Lease_Type__c,
		Location__c,
		Nickname__c,
		Number_of_Assets__c,
		Opportunity_Number__c,
		Partner_Sales_Rep__r.Name,
		Partner_Status__c,
		Payment_Amount__c,
		Rate_Type__c,
		Rental_Amount__c,
		Residual_Amount__c,
		Service_Fee_Total__c,
		Sub_Stage__c,
		StageName,
		Term__c,
		Total_Contract_Payment__c,
		Years_in_Business__c
		FROM Opportunity
		WHERE Id = : opportunityId
		           LIMIT 1
	];

	// Flip the sub-stage if enrollment is starting.
	if(opp.Sub_Stage__c == 'Application Approved' || opp.Sub_Stage__c == 'Conditional Approval') {
		opp.Sub_Stage__c = 'Document Request Draft';
		startOppEnroll(opportunityId, opp.Sub_Stage__c);
	}

	return opp;
}
@AuraEnabled
public static String getFundingDate(String opportunityId){

	Opportunity o = [select Passed_To_Funding_Date__c from Opportunity where id = : opportunityId];

	return o.Passed_To_Funding_Date__c.format();

}

@AuraEnabled
public static Date saveFundingDate(String opportunityId){

	Opportunity o =  [select id
	                  from Opportunity
	                  where id = : opportunityId];

	o.passed_to_funding_date__c = date.today();

	update o;

	return o.passed_to_funding_date__c;
}

@AuraEnabled
public static String saveNewBillingAddress(String opportunityId, List<Map<String,String> > dataToSave){

	try {
		Id accountId = [SELECT End_User__c, Id FROM Opportunity WHERE Id = : opportunityId LIMIT 1].End_User__c;
		Account accToSave = new Account();
		accToSave.Id = accountId;
		if (dataToSave[0].get('addressLineOne') != null && dataToSave[0].get('addressLineOne') != '') {
			accToSave.ShippingStreet = dataToSave[0].get('addressLineOne');
		}
		if (dataToSave[0].get('addressLineTwo') != null && dataToSave[0].get('addressLineTwo') != '') {
			//accToSave.ShippingStreet += ' ';
			accToSave.ShippingStreet = accToSave.ShippingStreet + dataToSave[0].get('addressLineTwo');
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

// Update the opportunity sub-stage
@future
public static void startOppEnroll(Id oppId, String subStage){
	Opportunity opp = new Opportunity();
	opp.Id = oppId;
	opp.Sub_Stage__c = subStage;
	if (opp.Sub_Stage__c == 'Document Request Draft')
		opp.stagename = 'Documentation';
	update opp;
}

@AuraEnabled(cacheable=true)
public static List<Quote_Line__c> getQuoteLineAccessoryData(Id opportunityId){
	List<Quote> quoteId=[select Id,OpportunityId from Quote where OpportunityId=: opportunityId and Is_Primary__c=true LIMIT 1];
	if(quoteId.size() != 0) {
		List<Quote_Line__c> quoteLineAssets = [
			SELECT Id
			,Annual_Hours__c
			,Asset_Type_ITA_Class__c
			,Base_Unit_Sales_Price__c
			,Battery_Included__c
			,Make__c
			,Mast_Type__c
			,Model__c
			,Number_of_Units__c
			,Operating_Environment__c
			,Related_Asset__c
			,Related_Asset__r.Make__c
			,Related_Asset__r.Model__c
			,Subsidy__c
			FROM Quote_Line__c
			WHERE Quote__c = : quoteId[0].Id
			                 AND Equipment_Type__c = 'Add-on'
		];

		return quoteLineAssets;
	} else {
		return new List<Quote_Line__c>();
	}
}
@AuraEnabled(cacheable=true)
public static List<Quote_Line__c> getQuoteLineData(Id opportunityId){
	List<Quote> quoteId=[select Id,OpportunityId from Quote where OpportunityId=: opportunityId and Is_Primary__c=true LIMIT 1];
	if(quoteId.size() != 0) {
		List<Quote_Line__c> quoteLineAssets = [
			SELECT Id
			,Annual_Hours__c
			,Asset_Type_ITA_Class__c
			,Base_Unit_Sales_Price__c
			,Battery_Included__c
			,Make__c
			,Mast_Type__c
			,Model__c
			,Name
			,Number_of_Units__c
			,Operating_Environment__c
			,Quote__c
			,Related_Asset__c
			,Subsidy__c
			FROM Quote_Line__c
			WHERE Quote__c = : quoteId[0].Id
			                 AND Equipment_Type__c = 'Asset'
		];
		return quoteLineAssets;
	} else {
		return new List<Quote_Line__c>();
	}
}

@AuraEnabled(cacheable=true)
public static String getCustomerId(String recordId, Boolean refreshExecute){
	Quote q;
	Opportunity o;
	Boolean isOpportunity;
	String customerId;
	if (recordId.startsWith('006'))
		isOpportunity = true;
	else
		isOpportunity = false;
	try{
		if (isOpportunity) {
			o = [select End_User__c from Opportunity where id = : recordId ];
			customerId = o.End_User__c;
		}
		else{
			q = [select End_User__c from Quote where id = : recordId ];
			customerId = q.End_User__c;
		}
	}
	catch (exception e) {
		return null;
	}
	return customerId;
}

@AuraEnabled(cacheable=true)
public static Map<String, String> createPicklistValues(String objectName, String fieldName, string oppId) {

	Map<String, String> values = new Map<String, String> {};
	string queryString='Select Id , ' + fieldName +' From ' + objectName + ' where '+fieldName + ' !=Null';
	List<sObject> sobjList = Database.query(queryString);
	Set<String> setOfValues=new Set<string>();
	for(sobject obj : sobjList) {
		setOfValues.add(string.valueof(obj.get(fieldName)));
	}
	for(string val : setOfValues) {
		values.put(val, val);
	}

	return values;
}

@AuraEnabled(cacheable=true)
public static List<String> picklistValues(String objectName, String fieldName) {
	List<String> values = new List<String> {};
	List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String> {objectName});
	for(Schema.DescribeSobjectResult res : results) {
		for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				values.add(entry.getValue());
			}
		}
	}
	return values;
}

@AuraEnabled
public static void updateStep(String enrollStep,Id oppId) {
	Opportunity opp=[select Id,Enrollment_Steps__c from opportunity where Id = : oppId limit 1];
	opp.Enrollment_Steps__c=enrollStep;
	update opp;
}

@AuraEnabled(cacheable=true)
public static List<Opportunity_Line_Item__c> getAssetDetails(Id opportunityId){

	List<Opportunity_Line_Item__c> oppLineItemList=[
		SELECT Id,
		Amount__c,
		External_Id__c,
		Line_Item_Type__c,
		Name,
		Opportunity__c,
		Planned_Install_City__c,
		Planned_Install_Date__c,
		Planned_Install_State__c,
		Planned_Install_Street__c,
		Planned_ZIP_Code__c,
		Related_App_Line_Item__c,
		Related_App_Line_Item__r.Amount__c,
		Related_Quote_Line__c,
		Related_Quote_Line__r.Make__c,
		Related_Quote_Line__r.Model__c,
		Serial_Number__c,
		Tax_Exempt__c
		FROM Opportunity_Line_Item__c
		WHERE Line_Item_Type__c = 'Asset'
		                          AND Opportunity__c = : opportunityId
		                                               ORDER BY Name ASC
	];
	return oppLineItemList;
}

@AuraEnabled(cacheable=true)
public static List<Quote_Line__c> getAllQuoteLineData(Id opportunityId ){
	List<Quote> quoteId=[select Id,OpportunityId from Quote where OpportunityId=: opportunityId and Is_Primary__c=true LIMIT 1];
	if(quoteId.size() != 0) {
		List<Quote_Line__c> quoteLineAssets = [
			SELECT Id
			,Annual_Hours__c
			,Asset_Type_ITA_Class__c
			,Base_Unit_Sales_Price__c
			,Battery_Included__c
			,Make__c
			,Mast_Type__c
			,Model__c
			,Name
			,Number_of_Units__c
			,Operating_Environment__c
			,Quote__c
			,Related_Asset__c
			,Subsidy__c
			,Total_Sales_Price_Base__c
			FROM Quote_Line__c
			WHERE Quote__c = : quoteId[0].Id
		];

		return quoteLineAssets;
	} else {
		return new List<Quote_Line__c>();
	}
}

@AuraEnabled
public static void updateAssetDetails(List<Map<String, String> > assetRecords) {

	// Set up the new and existing opportunity line items for assets and fees.
	List<Opportunity_Line_Item__c> oppLineItems = new List<Opportunity_Line_Item__c>();
	List<Opportunity_Line_Item__c> oppLineItemsInsert = new List<Opportunity_Line_Item__c>();
	List<Opportunity_Line_Item__c> oppLineItemsDelete = new List<Opportunity_Line_Item__c>();
	Opportunity_Line_Item__c oppLineItem = new Opportunity_Line_Item__c();

	// Loop through all the assets, process them for updates, and identify service fees.
	for(integer j=0; j<assetRecords.size(); j++) {

		// Start a new asset to be updated.
		oppLineItem = new Opportunity_Line_Item__c();
		oppLineItem.Id = assetRecords[j].get('id');
		oppLineItem.Name = assetRecords[j].get('name');

		// Delivery Date
		if(assetRecords[j].get('deliveryDate') != null && assetRecords[j].get('deliveryDate') != '') {
			List<String> dateFormat = assetRecords[j].get('deliveryDate').split('-');
			oppLineItem.Planned_Install_Date__c = Date.parse(dateFormat[1] + '/' + dateFormat[2] + '/' + dateFormat[0]);
		}

		// Location
		if(assetRecords[j].get('assetLocation') != null && assetRecords[j].get('assetLocation') != '') {
			List<String> addressList = assetRecords[j].get('assetLocation').split(',');

			/*
			   string street = '';
			   for(integer k=addressList.size()-4; k>=0; k--){
			    if(k==0){
			        street = street + addressList[k];
			    }else{
			        street = street + addressList[k] + ' ';
			    }
			   }
			 */

			oppLineItem.Planned_Install_Street__c = addressList[addressList.size()-4];
			oppLineItem.Planned_Install_City__c = addressList[addressList.size()-3];
			oppLineItem.Planned_Install_State__c = addressList[addressList.size()-2];
			oppLineItem.Planned_ZIP_Code__c = addressList[addressList.size()-1];
		}

		// Serial Number
		if(assetRecords[j].get('serialNumber') != null && assetRecords[j].get('serialNumber')!= '') {
			oppLineItem.Serial_Number__c = assetRecords[j].get('serialNumber');
		}

		// Tax Exempt
		oppLineItem.Tax_Exempt__c = Boolean.valueOf(assetRecords[j].get('taxExempt'));

		// Add the asset to the list of opportunity line items to be updated.
		oppLineItems.add(oppLineItem);

		// Handle the related service fee.
		if(assetRecords[j].get('serviceFee') != null && assetRecords[j].get('serviceFee') != '' && decimal.valueOf(assetRecords[j].get('serviceFee')) > 0) {

			oppLineItem = new Opportunity_Line_Item__c();
			oppLineItem.Amount__c = decimal.valueOf(assetRecords[j].get('serviceFee'));
			oppLineItem.Line_Item_Type__c = 'Fee';
			oppLineItem.Name = assetRecords[j].get('name') + ' - Fee';
			oppLineItem.Opportunity__c = assetRecords[j].get('opportunity');
			oppLineItem.Related_App_Line_Item__c = assetRecords[j].get('id');

			// If the service fee record already exists just update it.
			if(assetRecords[j].get('serviceFeeId') != null && assetRecords[j].get('serviceFeeId') != '') {
				oppLineItem.Id = assetRecords[j].get('serviceFeeId');
				oppLineItems.add(oppLineItem);
			}else{
				oppLineItemsInsert.add(oppLineItem);
			}
		}else if(assetRecords[j].get('serviceFeeId') != null && assetRecords[j].get('serviceFeeId') != '') {

			// Handle deletions if a service fee ID exists but the value has been cleared.
			oppLineItem = new Opportunity_Line_Item__c();
			oppLineItem.Id = assetRecords[j].get('serviceFeeId');
			oppLineItemsDelete.add(oppLineItem);
		}
	}

	// Delete any cleared service fees.
	if(oppLineItemsDelete.size() > 0) {
		delete oppLineItemsDelete;
	}

	// Service fee records to insert.
	if(oppLineItemsInsert.size() > 0) {
		insert oppLineItemsInsert;
	}

	// Relate the newly create fee records to the parent asset.
	for(Opportunity_Line_Item__c oppAfterInsert :oppLineItemsInsert) {
		for(Opportunity_Line_Item__c opp :oppLineItems) {
			if(oppAfterInsert.Related_App_Line_Item__c == opp.Id) {
				opp.Related_App_Line_Item__c = oppAfterInsert.Id;
			}
		}
	}

	// Update the parent asset records.
	if(oppLineItems.size() > 0) {
		update oppLineItems;
	}
}

//To get End User Account Name
@AuraEnabled(cacheable=true)
public static Opportunity getEndUserData(Id oppId){
	return [
		SELECT Id,End_User__c,End_User__r.Name FROM Opportunity
		WHERE Id = : oppId
		           LIMIT 1
	];
}

@AuraEnabled
public static string getBillingPreference(String opportunityId){
	try {
		return [SELECT Id, Billing_Address_Preference__c FROM Opportunity WHERE Id = : opportunityId].Billing_Address_Preference__c;
	} catch (Exception e) {
		return 'NotFound';
	}
}

@AuraEnabled
public static String saveBillingPreference(String opportunityId, String selection) {
	Opportunity oppToUpdate = new Opportunity();
	oppToUpdate.Id = opportunityId;

	if (selection == 'true') {
		oppToUpdate.Billing_Address_Preference__c = 'Use existing billing address';
	} else if (selection == 'false') {
		oppToUpdate.Billing_Address_Preference__c = 'Enter new billing address';
	}
	update oppToUpdate;

	return 'true';
}

public class signersAndReviewersData {
@AuraEnabled
public String uboID;
@AuraEnabled
public String Id;
@AuraEnabled
public Integer Account_Ownership_Percentage;
@AuraEnabled
public String AccountId;
@AuraEnabled
public String Birthdate_Encrypted;
@AuraEnabled
public String FirstName;
@AuraEnabled
public String LastName;
@AuraEnabled
public String MiddleName;
@AuraEnabled
public String MailingCountry;
@AuraEnabled
public String Title;
@AuraEnabled
public String Email;
@AuraEnabled
public String UBO_Country_of_Residence;
@AuraEnabled
public String Phone;
}

@AuraEnabled(cacheable=true)
public static List<signersAndReviewersData> getContactField(Id opportunityId){
	List<OpportunityContactRole> contactRole = [
		SELECT Id,ContactId,Role,OpportunityId
		FROM OpportunityContactRole
		WHERE OpportunityId = : opportunityId
		                      AND Role = 'Signer'
	];
	system.debug('Enrol in Financing Contact role: ' + contactRole.size());

	Set<Id> contactIds = new Set<Id>();
	Map<Id, Id> contactToOCRIds = new Map<Id, Id>();
	for(integer i=0; i<contactRole.size(); i++) {
		if(contactRole[i].ContactId != null) {
			contactIds.add(contactRole[i].ContactId);
			contactToOCRIds.put(contactRole[i].ContactId, contactRole[i].Id);
		}
	}
	List<Contact> contacts = [
		SELECT Id
		,Account_Ownership_Percentage__c
		,AccountId
		,Birthdate_Encrypted__c
		,firstName
		,lastName
		,MailingCountry
		,MiddleName
		,title
		,email
		,UBO_Country_of_Residence__c
		FROM contact
		WHERE Id = : contactIds
		           ORDER BY CreatedDate ASC
	];

	List<signersAndReviewersData> returnList = new List<signersAndReviewersData>();
	for (Contact con : contacts) {
		signersAndReviewersData signer = new signersAndReviewersData();
		signer.Id = (String) con.Id;
		signer.uboID = (String) contactToOCRIds.get(con.Id);
		signer.Account_Ownership_Percentage = (Integer) con.Account_Ownership_Percentage__c;
		signer.AccountId = (String) con.AccountId;
		signer.Birthdate_Encrypted = con.Birthdate_Encrypted__c;
		signer.FirstName = con.firstName;
		signer.LastName = con.lastName;
		signer.MiddleName = con.MiddleName;
		signer.Title = con.title;
		signer.Email = con.email;
		signer.UBO_Country_of_Residence = con.UBO_Country_of_Residence__c;
		returnList.add(signer);
	}

	return returnList;
}

@AuraEnabled(cacheable=true)
public static List<signersAndReviewersData> getReviewerField(Id opportunityId){
	List<OpportunityContactRole> contactRole = [
		SELECT Id,ContactId,Role,OpportunityId
		FROM OpportunityContactRole
		WHERE OpportunityId = : opportunityId
		                      AND Role = 'Reviewer'
	];
	system.debug('Enrol in Financing Contact role: ' + contactRole.size());

	Set<Id> contactIds = new Set<Id>();
	Map<Id, Id> contactToOCRIds = new Map<Id, Id>();
	for(integer i=0; i<contactRole.size(); i++) {
		if(contactRole[i].ContactId != null) {
			contactIds.add(contactRole[i].ContactId);
			contactToOCRIds.put(contactRole[i].ContactId, contactRole[i].Id);
		}
	}
	List<Contact> contacts = [
		SELECT Id
		,Account_Ownership_Percentage__c
		,AccountId
		,Birthdate_Encrypted__c
		,firstName
		,lastName
		,MailingCountry
		,MiddleName
		,title
		,email
		,UBO_Country_of_Residence__c
		FROM contact
		WHERE Id = : contactIds
		           ORDER BY CreatedDate ASC
	];

	List<signersAndReviewersData> returnList = new List<signersAndReviewersData>();
	for (Contact con : contacts) {
		signersAndReviewersData signer = new signersAndReviewersData();
		signer.Id = (String) con.Id;
		signer.uboID = (String) contactToOCRIds.get(con.Id);
		signer.Account_Ownership_Percentage = (Integer) con.Account_Ownership_Percentage__c;
		signer.AccountId = (String) con.AccountId;
		signer.Birthdate_Encrypted = con.Birthdate_Encrypted__c;
		signer.FirstName = con.firstName;
		signer.LastName = con.lastName;
		signer.MiddleName = con.MiddleName;
		signer.Title = con.title;
		signer.Email = con.email;
		signer.UBO_Country_of_Residence = con.UBO_Country_of_Residence__c;
		returnList.add(signer);
	}

	return returnList;
}

@AuraEnabled(cacheable=false)
public static Boolean updateSignersDetails(List<Map<String,string> > signersRecords, Id opportunityId) {
	List<Id> signersIds=new List<Id>();
	for(integer i=0; i<signersRecords.size(); i++) {
		signersIds.add(signersRecords[i].get('uboID'));
	}
	system.debug('signers records'+signersRecords);
	List<OpportunityContactRole> contactRoleItemList=[
		SELECT Id
		,ContactId
		,Role
		,OpportunityId
		,Contact.Name
		,Contact.FirstName
		,Contact.LastName
		,Contact.MiddleName
		,Contact.Title
		,Contact.Email
		FROM OpportunityContactRole
		WHERE Id In : signersIds
	];

	List<OpportunityContactRole> oppContactRoleUpdate= new List<OpportunityContactRole>();
	List<Contact> conToUpdate = new List<Contact>();

	for(integer i=0; i<contactRoleItemList.size(); i++) {
		for(integer j=0; j<signersRecords.size(); j++) {
			if(signersRecords[j].get('Id')==contactRoleItemList[i].ContactId) {
				Contact conToAdd = new Contact();
				Boolean changeMade = false;
				conToAdd.Id = contactRoleItemList[i].ContactId;
				if(signersRecords[j].get('firstName') != null && signersRecords[j].get('firstName')!= '') {
					//contactRoleItemList[i].Contact.FirstName=contactRecord[j].get('firstName');
					conToAdd.FirstName = signersRecords[j].get('firstName');
					changeMade = true;
				}
				if(signersRecords[j].get('lastName') != null && signersRecords[j].get('lastName')!= '') {
					//contactRoleItemList[i].Contact.LastName=contactRecord[j].get('lastName');
					conToAdd.LastName=signersRecords[j].get('lastName');
					changeMade = true;
				}
				if(signersRecords[j].get('middleName') != null && signersRecords[j].get('middleName')!= '') {
					//contactRoleItemList[i].Contact.Phone=contactRecord[j].get('phoneNumber');
					conToAdd.MiddleName=signersRecords[j].get('middleName');
					changeMade = true;
				}
				if(signersRecords[j].get('emailValue') != null && signersRecords[j].get('emailValue')!= '') {
					//contactRoleItemList[i].Contact.Email=contactRecord[j].get('email');
					conToAdd.Email=signersRecords[j].get('emailValue');
					changeMade = true;
				}
				if(signersRecords[j].get('titleValue') != null && signersRecords[j].get('titleValue')!= '') {
					//contactRoleItemList[i].Contact.Email=contactRecord[j].get('email');
					conToAdd.Title=signersRecords[j].get('titleValue');
					changeMade = true;
				}
				if (changeMade) {
					conToUpdate.add(conToAdd);
				}
			}
		}
	}

	// Update existing Contact Role
	system.debug('update contact role signers');
	if(conToUpdate.size()!=0) {
		//return JSON.serialize(conToUpdate);
		update conToUpdate;
	} //else {
	  //return 'false';
	  //}

	if (conToUpdate.size() == signersRecords.size()) {
		return true;
	}

	Id accountIdFromOpp;

	try {
		accountIdFromOpp = [SELECT Id, End_User__c FROM Opportunity WHERE Id = : opportunityId LIMIT 1].End_User__c;
	} catch (Exception e) {
		accountIdFromOpp = '';
	}

	// Add new contacts
	Contact oppContactRole = new Contact();
	List<Contact> newContacts = new List<Contact>();
	for(Integer j=0; j<signersRecords.size(); j++) {
		system.debug('uboId::'+signersRecords[j].get('uboID'));
		if(signersRecords[j].get('uboID') == null || signersRecords[j].get('uboID') == '') {
			oppContactRole = new Contact();
			oppContactRole.AccountId = accountIdFromOpp;
			oppContactRole.FirstName=signersRecords[j].get('firstName');
			oppContactRole.MiddleName=signersRecords[j].get('middleName');
			oppContactRole.LastName=signersRecords[j].get('lastName');
			oppContactRole.Title=signersRecords[j].get('titleValue');
			oppContactRole.Email=signersRecords[j].get('emailValue');

			newContacts.add(oppContactRole);
		}
	}

	// Add new contact role for signers
	system.debug('insert new Contacts Role for signers');
	if(newContacts.size() > 0) {
		system.debug('insert new Contacts Role for signers');
		insert newContacts;
	}

	// Add the contact roles
	List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
	OpportunityContactRole newCR = new OpportunityContactRole();
	for(integer i=0; i<newContacts.size(); i++) {
		// Add Contact Role
		newCR = new OpportunityContactRole();
		newCR.ContactId = newContacts[i].Id;
		newCR.Role = 'Signer';
		newCR.OpportunityId = opportunityId;
		newContactRoles.add(newCR);
	}
	if(newContactRoles.size() > 0) {
		system.debug('insert newContactRoles');
		insert newContactRoles;
	}

	return true;
}

@AuraEnabled
public static Boolean updateReviewersDetails(List<map<string,string> > reviewersRecords, Id opportunityId) {
	List<Id> reviewersIds=new List<Id>();
	for(integer i=0; i<reviewersRecords.size(); i++) {
		reviewersIds.add(reviewersRecords[i].get('uboID'));
	}
	system.debug('Reviewers records'+reviewersRecords);
	List<OpportunityContactRole> contactRoleItemList=[
		SELECT Id
		,ContactId
		,Role
		,OpportunityId
		,Contact.Name
		,Contact.FirstName
		,Contact.LastName
		,Contact.MiddleName
		,Contact.Title
		,Contact.Email
		FROM OpportunityContactRole
		WHERE Id In : reviewersIds
	];

	List<OpportunityContactRole> oppContactRoleUpdate= new List<OpportunityContactRole>();
	List<Contact> conToUpdate = new List<Contact>();

	for(integer i=0; i<contactRoleItemList.size(); i++) {
		for(integer j=0; j<reviewersRecords.size(); j++) {
			if(reviewersRecords[j].get('Id')==contactRoleItemList[i].ContactId) {
				Contact conToAdd = new Contact();
				Boolean changeMade = false;
				conToAdd.Id = contactRoleItemList[i].ContactId;
				if(reviewersRecords[j].get('firstName') != null && reviewersRecords[j].get('firstName')!= '') {
					//contactRoleItemList[i].Contact.FirstName=contactRecord[j].get('firstName');
					conToAdd.FirstName = reviewersRecords[j].get('firstName');
					changeMade = true;
				}
				if(reviewersRecords[j].get('lastName') != null && reviewersRecords[j].get('lastName')!= '') {
					//contactRoleItemList[i].Contact.LastName=contactRecord[j].get('lastName');
					conToAdd.LastName=reviewersRecords[j].get('lastName');
					changeMade = true;
				}
				if(reviewersRecords[j].get('middleName') != null && reviewersRecords[j].get('middleName')!= '') {
					//contactRoleItemList[i].Contact.Phone=contactRecord[j].get('phoneNumber');
					conToAdd.MiddleName=reviewersRecords[j].get('middleName');
					changeMade = true;
				}
				if(reviewersRecords[j].get('emailValue') != null && reviewersRecords[j].get('emailValue')!= '') {
					//contactRoleItemList[i].Contact.Email=contactRecord[j].get('email');
					conToAdd.Email=reviewersRecords[j].get('emailValue');
					changeMade = true;
				}
				if(reviewersRecords[j].get('titleValue') != null && reviewersRecords[j].get('titleValue')!= '') {
					//contactRoleItemList[i].Contact.Email=contactRecord[j].get('email');
					conToAdd.Title=reviewersRecords[j].get('titleValue');
					changeMade = true;
				}
				if (changeMade) {
					conToUpdate.add(conToAdd);
				}
			}
		}
	}
	// Update existing Contact Role
	system.debug('update contact role Reviewers');
	if(conToUpdate.size()!=0) {
		update conToUpdate;
	}

	Id accountIdFromOpp;

	try {
		accountIdFromOpp = [SELECT Id, End_User__c FROM Opportunity WHERE Id = : opportunityId LIMIT 1].End_User__c;
	} catch (Exception e) {
		accountIdFromOpp = '';
	}

	// Add new contacts
	Contact oppContactRole = new Contact();
	List<Contact> newContacts = new List<Contact>();
	for(Integer j=0; j<reviewersRecords.size(); j++) {
		system.debug('uboId::'+reviewersRecords[j].get('uboID'));
		if(reviewersRecords[j].get('uboID') == null || reviewersRecords[j].get('uboID') == '') {
			oppContactRole = new Contact();
			oppContactRole.AccountId = accountIdFromOpp;
			oppContactRole.FirstName=reviewersRecords[j].get('firstName');
			oppContactRole.MiddleName=reviewersRecords[j].get('middleName');
			oppContactRole.LastName=reviewersRecords[j].get('lastName');
			oppContactRole.Title=reviewersRecords[j].get('titleValue');
			oppContactRole.Email=reviewersRecords[j].get('emailValue');

			newContacts.add(oppContactRole);
		}
	}

	// Add new contact role for Reviewers
	system.debug('insert new Contacts Role for Reviewers');
	if(newContacts.size() > 0) {
		system.debug('insert new Contacts Role for Reviewers');
		insert newContacts;
	}

	// Add the contact roles
	List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
	OpportunityContactRole newCR = new OpportunityContactRole();
	for(integer i=0; i<newContacts.size(); i++) {
		// Add Contact Role
		newCR = new OpportunityContactRole();
		newCR.ContactId = newContacts[i].Id;
		newCR.Role = 'Reviewer';
		newCR.OpportunityId = opportunityId;
		newContactRoles.add(newCR);
	}
	if(newContactRoles.size() > 0) {
		system.debug('insert newContactRoles');
		insert newContactRoles;
	}

	return true;
}

@AuraEnabled
public static signersAndReviewersData getBillingContactData(Id opportunityId){
	OpportunityContactRole contactRoleItemList;
	try {
		contactRoleItemList=[
			SELECT Id
			,Role
			,ContactId
			,Contact.FirstName
			,Contact.LastName
			,Contact.Phone
			,Contact.Email
			FROM OpportunityContactRole
			WHERE OpportunityId = : opportunityId
			                      AND Role = 'Billing Contact'
			                                 LIMIT 1
		];
	} catch (Exception e) {
		signersAndReviewersData emptyData = new signersAndReviewersData();
		emptyData.Id = 'no contact found';
		return emptyData;
	}

	signersAndReviewersData returnValue = new signersAndReviewersData();
	returnValue.FirstName = contactRoleItemList.Contact.FirstName;
	returnValue.LastName = contactRoleItemList.Contact.LastName;
	returnValue.Phone = contactRoleItemList.Contact.Phone;
	returnValue.Email = contactRoleItemList.Contact.Email;
	returnValue.uboID = contactRoleItemList.Id;
	returnValue.Id = contactRoleItemList.ContactId;
	return returnValue;
}

@AuraEnabled
public static Boolean updateContactRoleData(List<map<string,string> > contactRecord,Id opportunityId){
	List<Id> contactRecordIds=new List<Id>();
	for(integer i=0; i<contactRecord.size(); i++) {
		contactRecordIds.add(contactRecord[i].get('uboID'));
	}
	system.debug('contact role records'+contactRecord);
	List<OpportunityContactRole> contactRoleItemList=[
		SELECT Id
		,ContactId
		,Role
		,OpportunityId
		,Contact.Name
		,Contact.FirstName
		,Contact.LastName
		,Contact.Phone
		,Contact.Email
		FROM OpportunityContactRole
		WHERE Id IN : contactRecordIds
	];

	List<Contact> conToUpdate = new List<Contact>();

	for(integer i=0; i<contactRoleItemList.size(); i++) {
		for(integer j=0; j<contactRecord.size(); j++) {
			if(contactRecord[j].get('Id')==contactRoleItemList[i].ContactId) {
				Contact conToAdd = new Contact();
				Boolean changeMade = false;
				conToAdd.Id = contactRoleItemList[i].ContactId;
				if(contactRecord[j].get('firstName') != null && contactRecord[j].get('firstName')!= '') {
					//contactRoleItemList[i].Contact.FirstName=contactRecord[j].get('firstName');
					conToAdd.FirstName = contactRecord[j].get('firstName');
					changeMade = true;
				}
				if(contactRecord[j].get('lastName') != null && contactRecord[j].get('lastName')!= '') {
					//contactRoleItemList[i].Contact.LastName=contactRecord[j].get('lastName');
					conToAdd.LastName=contactRecord[j].get('lastName');
					changeMade = true;
				}
				if(contactRecord[j].get('phoneNumber') != null && contactRecord[j].get('phoneNumber')!= '') {
					//contactRoleItemList[i].Contact.Phone=contactRecord[j].get('phoneNumber');
					conToAdd.Phone=contactRecord[j].get('phoneNumber');
					changeMade = true;
				}
				if(contactRecord[j].get('email') != null && contactRecord[j].get('email')!= '') {
					//contactRoleItemList[i].Contact.Email=contactRecord[j].get('email');
					conToAdd.Email=contactRecord[j].get('email');
					changeMade = true;
				}
				if (changeMade) {
					conToUpdate.add(conToAdd);
				}
			}
		}
	}
	// Update existing Contact Role
	system.debug('update contact role signers');
	if(conToUpdate.size()!=0) {
		update conToUpdate;
	}

	Id accountIdFromOpp;

	try {
		accountIdFromOpp = [SELECT Id, End_User__c FROM Opportunity WHERE Id = : opportunityId LIMIT 1].End_User__c;
	} catch (Exception e) {
		accountIdFromOpp = '';
	}

	// Add new contacts
	Contact oppContactRole = new Contact();
	List<Contact> newContacts = new List<Contact>();
	for(Integer j=0; j<contactRecord.size(); j++) {
		system.debug('uboId::'+contactRecord[j].get('uboID'));
		if(contactRecord[j].get('uboID') == null || contactRecord[j].get('uboID') == '') {
			oppContactRole = new Contact();
			oppContactRole.AccountId = accountIdFromOpp;
			oppContactRole.FirstName=contactRecord[j].get('firstName');
			//oppContactRole.MiddleName=contactRecord[j].get('middleName');
			oppContactRole.LastName=contactRecord[j].get('lastName');
			oppContactRole.Phone=contactRecord[j].get('phoneNumber');
			oppContactRole.Email=contactRecord[j].get('email');

			newContacts.add(oppContactRole);
		}
	}

	// Add new contact role for signers
	system.debug('insert new Contacts Role for signers');
	if(newContacts.size() > 0) {
		system.debug('insert new Contacts Role for signers');
		insert newContacts;
	}

	// Add the contact roles
	List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
	OpportunityContactRole newCR = new OpportunityContactRole();
	for(integer i=0; i<newContacts.size(); i++) {
		// Add Contact Role
		newCR = new OpportunityContactRole();
		newCR.ContactId = newContacts[i].Id;
		newCR.Role = 'Billing Contact';
		newCR.OpportunityId = opportunityId;
		newContactRoles.add(newCR);
	}
	if(newContactRoles.size() > 0) {
		system.debug('insert newContactRoles');
		insert newContactRoles;
	}
	return true;
}

@AuraEnabled
public static void saveDocusignToOpp(String opportunityId, String docusign) {
	Opportunity opp = new Opportunity();
	opp.Id = opportunityId;
	if (docusign.toLowerCase() == 'false') {
		opp.Document_Delivery_Preference__c = 'PDF';
	} else {
		opp.Document_Delivery_Preference__c = 'Docusign';
	}
	update opp;
}


@AuraEnabled
public static string deleteContentDocument(String recordId) {

	system.debug('trying to delete the document');
	try{
		ContentDocument c = [select id from ContentDocument where id = : recordId];
		delete c;
		return 'ok';
	}
	catch (exception e) {
		return string.valueOf(e);
	}

}

@AuraEnabled(cacheable=true)
public static Map<ID, String> getRelatedFilesByRecordId(String recordId, String docType) {
	// Get record file IDs
	List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : recordId];
	List<ID> fileIDs = new List<ID>();
	for (ContentDocumentLink docLink : files) {
		fileIDs.add(docLink.ContentDocumentId);
	}

	List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title
	                             FROM ContentVersion WHERE ContentDocumentId IN : fileIDs
	                             and Document_Source__c = : docType];
	Map<ID, String> mapIdTitle = new Map<ID, String>();
	for (ContentVersion docLink : docs) {
		mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
	}
	return mapIdTitle;
}

@AuraEnabled(cacheable=true)
public static String getZipUrl(String recordId) {
	// Get record file IDs
	String url;
	system.debug('record id:' + recordId);
	List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : recordId];
	List<ID> fileIDs = new List<ID>();
	for (ContentDocumentLink docLink : files) {
		fileIDs.add(docLink.ContentDocumentId);
	}

	List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title
	                             FROM ContentVersion WHERE ContentDocumentId IN : fileIDs
	                             and Document_Source__c = 'Sales Support'];
	Map<ID, String> mapIdTitle = new Map<ID, String>();

	url = '/sfc/servlet.shepherd/version/download';
	for (ContentVersion docLink : docs) {
		url += '/' + docLink.id;
	}
	url += '?';

	return url;
}

@AuraEnabled
//mrm fixed to check for null
public static String getDocusignValueFromOpp(String opportunityId) {
	String resultAsBool = [SELECT Id, Document_Delivery_Preference__c FROM Opportunity WHERE Id = : opportunityId LIMIT 1].Document_Delivery_Preference__c;
	if (resultAsBool != null) {
		if (resultAsBool.toLowerCase() == 'docusign') {
			return 'true';
		}
		else
			return 'false';
	}
	else {
		return 'false';
	}


}



}