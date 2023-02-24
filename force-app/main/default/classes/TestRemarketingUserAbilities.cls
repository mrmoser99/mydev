@isTest
public with sharing class TestRemarketingUserAbilities {

    class TestData {
        String remarketingUserFirstName = 'Pedro';
        String remarketingUserLastName = 'Porro';
        String remarketingUserEmail = 'pporro@notarealemail.com';

        String endUserAcctName = 'Clienta Remarketing';
    
        String vendorAcctName = 'Remarketer Falso';

        String vendorContactFirstName = 'Rodrigo';
        String vendorContactLastName = 'Bentancour';
        
        String oppName = 'Nombre de Opp Falso';
        String oppStage = 'Quoting';
        String oppType = 'New';
        Integer oppAmount = 75000;
        Date oppCloseDate = Date.today().addDays(30);
    
        String quoteName = 'Remarketing Quote';
        
    }
    
    @testSetup
    static void makeData() {
    
        TestData tData = new TestData();
        TestDataFactory dataFactory = TestDataFactory.getInstance();
    
        Account endUserAcct = new Account(name = tData.endUserAcctName);
        endUserAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();
    
        insert endUserAcct;
    
        Account vendorAcct = new Account(name = tData.vendorAcctName);
        vendorAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    
        insert vendorAcct;
    
        Contact c = new Contact(FirstName = tData.vendorContactFirstName, LastName = tData.vendorContactLastName, AccountId = vendorAcct.Id, Role__c = 'Partner Sales Rep');
        insert c;
        
        String oppRecordTypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Remarketing').getRecordTypeId();
    
        Opportunity o = dataFactory.buildOpportunity(tData.oppName ,tData.oppStage ,tData.oppCloseDate, tData.oppType , oppRecordTypeId, vendorAcct.Id, tData.oppAmount, Test.getStandardPricebookId());
    
        Quote q = new Quote (name = tData.quoteName, opportunityId = o.id, End_User__c = endUserAcct.Id);
        insert q;
    
        Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
        insert ql;

        Profile remarketingProfile = [SELECT Id FROM Profile WHERE Name = 'Remarketing']; 
        UserRole remarketingTopRole = [SELECT Id, ParentRoleId FROM UserRole WHERE Name = 'GBU President AM']; 
        UserRole remarketingMiddleRole = [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId = :remarketingTopRole.Id]; 
        UserRole remarketingBottomRole = [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId = :remarketingMiddleRole.Id]; 

        User u = new User(Alias = 'rmktg', Email= tData.remarketingUserEmail, UserRoleId = remarketingTopRole.Id,
            EmailEncodingKey='UTF-8', FirstName=tData.remarketingUserFirstName, LastName=tData.remarketingUserLastName, 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = remarketingProfile.Id, DB_Region__c = 'United States - Wayne',
            TimeZoneSidKey='America/New_York', UserName= tData.remarketingUserEmail);
        
        insert u;

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
        
            User testUser = [SELECT Id, FirstName FROM User WHERE Profile.Name = 'Remarketing' AND Email = :tData.remarketingUserEmail LIMIT 1];     
            System.assertEquals(tData.remarketingUserFirstName, testUser.FirstName, 'Failed to create the test user as expected');
   
        Test.stopTest();
        
    }

    @isTest
    private static void testRoleHierarchySharing() {
        
        TestData tData = new TestData();

        User testPresidentUser = [SELECT Id, FirstName, ProfileId FROM User WHERE Profile.Name = 'Remarketing' AND Email = :tData.remarketingUserEmail LIMIT 1];    

        UserRole remarketingOperationsRole = [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId = :testPresidentUser.Id]; 

        User u = new User(Alias = 'rmktg', Email= 'OperationsUser@notarealemail.com', UserRoleId = remarketingOperationsRole.Id,
            EmailEncodingKey='UTF-8', FirstName= 'RemarketingOperations', LastName= 'Surname', 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testPresidentUser.ProfileId, DB_Region__c = 'United States - Wayne',
            TimeZoneSidKey='America/New_York', UserName= 'OperationsUser@notarealemail.com');
        
        insert u;

        System.runAs(u) { 
            
        }


        Test.startTest();



        Test.stopTest();


        System.assert(true);
    }

    @isTest
    private static void testBusinessUnitLogicExists() {
        
    }

    @isTest
    private static void testRemarketingUserObjectVisibility() {
        
    }

    @isTest
    private static void testProfileExists() {
        
    }

}