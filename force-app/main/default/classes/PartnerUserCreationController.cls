/**
 * This class is used in Partner Onboarding Flow:
 *  - Creates Partner User based on details provided in Partner Contact Flow (PBI-748297 Partner Onboarding Flow)
 * 
 * @author Udayasree @date July 28, 2022
 * 
 */
public without sharing class PartnerUserCreationController {
    
    /**
    * @description : to get Partner Contact details and created Partner User Record
    * @author Udayasree | July 28, 2022
    * @param partnerContactId, userRole - List of Partner Contact Ids and User Role from LWC Component
    * @return void
    **/
    @AuraEnabled
    public static void createPartnerUserRecord(List<String> partnerContactId, String userRole) {
        updatePartnerAccount(partnerContactId, userRole);
    }
    
    /**
    * @description : method to update partner account
    * @author Sujana Mummadi | Sep 26, 2022
    * @param partnerContactIds, selectedRole - List of Partner Contact Ids and role get from LWC component
    * @return void
    **/   
    public static void updatePartnerAccount(List<String> partnerContactIds, String selectedRole) {
        try{
            Set<Id> accountIds = new Set<Id>();
            Set<String> partnerContactIdSet = new Set<String>();
            partnerContactIdSet.addAll(partnerContactIds);
            List<Account> accountListToUpdate = new List<Account>();
            List<Contact> conList = new WoSSelector().getContactDetails(partnerContactIdSet);
            Map<String, Object>  contactIdsMap = new Map<String, Object>();
            for(Contact conRec : conList){
                contactIdsMap.put(String.valueOf(conRec.Id), conRec);
                if(conRec.Account.IsPartner == false){
                    accountIds.add(conRec.AccountId);
                }
            }

            if(accountIds.size() > 0){
                for(Id accId : accountIds){
                    Account acc = new Account();
                    acc.Id = accId;
                    acc.IsPartner = true;
                    accountListToUpdate.add(acc);
                }
            }
            
            if(accountListToUpdate.size() > 0){
                update accountListToUpdate;
            }
            if(!contactIdsMap.isEmpty()){
                ID jobID = System.enqueueJob(new QueueableCalloutService(Constants.CREATE_USER_IN_SFDC,contactIdsMap));
            }
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, JSON.serialize(partnerContactIds), true);
        }
    }
    /**
    * @description : future method to create Partner User record based on Contact details
    * @author Sujana | Sep 26, 2022
    * @param partnerContactIds, selectedRole - List of Partner Contact Ids and role get from LWC component
    * @return void
    **/   
    public static void createUser(Map<String, Object> reqParams) {
        try{
            List<Contact> conList = new WoSSelector().getContactDetails(reqParams.keyset());
            Id profileId = [SELECT Id, Name FROM Profile WHERE Name =: Constants.NORDICS_PROFILE_NAME].Id;

            List<User> usrList = getUsers(conList, profileId,Constants.USER_REGION, 
                                        Constants.LANGUAGE_LOCALE_KEY, Constants.TIMEZONE_SIDKEY, 
                                        Constants.LANGUAGE_LOCALE_KEY,Constants.EMAIL_ENCODING_KEY);
		    Map<String, Object> userRequest = new Map<String, Object>();
            if(usrList.size() > 0){
                insert usrList;
                for(User usr : usrList){
                    userRequest.put(usr.ContactId, usr);
                }
            }
            if(!userRequest.isEmpty()){
                ID jobID = System.enqueueJob(new QueueableCalloutService(Constants.DUPS_CREATE_CONTACT,userRequest));
            } 
        }catch(Exception e){
        ErrorLogger errorLog = new ErrorLogger();
        errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, null, true);
    }
    }
