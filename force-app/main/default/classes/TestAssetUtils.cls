@isTest
public with sharing class TestAssetUtils {
    
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
        String testMakeId = '30001422';
        String testAssetId = '31005498';
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
    
        Quote_Line__c testQuoteLine = [SELECT Id, Name FROM Quote_Line__c WHERE Quote__c = :testQuote.Id];
        System.assertNotEquals(null, testQuoteLine.Id, 'Failed to create the test quote line as expected');
    
    }
    
    @isTest
    private static void testGetAuthToken() {
    
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getAuthTokenTestResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            AssetUtils.tokenClass tokenObject = AssetUtils.getAuthToken();
    
        Test.stopTest();
    
        System.assertNotEquals(null, tokenObject, 'Failed to properly return a properly formatted tokenClass as expected');
    
    }


    
    @isTest
    private static void testGetPrograms() {
        
        TestData tData = new TestData();
    
        Account vendorAccount = [SELECT Id, Name FROM Account WHERE Name = :tData.vendorAcctName];
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getProgramsTestResponse_0000105570_0001');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getPrograms(tData.vendorOriginatingSiteId);
    
        Test.stopTest();
    
        List<AssetUtils.Program> parsedReturnSiteObj = (List<AssetUtils.Program>)JSON.deserializeStrict(jsonResponseString, List<AssetUtils.Program>.class);
        
        System.assertEquals(10, parsedReturnSiteObj.size(), 'Failed to return an array of Program objects in the response as expected');
    }
    
    
    
    @isTest
    private static void testGetPrograms_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
            
            try {
                String jsonResponseString = AssetUtils.getPrograms(tData.vendorOriginatingSiteId);

            } catch(Exception err) {
                System.debug(err);
                System.assertEquals('Script-thrown exception', err.getMessage(), 'Failed to properly return a formatted error');
                errorThrown = true;

            }
        Test.stopTest();

        System.assert(errorThrown, 'Failed to throw an error on a 500 status as expected');

        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getPrograms' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }
    
    
    @isTest
    private static void testGetFinancialProducts() {
        
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getFinancialProductsTestResponse_0000105570_0001_1604');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
            String jsonResponseString = AssetUtils.getFinancialProducts(tData.vendorProgramId, 'dollar-out', null);
        Test.stopTest();
    
        List<JSONPricingFinancialProducts.Data> parsedReturnSiteObj = (List<JSONPricingFinancialProducts.Data>)JSON.deserializeStrict(jsonResponseString, List<JSONPricingFinancialProducts.Data>.class);
        
        System.assertEquals(3, parsedReturnSiteObj.size(), 'Failed to return an array of Financial Product objects in the response as expected');
    }
    
    @isTest
    private static void testGetFinancialProducts_Regression() {
        
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getFinancialProductsTestResponse_0000105570_0001_1604');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
            String jsonResponseString = AssetUtils.getFinancialProducts(tData.vendorProgramId, 'BO', 'New');
        Test.stopTest();
    
        List<JSONPricingFinancialProducts.Data> parsedReturnSiteObj = (List<JSONPricingFinancialProducts.Data>)JSON.deserializeStrict(jsonResponseString, List<JSONPricingFinancialProducts.Data>.class);
        
        System.assertEquals(3, parsedReturnSiteObj.size(), 'Failed to return an array of Financial Product objects in the response as expected');
    }
    
    
    @isTest
    private static void testGetFinancialProducts_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            try {
                String jsonResponseString = AssetUtils.getFinancialProducts(tData.vendorProgramId, 'dollar-out', null);

            } catch(Exception err) {
                System.debug(err);
                System.assertEquals('Script-thrown exception', err.getMessage(), 'Failed to properly return a formatted error');
                errorThrown = true;

            }
    
        Test.stopTest();
        
        System.assert(errorThrown, 'Failed to throw an error on a 500 status as expected');

        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getFinancialProducts' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }
    
    @isTest
    private static void testGetFinancialProduct() {
    
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getFinancialProductTestResponse_0000105570_0001_1604_1360_3080');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getFinancialProduct(tData.vendorProgramId, tData.vendorProductId, null);
    
        Test.stopTest();
    
        System.debug(jsonResponseString);
    
        JSONPricingFinancialProduct parsedReturnSiteObj = (JSONPricingFinancialProduct)JSON.deserializeStrict(jsonResponseString, JSONPricingFinancialProduct.class);
    
        System.assertNotEquals(null, parsedReturnSiteObj.data, 'Failed to return a JSONPricingFinancialProduct.data object in the response as expected');
        System.assertNotEquals(null, parsedReturnSiteObj.data.duration.numberOfMonths, 'Failed to return a JSONPricingFinancialProduct.data.duration.numberOfMonths object in the response as expected');
    }
    
    @isTest
    private static void testGetFinancialProduct_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            try {
                String jsonResponseString = AssetUtils.getFinancialProduct(tData.vendorProgramId, tData.vendorProductId, null);

            } catch(Exception err) {
                System.debug(err);
                System.assertEquals('Script-thrown exception', err.getMessage(), 'Failed to properly return a formatted error');
                errorThrown = true;
            }

        Test.stopTest();
        
        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getFinancialProduct' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }

    
    @isTest
    private static void testGetMakes() {
    
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getMakesTestResponse_0000105570_0001_1604');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getMakes(tData.vendorProgramId);
    
        Test.stopTest();
    
        List<AssetUtils.Make> parsedReturnSiteObjArray = (List<AssetUtils.Make>)JSON.deserializeStrict(jsonResponseString, List<AssetUtils.Make>.class);
    
        System.assert(5 < parsedReturnSiteObjArray.size(), 'Failed to return JSONPricingFinancialProducts objects in the response as expected');
    }
    
    @isTest
    private static void testGetMakes_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getMakes(tData.vendorProgramId);
    
        Test.stopTest();
        
        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getMakes' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }
    
    @isTest
    private static void testGetModels() {
    
        TestData tData = new TestData();
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getModelsTestResponse_0000105570_0001_1604_30001422');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getModels(tData.vendorProgramId, tData.testMakeId, null);
    
        Test.stopTest();
    
        System.debug(jsonResponseString);
    
        List<JSONPricingAssets.data> parsedReturnSiteObjArray = (List<JSONPricingAssets.data>)JSON.deserializeStrict(jsonResponseString, List<JSONPricingAssets.data>.class);
    
        System.assert(5 < parsedReturnSiteObjArray.size(), 'Failed to return JSONPricingFinancialProducts objects in the response as expected');
    }
    
    @isTest
    private static void testGetModels_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getModels(tData.vendorProgramId, tData.testMakeId, null);
    
        Test.stopTest();
        
        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getModels' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }
    
    @isTest
    private static void testGetAsset() {
    
        TestData tData = new TestData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getAssetTestResponse_0000105570_0001_1604_31005498');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getAsset(tData.vendorProgramId, tData.testAssetId);
    
        Test.stopTest();
    
        JSONPricingAsset parsedReturnSiteObjArray = (JSONPricingAsset)JSON.deserializeStrict(jsonResponseString, JSONPricingAsset.class);
    
        System.assert(parsedReturnSiteObjArray.data.id.contains(tData.testAssetId), 'Failed to return JSONPricingFinancialProducts objects in the response as expected');
    }
    
    
    @isTest
    private static void testGetAsset_Error() {
        
        TestData tData = new TestData();
    
        Boolean errorThrown = false;
    
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('internalServerErrorTestResponse');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    
            String jsonResponseString = AssetUtils.getAsset(tData.vendorProgramId, tData.testAssetId);
    
        Test.stopTest();
        
        Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getAsset' AND Class_Name__c = 'AssetUtils' LIMIT 1];
        System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    }
    

    // @isTest
    // private static void testGetAssetTypes() {
    
    //     TestData tData = new TestData();
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('getAssetTypesTestResponse_0000105570_0001_1604');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    //         String jsonResponseString = AssetUtils.getAssetTypes(tData.vendorProgramId, '0.01');
    //     Test.stopTest();
    
    //     List<AssetUtils.AssetType> parsedReturnSiteObjArray = (List<AssetUtils.AssetType>)JSON.deserializeStrict(jsonResponseString, List<AssetUtils.AssetType>.class);
    
    //     System.assert(5 < parsedReturnSiteObjArray.size(), 'Failed to return JSONPricingFinancialProducts objects in the response as expected');
    // }
    
    // @isTest
    // private static void testGetAssetTypes_Error() {
        
    //     TestData tData = new TestData();
    
    //     Boolean errorThrown = false;
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('internalServerErrorTestResponse');
    //     mock.setStatusCode(500);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
            
    //         String jsonResponseString = AssetUtils.getAssetTypes(tData.vendorProgramId, '0.01');
    
    //     Test.stopTest();
        
    //     Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getAssetTypes' AND Class_Name__c = 'AssetUtils' LIMIT 1];
    //     System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    // }
    
    
    // @isTest
    // private static void testGetAccessories() {
    
    //     TestData tData = new TestData();
        
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('getAccessoriesTestResponse_0000105570_0001_1604');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    
    //         String jsonResponseString = AssetUtils.getAccessories(tData.vendorProgramId, '1.NA.PI.0000105570-0001.1668.30002148');
    
    //     Test.stopTest();
    
    //     List<AssetUtils.Model> parsedReturnSiteObjArray = (List<AssetUtils.Model>)JSON.deserializeStrict(jsonResponseString, List<AssetUtils.Model>.class);
    
    //     System.assert(2 < parsedReturnSiteObjArray.size(), 'Failed to return AssetUtils.Model objects in the response as expected');
    // }
    
    
    // @isTest
    // private static void testGetAccessories_Error() {
        
    //     TestData tData = new TestData();
    
    //     Boolean errorThrown = false;
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('internalServerErrorTestResponse');
    //     mock.setStatusCode(500);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    
    //         String jsonResponseString = AssetUtils.getAccessories(tData.vendorProgramId, tData.testAssetId);
    
    //     Test.stopTest();
        
    //     Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getAccessories' AND Class_Name__c = 'AssetUtils' LIMIT 1];
    //     System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    // }
    
    
    // @isTest
    // private static void testGetPrice() {
    
    //     TestData tData = new TestData();
    
    //     Quote quote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName];
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('getPriceTestResponse_0000105570_0001_1604');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    
    //         String jsonResponseString = AssetUtils.getPrice(quote.Id, tData.vendorOriginatingSiteId, tData.vendorProgramId);
    
    //     Test.stopTest();
    
    //     System.assertNotEquals(null, jsonResponseString, 'Failed to return a non-null response string as expected');
    // }
    
    
    // @isTest
    // private static void testGetPrice_Error() {
        
    //     TestData tData = new TestData();
    
    //     Boolean errorThrown = false;
    
    //     Quote quote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName];
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('internalServerErrorTestResponse');
    //     mock.setStatusCode(500);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    
    //         String jsonResponseString = AssetUtils.getPrice(quote.Id, tData.vendorOriginatingSiteId, tData.vendorProgramId);
    
    //     Test.stopTest();
        
    //     Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getPrice' AND Class_Name__c = 'AssetUtils' LIMIT 1];
    //     System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    // }
    
    // // @isTest
    // // private static void testGetPrice() {
    
    // // 	TestData tData = new TestData();
    
    // // 	Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = :tData.quoteName];
    
    // // 	StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    // // 	mock.setStaticResource('getPriceTestResponse_0000105570_0001_1604');
    // // 	mock.setStatusCode(200);
    // // 	mock.setHeader('Content-Type', 'application/json');
    // // 	Test.setMock(HttpCalloutMock.class, mock);
    
    // // 	Test.startTest();
    // // 		String responseBodyString = AssetUtils.getPrice(testQuote.Id, tData.vendorOriginatingSiteId, tData.vendorProgramId);
    // // 	Test.stopTest();
    
    // // 	System.assertNotEquals(null, responseBodyString, 'Failed to return a response body string as expected');
    
    // // }
    

    // @isTest
    // private static void testGetSubsidies() {
    
    //     TestData tData = new TestData();
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('getSubsidiesTestResponse_0000105570_0001_1604_1360_3080');
    //     mock.setStatusCode(200);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    //         String jsonResponseString = AssetUtils.getSubsidies(tData.vendorProgramId, tData.vendorProductId, '12', tData.testMakeId, 'monthly', 12000.00, 'new', 'in-advance', 'fair-market-value');
    //     Test.stopTest();
    
    //     // JSONPricingSubsidies parsedReturnSiteObj = (JSONPricingSubsidies)JSON.deserializeStrict(jsonResponseString, JSONPricingSubsidies.class);
    
    //     System.assertNotEquals(null, jsonResponseString, 'Failed to return a jsonResponseString object in the response as expected');
    //     // System.assertNotEquals(null, parsedReturnSiteObj.data, 'Failed to return a JSONPricingFinancialProduct.data object in the response as expected');
    //     // System.assertNotEquals(null, parsedReturnSiteObj.data.duration.numberOfMonths, 'Failed to return a JSONPricingFinancialProduct.data.duration.numberOfMonths object in the response as expected');
    // }
    
    
    // @isTest
    // private static void testGetSubsidies_Error() {
        
    //     TestData tData = new TestData();
    
    //     Boolean errorThrown = false;
    
    //     StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    //     mock.setStaticResource('internalServerErrorTestResponse');
    //     mock.setStatusCode(500);
    //     mock.setHeader('Content-Type', 'application/json');
    //     Test.setMock(HttpCalloutMock.class, mock);
    
    //     Test.startTest();
    
    //     String jsonResponseString = AssetUtils.getSubsidies(tData.vendorProgramId, tData.vendorProductId, '12', tData.testMakeId, 'monthly', 12000.00, 'new', 'in-advance', 'fair-market-value');
    
    //     Test.stopTest();
        
    //     Error_Log__c errLog = [SELECT Id, Callout_Name__c, Exception_Message__c, Method_Name__c FROM Error_Log__c WHERE Method_Name__c = 'getSubsidies' AND Class_Name__c = 'AssetUtils' LIMIT 1];
    //     System.assertNotEquals(null, errLog.Exception_Message__c, 'Failed to properly set an Exception Message on the error log stored after a failed callout');
        
    // }
    
    // @isTest
    // private static void testErrorsAreThrown() {
    
    //     AssetUtils.doCallout('[]', '1', '1');
    
    // }
    
    
}