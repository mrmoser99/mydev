@isTest
public with sharing class TestErrorLogTriggerHandler {
    
    class TestData {
    
        String endUserAcctName = 'Clienta Falso';
    
        String vendorAcctName = 'Vendedora Falso';
        String vendorOriginatingSiteId = '0000105570_0001';
        String vendorProgramId = '1604';
        String vendorProductId = '1360.3080';
    
        String vendorContactFirstName = 'Harry';
        String vendorContactLastName = 'Kane';
        
        String oppName = 'Nombre de Opp Falso';
        String oppStage = 'Quoting';
        String oppType = 'New';
        Integer oppAmount = 75000;
        Date oppCloseDate = Date.today().addDays(30);
        String quoteName = 'Cotiza falsa';
    }
    
    @testSetup
    static void makeData() {
        
        TestData tData = new TestData();
        TestDataFactory dataFactory = TestDataFactory.getInstance();
    
        Account endUserAcct = new Account(name = tData.endUserAcctName);
        endUserAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();
    
        insert endUserAcct;
    
        Account vendorAcct = new Account(name = tData.vendorAcctName, Originating_Site_Id__c = tData.vendorOriginatingSiteId);
        vendorAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    
        insert vendorAcct;
    
        Contact c = new Contact(FirstName = tData.vendorContactFirstName, LastName = tData.vendorContactLastName, AccountId = vendorAcct.Id, Role__c = 'Partner Sales Rep');
        insert c;
        
        String oppRecordTypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
    
        Opportunity o = dataFactory.buildOpportunity(tData.oppName ,tData.oppStage ,tData.oppCloseDate, tData.oppType , oppRecordTypeId, vendorAcct.Id, tData.oppAmount, Test.getStandardPricebookId());
    
        Quote q = new Quote (name = tData.quoteName, opportunityId = o.id, lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly', payment_timing__c = 'in-arrears');
        insert q;
    
        Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
        insert ql;
    }

    
    @isTest
    private static void sanityTest() {
    
        TestData tData = new TestData();
    
        Test.startTest();

            Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
            System.assertNotEquals(null, endUserAcct.Id, 'Failed to create the test account as expected');
            
            Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
            System.assertNotEquals(null, vendorAcct.Id, 'Failed to create the test account as expected');
        
            Contact vendorContact = [SELECT Id, Name FROM Contact WHERE LastName = :tData.vendorContactLastName AND AccountId = :vendorAcct.Id];
            System.assertNotEquals(null, vendorContact.Id, 'Failed to create the test account as expected');
        
            Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
            System.assertNotEquals(null, testOpp.Id, 'Failed to create the test opp as expected');
        
            Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName AND OpportunityId = :testOpp.Id];
            System.assertNotEquals(null, testQuote.Id, 'Failed to create the test quote as expected');
        
        Test.stopTest();
    }


    @isTest
    private static void testAutoRelateErrorLog_IgnoresBadIds() {
        TestData tData = new TestData();
    
        Test.startTest();

            List<Error_Log__c> els = new List<Error_Log__c>{
                new Error_Log__c(Record_Id__c = '060&()%&#^@)84$'), 
                new Error_Log__c(Record_Id__c = '001Polouhlkjshgy') 
            };
        
            insert els;

        Test.stopTest();

        List<Error_Log__c> elsAfterInsert = [SELECT Id, Name, Account__c FROM Error_Log__c WHERE Id IN :els];


        System.assertEquals(els.size(), elsAfterInsert.size(), 'Failed to properly persist Error_Log__c data likely because bad ids were passed as record ids');
    }

    @isTest
    private static void testAutoRelateErrorLog_Account() {
        TestData tData = new TestData();
    
        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];

        Test.startTest();

            Error_Log__c el = new Error_Log__c();
            el.Record_Id__c = endUserAcct.Id;
            insert el;

        Test.stopTest();

        Error_Log__c elAfterInsert = [SELECT Id, Name, Account__c FROM Error_Log__c WHERE Id = :el.Id];

        System.assertEquals(endUserAcct.Id, elAfterInsert.Account__c, 'Failed to auto-relate an opportunity from the string recordId value');
    }

    @isTest
    private static void testAutoRelateErrorLog_Opportunity() {
    
        TestData tData = new TestData();

        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];

        Test.startTest();

            Error_Log__c el = new Error_Log__c();
            el.Record_Id__c = testOpp.Id;
            insert el;

        Test.stopTest();

        Error_Log__c elAfterInsert = [SELECT Id, Name, Opportunity__c FROM Error_Log__c WHERE Id = :el.Id];

        System.assertEquals(testOpp.Id, elAfterInsert.Opportunity__c, 'Failed to auto-relate an opportunity from the string recordId value');


    }

    @isTest
    private static void testAutoRelateErrorLog_Quote() {
        TestData tData = new TestData();

        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
        Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName AND OpportunityId = :testOpp.Id];

        Test.startTest();

            Error_Log__c el = new Error_Log__c();
            el.Record_Id__c = testQuote.Id;
            insert el;

        Test.stopTest();

        Error_Log__c elAfterInsert = [SELECT Id, Name, Quote__c FROM Error_Log__c WHERE Id = :el.Id];

        System.assertEquals(testQuote.Id, elAfterInsert.Quote__c, 'Failed to auto-relate an opportunity from the string recordId value');
    }


    @isTest
    private static void testAutoRelateErrorLog_MultipleTypesOfRecords() {
        TestData tData = new TestData();
    

        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
        Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName AND OpportunityId = :testOpp.Id];

        Test.startTest();

            List<Error_Log__c> els = new List<Error_Log__c>{
                new Error_Log__c(Record_Id__c = null),
                new Error_Log__c(Record_Id__c = '001*)WR**E*R('),
                new Error_Log__c(Record_Id__c = vendorAcct.Id), 
                new Error_Log__c(Record_Id__c = testOpp.Id),
                new Error_Log__c(Record_Id__c = testQuote.Id)
            };
        
            insert els;

        Test.stopTest();

        List<Error_Log__c> elsAfterInsert = [SELECT Id, Name, Account__c, Opportunity__c, Quote__c FROM Error_Log__c WHERE Id IN :els];
        System.assertEquals(els.size(), elsAfterInsert.size(), 'Failed to properly persist Error_Log__c data likely because bad ids were passed as record ids');

        Boolean acctRelationshipExists = false;
        Boolean oppRelationshipExists = false;
        Boolean quoteRelationshipExists = false;

        for(Error_Log__c el : elsAfterInsert) {
            if(el.Account__c != null) {
                acctRelationshipExists = true;
            } 
            if(el.Opportunity__c != null) {
                oppRelationshipExists = true;
            } 
            if(el.Quote__c != null) {
                quoteRelationshipExists = true;
            } 
            
        }
    
        System.assert(acctRelationshipExists, 'Failed to properly mark that acctRelationshipExists');
        System.assert(oppRelationshipExists, 'Failed to properly mark that oppRelationshipExists');
        System.assert(quoteRelationshipExists, 'Failed to properly mark that quoteRelationshipExists');
    
    }

    
}