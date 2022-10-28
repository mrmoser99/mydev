/**
 * This class is used as apex controller for quoteCalculator, customerSearchCmp LWC (Customer screen)
 * 
 * @author Elena Sokolova @date 2020-12-15 
 */
public with sharing class CustomerSetupController {
    
    /**
     * Method is called from LWC to save customer info if where is not such info in the database
     * 
     * @return account Id
     */
    @AuraEnabled
    public static Id saveAccountAndUpdateDeal(String customerInfo, String customerExtId, String quoteId) {
        Account account = new WoSSelector().getAccountByExternalId(customerExtId);

        if (account == null) {
            account = new Account();
        }

        SearchPartyResponseBodyWrapper.Data data = (SearchPartyResponseBodyWrapper.Data) JSON.deserialize(
            customerInfo, 
            SearchPartyResponseBodyWrapper.Data.class
        );

        Quote qoute = new WoSSelector().getQuoteById(quoteId);

        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(Constants.END_USER_RECORD_TYPE_NAME).getRecordTypeId();
        account.Name = data.name;
        account.External_Identifier__c = customerExtId;
        account.Region_Relationship__c = qoute.Applicable_Offers__r.Offer__r.Program__r.Region__c;
        account.Account_Region_Code__c = qoute.Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c;
        account.BillingStreet = data.Address.street;
        account.BillingCity = data.Address.city;
        account.BillingPostalCode = data.Address.postalCode;
        account.Phone = (data.phoneNumbers != null) ? (data.phoneNumbers[0].areaCode + data.phoneNumbers[0].phoneNumber) : '';
        account.Legal_Entity_Name__c = (data.legalEntity != null) ? data.legalEntity.name : null;
        account.Legal_Entity_Description__c = (data.legalEntity != null) ? data.legalEntity.id : null;

        try {
            //upsert account;
            new GenericUtilityClass.WoSDMLProcessor().upsertRecords(new List<SObject>{account});
            updateDeal(quoteId, account.Id, account.Name, customerExtId);
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, quoteId, true); 
        }

        
        return account.Id;
    }

    /**
     * Method updates quote status 
     */
    @AuraEnabled
    public static void updateQuoteStatus(String quoteId, String status) {
        Quote qoute = new WoSSelector().getQuoteById(quoteId);
        qoute.Status = status;
        new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{qoute});
        //update qoute;
    }

    /**
     * Method saves customer external id in the opportunity level
     */
    private static void updateDeal(String quoteId, String customerId, String customerName, String customerExtId) {
        Quote qoute = new WoSSelector().getQuoteById(quoteId);
        Opportunity opportunity = new WoSSelector().getOpportunityById(qoute.OpportunityId);
        opportunity.End_User__c = customerId;
        opportunity.Customer_Id__c = customerExtId;
        opportunity.Customer_Name__c = customerName;
        //update opportunity;
        new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{opportunity});
    }


    /**
     * Method gets info about selected customer
     */
    @AuraEnabled
    public static String getCustomerScreenInfo(String quoteId) {
        return JSON.serialize(new WoSSelector().getCustomerScreenInfoByQuoteId(quoteId));
    }

    // inner class-selector
    public without sharing class WoSSelector {

        public Quote getQuoteById(String quoteId) {
            return [
                SELECT  OpportunityId, Status, Auto_Decision__c, Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c,
                        Applicable_Offers__r.Offer__r.Program__r.Region__c
                FROM    Quote 
                WHERE   Id = :quoteId
            ];
        }

        private Opportunity getOpportunityById(String opportunityId) {
            return [SELECT End_User__c, Customer_Id__c, Customer_Name__c FROM Opportunity WHERE Id = :opportunityId];
        }

        private Opportunity getCustomerScreenInfoByQuoteId(String quoteId) {
            return [
                SELECT  End_User__c, End_User__r.Name, End_User__r.External_Identifier__c, End_User__r.BillingStreet, 
                        End_User__r.BillingCity, End_User__r.BillingPostalCode,
                        (SELECT Status, Conditions__c, Valid_From__c, Valid_To__c FROM Quotes WHERE Id = :quoteId)
                FROM    Opportunity 
                WHERE   Id IN (SELECT OpportunityId FROM Quote WHERE Id = :quoteId)
            ];
        }

        private Account getAccountByExternalId(String customerExtId) {
            List<Account> accounts = [SELECT Id, Name, External_Identifier__c FROM Account WHERE External_Identifier__c = :customerExtId];
            return (accounts.isEmpty()) ? null : accounts[0];
        }
    }
}