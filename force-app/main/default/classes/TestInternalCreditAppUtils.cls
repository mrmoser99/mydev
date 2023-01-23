/**
 * @description       : Testing all non API methods for InternalCreditApp Submission from an Opportunity Record
 * @author            : Adam Tolbert   
 * @group             : 
 * @last modified on  : 1-12-2023
 * @last modified by  : Adam Tolbert
**/
@isTest
public with sharing class TestInternalCreditAppUtils {
   
    
	class TestData {
		String endUserAcctName = 'Clienta Nonreal';
		String endUserAcctCity = 'Atlanta';
		String endUserAcctState = 'GA';

		String vendorAcctName = 'Vendedora Nonreal';
		String vendorAcctCity = 'Atlanta';
		String vendorAcctState = 'GA';
		String vendorOriginatingSiteId = '0000105570_0001';
		String vendorProgramId = '1604';
		String vendorProductId = '1360.3080';
	
		String vendorContactFirstName = 'Rodrigo';
		String vendorContactLastName = 'Bentancour';
		
		String oppName = 'Nombre de Opp Nonreal';
		String oppStage = 'Quoting';
		String oppType = 'New';
		Integer oppAmount = 75000;
		Date oppCloseDate = Date.today().addDays(30);
	
		String quoteName = 'Cotiza falsa';
		String testMakeId = '30001422';
		String testAssetId = '31005498';

		String tcaPartySystemIdType = 'TCAPartyId';
		String tcaPartyId = '52658243';

        Decimal paymentAmount = 123.45;
        Decimal financeTermLength = 123.45;

        Map<String, String> testCustomerStory = new Map<String, String>{
            'customerStoryId' => '',
            'yearsInBusiness' => '1.10',
            'story' => 'Esto es una fabula sobre la clienta',
            'amount' => '2000.25',
            'salesRepId' => '',
            'location' => ''
        };

	}

	@testSetup
	static void makeData() {

		TestData tData = new TestData();
		TestDataFactory dataFactory = TestDataFactory.getInstance();

		Account vendorAcct = new Account(name = tData.vendorAcctName, Originating_Site_Id__c = tData.vendorOriginatingSiteId, BillingCity = tData.vendorAcctCity, BillingState = tData.vendorAcctState);
		vendorAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
		insert vendorAcct;

		Account endUserAcct = new Account(name = tData.endUserAcctName, BillingCity = tData.endUserAcctCity, BillingState = tData.endUserAcctState);
		endUserAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();
		insert endUserAcct;

		System_ID__c s = new System_Id__c(Account__c = endUserAcct.id, DLL_External_Key_Source__c = 'ORACLE', DLL_External_id__c = tData.tcaPartyId, DLL_External_Key_Type__c = tData.tcaPartySystemIdType);
		insert s;

		Contact vendorContact = new Contact(firstName = tData.vendorContactFirstName, lastName = tData.vendorContactLastName, accountId = vendorAcct.id, Role__c='Partner Sales Rep');
		insert vendorContact;

		Contact endUserContact = new Contact(firstName = 'Test', lastName = 'Dog', accountId = endUserAcct.id, Role__c = 'Ultimate Beneficial Owner');
		insert endUserContact;

		String oppRecordTypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
		Opportunity opp = dataFactory.buildOpportunity(tData.oppName ,tData.oppStage ,tData.oppCloseDate, tData.oppType , oppRecordTypeId, vendorAcct.Id, tData.oppAmount, Test.getStandardPricebookId());

		Related_Party__c rp = new Related_Party__c(First_name__c = 'test', Last_name__c = 'cat', Address_line__c = '430 dog head lane', City__c = 'Pet Ville', SSN_encrypted__c = '989112222', Opportunity__c = opp.id);
		insert rp;

		Quote q = new Quote (name = tData.quoteName, opportunityId = opp.id, End_User__c = endUserAcct.Id, lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly', payment_timing__c = 'in-arrears');
		insert q;
	
		Quote_Line__c assetLine = new Quote_Line__c(quote__c = q.id, Number_of_Units__c = 5, Base_Unit_Sales_Price__c = 10.21);
		insert assetLine;

		Quote_Line__c relatedAssetLine = new Quote_Line__c(quote__c = q.id, Related_Asset__c = assetLine.Id, Number_of_Units__c = 5, Base_Unit_Sales_Price__c = 10.21);
		insert relatedAssetLine;

		opp.End_User__c = endUserAcct.Id;
		opp.SyncedQuoteId = q.Id;
		update opp;

	}


	@isTest
	private static void sanityTest() {
	
		TestData tData = new TestData();
	
		Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
		System.assertNotEquals(null, endUserAcct.Id, 'Failed to create the test account as expected');
		Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
		System.assertNotEquals(null, vendorAcct.Id, 'Failed to create the test account as expected');
	
		Contact vendorContact = [SELECT Id, Name FROM Contact WHERE LastName = :tData.vendorContactLastName AND AccountId = :vendorAcct.Id];
		System.assertNotEquals(null, vendorContact.Id, 'Failed to create the test account as expected');
	
		Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];
		System.assertNotEquals(null, testOpp.Id, 'Failed to create the test opp as expected');
	
		Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName AND OpportunityId = :testOpp.Id];
		System.assertNotEquals(null, testQuote.Id, 'Failed to create the test quote as expected');
	
		Quote_Line__c testQuoteLine = [SELECT Id, Name, Related_Asset__c FROM Quote_Line__c WHERE Quote__c = :testQuote.Id AND Related_Asset__c != null];
		System.assertNotEquals(null, testQuoteLine.Id, 'Failed to create the test quote line as expected');

		Quote_Line__c relatedAssetQuoteLine = [SELECT Id, Name FROM Quote_Line__c WHERE Id = :testQuoteLine.Related_Asset__c];
		System.assertNotEquals(null, relatedAssetQuoteLine.Id, 'Failed to create the related asset quote line as expected');
	
	}


	// @isTest
	// private static void testGetCustomerId_Opp() {

	// 	TestData tData = new TestData();

	// 	Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
	// 	Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE End_User__c = :endUserAcct.Id LIMIT 1];
	
	// 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
	// 	mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
	// 	mock.setStatusCode(200);
	// 	mock.setHeader('Content-Type', 'application/json');
	// 	Test.setMock(HttpCalloutMock.class, mock);
	
	// 	Test.startTest();
		
	// 		String customerId = InternalCreditAppUtils.getCustomerId(testOpp.Id, 0);
		
	// 	Test.stopTest();

	// 	System.assertEquals(endUserAcct.Id, customerId, 'Failed to return the customer account Id as expected');

	// }

	// @isTest
	// private static void testGetCustomerId_Quote() {

	// 	TestData tData = new TestData();

	// 	Quote testQuote = [SELECT Id, Name, End_User__c FROM Quote WHERE Name = :tData.quoteName];
	
	// 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
	// 	mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
	// 	mock.setStatusCode(200);
	// 	mock.setHeader('Content-Type', 'application/json');
	// 	Test.setMock(HttpCalloutMock.class, mock);
	
	// 	Test.startTest();
		
	// 		String customerId = InternalCreditAppUtils.getCustomerId(testQuote.Id, 999);
		
	// 	Test.stopTest();

	// 	System.assertEquals(testQuote.End_User__c, customerId, 'Failed to return the customer account Id as expected');

	// }

	// @isTest
	// private static void testUpdateCustomerId_Opp() {

	// 	TestData tData = new TestData();

	// 	Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
	// 	Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE End_User__c = :endUserAcct.Id LIMIT 1];
		
	// 	Account newAcct = new Account(name = 'New EndUser Account', Originating_Site_Id__c = '1230987');
	// 	insert newAcct;

	// 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
	// 	mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
	// 	mock.setStatusCode(200);
	// 	mock.setHeader('Content-Type', 'application/json');
	// 	Test.setMock(HttpCalloutMock.class, mock);
	
	// 	Test.startTest();
		
	// 		String successMessage = InternalCreditAppUtilsWithoutSharing.updateCustomerId(true, testOpp.Id, newAcct.Id);
		
	// 	Test.stopTest();
		
	// 	System.assertEquals('ok', successMessage, 'Failed to return an ok message as expected');


	// 	Opportunity updatedOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE Id = :testOpp.Id];

	// 	System.assertEquals(updatedOpp.End_User__c, newAcct.Id, 'Failed to update the opportunity with the new Account Id');

	// }


	// @isTest
	// private static void testUpdateCustomerId_Quote() {

	// 	TestData tData = new TestData();

	// 	Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
	// 	Quote testQuote = [SELECT Id, Name, End_User__c FROM Quote WHERE Name = :tData.quoteName];

	// 	Account newAcct = new Account(name = 'New EndUser Account', Originating_Site_Id__c = '1230987');
	// 	insert newAcct;

	// 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
	// 	mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
	// 	mock.setStatusCode(200);
	// 	mock.setHeader('Content-Type', 'application/json');
	// 	Test.setMock(HttpCalloutMock.class, mock);
	
	// 	Test.startTest();
		
	// 		String successMessage = InternalCreditAppUtilsWithoutSharing.updateCustomerId(false, testQuote.Id, newAcct.Id);
	// 		System.assertEquals('ok', successMessage, 'Failed to return an ok message as expected');
		
	// 	Test.stopTest();
		

	// 	Quote updatedQuote = [SELECT Id, Name, End_User__c FROM Quote WHERE Id = :testQuote.Id];

	// 	System.assertEquals(updatedQuote.End_User__c, newAcct.Id, 'Failed to update the quote with the new Account Id');

	// }
	


	// @isTest
	// private static void testCreateExternalCustomer_CreateNewTCA() {

	// 	TestData tData = new TestData();
		
	// 	Account newEndUserAcct = new Account(name = 'NewAccountMissingTCAId', Tax_Id__c = '01010');
	// 	newEndUserAcct.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();
	// 	insert newEndUserAcct;

	// 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
	// 	mock.setStaticResource('createCustomerResponse_Success_52658243');
	// 	mock.setStatusCode(200);
	// 	mock.setHeader('Content-Type', 'application/json');
	// 	Test.setMock(HttpCalloutMock.class, mock);
	
	// 	Test.startTest();

	// 		String jsonResponseString = InternalCreditAppUtils.createExternalCustomer(newEndUserAcct.Id, null);

	// 	Test.stopTest();

	// 	JSONCreateCustomerResponse parsedCreateCustomerResponseObj = (JSONCreateCustomerResponse)JSON.deserializeStrict(jsonResponseString, JSONCreateCustomerResponse.class);

	// 	System.assert(parsedCreateCustomerResponseObj.success, 'Failed to read an Account that already has a TCA Party Id as having one');
	// 	System.assertEquals(parsedCreateCustomerResponseObj.tcaPartyId, tData.tcaPartyId, 'Failed to read an Account that already has a TCA Party Id as having one');

	// }
	
	// @isTest
	// private static void testCreateExternalCustomer_IgnoreBcTCAExists() {

	// 	TestData tData = new TestData();

	// 	Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
	// 	Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE End_User__c = :endUserAcct.Id LIMIT 1];

	// 	Test.startTest();

	// 		String jsonResponseString = InternalCreditAppUtils.createExternalCustomer(endUserAcct.Id, testOpp.Id);

	// 	Test.stopTest();

	// 	JSONCreateCustomerResponse parsedCreateCustomerResponseObj = (JSONCreateCustomerResponse)JSON.deserializeStrict(jsonResponseString, JSONCreateCustomerResponse.class);

	// 	System.assert(parsedCreateCustomerResponseObj.success, 'Failed to return success despite passing an Account that already has a TCA Party Id');
	// 	System.assertEquals(parsedCreateCustomerResponseObj.tcaPartyId, tData.tcaPartyId, 'Failed to return the TCA Party Id expected');

	// }
	

	// @isTest
	// private static void testFillBufferLWC() {

	// 	TestData tData = new TestData();

	// 	Test.startTest();

	// 		InternalCreditAppUtils.fillBufferLWC();
	// 		System.assertEquals(1, Limits.getFutureCalls(), 'Failed to queue the future method as expected');

	// 	Test.stopTest();

	// 	System.assert(2 <= Limits.getQueries(), 'Failed to queue the future method as expected');

	// }

	// @isTest
	// private static void testQuickSearch() {

	// 	TestData tData = new TestData();
	// 	TestDataFactory dataFactory = TestDataFactory.getInstance();

	// 	Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];

	// 	List<Account> endUserAccts = [SELECT Id, Name FROM Account WHERE Name LIKE : tData.endUserAcctName AND BillingCity = :tData.endUserAcctCity AND BillingState = :tData.endUserAcctState];
    //     System.assertEquals(1, endUserAccts.size(), 'Failed to locate the expected number of test end user accounts');
	// 	Account endUserAcct = endUserAccts[0];
	// 	Account secondEndUserAcct = new Account(Name = tData.endUserAcctName + ' moreOtherStuff', BillingCity = tData.endUserAcctCity, BillingState = tData.endUserAcctState);
	// 	insert secondEndUserAcct;

	// 	List<Contract__c> contracts = new List<Contract__c>{
	// 		new Contract__c(End_User__c = endUserAcct.Id),
	// 		new Contract__c(End_User__c = secondEndUserAcct.Id)
	// 	};

	// 	insert contracts;

	// 	Test.startTest();

	// 		String oppRecordTypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
	// 		Opportunity opp = dataFactory.buildOpportunity(tData.oppName ,tData.oppStage ,tData.oppCloseDate, tData.oppType , oppRecordTypeId, vendorAcct.Id, tData.oppAmount, Test.getStandardPricebookId());
	// 		opp.End_User__c = endUserAcct.Id;
	// 		opp.Application_Number__c = '0192827';
 	// 		update opp;

	// 		String jsonResponseString = InternalCreditAppUtils.quickSearch(tData.endUserAcctName, tData.endUserAcctCity, tData.endUserAcctState);

	// 	Test.stopTest();

	// 	List<Account> acctsArray = (List<Account>)JSON.deserializeStrict(jsonResponseString, List<Account>.class);

	// 	System.assertEquals(2, acctsArray.size(), 'Failed to return an array of Accounts as expected');

	// }

    // @isTest
    // private static void testSubmitCreditApp(){

    //     TestData tData = new TestData();

    //     Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName];

    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);

    //     Test.startTest();
        
    //         String jsonResponseObject = InternalCreditAppUtils.submitCreditApp(testQuote.id);
    //         System.assertEquals(2, Limits.getFutureCalls(), 'Failed to schedule a future call to create a credit app from the quote id');

    //     Test.stopTest();
        
    //     Quote updatedQuote = [SELECT Id, Name, OpportunityId  FROM Quote WHERE Id = :testQuote.Id];
    //     // System.assertEquals('Application Submitted', updatedQuote.OpportunityId, 'Failed to set the opportunity Sub-Stage to the correct value on Application Submitted');

    // }

            
    // @isTest
    // private static void testSubmitCreditAppFuture(){

    //     TestData tData = new TestData();

    //     Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName];
        
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);

    //     Test.startTest();
        
    //         InternalCreditAppUtils.submitCreditAppFuture(testQuote.id);

    //     Test.stopTest();
        
    //     Quote updatedQuote = [SELECT Id, Name, OpportunityId  FROM Quote WHERE Id = :testQuote.Id];

    // }

    @isTest
    private static void testSubmitCreditAppRequest(){

        TestData tData = new TestData();

        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        
            String jsonObjectString = InternalCreditAppUtils.submitCreditAppRequest(testOpp.id);
        
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Name, Sub_Stage__c FROM Opportunity WHERE Id = :testOpp.Id];

        System.assertEquals('Application Submitted', updatedOpp.Sub_Stage__c, 'Failed to set the opportunity Sub-Stage to the correct value on Application Submitted');

    }

    @isTest
    private static void testSubmitCreditAppBadRequest(){

        TestData tData = new TestData();

        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

        Boolean errorDetected = false;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('postFinanceApplicationTestResponse_BadRequest');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            try {
                String jsonObjectString = InternalCreditAppUtils.submitCreditAppRequest(testOpp.id);
            } catch(Exception err) {
                System.debug(err);
                errorDetected = true;
                String customErrorMessage = err.getMessage();
                System.debug(customErrorMessage);
                // System.assert(customErrorMessage.contains('400'), 'customErrorMessage ' + customErrorMessage + ' doesnt contain the error http status code');
            }

        Test.stopTest();

        // InternalCreditAppUtils.ReturnStatus errorReturnStatusObj = (InternalCreditAppUtils.ReturnStatus)JSON.deserializeStrict(jsonObjectString, InternalCreditAppUtils.ReturnStatus.class);

        System.assert(errorDetected, 'Failed to throw an error on the 400 response');
        // System.assertEquals(400, errorReturnStatusObj.responseCode, 'Failed to store the statuscode on the res.status field as expected');
        // System.assertNotEquals(null, errorReturnStatusObj, 'Failed to store an error message that describes the nature of the error as expected');

    }

    // @isTest
    // private static void testSubmitPreQualCreditApp() {

    //     TestData tData = new TestData();

    //     Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
    //     Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
    //     Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];
        
    //     System.debug(testOpp.Id);

    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);

    //     Test.startTest();
        
    //         String jsonResponseMessage = InternalCreditAppUtils.submitPreQualCreditApp(testOpp.Id);
    //         System.assertEquals('OK', jsonResponseMessage, 'Failed to return an OK as expected');

    //     Test.stopTest();

    //     Opportunity updatedOpp = [SELECT Id, Name, Sub_Stage__c FROM Opportunity WHERE Id = :testOpp.Id];

    //     System.assertEquals('Application Submitted', updatedOpp.Sub_Stage__c, 'Failed to set the opportunity Sub-Stage to the correct value on Application Submitted');
    // }

    // @isTest
    // private static void testSubmitPreQualCreditApp_Error() {

    // 	TestData tData = new TestData();

    // 	Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
    // 	Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
    // 	Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];
        
    // 	System.debug(testOpp.Id);

    // 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    // 	mock.setStaticResource('postFinanceApplicationTestResponse_Error');
    // 	mock.setStatusCode(400);
    // 	mock.setHeader('Content-Type', 'application/json');
    // 	Test.setMock(HttpCalloutMock.class, mock);

    // 	Test.startTest();

    // 		String jsonResponseMessage = InternalCreditAppUtils.submitPreQualCreditApp(testOpp.Id);

    // 	Test.stopTest();

    // 	Opportunity updatedOpp = [SELECT Id, Name, Sub_Stage__c FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];

    // 	System.assertEquals('Application Submitted', updatedOpp.Sub_Stage__c, 'Failed to set the opportunity Sub-Stage to the correct value on Application Submitted');
    // }

    // @isTest
    // private static void testSubmitPreQualCreditAppFuture() {

    //     TestData tData = new TestData();

    //     Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
    //     Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
    //     Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);

    //     Test.startTest();

    //         InternalCreditAppUtils.submitPreQualCreditAppFuture(testOpp.Id);
    //         System.assertEquals(1, Limits.getFutureCalls(), 'Failed to schedule a future method as expected');

    //     Test.stopTest();

    //     Opportunity updatedOpp = [SELECT Id, Name, Sub_Stage__c FROM Opportunity WHERE Id = :testOpp.Id];

    //     System.assertEquals('Application Submitted', updatedOpp.Sub_Stage__c, 'Failed to set the opportunity Sub-Stage to the correct value on Application Submitted');
    // }


    @isTest
    private static void testDoCallout() {

        TestData tData = new TestData();

        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('postFinanceApplicationTestResponse_001_2540_1605');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

            InternalCreditAppUtils.ReturnStatus returnStatus = InternalCreditAppUtils.doCallout('jsonGoesHere', 'method', testOpp.Id);

        Test.stopTest();

        System.assert(returnStatus.isSuccess, 'Failed to set a status of OK on the status field of a successful callout');
    }

    @isTest
    private static void testDoCallout_Error() {

        TestData tData = new TestData();

        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

        String methodName = 'methodName';

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('postFinanceApplicationTestResponse_Error');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

            InternalCreditAppUtils.ReturnStatus returnStatus = InternalCreditAppUtils.doCallout('jsonGoesHere', methodName, testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(true, returnStatus.isSuccess, 'Failed properly set the status of null on the status field of a errored callout');

    }

    @isTest
    private static void testDoCallout_Exception() {

        TestData tData = new TestData();

        Account endUserAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.endUserAcctName];
        Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :vendorAcct.Id AND End_User__c = :endUserAcct.Id LIMIT 1];

        String methodName = 'methodName';

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('postFinanceApplicationTestResponse_Error');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

            InternalCreditAppUtils.ReturnStatus returnStatus = InternalCreditAppUtils.doCallout('jsonGoesHere', methodName, testOpp.Id);

        Test.stopTest();

        System.assertNotEquals(true, returnStatus.isSuccess, 'Failed properly set the status of null on the status field of a errored callout');

    }


    @isTest
    private static void testUpdateOpportunityData() {

		TestData tData = new TestData();
        Map<String, String> customerStory = tData.testCustomerStory;

		Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
		Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
		Contact newVendorContact = new Contact(firstName = 'FirstName', lastName = 'LastName', accountId = vendorAcct.id, Role__c='Partner Sales Rep');
		insert newVendorContact;

        customerStory.put('salesRepId', newVendorContact.Id);
        customerStory.put('amount', String.valueOf(tData.oppAmount));
        customerStory.put('paymentAmount', String.valueOf(tData.paymentAmount));
        customerStory.put('paymentFrequency', 'MONTHLY');
        customerStory.put('financeTerm', String.valueOf(tData.financeTermLength));


        Test.startTest();

            Boolean updatedSuccessfully = InternalCreditAppUtils.updateOpportunityData(testOpp.Id, customerStory, null);
            System.assert(updatedSuccessfully, 'Failed to return true after attempting to update the opportunity');

        Test.stopTest();

        Opportunity updatedTestOpp = [SELECT Id, Name, Frequency__c, Payment_Amount__c, Partner_Sales_Rep__c FROM Opportunity WHERE Id = :testOpp.Id];

		System.assertEquals(newVendorContact.Id, updatedTestOpp.Partner_Sales_Rep__c, 'Failed to update the Opportunity with the correct Partner Sales Rep details');
		System.assertEquals('MONTHLY', updatedTestOpp.Frequency__c, 'Failed to update the Opportunity with the correct Frequency value');
        System.assertEquals(updatedTestOpp.Payment_Amount__c, tData.paymentAmount, 'Failed to properly stamp the input payment amount on the Opportunity as expected');
    }


    @isTest
    private static void testUpdateOpportunityData_WithAssets() {

		TestData tData = new TestData();
        Map<String, String> customerStory = tData.testCustomerStory;

		Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
		Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
		Contact newVendorContact = new Contact(firstName = 'FirstName', lastName = 'LastName', accountId = vendorAcct.id, Role__c='Partner Sales Rep');
		insert newVendorContact;

        customerStory.put('salesRepId', newVendorContact.Id);
        customerStory.put('amount', String.valueOf(tData.oppAmount));
        customerStory.put('paymentAmount', String.valueOf(tData.paymentAmount));
        customerStory.put('paymentFrequency', 'quarterly');
        customerStory.put('financeTerm', String.valueOf(tData.financeTermLength));

        List<InternalCreditAppUtils.Asset> listOfNewAssets = new List<InternalCreditAppUtils.Asset>();
        for (Integer i = 0; i < 10; i++) {

        }

        Test.startTest();

            Boolean updatedSuccessfully = InternalCreditAppUtils.updateOpportunityData(testOpp.Id, customerStory, null);
            System.assert(updatedSuccessfully, 'Failed to return true after attempting to update the opportunity');

        Test.stopTest();

        Opportunity updatedTestOpp = [SELECT Id, Name, Frequency__c, Payment_Amount__c, Partner_Sales_Rep__c FROM Opportunity WHERE Id = :testOpp.Id];

		System.assertEquals(newVendorContact.Id, updatedTestOpp.Partner_Sales_Rep__c, 'Failed to update the Opportunity with the correct Partner Sales Rep details');
		System.assertEquals('quarterly', updatedTestOpp.Frequency__c, 'Failed to update the Opportunity with the correct Frequency value');
        System.assertEquals(updatedTestOpp.Payment_Amount__c, tData.paymentAmount, 'Failed to properly stamp the input payment amount on the Opportunity as expected');
    }

    @isTest
    private static void testGetOpportunity() {

		TestData tData = new TestData();
        Map<String, String> customerStory = tData.testCustomerStory;

		Account vendorAcct = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
		Opportunity testOpp = [SELECT Id, Name, End_User__c FROM Opportunity WHERE AccountId = :vendorAcct.Id LIMIT 1];
		
        
        Test.startTest();

            String jsonResponseString = InternalCreditAppUtils.getOpportunity(testOpp.Id);

        Test.stopTest();

		InternalCreditAppUtils.OpportunityResObject parsedCreateCustomerResponseObj = (InternalCreditAppUtils.OpportunityResObject)JSON.deserializeStrict(jsonResponseString, InternalCreditAppUtils.OpportunityResObject.class);

		System.assertEquals(vendorAcct.Id, parsedCreateCustomerResponseObj.accountId, 'Failed to properly respond with the formattted Opportunity object');

    }



}