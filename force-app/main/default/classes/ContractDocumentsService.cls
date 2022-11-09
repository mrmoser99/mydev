public with sharing class ContractDocumentsService {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountTest(){
        return [SELECT Name, BillingStreet, BillingPostalCode FROM Account limit 5];
    }
}