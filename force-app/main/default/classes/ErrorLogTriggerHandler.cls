public with sharing class ErrorLogTriggerHandler {

    public static void processNewErrorLogs(List<Error_Log__c> newLogs) {

        Set<String> acctIds = new Set<String>();
        Set<String> oppIds = new Set<String>();
        Set<String> quoteids = new Set<String>();

        for(Error_Log__c log : newLogs) {
            if(log.Record_Id__c != null) {
                String firstThreeChars = log.Record_Id__c.left(3);
                if(firstThreeChars == '001') {
                    acctIds.add(log.Record_Id__c);
                } else if(firstThreeChars == '006') {
                    oppIds.add(log.Record_Id__c);
                } else if(firstThreeChars == '0Q0') {
                    quoteids.add(log.Record_Id__c);
                } else {
                    System.debug('Uncaught RecordId type that starts with ' + firstThreeChars);
                }
            }
        }

        if(acctIds.size() > 0) {
            Map<String, Account> mapOfAccounts = new Map<String, Account>([SELECT Id FROM Account WHERE Id IN :acctIds]);
            for(Error_Log__c log : newLogs) {
                if(mapOfAccounts.containsKey(log.Record_Id__c)) {
                    // log.Account__c = log.Record_Id__c;
                    log.Account__c = mapOfAccounts.get(log.Record_Id__c).Id;
                }
            }

        }

        if(oppIds.size() > 0) {
            Map<String, Opportunity> mapOfOpportunities = new Map<String, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :oppIds]);
            for(Error_Log__c log : newLogs) {
                if(mapOfOpportunities.containsKey(log.Record_Id__c)) {
                    // log.Opportunity__c = log.Record_Id__c;
                    log.Opportunity__c = mapOfOpportunities.get(log.Record_Id__c).Id;
                }
            }

        }


        if(quoteids.size() > 0) {
            Map<String, Quote> mapOfQuotes = new Map<String, Quote>([SELECT Id FROM Quote WHERE Id IN :quoteids]);
            for(Error_Log__c log : newLogs) {
                if(mapOfQuotes.containsKey(log.Record_Id__c)) {
                    // log.Quote__c = log.Record_Id__c;
                    log.Quote__c = mapOfQuotes.get(log.Record_Id__c).Id;
                }
            }
        }
        
    }


    // @future
    // public static void processNewErrorLogs_Future(List<Id> newLogIds) {

    //     List<Error_Log__c> newLogs = [SELECT Id, Name, Record_Id__c, Account__c, Opportunity__c, Quote__c FROM Error_Log__c WHERE Id IN :newLogIds];

    //     Set<String> acctIds = new Set<String>();
    //     Set<String> oppIds = new Set<String>();
    //     Set<String> quoteids = new Set<String>();

    //     for(Error_Log__c log : newLogs) {
    //         if(log.Record_Id__c != null) {
    //             String firstThreeChars = log.Record_Id__c.left(3);
    //             if(firstThreeChars == '001') {
    //                 acctIds.add(log.Record_Id__c);
    //             } else if(firstThreeChars == '006') {
    //                 oppIds.add(log.Record_Id__c);
    //             } else if(firstThreeChars == '0Q0') {
    //                 quoteids.add(log.Record_Id__c);
    //             } else {
    //                 System.debug('Uncaught RecordId type that starts with ' + firstThreeChars);
    //             }
    //         }
    //     }

    //     if(acctIds.size() > 0) {
    //         Map<String, Account> mapOfAccounts = new Map<String, Account>([SELECT Id FROM Account WHERE Id IN :acctIds]);
    //         for(Error_Log__c log : newLogs) {
    //             if(mapOfAccounts.containsKey(log.Record_Id__c)) {
    //                 // log.Opportunity__c = log.Record_Id__c;
    //                 log.Account__c = mapOfAccounts.get(log.Record_Id__c).Id;
    //             }
    //         }
    //     }

    //     if(oppIds.size() > 0) {
    //         Map<String, Opportunity> mapOfOpportunities = new Map<String, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :oppIds]);
    //         for(Error_Log__c log : newLogs) {
    //             if(mapOfOpportunities.containsKey(log.Record_Id__c)) {
    //                 // log.Opportunity__c = log.Record_Id__c;
    //                 log.Opportunity__c = mapOfOpportunities.get(log.Record_Id__c).Id;
    //             }
    //         }
    //     }


    //     if(quoteids.size() > 0) {
    //         Map<String, Quote> mapOfQuotes = new Map<String, Quote>([SELECT Id FROM Quote WHERE Id IN :quoteids]);
    //         for(Error_Log__c log : newLogs) {
    //             if(mapOfQuotes.containsKey(log.Record_Id__c)) {
    //                 // log.Quote__c = log.Record_Id__c;
    //                 log.Quote__c = mapOfQuotes.get(log.Record_Id__c).Id;
    //             }
    //         }
    //     }    

    // }


}