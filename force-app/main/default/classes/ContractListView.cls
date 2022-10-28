public with sharing class ContractListView {
    
    @AuraEnabled
    public static Integer getTotalRecords(String accountId ) {
        system.debug('inicio getTotalRecords ');
        String querySQL;
		Integer totalNumberOfRows;
		querySQL = 'SELECT COUNT() FROM Contract__c WHERE End_User__c = :accountId';
		totalNumberOfRows = Database.countQuery(querySQL);
        system.debug('totalNumberOfRows ' + totalNumberOfRows);
		return totalNumberOfRows;
    }
    
	@AuraEnabled(cacheable=true)
	public static List<Contract__c> getRecords(String accountId, Integer rowLimit, Integer rowOffset){
        system.debug('inicio getRecords ');          
        string querySQL;   
        list<Contract__c> contractList = new List<Contract__c>(); 
                         
        querySQL = 'SELECT Id, Name, Contract_Term_months__c, End_User__c, Finance_Type__c, Health__c, Payments_Remaining__c, Program__r.Name, Status_Text__c, Account__r.Name, Opportunity__r.Partner_Sales_Rep__r.Name FROM Contract__c WHERE End_User__c = :accountId AND (NOT Program__r.Name LIKE \'%gfc%\')';

        contractList = Database.query(querySQL);
        system.debug('contractList ' + contractList);
        return contractList;
	}    
    
}