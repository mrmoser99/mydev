/**
 * Test class for DocumentQuestionnaireTriggerHandler apex classes 
 * 
 * Version 1.0
 * 
 */
@IsTest
public with sharing class TestDocumentQuestionaireTriggerHandler {
    
     @TestSetup
     public static void setupTestData() {
         
         Profile sysAdminProf = [SELECT Id FROM Profile WHERE Name=:Constants.SYSTEM_ADMIN_PROFILE_NAME limit 1];
         UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
         
         User user = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Test System',
            EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = sysAdminProf.Id, userroleid=portalRole.id,
            TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com', 
            Legal_Entity_Description__c = 'DLL');   
         insert user;
         
         system.runAs(user) {
             
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
                .withRecordType(Constants.VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Account')
                .withRegion(testRegion.Id)
                .build(); 
                
            Account customerAccount = accountBuilder
                .withRecordType(Constants.END_USER_RECORD_TYPE_NAME)
                .withName('Test Customer Account')
                .withRegion(testRegion.Id)
                .build();     

            insert new List<SObject>{testOffer, account, customerAccount}; 

            TestApplicableOfferBuilder appOfferBuilder = new TestApplicableOfferBuilder();
            Applicable_Offer__c appOffer = appOfferBuilder
                .withName('Test Applicable Offer')
                .withAccount(account.Id)
                .withOffer(testOffer.Id)
                .insertRecord(true)
                .build(); 

            Contact leaseSignerContact = new Contact(
                LastName ='TestContact', 
                AccountId = customerAccount.Id, 
                Role__c = Constants.LEASE_SIGNER_CONTACT_ROLE, 
                Authorized_signatory_Text__c = 'Authorized Signatory Text',
                External_ID__c = '012345678', 
                Title = 'Title'
            ); 
            
            Contact leaseSignerContact2 = new Contact(
                LastName ='TestContact2', 
                AccountId = customerAccount.Id, 
                Role__c = Constants.LEASE_SIGNER_CONTACT_ROLE, 
                Authorized_signatory_Text__c = 'Authorized Signatory Text',
                External_ID__c = '123456789', 
                Title = 'Title2'
            ); 

            insert new List<Contact>{leaseSignerContact, leaseSignerContact2}; 

            TestDataFactory dataFactory = TestDataFactory.getInstance();
            Contact cont = dataFactory.buildContact('Das','Anujit','Developer',account,'93283282','anujit.das@cognziant.com');
            Profile p = [SELECT Id FROM Profile WHERE Name= :Constants.NORDICS_PROFILE_NAME limit 1];
        
            User portalUser = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='User',
                EmailEncodingKey='UTF-8', LastName='PartnerCommunityUser', LanguageLocaleKey='en_US', isActive=true,
                LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id, 
                TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');   
            insert portalUser;

            TestOpportunityBuilder oppBuilder = new TestOpportunityBuilder();
            Opportunity opportunity = oppBuilder
                .withRecordType(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Opportunity')
                .withAccount(account.Id)
                .withEndUser(customerAccount.Id)
                .insertRecord(false)
                .build();

            opportunity.OwnerId = portalUser.Id;

            
            TestOpportunityBuilder oppBuilder2 = new TestOpportunityBuilder();
            Opportunity opportunity2 = oppBuilder2
                .withRecordType(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Opportunity 2')
                .withAccount(account.Id)
                .withEndUser(customerAccount.Id)
                .insertRecord(false)
                .build();

            opportunity2.OwnerId = portalUser.Id;

            insert new List<Opportunity>{opportunity, opportunity2};

            Quote quote, quote1;

            // This code runs as the partner community user
            system.runAs(portalUser) {
                opportunity.Name = 'Test Opportunity'; 
                update opportunity;

                TestQuoteBuilder quoteBuilder = new TestQuoteBuilder();
                quote = quoteBuilder
                    .withName('Test Quote')
                    .withStatus(Constants.QUOTE_DOCUMENT_GEN_STATUS)
                    .withOpportunity(opportunity.Id)
                    .build();  
                
                TestQuoteBuilder quoteBuilder1 = new TestQuoteBuilder();
                quote1 = quoteBuilder1
                    .withName('Test Quote1')
                    .withStatus(Constants.QUOTE_DOCUMENT_GEN_STATUS)
                    .withOpportunity(opportunity.Id)
                    .build();  
                    
                insert new List<Quote>{quote, quote1};                 
                
                E_Sign_Information__c AodRecord = new E_Sign_Information__c(
                    Status__c = Constants.PENDING_CONTRACT_STATUS, 
                    Customer_Email__c = 'customer4.email@gmail.com', 
                    Document_Type__c = 'AOD',
                    Opportunity__c = opportunity.Id,
                    Quote__c = quote.Id,
                    Signer_Name__c = 'Signer Name1', 
                    SSN_Number__c = '12345999',
                    Document_Name__c = String.valueof('AOD' + opportunity.Name)
                );
                
                E_Sign_Information__c ContractRecord = new E_Sign_Information__c(
                    Status__c = Constants.COMPLETE_STATUS, 
                    Customer_Email__c = 'customer.email@gmail.com', 
                    Document_Type__c = 'Contract',
                    Opportunity__c = opportunity.Id,
                    Quote__c = quote1.Id,
                    Signer_Name__c = 'Signer Name', 
                    SSN_Number__c = '1234655999',
                    Document_Name__c = String.valueof(Constants.CONTRACT_DOCUMENT_TYPE + opportunity.Name)
                );
                
                insert new List<E_Sign_Information__c>{AodRecord, ContractRecord};
            }
                          
         }
         
     } 
    
    @IsTest
    static void getDocQuestionnaireInfo(){
        
        Quote quote = [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote'];
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Document_Type__c = 'AOD' AND Quote__c =: quote.Id];
        
        Test.startTest();
        Document_Questionnaire__c docQuestion = new Document_Questionnaire__c(
                    Question_Name__c = System.Label.Contract_Certified_as_Complete,
            //'Contract certified as complete',
                    Response__c = 'Yes',
                    Quote__c = quote.Id
         );
        insert docQuestion;
        Test.stopTest();
        
        E_Sign_Information__c updatedESignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Document_Type__c = 'AOD' AND Quote__c =: quote.Id];
        System.assertNotEquals(eSignInfo.Status__c, updatedESignInfo.Status__c); 
    }   

    @IsTest
    static void getDocQuestionnaireInfoUpdate(){
        
        Quote quote = [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote'];
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Document_Type__c = 'AOD' AND Quote__c =: quote.Id];
        Boolean excp = False; 
        
        Test.startTest();
        Document_Questionnaire__c docQuestion = new Document_Questionnaire__c(
                    Question_Name__c = 'Contract certified as complete',
                    Response__c = 'Yes',
                    Quote__c = quote.Id
         );
         insert docQuestion;
        
         try{
             docQuestion.Question_Name__c = 'test question';
             update docQuestion;  
         }
        catch(exception e){
            excp = true;  
        }
         Test.stopTest();
         System.assertNotEquals(excp, true); 
    }     
    
    @IsTest
    static void getDocQuestionnaireInfoContract(){
        
        Quote quote = [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote1'];
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Document_Type__c = 'Contract' AND Quote__c =: quote.Id];
        Boolean excp = False;
        
        Test.startTest();
        try{
            Document_Questionnaire__c docQuestion = new Document_Questionnaire__c(
                        Question_Name__c = 'Contract certified as complete',
                        Response__c = 'Yes',
                        Quote__c = quote.Id
             );
             insert docQuestion;
         }
        catch(exception e){
            excp = true;
         }
        Test.stopTest();
        System.assertNotEquals(excp, true); 
    }     
}