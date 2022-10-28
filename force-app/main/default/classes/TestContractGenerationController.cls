/**
 * Test class for ContractGenerationController apex class 
 * 
 * Version 1.0
 * 
 */ 
@IsTest  
public class TestContractGenerationController {
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
    
     /**
     * Name : setupTestData
     * Purpose : Create Test data for the test methods. 
     */
      @testSetup static void setupTestData() {
         Integer daysAfterToday = 365;
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
            .withRegion(testRegion.Id)
            .withExternalId('559248-16419')
            .withBillingStreet('Box 3722')
            .withBillingCity('Svenshogen')
            .withBillingPostalCode('4497')
            .build();  
          
           insert new List<Account>{account, account2};       
          
          TestOpportunityBuilder oppBuilder1 = new TestOpportunityBuilder();
          Opportunity opportunity1 = oppBuilder1
            .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Opportunity 1')
            .withAccount(account.Id)
            .withEndUser(account2.Id)
            .withCurrencyIsoCode('EUR')
            .insertRecord(true)
            .build();
          
           TestProgramBuilder testprogramBuilder= new TestProgramBuilder();
           Program__c prog= testprogramBuilder
              .withName('Test Program')
              .withCurrencyIsoCode('SEK')
              .insertRecord(true)
              .build();
          
          TestRateBuilder testrateBuilder= new TestRateBuilder();
          Rate__c rate=  testrateBuilder
              .withName('Stibor')
              .withType('Variable')
              .insertRecord(true)
              .build(); 
          
         
          TestDataFactory dataFactory = TestDataFactory.getInstance();
          Financial_Product__c testFinancialProduct = dataFactory.buildFinancialProduct ('Test Financial Product','Core',TRUE);
          
          Offer__c testOffer= dataFactory.buildOffer('Test Offer','in-advance','Monthly','SEK',
                                                  prog.id,'Standard','Variable','Variable',rate.id,testFinancialProduct.Id,Date.today(), Date.today().addDays(daysAfterToday),'Displayed separately');
          
          TestApplicableOfferBuilder appBuilder = new TestApplicableOfferBuilder();
          Applicable_Offer__c appBuilder1 = appBuilder
              .withName('Test Applicable Offer')
              .withAccount(account.id)
              .withOffer(testOffer.id)
              .insertRecord(true)
              .build(); 
          
          Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
          
          Quote testQuote = dataFactory.buildQuote('Test Quote','Monthly','Variable','24',appBuilder1.id,'Calculation',1000,5000,1.25,'in-advance',opportunity1.id,standardPricebook.id);
          
          Special_Terms_and_Conditions__c stc = dataFactory.buildSpecialTermsAndConditions('Test Special Terms and Conditions','Optional','Yes',prog.Id,testRegion.Id);
          
          Offer_Special_Terms_Conditions__c ostc = dataFactory.buildOfferSpecialTermsAndConditions(testOffer.id,stc.id);
         
      }

    @isTest static void testGetCustomerDetails() {
        
        Quote testQuote = [SELECT Id FROM Quote WHERE Name= 'Test Quote' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Custom Account'];
        
        Test.startTest();
		String customerDetails = ContractGenerationController.getCustomerDetails(testQuote.id);
        Test.stopTest(); 
        
        ContractGenerationController.ContactAddressWrapperClass customerDetailsWrapper = (ContractGenerationController.ContactAddressWrapperClass) JSON.deserialize(customerDetails,ContractGenerationController.ContactAddressWrapperClass.class );
        System.assertEquals(acc.id,customerDetailsWrapper.accountId);
    }
    
    @isTest static void testGenSmartcommDoc_CreateCont_Quote(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Custom Account'];
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        Special_Terms_and_Conditions__c stc = [SELECT Id FROM Special_Terms_and_Conditions__c WHERE Name LIKE 'Test Special Terms and Conditions'];
        String contact = '{"contactName" : "Test Contact", "contactEmail" : "testContact@xyz.com","contactPhone" : "12345", "accountId" :"'+ acc.id +'", "quoteId":"'+ quote.Id +'","contactStreet":"Box 3777","contactCity":"Svenshogen","contactReference":"Test Reference", "specialTnCId":["' + stc.Id +'"]}';      
        
        Test.startTest();
        String response = ContractGenerationController.createCont_Quote(contact);
        ContractGenerationController.genSmartCommDoc(contact,null);
        Test.stopTest();
        
		Contact con = [SELECT Id FROM Contact WHERE Email = 'testContact@xyz.com' LIMIT 1];
        System.assertEquals(con.id+''+quote.id , response);
    }
    
    @isTest static void testWrongGenSmartcommDoc_CreateCont_Quote(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Custom Account'];
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        String contact = '{"contactPhone" : "12345", "accountId" :"'+ acc.id +'", "quoteId":"'+ quote.Id +'","contactStreet":"Box 3777","contactCity":"Svenshogen","contactReference":"Test Reference"}';      
        
        Test.startTest();
		String response = ContractGenerationController.createCont_Quote(contact);
        ContractGenerationController.genSmartCommDoc(contact,null);
      	Test.stopTest();
        
        System.assertEquals(true , response.contains('Error'));       

    }

}