/**
    * @description  : Method to map user details
    * @author Sujana | 09-21-2022 
    * @param listconatct 
    * @param prodileIdPartner 
    * @param roleIdpartner 
    * @param userRegion 
    * @param language 
    * @param timeZone 
    * @param localeSidKey 
    * @param emailEncodingKey 
    * @return user 
    **/
    public static List<User> getUsers( list<contact> contactList ,  id partnerProfileId , 
                                       string userRegion , string language ,
                                      string timeZone,string localeSidKey,
                                      string emailEncodingKey){ 
            List<User> userList = new List<User>();
            User usr;
            try{
                 for(Contact conRecord : contactList){
                       usr  = new User();
                        usr.FirstName = conRecord.FirstName;
                        usr.LastName = conRecord.LastName;
                        usr.Alias = (conRecord.FirstName.substring(0, 1) + conRecord.LastName.substring(0, 3)).toLowerCase();
                        usr.CommunityNickName = (conRecord.FirstName + conRecord.LastName).toLowerCase();
                        usr.ContactId = conRecord.Id;
                        usr.DB_Region__c = userRegion;
                        usr.Email = conRecord.Email;
                        usr.IsActive = true;
                        usr.LanguageLocaleKey = language;
                        usr.Phone = conRecord.Phone;
                        usr.ProfileId = partnerProfileId;
                        usr.Title = conRecord.Title;
                        usr.Username = conRecord.Email + Constants.USERNAME_SUFFIX;
                        usr.DefaultCurrencyIsoCode = Constants.SWEDISH_CURRENCY;
                        usr.Legal_Entity_Description__c = Constants.DLL;
                        usr.Quick_Calculation_Preference__c = Constants.STANDARD;
                        usr.TimeZoneSidKey = timeZone;
                        usr.LocaleSidKey = localeSidKey;
                        usr.EmailEncodingKey = emailEncodingKey;
                        userList.add(usr);
                    }  
                }catch(Exception e){
                    ErrorLogger errorLog = new ErrorLogger();
                    errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, JSON.serialize(userList), true);
                }  
                return userList;
    }

    /**
    * @description : Method to create request body
    * @author Rohit Pal | 08-30-2022 
    * @param listUsers 
    * @return Map<Id, String> 
    **/
    public static Map<String, Object> createUserOnDups(Map<String,Object> params){
    
        List<User> userList = new WoSSelector().getUserDetails(params.keyset());
        integer totalUserRecs = userList.size();
        
        Map<String, Object> reqParams = new Map<String, Object>();
        try{
        for(integer i= 0 ; i < totalUserRecs ; i++ ){
                Set<String> userIdSet = new Set<String>();
				userIdSet.add(userList[i].Contact.Id);
				
                Map<String, Object> organization = new Map<String, Object>();

				organization.put('name', userList[i].Contact.Account.Name);
				
				Map<String, Object> addressMap = getAddressDetails(userIdSet);
				organization.put('address', addressMap);
				
				Map<String, Object> identifiersMap = getIdentifiersDetails(userIdSet);
				organization.put('identifiers', identifiersMap);
				
				List<Map<String, Object>> identityStores = new List<Map<String, Object>>();
				Map<String, Object> identityStoresMap = getIdentityStoresDetails(userIdSet);
				identityStores.add(identityStoresMap);
				organization.put('identityStores', identityStores);
				
				
				Map<String, Object> user= new Map<String, Object>();
				user.put('givenName', userList[i].FirstName);
            	user.put('familyName', userList[i].LastName);
                user.put('email', userList[i].Email);
                user.put('preferredLocale', Constants.LANGUAGE_KEY);
                user.put('identityStores', identityStores);
                user.put('ContactId', userList[i].Contact.Id);
				
				reqParams.put('organization', organization);
                reqParams.put('user', user);
        }
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, JSON.serialize(params), true);
        }    
        system.debug('params:'+ params);
        return reqParams;
    }
/**
    * @description : Method to get address details for request body
    * @author Sujana Mummadi | 29-09-2022 
    * @param listUsers 
    * @return Map<Id, String> 
    **/    
    public static Map<String, Object> getAddressDetails(set<string> userId){

	List<User> userList = new WoSSelector().getUserDetails(userId);
	Map<String, Object> addressMap = new Map<String, Object>();
		
		for(User usr: userList){
            addressMap.put('street', usr.Contact.Account.BillingStreet);
            addressMap.put('city',usr.Contact.Account.BillingCity);
            addressMap.put('postalCode', usr.Contact.Account.BillingPostalCode);
            addressMap.put('country', usr.Contact.Account.Region_Relationship__r.ISO_Code__c);

		}
	return addressMap;

  }
/**
    * @description : Method to get identifiers details for request body
    * @author Sujana Mummadi | 29-09-2022 
    * @param listUsers 
    * @return Map<Id, String> 
    **/    
    public static Map<String, Object> getIdentifiersDetails(set<string> userId){

		List<User> userList = new WoSSelector().getUserDetails(userId);
		Map<String, Object> identifiersMap = new Map<String, Object>();
			for(User usr: userList){
                List<Map<String, Object>> jurisdictionIdentifiersMap = new List<Map<String, Object>>();
                Map<String, Object> jurisdictionIdentifiersMaps = new Map<String, Object>();
                jurisdictionIdentifiersMaps.put('id', usr.Contact.Account.Org_No__c);
                jurisdictionIdentifiersMap.add(jurisdictionIdentifiersMaps);
				identifiersMap.put('jurisdictionIdentifiers', jurisdictionIdentifiersMap);

			}
		return identifiersMap;

   }
