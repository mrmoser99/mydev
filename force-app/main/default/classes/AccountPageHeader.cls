/**
 * @description       : Apex class for Account Page Header.
 * @author            : Kritika Sharma (Traction on Demand)
 * @group             : 
 * @last modified on  : 10-03-2022
 * @last modified by  : Kritika Sharma
**/
public with sharing class AccountPageHeader {
    @AuraEnabled(cacheable=true)
    public static Account getAccountData(Id accountId){
        return [
                SELECT Id, Name, AccountNumber, Industry
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=false)
    public static String createNewOppForCreditCheck(String endUserId) {
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
        newOpp.Nickname__c = 'Credit Check';
        if (!String.isBlank(endUserId)) {
            newOpp.End_User__c = endUserId;
        }
        newOpp.CloseDate = System.today() + 30;
        newOpp.StageName = 'Quoting';
        newOpp.Sub_Stage__c = 'Application Draft';
        newOpp.ForecastCategoryName = 'Omitted';
        newOpp.Amount = 0;
        newOpp.CurrencyIsoCode = 'USD';
        newOpp.Type = 'Credit Check';

        try {
            insert newOpp;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }

        return newOpp.Id;
    }
    
    @AuraEnabled
    public static Integer getTotalRecords(String accountId ) {
        String querySQL;
		Integer totalNumberOfRows;
		querySQL = 'SELECT COUNT() FROM Opportunity WHERE End_User__c = :accountId AND RecordType.DeveloperName = \'Retail\'';
		totalNumberOfRows = Database.countQuery(querySQL);
		return totalNumberOfRows;
    }
    
	@AuraEnabled(cacheable=true)
	public static List<Opportunity> getRecords(String accountId, Integer rowLimit, Integer rowOffset){
                  
        string querySQL;   
        list<Opportunity> oppList = new List<Opportunity>();
        
        system.debug(accountId);
                         
        querySQL = 'SELECT Opportunity_Name__c, Name, Amount, Application_Date__c, Application_Number__c, End_User__c, Partner_Sales_Rep__r.Name, Sub_Stage__c, Account.Name ' +
                   ' FROM Opportunity WHERE End_User__c = \'' + accountId + '\' ORDER BY CreatedDate desc LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
		system.debug(querySQL);
        oppList = Database.query(querySQL);
        system.debug(oppList);
        return oppList;
	}    
    
}