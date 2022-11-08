/**
 * @description       : Apex class for Set the Credit Application Header fields values.
 * @author            : Kritika Sharma & Surbhi Goyal From Traction on Demand
 * @group             : 
 * @last modified on  : 22-04-2022
 * @last modified by  : Kritika Sharma
**/
public with sharing class CreditApplicationHeaderController {

    @AuraEnabled(cacheable=false)
    public static Boolean UpdateQuoteData( Map<String,string> customerStory , string ownershipInfo, string applicationNo, string applicationStatus,Date applicationDateSubmitted){
        Opportunity oppRecord=[Select Id,Beneficial_Owner_Type__c,Business_Structure__c,Years_in_Business__c,Customer_Story__c,Application_Date__c,Sub_Stage__c, Application_Number__c from Opportunity where Id=:customerStory.get('customerStoryId')];
        oppRecord.Business_Structure__c=customerStory.get('businessStructure');
        if(customerStory.get('yearsInBusiness')!=null && customerStory.get('yearsInBusiness')!=''){
            oppRecord.Years_in_Business__c=decimal.valueof(customerStory.get('yearsInBusiness'));
        } else {
            oppRecord.Years_in_Business__c=null;
        }
        oppRecord.Customer_Story__c=customerStory.get('story');

        if(customerStory.get('amount')!=null && customerStory.get('amount')!='') {
            oppRecord.Amount = Decimal.valueOf(customerStory.get('amount'));
        }
        if(customerStory.get('salesRepId')!=null && customerStory.get('salesRepId')!='') {
            oppRecord.Partner_Sales_Rep__c = customerStory.get('salesRepId');
        }
        if(customerStory.get('location')!=null && customerStory.get('location')!='') {
            oppRecord.AccountId = [SELECT Id, Originating_Site_ID__c from Account where Originating_Site_ID__c = :customerStory.get('location') Limit 1].Id;
        }

        system.debug('ownershipInfo::'+ownershipInfo);
        if(ownershipInfo!= null && ownershipInfo!= '') {
            oppRecord.Beneficial_Owner_Type__c = ownershipInfo;
        }

        // Update the customer authorization
        if(customerStory.get('acceptedCheckbox') == 'true'){
            oppRecord.Customer_Authorization__c = true;
        } else {
            oppRecord.Customer_Authorization__c = false;
        }

        // Update the record
        database.update(oppRecord);
        return true;
    }

    @AuraEnabled // Don't make it cacheable
    public static Boolean UpdateBenefitOwnerData(List<Map<String,string>> benefitOwner, Id opportunityId ){
        Set<Id> contactId=new Set<Id>();
                
        for(integer i=0;i<benefitOwner.size();i++) {           
            contactId.add(benefitOwner[i].get('uboID'));          
        }
        
        List<Contact> contactList=[select Id,Account_Ownership_Percentage__c from Contact where Id In :contactId];
		      
        // Update existing contacts
        for(integer i=0;i<contactList.size();i++) {
            for(integer j=0;j<benefitOwner.size();j++) {
                if(contactList[i].Id == benefitOwner[j].get('uboID')) {

                    contactList[i].AccountId = benefitOwner[j].get('endUserAccount');
                    contactList[i].FirstName=benefitOwner[j].get('firstName');
                    contactList[i].MiddleName=benefitOwner[j].get('middleName');
                    contactList[i].LastName=benefitOwner[j].get('lastName');
                    contactList[i].Title=benefitOwner[j].get('titleValue');

                    // Birthdate Encrypted
                    if(benefitOwner[j].get('dateOfBirthValue') != null && benefitOwner[j].get('dateOfBirthValue') != ''){
                        contactList[i].Birthdate_Encrypted__c = benefitOwner[j].get('dateOfBirthValue');
                    } else {
                        contactList[i].Birthdate_Encrypted__c = null;
                    }

                    contactList[i].UBO_Country_of_Residence__c=benefitOwner[j].get('countryOfResidenceValue');
                    if(benefitOwner[j].get('ownershipPercentageValue')!=null && benefitOwner[j].get('ownershipPercentageValue')!=''){
                        contactList[i].Account_Ownership_Percentage__c=Decimal.valueof(benefitOwner[j].get('ownershipPercentageValue'));//convert percent
                    } else {
                        contactList[i].Account_Ownership_Percentage__c=null;
                    }
                }
            }
        }
		        
        // Update existing contacts
        system.debug('update contactList');
        update contactList;
		        
        // Add new contacts
        Contact c = new Contact();
        List<Contact> newContacts = new List<Contact>();
        for(integer j=0;j<benefitOwner.size();j++) {
            system.debug('uboId::'+benefitOwner[j].get('uboID'));
            if(benefitOwner[j].get('uboID') == null || benefitOwner[j].get('uboID') == '') {
                c = new Contact();
                //c.AccountId = benefitOwner[j].get('endUserAccount');
                c.FirstName=benefitOwner[j].get('firstName');
                c.MiddleName=benefitOwner[j].get('middleName');
                c.LastName=benefitOwner[j].get('lastName');
                c.Title=benefitOwner[j].get('titleValue');

                // Birthdate Encrypted
                if(benefitOwner[j].get('dateOfBirthValue')!=null && benefitOwner[j].get('dateOfBirthValue')!=''){
                    c.Birthdate_Encrypted__c = benefitOwner[j].get('dateOfBirthValue');
                } else {
                    c.Birthdate_Encrypted__c = null;
                }

                c.UBO_Country_of_Residence__c=benefitOwner[j].get('countryOfResidenceValue');
                if(benefitOwner[j].get('ownershipPercentageValue')!=null && benefitOwner[j].get('ownershipPercentageValue')!=''){
                    c.Account_Ownership_Percentage__c=Decimal.valueof(benefitOwner[j].get('ownershipPercentageValue'));//convert percent
                } else {
                    c.Account_Ownership_Percentage__c=null;
                }

                newContacts.add(c);
            }
        }
		        
        // Add new contacts
        if(newContacts.size() > 0) {
            system.debug('insert newContacts');
            insert newContacts;
        }
		       
        // Add the contact roles
        List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
        OpportunityContactRole newCR = new OpportunityContactRole();
        for(integer i=0; i<newContacts.size(); i++) {
            // Add Contact Role
            newCR = new OpportunityContactRole();
            newCR.ContactId = newContacts[i].Id;
            newCR.Role = 'Beneficial Owner';
            newCR.OpportunityId = opportunityId;
            newContactRoles.add(newCR);
        }
        if(newContactRoles.size() > 0){
            system.debug('insert newContactRoles');
            insert newContactRoles;
        }		
        return true;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactField(Id opportunityId){

        system.debug('OpportunityContactRole: ' + opportunityId);

        List<OpportunityContactRole> contactRole = [
                SELECT Id,ContactId,Role,OpportunityId
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Beneficial Owner'
        ];
        system.debug('OpportunityContactRoles: ' + contactRole.size());

        Set<Id> contactIds = new Set<Id>();
        for(integer i=0; i<contactRole.size(); i++) {
            if(contactRole[i].ContactId != null) {
                contactIds.add(contactRole[i].ContactId);
            }
        }

        return [
            SELECT Id
                    ,Account_Ownership_Percentage__c
                    ,AccountId
                    ,Birthdate_Encrypted__c
                    ,firstName
                    ,lastName
                    ,MailingCountry
                    ,MiddleName
                    ,title
                    ,UBO_Country_of_Residence__c
            FROM contact
            WHERE Id = :contactIds
            ORDER BY CreatedDate ASC
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityData(Id opportunityId){
        return [
            SELECT Id,
                Account.BillingCity,
                Account.BillingCountry,
                Account.BillingCounty__c,
                Account.BillingPostalCode,
                Account.BillingStreet,
                Account.Email__c,
                Account.Name,
                Account.Originating_Site_ID__c,
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
                End_User__c,
                End_User__r.BillingCity,
                End_User__r.BillingCountry,
                End_User__r.BillingCounty__c,
                End_User__r.BillingPostalCode,
                End_User__r.BillingStreet,
                End_User__r.Email__c,
                End_User__r.Name,
                End_User__r.Phone,
                End_User__r.Primary_Contact_Name__c,
                End_User__r.Tax_ID__c,
                Frequency__c,
                Interest_Rate__c,
                Lease_Type__c,
                Location__c,
                Nickname__c,
                Partner_Sales_Rep__c,
                Partner_Sales_Rep__r.Name,
                Partner_Status__c,
                Payment_Amount__c,
                Pre_Qualification_Application_Number__c,
                Rate_Type__c,
                Residual_Amount__c,
                Sub_Stage__c,
                Term__c,
                Type,
                Years_in_Business__c,
            	Opportunity_Number__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ]; 
    }
    @AuraEnabled(cacheable=true)
    public static List<Quote_Line__c> getQuoteLineAccessoryData(Id opportunityId){
        try{
            Quote quoteId=[select Id,OpportunityId from Quote  where OpportunityId=:opportunityId and Is_Primary__c=true LIMIT 1];
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
                 WHERE Quote__c = :quoteId.Id
                   AND Equipment_Type__c = 'Add-on'
                ];

                return quoteLineAssets;
        } catch (QueryException e) {
            return new List<Quote_Line__c>();
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Quote_Line__c> getQuoteLineData(Id opportunityId){
        system.debug('getQuoteLineData Method ' +opportunityId);
        try {
            Quote quoteId=[select Id,OpportunityId from Quote  where OpportunityId=:opportunityId and Is_Primary__c=true LIMIT 1];
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
                 WHERE Quote__c = :quoteId.Id
                   AND Equipment_Type__c = 'Asset'
                ];

                return quoteLineAssets;
        } catch (QueryException e) {
            return new List<Quote_Line__c>();
        }

    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> picklistValues(String objectName, String fieldName) {
        Map<String, String> values = new Map<String, String>{};

        List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String>{objectName});

        for (Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.put(entry.getValue(), entry.getLabel());
                }
            }
        }

        return values;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> createPicklistValues(String objectName, String fieldName) {
        Map<String, String> values = new Map<String, String>{};

        string queryString = 'Select Id , ' + fieldName + ' From ' + objectName + ' where ' + fieldName + ' !=Null';
        List<sObject> sobjList = Database.query(queryString);
        Set<String> setOfValues = new Set<string>();
        for (sobject obj : sobjList) {
            setOfValues.add(string.valueof(obj.get(fieldName)));
        }
        for (string val : setOfValues) {
            values.put(val, val);
        }

        return values;
    }

     @AuraEnabled(cacheable=true)
    public static Boolean insertSubmitCreditAppNumber(string appNumber, String oppId){
        Opportunity oppRecord=[Select Id, Application_Number__c from Opportunity where Id=:oppId];

        //Update Application Number coming from MOSIAC
        if(appNumber != null){
            oppRecord.Application_Number__c = appNumber;
        }
        // Update the record
        system.debug('update oppRecord');
        database.update(oppRecord);
        return true;
    }

    @AuraEnabled(cacheable=false)
    public static String getRelatedPartyForOpp(String oppId) {
        try {
            Related_Party__c relatedPartyReturn = [
                SELECT 
                First_Name__c,
                Last_Name__c,
                Middle_Name__c,
                SSN_Encrypted__c
                FROM Related_Party__c
                WHERE (Opportunity__c = :oppId) AND (Type__c = 'Guarantor')
                LIMIT 1];

            return JSON.serialize(relatedPartyReturn);
        } catch (QueryException e) {
			return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean saveRelatedPartyForOpp(String oppId, String firstName, String middleName, String lastName, String ssn) {
        Related_Party__c relatedPartyUpdate;
		if (!String.isEmpty(firstName) && !String.isEmpty(lastName) && !String.isEmpty(ssn)) {
            system.debug('inside if 370');
            try {
                relatedPartyUpdate = [
                    SELECT
                    First_Name__c,
                    Last_Name__c,
                    Middle_Name__c,
                    SSN_Encrypted__c,
                    Opportunity__c,
                    Type__c
                    FROM Related_Party__c
                    WHERE (Opportunity__c = :oppId) AND (Type__c = 'Guarantor')
                    LIMIT 1
                ];
                if (String.isBlank(firstName) && String.isBlank(lastName) && String.isBlank(ssn)) {
                    delete relatedPartyUpdate;
                    return true;
                }
                relatedPartyUpdate.First_Name__c = firstName;
                relatedPartyUpdate.Last_Name__c = lastName;
                relatedPartyUpdate.Middle_Name__c = middleName;
                relatedPartyUpdate.SSN_Encrypted__c = ssn;
                relatedPartyUpdate.Name = firstName + ' ' + lastName;
                update relatedPartyUpdate;
            } catch (Exception e) {
                relatedPartyUpdate = new Related_Party__c();
                relatedPartyUpdate.First_Name__c = firstName;
                relatedPartyUpdate.Last_Name__c = lastName;
                relatedPartyUpdate.Middle_Name__c = middleName;
                relatedPartyUpdate.SSN_Encrypted__c = ssn;
                relatedPartyUpdate.Opportunity__c = oppId;
                relatedPartyUpdate.Name = firstName + ' ' + lastName;
                relatedPartyUpdate.Type__c = 'Guarantor';
                insert relatedPartyUpdate;
            }
    	}

        return true;
    }

    @AuraEnabled(cacheable=false)
     public static Boolean saveRelatedPartyForOpp1(String oppId, String firstName, String middleName, String lastName, String ssn) {
        Related_Party__c relatedPartyUpdate;
         system.debug('string fn' +firstName +ssn);
         ssn = ssn.replace('-','');
          system.debug('string fn' +firstName +ssn);
		if (!String.isEmpty(firstName) && !String.isEmpty(ssn)) {
            system.debug('inside if cross');
            try {
                relatedPartyUpdate = [
                    SELECT
                    First_Name__c,
                    Last_Name__c,
                    Middle_Name__c,
                    SSN_Encrypted__c,
                    Opportunity__c,
                    Type__c
                    FROM Related_Party__c
                    WHERE (Opportunity__c = :oppId) AND (Type__c = 'CrossCorporate')
                    LIMIT 1
                ];
                if (String.isBlank(firstName) && String.isBlank(ssn)) {
                    delete relatedPartyUpdate;
                    return true;
                }
                relatedPartyUpdate.First_Name__c = firstName;
               
                relatedPartyUpdate.SSN_Encrypted__c = ssn;
                relatedPartyUpdate.Name = firstName;
                update relatedPartyUpdate;
            } catch (Exception e) {
                relatedPartyUpdate = new Related_Party__c();
                relatedPartyUpdate.First_Name__c = firstName;
               
                relatedPartyUpdate.SSN_Encrypted__c = ssn;
                relatedPartyUpdate.Opportunity__c = oppId;
                relatedPartyUpdate.Name = firstName;
                relatedPartyUpdate.Type__c = 'CrossCorporate';
                insert relatedPartyUpdate;
            }
    	}

        return true;
    }
    
    //Method to save comments in Addinfo section
    @AuraEnabled(cacheable=false)
    public static boolean saveComments(String comments, Id oppId){
        system.debug('savecomm ' +comments +oppId);
        Opportunity o = new Opportunity();
        o.id = oppId;
        o.Resubmit_Comments__c = comments;
        update o;
        return true;
        
    }

    
    @AuraEnabled(cacheable=false)
    public static String createNewOppForCreditCheck(String location, String amount) {
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
        newOpp.Nickname__c = 'Credit Check';
        if (!String.isBlank(location)) {
            newOpp.AccountId = [SELECT Id, Originating_Site_ID__c from Account where Originating_Site_ID__c = :location Limit 1].Id;
        }
        newOpp.CloseDate = System.today() + 30;
        newOpp.StageName = 'Quoting';
        newOpp.Sub_Stage__c = 'Application Draft';
        newOpp.ForecastCategoryName = 'Omitted';
        newOpp.Amount = decimal.valueOf(amount);
        newOpp.CurrencyIsoCode = 'USD';
        newOpp.Type = 'Credit Check';

        try {
            insert newOpp;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }

        return newOpp.Id;
    }
}