/**
    * @description : Method to get Secondary details for request body
    * @author Sujana Mummadi | 29-09-2022 
    * @param listUsers 
    * @return Map<Id, String> 
    **/    
   public static Map<String, Object> getSecondaryDetails(set<string> userId){

		List<User> userList = new WoSSelector().getUserDetails(userId);
		Map<String, Object> secondaryMap = new Map<String, Object>();
			for(User usr: userList){
                List<Map<String, Object>> organizationLinks = new List<Map<String, Object>>();
				Map<String, Object> organizationLinksMap = new Map<String, Object>();
				organizationLinksMap.put('id', usr.Contact.Account.Id);
				organizationLinksMap.put('name', usr.Contact.Account.Name);
					if(usr.IsActive == true){
						organizationLinksMap.put('status', 'Active');
					}else{
						organizationLinksMap.put('status', 'In Active');
					}
                
                organizationLinks.add(organizationLinksMap);
				
				Map<String, Object> organizationLink = new Map<String, Object>();
                organizationLink.put('id', usr.Contact.Account.Id);
                
                Map<String, Object> usersMap = new Map<String, Object>();
                usersMap.put('id', usr.Id);
                
                organizationLink.put('user',usersMap);
				secondaryMap.put('organizationLink', organizationLink);
				secondaryMap.put('organizationLinks', organizationLinks);

			}
		return secondaryMap;

	}
