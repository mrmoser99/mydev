/**
 * Test class for AccountWebService apex class (REST webservice for getting information about account and its opportunities)
 * 
 * Version 1.0 @author Elena Sokolova @date 2021-03-02
 * Version 1.1 @author Neha Tyagi @date 2021-03-15
 * 
 */
@IsTest 
private class TestPipelineExposureWebService {
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;

    @testSetup static void setupTestData() {
        TestRegionBuilder regionBuilder = new TestRegionBuilder();
        Region__c testRegion = regionBuilder
            .withName('Sweden')
            .withIsoCode('SE')
            .insertRecord(true)
            .build();

        TestAccountBuilder accountBuilder = new TestAccountBuilder();
        Account account = accountBuilder
            .withRecordType('Vendor')
            .withName('Partner Account')
            .withRegion(testRegion.Id)
            .build(); 

        TestAccountBuilder accountBuilder2 = new TestAccountBuilder();
        Account account2 = accountBuilder2
            .withRecordType('End_User')
            .withName('Test Custom Account')
            .withExternalId('559248-16419')
            .withRegion(testRegion.Id)
            .build();    
        
        insert new List<Account>{account, account2};

        TestOpportunityBuilder oppBuilder1 = new TestOpportunityBuilder();
        Opportunity opportunity1 = oppBuilder1
            .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Opportunity 1')
            .withAccount(account.Id)
            .withEndUser(account2.Id)
            .withCurrencyIsoCode('EUR')
            .build();
        
        TestOpportunityBuilder oppBuilder2 = new TestOpportunityBuilder();
        Opportunity opportunity2 = oppBuilder2
            .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Opportunity 2')
            .withAccount(account.Id)
            .withEndUser(account2.Id)
            .withCurrencyIsoCode('EUR')
            .build();
        
        insert new List<Opportunity>{opportunity1, opportunity2};

        TestQuoteBuilder quoteBuilder1 = new TestQuoteBuilder();
        Quote quote1 = quoteBuilder1
            .withName('Test Quote 1')
            .withStatus('Approved')
            .withOpportunity(opportunity1.Id)
            .withAmount(50000)
            .build(); 
            
        TestQuoteBuilder quoteBuilder2 = new TestQuoteBuilder();
        Quote quote2 = quoteBuilder2
            .withName('Test Quote 2')
            .withStatus('Refer')
            .withOpportunity(opportunity1.Id)
            .withAmount(70000)
            .build();
        
        TestQuoteBuilder quoteBuilder3 = new TestQuoteBuilder();
        Quote quote3 = quoteBuilder3
            .withName('Test Quote 3')
            .withStatus('Refer')
            .withOpportunity(opportunity1.Id)
            .withAmount(60000)
            .build();
        
        TestQuoteBuilder quoteBuilder4 = new TestQuoteBuilder();
        Quote quote4 = quoteBuilder4
            .withName('Test Quote 4')
            .withStatus('Approved')
            .withOpportunity(opportunity1.Id)
            .withAmount(10000)
            .build();
        
         TestQuoteBuilder quoteBuilder5 = new TestQuoteBuilder();
         Quote quote5 = quoteBuilder5
            .withName('Test Quote 5')
            .withStatus('Approved')
            .withOpportunity(opportunity2.Id)
            .withAmount(10000)
            .build();

         TestQuoteBuilder quoteBuilder6 = new TestQuoteBuilder();
          Quote quote6 = quoteBuilder6
            .withName('Test Quote 6')
            .withStatus('Refer')
            .withOpportunity(opportunity2.Id)
            .withAmount(10000)
            .build();
        
        TestQuoteBuilder quoteBuilder7 = new TestQuoteBuilder();
        Quote quote7 = quoteBuilder7
            .withName('Test Quote 7')
            .withStatus('Approved')
            .withOpportunity(opportunity1.Id)
            .withAmount(60000)
            .build(); 
        
        TestQuoteBuilder quoteBuilder8 = new TestQuoteBuilder();
        Quote quote8 = quoteBuilder8
            .withName('Test Quote 8')
            .withStatus('Refer')
            .withOpportunity(opportunity1.Id)
            .withAmount(90000)
            .build(); 
        
        insert new List<Quote>{quote1, quote2 ,quote3 ,quote4, quote5, quote6, quote7, quote8};

    }
  
     @isTest static void testGetAmountByCustomerId() {
        Account account = [SELECT External_Identifier__c FROM Account WHERE Name = 'Test Custom Account' LIMIT 1];
     
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs195.salesforce.com/services/apexrest/financialrisks/' + account.External_Identifier__c;
        request.httpMethod = 'GET';
        RestContext.request = request;
 
        Test.startTest();
        PipelineExposureWebService.getQuoteAmountByCustomerId();
        Test.stopTest();
         
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(100000, ((PipelineExposureWebService.QuoteAmountWrapper) JSON.deserialize(RestContext.response.responseBody.toString(),PipelineExposureWebService.QuoteAmountWrapper.class)).pendingOpportunitiesAmount);
        System.assertEquals(70000, ((PipelineExposureWebService.QuoteAmountWrapper) JSON.deserialize(RestContext.response.responseBody.toString(),PipelineExposureWebService.QuoteAmountWrapper.class)).approvedOpportunitiesAmount);    
     } 
  
     @isTest static void testGetAmountByNullCustomerId() {

        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs195.salesforce.com/services/apexrest/financialrisks/';
        request.httpMethod = 'GET';
        RestContext.request = request;
         
        Test.startTest();
        PipelineExposureWebService.getQuoteAmountByCustomerId();
        Test.stopTest();
         
        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals('No Account Found.', (String) JSON.deserializeUntyped(RestContext.response.responseBody.toString())); 
    }    
}