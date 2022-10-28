/**
 * Class implements the trigger handler for Opportunity object.
 * @author v1.1 Alexey (Cognizant)
 * v1.2 Anujit (Cognizant)
 * @date 2020-12-12
 * updated on @date 2021-11-16 Anujit. to fix the same name on mulitple opptys issue in PRD
 */
public with sharing class OpportunityTriggerHandler extends TriggerHandler {  

    private static final Integer OPPORTUNITY_NAME_LENGTH = 10;
    private static final Integer ISO_CODE_NAME_PART_LENGTH = 2;
    private static final Integer NUMERIC_NAME_PART_LENGTH = 8;
    
    //we are handling 'After Insert' because same oppty names are created for more than one oppty. cannot be handled this in before insert trigger.
    public override void afterInsert() {
        id profileId = userinfo.getProfileId();
        String profileName = [select Name from profile where id = :profileId LIMIT 1].Name;
        if(profileName == Constants.NORDICS_PROFILE_NAME || profileName == Constants.NORDICS_INTERNAL_DLL_MEMBER){
            populateOpportunitiesNames();
        }else{
            return;
        }
    }

    //01-12-20: New logic -- Added logic to populate Name field on new Opportunity record of "Retail" record type
    //Name format - country code (ISO 3166-1 Alpha-3) + number of 7 digits (numbers are unique within each country code group)
    private static void populateOpportunitiesNames() {
        //Get opportunities of "Retail" record type
        List<Opportunity> retailDealOpportunities = getRetailDealOpportunities((List<Opportunity>) Trigger.new);

        //SOQL because we have to update the same oppty record in 'after insert'
        set<id> oppIdSet = new set<id>();
        for(Opportunity eachOpp : retailDealOpportunities){
            oppIdSet.add(eachOpp.id);
        }
        retailDealOpportunities =  new WoSSelector().getOpptyRecords(oppIdSet);

        //Get accounts Ids of the related to opportunities
        Set<Id> accountIds = new Set<Id>();        
        for(Opportunity opp : retailDealOpportunities) {
            accountIds.add(opp.AccountId);
        }
        if(accountIds.isEmpty()) {
            return;
        }
        //Get accounts with ISO codes mapped by account Ids        
        Map<Id, Account> accountsWithIsoCodes = getAccountsWithIsoCodes(accountIds);
        if(accountsWithIsoCodes.isEmpty()) {
            return;
        }
        //Get new opportunities mapped by ISO codes
        Map<String, List<Opportunity>> opportunitiesByCountryCodes = getOpportunitiesByCountryCodes(accountsWithIsoCodes, retailDealOpportunities);
        //Get existing opportunities based on given ISO codes
        List<Opportunity> existingOpportunities = getExistingOpportunities(opportunitiesByCountryCodes.keySet());
        //Map of the last created oportunities based on country codes
        Map<String, Opportunity> lastCreatedOpportunitiesByCountryCodes = getLastCreatedOpportunitiesByCountryCodes(existingOpportunities);
        //Construct the names of new opportunities based on ISO codes and 7 digit numbers
        constructNewOpportunitiesNames(opportunitiesByCountryCodes, lastCreatedOpportunitiesByCountryCodes);
    }

    /**
    Name: getRetailDealOpportunities
    Purpose: get the retail recrod type id
     */
    private static List<Opportunity> getRetailDealOpportunities(List<Opportunity> opportunities) {
        Id retailDealRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
        List<Opportunity> retailDealOpportunities = new List<Opportunity>();
        for(Opportunity opp : opportunities) {
            if(opp.RecordTypeId == retailDealRecordTypeId) {
                retailDealOpportunities.add(opp);
            }
        }
        return retailDealOpportunities;
    }
    
    /**
    Name: getAccountsWithIsoCodes
    Purpose: get the accounts with the ISO code
     */
    @TestVisible
    private static Map<Id, Account> getAccountsWithIsoCodes(Set<Id> accountIds) {
        
        Map<Id, Account> accountMap;
        accountMap = new WoSSelector().getAccountDetails(accountIds);

        return accountMap;
    }
    
    /**
    Name: getOpportunitiesByCountryCodes
    Purpose: get the opportunities with the country codes
     */
    private static Map<String, List<Opportunity>> getOpportunitiesByCountryCodes(Map<Id, Account> accountsWithIsoCodes, List<Opportunity> opportunities) {
        Map<String, List<Opportunity>> opportunitiesByCountryCodes = new Map<String, List<Opportunity>>();
        for(Opportunity opp : opportunities) {
            if(opportunitiesByCountryCodes.containsKey(accountsWithIsoCodes.get(opp.AccountId).Region_Relationship__r.ISO_Code__c)) {
                opportunitiesByCountryCodes.get(accountsWithIsoCodes.get(opp.AccountId).Region_Relationship__r.ISO_Code__c).add(opp);
            } else {
                opportunitiesByCountryCodes.put(accountsWithIsoCodes.get(opp.AccountId).Region_Relationship__r.ISO_Code__c, new List<Opportunity>{opp});
            }
        }
        return opportunitiesByCountryCodes;
    }
    
    /**
    Name: getExistingOpportunities
    Purpose: get the existing opportunities with the country codes
    */
    private static List<Opportunity> getExistingOpportunities(Set<String> isoCodes) {
        
        List<Opportunity> opportunitiesList;
        opportunitiesList = new WoSSelector().getOppDetails(isoCodes);

        return opportunitiesList;
    }
    
     /**
    Name: getLastCreatedOpportunitiesByCountryCodes
    Purpose: get the getLastCreatedOpportunities By CountryCodes
    */
    private static Map<String, Opportunity> getLastCreatedOpportunitiesByCountryCodes(List<Opportunity> existingOpportunities) {
        Map<String, Opportunity> lastCreatedOpportunitiesByCountryCodes = new Map<String, Opportunity>();
        for(Opportunity opp : existingOpportunities) {
            if(!lastCreatedOpportunitiesByCountryCodes.containsKey(opp.Account.Region_Relationship__r.ISO_Code__c)) {
                lastCreatedOpportunitiesByCountryCodes.put(opp.Account.Region_Relationship__r.ISO_Code__c, opp);
            }
        }
        return lastCreatedOpportunitiesByCountryCodes;
    }
    
     /**
    Name: constructNewOpportunitiesNames
    Purpose: method to consturct the opportunities name
    */
    private static void constructNewOpportunitiesNames(Map<String, List<Opportunity>> opportunitiesByCountryCodes, Map<String, Opportunity> lastCreatedOpportunitiesByCountryCodes) {
             
       list<Opportunity> oppListToUpdate = new list<Opportunity>();
        for(String isoCode : opportunitiesByCountryCodes.keySet()) {
            //Get the numeric part of the name of the last created opportunity
            Integer opportunityNameNumber = !lastCreatedOpportunitiesByCountryCodes.containsKey(isoCode) 
                || lastCreatedOpportunitiesByCountryCodes.get(isoCode).Name.length() != OPPORTUNITY_NAME_LENGTH 
                ? 0 : Integer.valueOf(lastCreatedOpportunitiesByCountryCodes.get(isoCode).Name.substring(ISO_CODE_NAME_PART_LENGTH, OPPORTUNITY_NAME_LENGTH));
            for(Opportunity opp : opportunitiesByCountryCodes.get(isoCode)) {
                opportunityNameNumber++;
                String opportunityNameNumberPart = String.valueOf(opportunityNameNumber);
                //Add leading zeros to the name to keep the length of the numeric part
                while(opportunityNameNumberPart.length() < NUMERIC_NAME_PART_LENGTH) {
                    opportunityNameNumberPart = 0 + opportunityNameNumberPart;
                }
                opp.Name = isoCode + opportunityNameNumberPart;
                
                if(!getStdPricebook().isEmpty()){
                    List<Pricebook2> pricebookList = getStdPriceBook();
                    opp.Pricebook2Id = pricebookList[0].id;
                } 
                oppListToUpdate.add(opp);  
            }
        }   
        
        update oppListToUpdate;
    }
    
    /**
    Name: getStdPriceBook
    Purpose: SOQL to get the standard pricebook id
    */
    private static List<Pricebook2> getStdPriceBook() {
        
       return [select id from Pricebook2 where isStandard = true limit 1];    

    }

    public class OpportunityTriggerHandlerException extends Exception {}
    
     /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {
        
        /**
        *Name: getOppDetails
        *Purpose: query account region's ISO code from opportunity.  
        */
        private List<Opportunity> getOppDetails(Set<String> isoCodes) {            
            return [
                SELECT Name, Account.Region_Relationship__r.ISO_Code__c 
                FROM Opportunity 
                WHERE Account.Region_Relationship__r.ISO_Code__c IN :isoCodes
                AND Name LIKE 'SE%' and owner.profile.name =: Constants.NORDICS_PROFILE_NAME 
                ORDER BY Name DESC LIMIT 1
            ];            
        }
        
         /**
        *Name: getOpptyRecords
        *Purpose: query Opportunities to get the inserted oppty details
        */
        private List<Opportunity> getOpptyRecords(Set<id> oppIdSet) {            
            return [SELECT id,AccountId,Name,Pricebook2Id FROM Opportunity WHERE id IN: oppIdSet];
                    
        }
        
        
        /**
        *Name: getAccountDetails
        *Purpose: query  region's ISO code from Account.  
        */
        private Map<Id,Account> getAccountDetails(Set<Id> accountIds) {
           return new Map<Id, Account>([
                    SELECT Region_Relationship__r.ISO_Code__c 
                    FROM Account 
                    WHERE Id IN :accountIds
                ]);
        }
    }
}