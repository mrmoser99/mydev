/**
* Test class for GenericUtilityClass class
* 
* Version 1.0
* 
*/
@isTest
public class TestGenericUtilityClass {
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
    private static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.Vendor;
    private static final String END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.End_User;
    
    @TestSetup
    static void setupData(){
        Profile prof = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        
        User user = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Anujit',
                             EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = prof.Id, userroleid=portalRole.id,
                             TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com', 
                             Legal_Entity_Description__c = 'DLL');   
        insert user;  
        system.runAs(user) { 
            TestDataFactory dataFactory = TestDataFactory.getInstance();
            TestRegionBuilder regionBuilder = new TestRegionBuilder();
            Region__c testRegion = regionBuilder
                .withName('Sweden')
                .withIsoCode('SE') 
                .insertRecord(true)
                .build();
            
            Program__c testProgram = new Program__c(Name = 'Test Program', Region__c = testRegion.Id); 
            Financial_Product__c financialProduct = new Financial_Product__c(Name = 'Test Financial Product', Type__c = 'Core');
            insert new List<SObject>{testProgram, financialProduct};
                
                TestOfferBuilder offerBuilder = new TestOfferBuilder();
            Offer__c testOffer = offerBuilder
                .withName('Test Offer')
                .withProgram(testProgram.Id)
                .withcoreFinancialProduct(financialProduct.Id)
                .build();
            
            TestAccountBuilder accountBuilder = new TestAccountBuilder();
            Account account = accountBuilder
                .withRecordType(VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Account')
                .withRegion(testRegion.Id)
                .build(); 
            
            Account customerAccount = accountBuilder
                .withRecordType(END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Customer Account')
                .withRegion(testRegion.Id)
                .withDoing_Business_As('Test Customer')
                .withOrg_No('Sample Org ')
                .withExternalId('124345667')
                .withFinalId('1645534')                
                .build();     
            
            insert new List<SObject>{testOffer, account, customerAccount};  
                 
            Contact cont = dataFactory.buildContact('Name','Test','Developer',account,'000000000','testEmail@test.com');
            
            TestApplicableOfferBuilder appOfferBuilder = new TestApplicableOfferBuilder();
            Applicable_Offer__c appOffer = appOfferBuilder
                .withName('Test Applicable Offer')
                .withAccount(account.Id)
                .withOffer(testOffer.Id)
                .build();  
            
            	insert new List<SObject>{appOffer};   
                
            TestOpportunityBuilder oppBuilder = new TestOpportunityBuilder();
            Opportunity opportunity = oppBuilder
                    .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                    .withName('Test Opportunity')
                    .withAccount(account.Id)
                    .withEndUser(customerAccount.Id)
                    .insertRecord(true)
                    .build(); 
                 
                    
            TestQuoteBuilder quoteBuilder = new TestQuoteBuilder();
            Quote quote = quoteBuilder
                    .withName('Test Quote')
                    .withStatus('Documents Generated')
                    .withOpportunity(opportunity.Id)
                    .withApplicableOffer(appOffer.Id)
                    .build();
                
           TestQuoteBuilder quoteBuilder2 = new TestQuoteBuilder();
           Quote quote2 = quoteBuilder
                    .withName('Test Quote 2')
                    .withStatus('Documents Generated')
                    .withOpportunity(opportunity.Id)
                    .withApplicableOffer(appOffer.Id)
                    .build(); 
                
            insert new List<Quote>{quote, quote2};    
            Blob bodyBlob = Blob.valueOf('Some string');
            
            Attachment objAttach = dataFactory.buildAttachment('test.pdf',opportunity.id,bodyBlob,false);
            
            EmailTemplate emailTemplateObj = dataFactory.buildEmailTemplate('TestDeveloper','Text','TestEmailTemplate',userInfo.getUserId(),true,false);
            insert new list<sObject>{objAttach,emailTemplateObj};
                
     }
    }
    @IsTest
    static void testUtility(){
        
        GenericUtilityClass.getSessionId(); 
        GenericUtilityClass.isSafeObject('Account');
        GenericUtilityClass.isSafeField('CreatedById', 'Account');
    }
    @IsTest
    static void testCreateAttachments() {
            Opportunity opportunity = [SELECT id,Name FROM Opportunity WHERE createdby.email = 'sysadmin876@testorg.com'];
            GenericUtilityClass.AttachmentInfo attachmentInfoObj = new GenericUtilityClass.AttachmentInfo(opportunity.id,'Test Name','Test String');
            List<GenericUtilityClass.AttachmentInfo> attachmentData = new List<GenericUtilityClass.AttachmentInfo>{attachmentInfoObj};
                
           user user_running = [select id,name from user where Email='sysadmin876@testorg.com'];
           system.runAs(user_running){
            
                Test.startTest();
                GenericUtilityClass.createAttachments(attachmentData);
                Test.stopTest();
                Attachment attachment = [SELECT name FROM Attachment WHERE contentType = 'application/pdf'];
                System.assertEquals('Test Name', attachment.name);
        }
        
    }
    @IsTest
    static void testCreateAndAttachFilesToRecords() {
        
        Opportunity opportunity = [SELECT id,Name FROM Opportunity WHERE createdby.email = 'sysadmin876@testorg.com'];
        Quote quote = [SELECT id FROM Quote WHERE Name = 'Test Quote'];
        Set<Id> recordIdsToAttach = new Set<Id>{opportunity.id,quote.id};
            GenericUtilityClass.DocumentInfo documentsInfoObj = new GenericUtilityClass.DocumentInfo('Test Name','contract','Test String');
        List<GenericUtilityClass.DocumentInfo> documentsInfo = new  List<GenericUtilityClass.DocumentInfo>{documentsInfoObj};
            
            user user_running = [select id,name from user where Email='sysadmin876@testorg.com'];
        system.runAs(user_running){
            
            Test.startTest();
            GenericUtilityClass.createAndAttachFilesToRecords(documentsInfo,recordIdsToAttach);
            Test.stopTest();
            
            ContentVersion newContent = [SELECT Title FROM ContentVersion WHERE Document_Type__c ='contract'];
            System.assertEquals('Test Name', newContent.Title);
        }
        
    }
    @IsTest
    static void testCreateEmailMessageAndsendEmailMessages() {
        
        String address = 'testEmail@test.com';
        List<String> addresses = new List<String>();
        addresses.add(address);
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Id templateId = [SELECT id FROM EmailTemplate WHERE Name = 'TestEmailTemplate'].id;
        Account testAcc = [select id from account where Name='Test Account' LIMIT 1];
        Id targetObjectId = [SELECT id FROM Contact WHERE accountid =: testAcc.id].id;
        Id whatId = [SELECT id FROM Opportunity WHERE createdby.email = 'sysadmin876@testorg.com'].id;
        
        Id emailAddressId = [SELECT id FROM OrgWideEmailAddress LIMIT 1].id;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Boolean isException = false;
        user user_running = [select id,name from user where Email='sysadmin876@testorg.com'];
        system.runAs(user_running){
            
            Test.startTest();
            try{
                Messaging.SingleEmailMessage singleEmailMessageTest = GenericUtilityClass.createEmailMessage(addresses,attachments,templateId,targetObjectId,whatId,emailAddressId);
                messages.add(singleEmailMessageTest);
                GenericUtilityClass.sendEmailMessages(messages);
            }catch(Exception e){
                isException = true;
            }            
            Test.stopTest(); 
            System.assertEquals(false, isException);
        }  
    }
    
    @IsTest
    static void testGetAttachments() {
        
        Map<String,String> documentsToAttach = new Map<String,String>();
        documentsToAttach.put('AOD','TestAODBody');
        user user_running = [select id,name from user where Email='sysadmin876@testorg.com'];
        system.runAs(user_running){
            
            Test.startTest();
            List<Messaging.EmailFileAttachment> attacments = GenericUtilityClass.getAttachments(documentsToAttach);
            Test.stopTest();
            System.assertEquals('AOD.pdf',attacments[0].filename);
        }        
    }
    
}