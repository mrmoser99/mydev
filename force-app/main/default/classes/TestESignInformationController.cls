/**
 * Test class for ESignInformationController, ESignInformationTriggerHandler apex classes 
 * 
 * Version 1.0
 * 
 */
@IsTest
public with sharing class TestESignInformationController {

    @TestSetup
    static void makeData(){
        Profile sysAdminProf = [SELECT Id FROM Profile WHERE Name=:Constants.SYSTEM_ADMIN_PROFILE_NAME limit 1];
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
         
        User user = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Test System',
            EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = sysAdminProf.Id, userroleid=portalRole.id,
            TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com', 
            Legal_Entity_Description__c = 'DLL');   
        insert user;

        // This code runs as the system admin
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

            Quote quote;

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

                TestQuoteBuilder quoteBuilder2 = new TestQuoteBuilder();
                Quote quote2 = quoteBuilder2
                    .withName('Test Quote 2')
                    .withStatus(Constants.QUOTE_DOCUMENT_GEN_STATUS)
                    .withOpportunity(opportunity.Id)
                    .build(); 

                TestQuoteBuilder quoteBuilder3 = new TestQuoteBuilder();
                Quote quote3 = quoteBuilder3
                    .withName('Test Quote 3')
                    .withStatus(Constants.QUOTE_DOCUMENT_GEN_STATUS)
                    .withOpportunity(opportunity2.Id)
                    .build();    
                    
                insert new List<Quote>{quote, quote2, quote3}; 

                Document_Questionnaire__c docQuestion = new Document_Questionnaire__c(
                    Question_Name__c = 'Question Name',
                    Response__c = 'Yes',
                    Quote__c = quote.Id
                );
                insert docQuestion;

                E_Sign_Information__c eSignInfoNew = new E_Sign_Information__c(
                    Status__c = Constants.NEW_STATUS, 
                    Customer_Email__c = 'customer.email@gmail.com', 
                    Document_Type__c = Constants.CONTRACT_DOCUMENT_TYPE,
                    Opportunity__c = opportunity.Id,
                    Document_Name__c = String.valueof(Constants.CONTRACT_DOCUMENT_TYPE + opportunity.Name),
                    Quote__c = quote.Id 
                );  
                
                E_Sign_Information__c eSignInfoActive = new E_Sign_Information__c(
                    Status__c = Constants.ACTIVE_STATUS, 
                    Customer_Email__c = 'customer2.email@gmail.com', 
                    Document_Type__c = Constants.CONTRACT_DOCUMENT_TYPE,
                    Opportunity__c = opportunity.Id,
                    Quote__c = quote.Id,
                    Document_Name__c = String.valueof(Constants.CONTRACT_DOCUMENT_TYPE + opportunity.Name),
                    Signer_Name__c = 'Signer Name', 
                    SSN_Number__c = '12345678'
                );
                
                E_Sign_Information__c eSignInfoComplete = new E_Sign_Information__c(
                    Status__c = Constants.COMPLETE_STATUS, 
                    Customer_Email__c = 'customer3.email@gmail.com', 
                    Document_Type__c = 'Contract',
                    Opportunity__c = opportunity.Id,
                    Quote__c = quote.Id,
                    Signer_Name__c = 'Signer Name0', 
                    Document_Name__c = String.valueof(Constants.CONTRACT_DOCUMENT_TYPE + opportunity.Name),
                    SSN_Number__c = '12345888'
                );
                
                E_Sign_Information__c AodRecord = new E_Sign_Information__c(
                    Status__c = Constants.PENDING_CONTRACT_STATUS, 
                    Customer_Email__c = 'customer4.email@gmail.com', 
                    Document_Type__c = 'AOD',
                    Opportunity__c = opportunity.Id,
                    Quote__c = quote.Id,
                    Signer_Name__c = 'Signer Name1', 
                    Document_Name__c = String.valueof('AOD' + opportunity.Name),
                    SSN_Number__c = '12345999'
                );
                
                insert new List<E_Sign_Information__c>{eSignInfoNew, eSignInfoActive, AodRecord, eSignInfoComplete};
            }

            Blob bodyBlob = Blob.valueOf('Some string');

            ContentVersion newContent = new ContentVersion();
            newContent.Title = Constants.CONTRACT_DOCUMENT_TYPE;
            newContent.VersionData = bodyBlob;
            newContent.PathOnClient = 'Contract.pdf';
            newContent.Document_Type__c = Constants.CONTRACT_DOCUMENT_TYPE;
            insert newContent;

            ContentVersion content = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContent.Id];

            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.LinkedEntityId = quote.Id;
            docLink.ContentDocumentId = content.ContentDocumentId;
            docLink.ShareType = 'V';
            docLink.Visibility = 'AllUsers';
            insert docLink;
        }
    }

    @IsTest
    static void testGetESignInfomation() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        System.runAs(portalUser) {
            Test.startTest();
            String eSignInfo = ESignInformationController.getESignInfomation(quote.Id);
            Test.stopTest();

            List<E_Sign_Information__c> orderInfo = (List<E_Sign_Information__c>) JSON.deserialize(eSignInfo, List<E_Sign_Information__c>.class);

            System.assertEquals(4, orderInfo.size());
        }
    }

    @IsTest
    static void testCancelSignatureWithNewStatus() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer.email@gmail.com'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];
        
        System.runAs(portalUser) {
            Test.startTest();
            String cancelResult = ESignInformationController.cancelSignture(eSignInfo.Id);
            Test.stopTest();
            
            E_Sign_Information__c updatedESignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer.email@gmail.com'];

            System.assertEquals(Label.Order_has_been_canceled, ((Map<String,Object>) JSON.deserializeUntyped(cancelResult)).get('Success message'));
            System.assertEquals(Constants.NEW_STATUS,  eSignInfo.Status__c);
            System.assertEquals(Constants.CANCELLED_STATUS,  updatedESignInfo.Status__c);
        }
    }

    @IsTest
    static void testCancelSignatureWithActiveStatus() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer2.email@gmail.com'];
        String responseBody = '{"Item":{"OrderID":"a2D1F000002OjY1UAK","TransRef":"685E82D7C2303762827367980F0A0ECE51C2B244"},"MerchantID":1587,"Time":"2021-06-25T13:16:48+00:00","MessageID":"00000000-0000-0000-0000-000000000000","AdditionalInfo":null}';
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);

        System.runAs(portalUser) {
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            String cancelResult = ESignInformationController.cancelSignture(eSignInfo.Id);
            Test.stopTest();
            
            E_Sign_Information__c updatedESignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer2.email@gmail.com'];

            System.assertEquals(Label.Order_has_been_canceled, ((Map<String,Object>) JSON.deserializeUntyped(cancelResult)).get('Success message'));
            System.assertEquals(Constants.ACTIVE_STATUS,  eSignInfo.Status__c);
            System.assertEquals(Constants.CANCELLED_STATUS,  updatedESignInfo.Status__c);
        }
    }

    @IsTest
    static void testGetAuthorizedSignatoriesInfo() {
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        System.runAs(portalUser) {
            Test.startTest();
            String result = ESignInformationController.getAuthorizedSignatoriesInfo(opportunity.Id);
            Test.stopTest();

            List<Contact> contacts = (List<Contact>) JSON.deserialize(result, List<Contact>.class);
            System.assertEquals(2, contacts.size());
            System.assertEquals('Authorized Signatory Text',  contacts[0].Authorized_signatory_Text__c);
        }
    }

    @IsTest
    static void testGetEsignInfoString() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer.email@gmail.com'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        System.runAs(portalUser) {
            Test.startTest();
            String result = ESignInformationController.getEsignInfoString(eSignInfo.Id);
            Test.stopTest();

            E_Sign_Information__c receivedESignInfo = (E_Sign_Information__c) JSON.deserialize(result, E_Sign_Information__c.class);
            System.assertEquals(eSignInfo.Status__c, receivedESignInfo.Status__c);
        }
    }

    @IsTest
    static void testCreateEsignOrderPositive() {
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity'];
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        ESignInformationController.EsignInfoClass eSignInfo1 = new ESignInformationController.EsignInfoClass();
        eSignInfo1.email = 'test.email1@gmail.com';
        eSignInfo1.opptyId = opportunity.Id;
        eSignInfo1.docType = Constants.CONTRACT_DOCUMENT_TYPE;
        eSignInfo1.quoteId = quote.Id;
        eSignInfo1.primaryProduct = 'Primary Product 1';
        eSignInfo1.primaryProductDesc = 'Primary Product Description 1';
        
        ESignInformationController.EsignInfoClass eSignInfo2 = new ESignInformationController.EsignInfoClass();
        eSignInfo2.email = 'test.email2@gmail.com';
        eSignInfo2.opptyId = opportunity.Id;
        eSignInfo2.docType = Constants.AOD_DOCUMENT_TYPE;
        eSignInfo2.quoteId = quote.Id;
        eSignInfo2.primaryProduct = 'Primary Product 2';
        eSignInfo2.primaryProductDesc = 'Primary Product Description 2';

        String params = JSON.serialize(new List<ESignInformationController.EsignInfoClass>{eSignInfo1, eSignInfo2});

        System.runAs(portalUser) {
            Test.startTest();
            Boolean result = ESignInformationController.createEsignOrder(params);
            Test.stopTest();

            System.assertEquals(true, result);
        }
    }

    @IsTest
    static void testCreateEsignOrderNegative1() {
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity'];
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        ESignInformationController.EsignInfoClass eSignInfo1 = new ESignInformationController.EsignInfoClass();
        eSignInfo1.email = 'customer.email@gmail.com';
        eSignInfo1.opptyId = opportunity.Id;
        eSignInfo1.docType = Constants.CONTRACT_DOCUMENT_TYPE;
        eSignInfo1.quoteId = quote.Id;
        eSignInfo1.primaryProduct = 'Primary Product 1';
        eSignInfo1.primaryProductDesc = 'Primary Product Description 1';

        String params = JSON.serialize(new List<ESignInformationController.EsignInfoClass>{eSignInfo1});

        Boolean exception1 = false;

        System.runAs(portalUser) {
            Test.startTest();
            try {
                Boolean result = ESignInformationController.createEsignOrder(params);
            } catch (Exception e) {
                exception1 = true;
            }
            Test.stopTest();

            String errorMessage = String.format(
                Label.E_Sign_Info_Error_Same_Document_Type_And_Email,
                new List<String>{'customer.email@gmail.com', 'Contract'}
            );

            System.assertEquals(true, exception1);
        }
    }

    @IsTest
    static void testCreateEsignOrderNegative2() {
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Opportunity'];
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote 2'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        ESignInformationController.EsignInfoClass eSignInfo1 = new ESignInformationController.EsignInfoClass();
        eSignInfo1.email = 'test.email@gmail.com';
        eSignInfo1.opptyId = opportunity.Id;
        eSignInfo1.docType = Constants.CONTRACT_DOCUMENT_TYPE;
        eSignInfo1.quoteId = quote.Id;
        eSignInfo1.primaryProduct = 'Primary Product 1';
        eSignInfo1.primaryProductDesc = 'Primary Product Description 1';

        String params = JSON.serialize(new List<ESignInformationController.EsignInfoClass>{eSignInfo1});

        Boolean exception1 = false;

        System.runAs(portalUser) {
            Test.startTest();
            try {
                Boolean result = ESignInformationController.createEsignOrder(params);
            } catch (Exception e) {
                exception1 = true;
            }
            Test.stopTest();

            String errorMessage = String.format(
                Label.E_Sign_Info_Error_Signing_Is_Pending_For_Another_Version,
                new List<String>{'Test Opportunity', 'Test Quote 1'}
            );

            System.assertEquals(true, exception1);
        }
    }

    @IsTest
    static void getPDFs() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        System.runAs(portalUser) {
            Test.startTest();
            String result = ESignInformationController.getPDFs(quote.Id);
            Test.stopTest();

            Map<ID, String> mapIdTitle = (Map<ID, String>) JSON.deserialize(result,Map<ID, String>.class);
            System.assertEquals(false, mapIdTitle.isEmpty());
        }
    }
    
    @IsTest
    static void testCreateContact() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c FROM E_Sign_Information__c WHERE Status__c LIKE 'Active'];
        Contact contactInfo = [SELECT Id FROM Contact WHERE External_ID__c = '123456789' LIMIT 1];

        String ContactJSON = '[{"contactName":"Anujit Partner","ssn":"12345678","orderId": "' + eSignInfo.id + '","ultimateBenOwner":true}]';
        Test.startTest();
        ESignInformationController.createAndDeleteContact(ContactJSON, new List<Id>{contactInfo.Id},eSignInfo.id);
        ESignInformationController.createAndDeleteContact(ContactJSON, new List<Id>{contactInfo.Id},eSignInfo.id);
        Test.stopTest();

        System.assertEquals(false, [SELECT Id FROM Contact WHERE External_ID__c = '12345678'].isEmpty());
        System.assertEquals(true, [SELECT Id FROM Contact WHERE External_ID__c = '123456789'].isEmpty());
        System.assertEquals(true, [SELECT Ultimate_Beneficial_Owner__c FROM Account WHERE Id = :eSignInfo.Opportunity__r.End_User__c].Ultimate_Beneficial_Owner__c);
    }
    
    @IsTest
    static void testCreateContactNegative() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c FROM E_Sign_Information__c WHERE Status__c LIKE 'Active'];
        Boolean exp = false; 
        
        String ContactJSON = '[{"contactName":"","ssn":"","orderId": "' + eSignInfo.id + '","ultimateBenOwner": false}]';
        Test.startTest();
        ESignInformationController.createAndDeleteContact(ContactJSON, null,eSignInfo.id);
        Test.stopTest();

        System.assertEquals(false, [SELECT Ultimate_Beneficial_Owner__c FROM Account WHERE Id = :eSignInfo.Opportunity__r.End_User__c].Ultimate_Beneficial_Owner__c);
    }
    
    @IsTest
    static void testGetExistingContactsAsString() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer.email@gmail.com'];
        String ContactJSON = '[{"contactName":"Anujit Partner","ssn":"12345678","orderId": "' + eSignInfo.id + '","ultimateBenOwner":true}]';
        
        Test.startTest();
        ESignInformationController.createAndDeleteContact(ContactJSON, null,eSignInfo.id);
        String result = ESignInformationController.getExistingContactsString(eSignInfo.Id);
        Test.stopTest();

        List<ESignInformationController.ContactWrapperClass> contacts = 
            (List<ESignInformationController.ContactWrapperClass>) JSON.deserialize(result, List<ESignInformationController.ContactWrapperClass>.class);

        System.assertEquals(false, contacts.isEmpty());
        System.assertEquals('Anujit Partner', contacts[0].contactName);
    }

    @IsTest
    static void testGetDocumentByType() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        User portalUser = [SELECT Id FROM User WHERE LastName='PartnerCommunityUser'];

        System.runAs(portalUser) {
            Test.startTest();
            List<ContentVersion> docs = ESignInformationController.getDocumentsByQuoteId(quote.Id);
            ContentVersion doc = ESignInformationController.getDocumentByType(docs, Constants.CONTRACT_DOCUMENT_TYPE);
            Test.stopTest();

            System.assertEquals(Constants.CONTRACT_DOCUMENT_TYPE, doc.Title);
            System.assertEquals(Constants.CONTRACT_DOCUMENT_TYPE, doc.Document_Type__c);
        }
    }

    @IsTest
    static void testGetCheckListQuestion() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];

        Test.startTest();
        List<ESignInformationController.DocumentQuestionClass> questions = ESignInformationController.getCheckListQuestion(quote.Id);
        Test.stopTest();

        System.assertEquals(false, questions.isEmpty());
    }
    
      @IsTest
    static void testStandardAuthCustomMeta() {
        

        Test.startTest();
       Standard_Auth_Credentials__mdt mdt = ESignInformationController.getStandardAuthCustomMeta('E_Sign_Creds');
        
        Test.stopTest();

        System.assert(mdt!=null);
        
    }
    
    @IsTest
    static void testDoSaveInvoiceData() {
        
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c FROM E_Sign_Information__c WHERE Status__c LIKE 'Active'];
        Id AccountId = eSignInfo.Opportunity__r.End_User__c;
        //Contact contactInfo = [SELECT Id FROM Contact WHERE External_ID__c = '123456789' LIMIT 1];
        
        String invoiceData = '{"invoiceType":"Letter","pepolIdValue":"12345678","pdfEmailValue":"TestPDFValue","pdfReferenceValue":"TestPDFReference","letterCoNameValue":"TestLetterCOName","letterAdresValue":"TestLetterAddress","letterPoNumValue":"TestLetterPONum","letterCityValue":"TestLetterCity","letterCountryValue":"TestLetterCountry","letterReferenceValue":"TestLetterReference","orderId": "' + eSignInfo.id +'","ediRefrenceValue":"TestEDIReference"}';
        
        Test.startTest();
       	ESignInformationController.doSaveInvoiceData(invoiceData);
        Test.stopTest(); 
        Account acc = [SELECT Id FROM Account WHERE Invoice_Type__c =: Constants.LETTER];
        System.assertEquals(acc.id,AccountId);
        
    }
    
    @IsTest
    static void testDoSaveInvoiceDataNegative() {
        
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c FROM E_Sign_Information__c WHERE Status__c LIKE 'Active'];
        Id AccountId = eSignInfo.Opportunity__r.End_User__c;
        //Contact contactInfo = [SELECT Id FROM Contact WHERE External_ID__c = '123456789' LIMIT 1];
        
        String invoiceData = '{"invoiceType":"","pepolIdValue":"12345678","pdfEmailValue":"TestPDFValue","pdfReferenceValue":"TestPDFReference","letterCoNameValue":"TestLetterCOName","letterAdresValue":"TestLetterAddress","letterPoNumValue":"TestLetterPONum","letterCityValue":"TestLetterCity","letterCountryValue":"TestLetterCountry","letterReferenceValue":"TestLetterReference","orderId": "' + eSignInfo.id +'","ediRefrenceValue":"TestEDIReference"}';
        String invoiceData1 = '{"invoiceType":"TestInvoiceType","pepolIdValue":"12345678","pdfEmailValue":"TestPDFValue","pdfReferenceValue":"TestPDFReference","letterCoNameValue":"TestLetterCOName","letterAdresValue":"TestLetterAddress","letterPoNumValue":"TestLetterPONum","letterCityValue":"TestLetterCity","letterCountryValue":"TestLetterCountry","letterReferenceValue":"TestLetterReference","orderId": "' + eSignInfo.id +'","ediRefrenceValue":"TestEDIReference"}';
        
        Test.startTest();
       	ESignInformationController.doSaveInvoiceData(invoiceData);
        ESignInformationController.doSaveInvoiceData(invoiceData1);
        Test.stopTest(); 
       
        
    }

    
    @IsTest 
    static void testGetExistingContactsAsString1() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c ,Status__c FROM E_Sign_Information__c WHERE Customer_Email__c = 'customer.email@gmail.com'];

        Test.startTest();
		eSignInfo.Opportunity__r.End_User__c = null;
        String result = ESignInformationController.getExistingContactsString(eSignInfo.Id);
        Test.stopTest();

    }
    
    @IsTest 
    static void testUpdatedQuoteWithSignedContract() {
        Quote quote = [SELECT Id, Status,OpportunityId FROM Quote WHERE Name LIKE 'Test Quote 3'];
        Id opportunity = quote.OpportunityId;
        E_Sign_Information__c eSignInfo = new E_Sign_Information__c(
            Status__c = Constants.NEW_STATUS, 
            Customer_Email__c = 'customer.email@gmail.com.test', 
            Document_Type__c = Constants.CONTRACT_DOCUMENT_TYPE,
            Opportunity__c = opportunity,
            Quote__c = quote.Id,
            Document_Name__c = 'Contract Test Opportunity 2'
        );
        insert eSignInfo;

        Test.startTest();
        update new E_Sign_Information__c(
            Status__c = Constants.COMPLETE_STATUS, 
            Id = eSignInfo.Id
        );
        Test.stopTest();

        Quote updatedQuote = [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote 3'];
        System.assertNotEquals(quote.Status, updatedQuote.Status);
        System.assertEquals(Constants.QUOTE_PENDING_VALIDATION_STATUS, updatedQuote.Status);
    }

	
    @IsTest
    static void testCreateContactNegative1() {
        E_Sign_Information__c eSignInfo = [SELECT Id, Opportunity__r.End_User__c FROM E_Sign_Information__c WHERE Status__c LIKE 'Active'];
        
        
        String ContactJSON = '[{"contactName":" ","ssn":"","orderId": "' + eSignInfo.id + '","ultimateBenOwner": true}]';
        
        Test.startTest();
        ESignInformationController.createAndDeleteContact(ContactJSON, null,eSignInfo.id);
        
        Test.stopTest();
  		System.assertEquals(1, [SELECT Id FROM Error_Log__c].size());
        
    }
           
    @IsTest
    static void testUpdateESignInfoNegative() {
       
        Test.startTest();
        ESignInformationController.updateESignInfo(new Map<String,Object>{
            'Id' => null, 
                'Status__c' => Constants.CANCELLED_STATUS
                });
        
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM Error_Log__c].size());
    }
    
    @IsTest
    static void testSendDoc() {
                                   
        String docsStr = '{"questionName":"TestQuestionName","response":"TestResponse","comment":"TestComment","reasonCode":"TestReasonCode","docType":"TestDocType","dealName":"TestDealName","uploadDocList":[{"filename":"TestFilename","base64":"TestBase64"}]}';

		Test.startTest();
        ESignInformationController.uploadFileinReviewScreen(docsStr);
        Test.stopTest();

    }
    
    @IsTest
    static void testGetMultipleSignerInfo() {
                                   
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote'];
        
		Test.startTest();
        String signingStatus = ESignInformationController.getMultipleSignerInfo(quote.id,'ContractTest Opportunity');
        Test.stopTest();
        
        System.assertEquals(signingStatus,'Complete');

    }

}