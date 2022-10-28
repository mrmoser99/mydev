/**
 * Class implements the controller logic for Contract Generation
 * @author Anujit (Cognizant)
 * @date 2021-03-09
 */
public with sharing class ContractGenerationController {
   

    /**
     * Name: getCustomerDetails
     * @return JSON string containing the details of the customer
     */
    @AuraEnabled
    public static String getCustomerDetails(String quoteId) {
        return JSON.serialize(getCustomerDetailsById(quoteId));      
    }

   /**
     * Name: getCustomerDetailsById
     * @return ContractGenerationWrapperClass containing the details of the customer and special T&C
     */  
    private static ContractGenerationWrapperClass getCustomerDetailsById(String quoteId) {
        Quote quoteRecord = new WoSSelector().getQuoteById(quoteId);
        List<Related_Party__c> relatedPartyList = new List<Related_Party__c>();
        
        if(quoteRecord.Status == 'Approved With Conditions'){
           relatedPartyList = new WoSSelector().getRelatedPartyList(quoteId);
        }
        
        List<Offer_Special_Terms_Conditions__c> offerSpTnCList = new WoSSelector().getOfferSpclCondtionsById(quoteRecord);
        Set<Id> quoteSTnCIds = new Set<Id>();

        for (Applicable_Special_Terms_and_Conditions__c appSTnCItem : quoteRecord.Applicable_Special_Terms_and_Conditions__r) {
            quoteSTnCIds.add(appSTnCItem.Special_Terms_and_Conditions__c);
        }

        ContractGenerationWrapperClass contractGenWrCls = new ContractGenerationWrapperClass(
                                                            quoteRecord.Opportunity.End_User__c,
                                                            quoteRecord.Opportunity.End_User__r.External_Identifier__c,
                                                            quoteRecord.Opportunity.End_User__r.Name,
                                                            quoteRecord.Opportunity.End_User__r.BillingStreet + ', ' + quoteRecord.Opportunity.End_User__r.BillingCity,
                                                            quoteRecord.Opportunity.End_User__r.BillingPostalCode,
                                                            quoteRecord.Applicable_Offers__r.Offer__r.Insurance_Display_Options__c,
             												quoteRecord.Applicable_Offers__r.Offer__r.Default_Insurance__c,             
                                                            offerSpTnCList,
                                                            quoteSTnCIds,
                                                            quoteRecord.Contact.Name,
                                                            quoteRecord.Contact.Email,
                                                            quoteRecord.Contact.Phone,
                                                            quoteRecord.ShippingStreet,
                                                            quoteRecord.ShippingPostalCode,
                                                            quoteRecord.ShippingCity,
                                                            quoteRecord.Reference__c,
                                                            quoteRecord.Insurance_Display_Options__c,
            												relatedPartyList,
            												quoteRecord.Status,
            												quoteRecord.Type_downpayment__c,
															quoteRecord.Value_downpayment__c, 
            												quoteRecord.Value_term__c,
            												quoteRecord.Opportunity.Name
                                                        );
                                                        
        
        return contractGenWrCls;              
    }

    /**
    * Name: genSmartcommDoc_CreateCont_Quote
    * @return boolean 
    * Purpose: pass the contact & quote details for dml
    */ 
    @AuraEnabled
    public static string createCont_Quote(string contactAddressDetails){
       
        string contactId = '';
        string quoteId = '';
        if(String.isNotBlank(contactAddressDetails)){
            ContactAddressWrapperClass contactAddresObj = (ContactAddressWrapperClass)System.JSON.deserialize(contactAddressDetails, ContactAddressWrapperClass.class);
            //create contact and update quote
            contactId = createContact(contactAddresObj);
            quoteId = updateQuote(contactAddresObj,contactId);                   
        }
        return contactId+quoteId;
    }
    
    
     /**
    * Name: genSmartCommDoc
    * @return void 
    * Purpose: call smartcomm class to generate documents
    */ 
    @AuraEnabled
    public static void genSmartCommDoc(string contactAddressDetails,id behaveOnUserId){
       
        if(String.isNotBlank(contactAddressDetails)){
            ContactAddressWrapperClass contactAddresObj = (ContactAddressWrapperClass)System.JSON.deserialize(contactAddressDetails, ContactAddressWrapperClass.class);
            	//Delete all previously generated files before generate smartComm Documents
            	GenericUtilityClass.deleteAttachments(new Set<Id>{contactAddresObj.quoteId});
                //smartcomm doc generation code
                SmartCommHelper.SmartCommDocParam smartCommDocObj = new SmartCommHelper.SmartCommDocParam();
                smartCommDocObj.quoteID = contactAddresObj.quoteId;
                smartCommDocObj.salesContactPerson = UserInfo.getFirstName()+' '+UserInfo.getLastName();
                smartCommDocObj.insuranceCondition = contactAddresObj.insuranceCondition;
                smartCommDocObj.Reference = contactAddresObj.contactReference;
            	smartCommDocObj.behaveOnUserId = behaveOnUserId;
                String docParamString = JSON.serialize(smartCommDocObj);
                SmartCommHelper.getSmartCommDocuments(docParamString,false); //send to smartcomm   
                              
        }
        //return contactId+quoteId;
    }
    

    /**
     * Name: createContact
     * @return string  
     * Purpose: to create contact
     */ 
    @Testvisible
    private static string createContact(ContactAddressWrapperClass contactAddresObj){
         if(!(GenericUtilityClass.isSafeObject('Contact'))){
             return null;
         }else{
             try{                 
                Contact contObj = new Contact();
                contObj.FirstName = String.isNotBlank(contactAddresObj.contactName) && contactAddresObj.contactName.contains(' ') ? contactAddresObj.contactName.substringBefore(' ') : '';
                contObj.LastName = String.isNotBlank(contactAddresObj.contactName) && contactAddresObj.contactName.contains(' ') ? contactAddresObj.contactName.substringAfter(' ') : contactAddresObj.contactName;
                contObj.Email = contactAddresObj.contactEmail;
                contObj.Phone = String.isNotBlank(contactAddresObj.contactPhone) ? contactAddresObj.contactPhone : '';
                contObj.AccountId = String.isNotBlank(contactAddresObj.accountId) ? contactAddresObj.accountId : null;
                contObj.Role__c = Constants.PRIMARY_CONTACT_ROLE;
				 new GenericUtilityClass.WoSDMLProcessor().insertRecords(new List<SObject>{contObj});
                //insert contObj; //DML on contact 
                return contObj.id;
             }catch(Exception e){
                 ErrorLogger errorLog = new ErrorLogger();
                 errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, contactAddresObj.quoteId, true); 
                 return 'Error:'+e.getMessage();
             }             
         }
    }

     /**
     * Name: updateQuote
     * @return string  
     * Purpose: to update the quote with address details
     */ 
    @Testvisible
    private static string updateQuote(ContactAddressWrapperClass contactAddresObj, string contactId){
         if(!(GenericUtilityClass.isSafeObject('Quote'))){
             return null;
         }else{
             try{
                 
                Id quoteId = String.isNotBlank(contactAddresObj.quoteId) ? contactAddresObj.quoteId : null;
                saveApplicableSTnC(quoteId, (List<Id>)contactAddresObj.specialTnCId);
                 
                Quote quoteObj = new Quote();
                quoteObj.id = quoteId;
                quoteObj.ShippingStreet = String.isNotBlank(contactAddresObj.contactStreet) ? contactAddresObj.contactStreet : '';
                quoteObj.ShippingCity = String.isNotBlank(contactAddresObj.contactCity) ? contactAddresObj.contactCity : '';
                quoteObj.ShippingPostalCode = String.isNotBlank(contactAddresObj.contactZipCode) ? contactAddresObj.contactZipCode : '';
                quoteObj.Reference__c = String.isNotBlank(contactAddresObj.contactReference) ? contactAddresObj.contactReference : '';
                quoteObj.contactid = contactId;
                quoteObj.Insurance_Display_Options__c = contactAddresObj.insuranceCondition; 
                quoteObj.SmartComm_Docs_Count__c = SmartCommHelper.getQuoteDocCount(new SmartCommHelper.WoSSelector().getQuoteDetails(quoteObj.id)).size();
               	
                //update quoteObj; //DML on Quote
                new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{quoteObj});
                return quoteObj.id;
             }catch(Exception e){
                 ErrorLogger errorLog = new ErrorLogger();
                 errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, contactAddresObj.quoteId, true); 
                 return 'Error:'+e.getMessage();
             }             
         }
    }

    /**
     * Name: saveApplicableSTnC
     * Purpose: to insert Applicable Special Terms and Conditions records. 
     *          Quote Id and Special Terms and Conditions Ids come from UI 
     *          (user selects Special Terms and Conditions on Document screen)
     */
    private static void saveApplicableSTnC(Id quoteId, List<Id> applicableSTnCIds) {
        List<Applicable_Special_Terms_and_Conditions__c> applicableSTnC = new List<Applicable_Special_Terms_and_Conditions__c>();
        List<Applicable_Special_Terms_and_Conditions__c> existingApplicableSTnC = new WoSSelector().getApplicableSTnC(quoteId);
        List<Applicable_Special_Terms_and_Conditions__c> deletedApplicableSTnC = new List<Applicable_Special_Terms_and_Conditions__c>();
        Set<Id> existingSTnCIds = new Set<Id>();

        for (Applicable_Special_Terms_and_Conditions__c existingApplicableSTnCItem : existingApplicableSTnC) {
            if (applicableSTnCIds.contains(existingApplicableSTnCItem.Special_Terms_and_Conditions__c)) {
                existingSTnCIds.add(existingApplicableSTnCItem.Special_Terms_and_Conditions__c);
            } else {
                deletedApplicableSTnC.add(existingApplicableSTnCItem);
            }
        }

        for (Id applicableSTnCId : applicableSTnCIds) {
            if (!existingSTnCIds.contains(applicableSTnCId)) {
                Applicable_Special_Terms_and_Conditions__c appSTnC = new Applicable_Special_Terms_and_Conditions__c(
                    Quote__c = quoteId,
                    Special_Terms_and_Conditions__c = applicableSTnCId
                );
                applicableSTnC.add(appSTnC);
            }
        }

        new GenericUtilityClass.WoSDMLProcessor().deleteRecords(deletedApplicableSTnC);
        new GenericUtilityClass.WoSDMLProcessor().insertRecords(applicableSTnC);
    }

    // inner class-selector
    public without sharing class WoSSelector {

        

        public Quote getQuoteById(String quoteId) {
            return [SELECT  id,Opportunity.End_User__c, Opportunity.End_User__r.Name, 
                                    Opportunity.End_User__r.External_Identifier__c, Opportunity.End_User__r.BillingStreet, 
                                    Opportunity.End_User__r.BillingCity, Opportunity.End_User__r.BillingPostalCode,
                                    Applicable_Offers__r.Offer__c, Applicable_Offers__r.Offer__r.Insurance_Display_Options__c,
                    				Applicable_Offers__r.Offer__r.Default_Insurance__c,Status,
                                    Contact.Name, contact.Email, contact.Phone,ShippingStreet,ShippingPostalCode,
                                    ShippingCity,Reference__c,Insurance_Display_Options__c,Type_downpayment__c,
									Value_downpayment__c, Value_term__c, Opportunity.Name,
                                    (SELECT Special_Terms_and_Conditions__c FROM Applicable_Special_Terms_and_Conditions__r) 
                                    FROM Quote 
                                    WHERE Id =:quoteId LIMIT 1 ];
        }
        
        public List<Offer_Special_Terms_Conditions__c> getOfferSpclCondtionsById(quote quoteRecord) {
            return [SELECT Special_Terms_and_Conditions__r.name, 
                    Special_Terms_and_Conditions__r.Category__c 
                    FROM Offer_Special_Terms_Conditions__c 
                    WHERE Offer__c =: quoteRecord.Applicable_Offers__r.Offer__c ORDER BY 
                    Special_Terms_and_Conditions__r.Category__c,Special_Terms_and_Conditions__r.Name];
        }

        public List<Applicable_Special_Terms_and_Conditions__c> getApplicableSTnC(String quoteId) {
            return [
                SELECT  Special_Terms_and_Conditions__c 
                FROM    Applicable_Special_Terms_and_Conditions__c
                WHERE   Quote__c = :quoteId
            ];
        }
        
        /**
        * Method is called to get and display personal gaurantee details.
        * 
        * @return Related_Party__c list
        */
        public List<Related_Party__c> getRelatedPartyList(String quoteId){
             return [SELECT Name FROM Related_Party__c WHERE Quote__c =: quoteId];
         }
    }

    public class ContractGenerationWrapperClass{
        public string accountId;
        public string companyId;
        public string companyLegalName;
        public string companyAddress;
        public string companyZipCode;
        public string insuranceDisplayOptions;
        public string defaultInsurance;
        public List<Offer_Special_Terms_Conditions__c> offerSpTnCList;
        public Set<Id> quoteSTnCIds;
        public string contactName;
        public string contactEmail;
        public string contactPhoneNumber;
        public string contactStreet;
        public string contactCity;
        public string contactZipCode;
        public string contactReference;
        public string insuranceCondition = '';
        public List<Related_Party__c> relatedPartyList;
        public string Status;            												
        public string typeDownpayment;
		public string valueDownpayment;
        public string valueTerm;
        public string opportunityName;

        public ContractGenerationWrapperClass(string accountId, string companyId,string companyLegalName,string companyAddress,string companyZipCode,string insuranceDisplayOptions,String defaultInsurance, List<Offer_Special_Terms_Conditions__c> offerSpTnCList,
                                                Set<Id> quoteSTnCIds, string contactName,string contactEmail,string contactPhoneNumber,string contactStreet,string contactCity,
                                                string contactZipCode,string contactReference,string insuranceCondition,
                                             	List<Related_Party__c> relatedPartyList, string Status, string typeDownpayment,
                                             	string valueDownpayment, string valueTerm, string opportunityName){
            this.accountId = accountId;
            this.companyId = companyId;
            this.companyLegalName = companyLegalName;
            this.companyAddress = companyAddress;
            this.companyZipCode = companyZipCode;
            this.insuranceDisplayOptions = insuranceDisplayOptions;
            this.defaultInsurance = defaultInsurance; 
            this.offerSpTnCList = offerSpTnCList; 
            this.contactName = contactName;
            this.contactEmail = contactEmail;
            this.contactPhoneNumber = contactPhoneNumber;
            this.contactStreet = contactStreet;
            this.contactCity = contactCity;
            this.contactZipCode = contactZipCode;
            this.contactReference = contactReference;
            this.insuranceCondition = insuranceCondition;
            this.quoteSTnCIds = quoteSTnCIds;    
           	this.relatedPartyList = relatedPartyList;
            this.Status = Status;
            this.typeDownpayment = typeDownpayment;
			this.valueDownpayment = valueDownpayment;
       	 	this.valueTerm = valueTerm;
            this.opportunityName = opportunityName;
        }
    }

    public class ContactAddressWrapperClass{
        public string contactName ;
        public string contactEmail;
        public string contactPhone;
        public string contactStreet;
        public string contactCity;
        public string contactZipCode;
        public string contactReference;
        public string accountId;
        public string quoteId;
        public string insuranceCondition = '';
        public List<Id> specialTnCId;
    }
    

}