/**
    * @description : Method to get identity store details for request body
    * @author Sujana Mummadi | 29-09-2022 
    * @param listUsers 
    * @return Map<Id, String> 
    **/    
    public static Map<String, Object> getIdentityStoresDetails(set<string> userId){

		Map<String, Object> identityStoresMap = new Map<String, Object>();

		Map<String, Object> primaryMap = new Map<String, Object>();
            	Map<String, Object> tenantMap = new Map<String, Object>();
                tenantMap.put('name', 'mscb2cparautprd.onmicrosoft.com');
            	primaryMap.put('tenant', tenantMap);
				
		identityStoresMap.put('primary', primaryMap);
		
        List<Map<String, Object>> secondary = new List<Map<String, Object>>();
        Map<String, Object> secondaryMap = getSecondaryDetails(userId);
        secondary.add(secondaryMap);
		identityStoresMap.put('secondary', secondary);
		
		return identityStoresMap;
	}

    /**
    * @description : Method to update contact status based on dups response.
    * @author Sujana Mummadi | 03-10 -2022 
    * @param UserContactId and StatusCode 
    * @return Contact
    **/ 
    public static Contact updatePartnerContact(String userContactId, integer stautsCode) {
        Contact contactRec ;
        try{
            contactRec  = new WoSSelector().getPartnerContact(userContactId);
        if(stautsCode == 200){
            contactRec.Partner_Onboarding_Status__c = 'Success';
        }else{
            contactRec.Partner_Onboarding_Status__c = 'Error';
        }

        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, JSON.serialize(contactRec), true);
        } 
        return contactRec;
    }
    /**
    * @description : Method to create request body for update user in dups
    * @author Sujana Mummadi | 21-10-2022 
    * @param inputWrapper 
    * @return 
    **/       
	@InvocableMethod(label='Update User on Dups' description='Get user details to dups system')
    public static void updatesUserOnDups(List<inputWrapper> request){
        integer totalUserRecs = request.size();
        String Status;
       Map<String, Object> params = new Map<String, Object>();
       
       for(integer i= 0 ; i < totalUserRecs ; i++ ){
            params.put('PathAppended', request.get(i).userEmailId);
            params.put('RecordId', request.get(i).changedRecordId);
			params.put('ContactId', request.get(i).contactId);
            if(String.isNotBlank(request.get(i).changedEmailVal)){
                params.put('Email', request.get(i).changedEmailVal);
                if(!params.isEmpty()){
                    ID jobID = System.enqueueJob(new QueueableCalloutService(Constants.DUPS_DELETE_CONTACT,params));
                    break;
                }
            }

            if(String.isNotBlank(request.get(i).changedFirstNameVal)){
                params.put('FirstName', request.get(i).changedFirstNameVal);
            }

            if(String.isNotBlank(request.get(i).changedLastNameVal)){
                params.put('LastName', request.get(i).changedLastNameVal);
            }
            
            if(String.isNotBlank(request.get(i).changedLocaleVal)){
                params.put('Preferred Locale', request.get(i).changedLocaleVal);
            }
            if(request.get(i).changedStatus == true){
                Status = Constants.ACTIVE;
            }
            else if(request.get(i).changedStatus == false){
                       Status = Constants.IN_ACTIVE; 
            }else{
                Status = '';
            }
            if(Status != ''){
                params.put('Status', Status);
            }
            if(!params.isEmpty()){
                ID jobID = System.enqueueJob(new QueueableCalloutService(Constants.DUPS_UPDATE_CONTACT,params));
            }
        }
        
    }

    /**
    * @description : Wrapper class to serealize data sent from Flow
    * @author Sujana Mummadi | 21-10-2022 
    * @param inputWrapper 
    * @return 
    **/      
    public class InputWrapper{
        @InvocableVariable
        public String changedFirstNameVal;
        
        @InvocableVariable
        public String changedLastNameVal;
        
        @InvocableVariable
        public String changedLocaleVal;
        
        @InvocableVariable
        public Boolean changedStatus;

        @InvocableVariable
        public String changedEmailVal;
        
        @InvocableVariable
        public String changedRecordId;

        @InvocableVariable
        public String userEmailId;
        
        @InvocableVariable
        public String contactId;
        
    } 

     /**
    * @description : Method to invoke create dups user callout when user gets deleted
    * @author Sujana Mummadi | 10-25-2022
    * @param partnerContactIds
    * @return void
    **/   
    public static void getPartnerUserDetails(Set<String> contactIds) {
        List<User> userList = new WoSSelector().getUserDetails(contactIds);
        Map<String, Object> params = new Map<String, Object>();
        for(User usr : userList){
            params.put(usr.ContactId, usr);
            if(!params.isEmpty()){
                ID jobID = System.enqueueJob(new QueueableCalloutService(Constants.DUPS_CREATE_CONTACT,params));
            } 
        }
        
    }
    
    /**
    * @description : Method to update contact record when user gets updated
    * @author Sujana Mummadi | 12-1-2022
    * @param Map<String, Object> params
    * @return void
    **/   
    public static void updatePartnerContactRecord(Map<String, Object> params) {
        String contactId = (String) params.get('ContactId');
        List<Contact> conList = new List<Contact>();
        Contact conRec = new Contact(Id=contactId);
        if(params.containsKey('FirstName')){
            String firstName = (String) params.get('FirstName');
            conRec.FirstName = firstName;
        }
        if(params.containsKey('LastName')){
        String lastName = (String) params.get('LastName');
            conRec.LastName = lastName;
        }
        if(params.containsKey('Email')){
        String email = (String) params.get('Email');
            conRec.Email = email;
        }
        conList.add(conRec);
        if(conList.size() > 0){
            update conList;
        }
    }
    
    /**
    * Inner class-selector
    */
    public without sharing class WoSSelector {
        
        /**
        *Name: getUserDetails
        *Purpose: queries all body parameters from user.  
        */
        public List<User> getUserDetails(Set<String> contactIds) {
            return
                [
                  SELECT
                  Id, FirstName, LastName, Name, Email, LocaleSidKey, IsActive,
                  Contact.Id,
                  Contact.Account.Id,
                  Contact.Account.Name,
                  Contact.Account.Org_No__c,
                  Contact.Account.BillingStreet,
                  Contact.Account.BillingCity,
                  Contact.Account.BillingCountry,
                  Contact.Account.BillingPostalCode,
                  Contact.Account.Region_Relationship__r.ISO_Code__c
                    
                  FROM User
                  WHERE ContactId IN: contactIds
            ];
        }
        
        /**
        *Name: getContactDetails
        *Purpose: queries all body parameters from contact.  
        */
        public List<Contact> getContactDetails(Set<String> contactIds) {
            return 
                [SELECT Id, FirstName, LastName, Email, Phone, Title, 
                 AccountId, Account.Name, Account.IsPartner
                 FROM Contact
                 WHERE Id IN: contactIds];
        }

        /**
        *Name: getPartnerContact
        *Purpose: queries all body parameters from contact.  
        */
        public Contact getPartnerContact(String contactId) {
            return 
                [SELECT Id, Partner_Onboarding_Status__c
                 FROM Contact
                 WHERE Id =: contactId];
        }
    }
    
}