/**
 * Test class for AssetProgramDetailTriggerHandler
 * @author Anujit
 * date 2021-05-06
 */
@isTest
public class TestAssetProgramDetailTriggerHandler {
    /**
    * Name : setupTestData
    * Purpose : Create Test data for the test methods. 
    */
    @testSetup
    private static void setupTestData() {
        
    TestDataFactory dataFactory = TestDataFactory.getInstance();
    Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
    
    TestRegionBuilder regionBuilder = new TestRegionBuilder(); 
    Region__c testRegion = regionBuilder
              .withName('Sweden')
              .withIsoCode('SE') 
              .insertRecord(true)
              .build(); 
    
   TestProductBuilder productBuilder= new TestProductBuilder();
   Product2 hardwareProd = productBuilder
               .withName('macbook pro')
               .withFamily('Asset Soft')
               .build();

    Product2 hardwareProd2 = productBuilder
               .withName('iphone 12 pro max')
               .withFamily('Asset Soft')
               .build();
        
    insert new list<Product2>{hardwareProd,hardwareProd2};
     
    
     PricebookEntry pbe1=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,1020,true,'USD',false);
     PricebookEntry pbe2=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd2.Id,1000,true,'USD',false);
     PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,100,true,'SEK',false);
        
     insert new List<PricebookEntry>{pbe1, pbe2, pbe3};
     
     Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');
     Asset_Program__c assetProgram1 = dataFactory.buildassetProgram('Asset Program 1');
         
     Program__c testProgram = new Program__c(Name = 'Test Program', Region__c = testRegion.id, Asset_Program__c = assetProgram.id,CurrencyIsoCode = 'USD');
     insert testProgram;
      
     Financial_Product__c FinancialProduct =dataFactory.buildFinancialProduct('Test Financial Product','Core',true);
    
     TestOfferBuilder offerBuilder = new TestOfferBuilder();
     Offer__c testOffer = offerBuilder
                .withName('Test Offer')
                .withProgram(testProgram.Id)
                .withcurrencyIsoCode('USD')
                .withcoreFinancialProduct(FinancialProduct.Id)
                .insertRecord(true)
                .build();
        
     Asset_Program_Detail__c assetProgramDetail = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd2.id,true,true);
        
    }
    /**
    * Name : testCorrectSameCurrencyIsoCode
    * Purpose : Method to test AssetProgramDetailTriggerHandler with same CurrencyIsoCode for Program and PriceBook Entry.
    */
    @isTest
    public static void testCorrectSameCurrencyIsoCode() {
        TestDataFactory dataFactory = TestDataFactory.getInstance();
        Asset_Program__c assetProgram =[SELECT id FROM Asset_Program__c WHERE name ='Test Asset Program'];
        Product2 hardwareProd =[SELECT id FROM Product2 WHERE name ='macbook pro'];  
        
        Test.startTest();
        Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd.id,true,true);
        Test.stopTest();
        
    }
    /**
    * Name : testWrongSameCurrencyIsoCode
    * Purpose : Method to test AssetProgramDetailTriggerHandler with different CurrencyIsoCode for Program and PriceBook Entry.
    */
    @isTest
    public static void testWrongSameCurrencyIsoCode() {
        TestDataFactory dataFactory = TestDataFactory.getInstance();
        Asset_Program__c assetProgram =[SELECT id FROM Asset_Program__c WHERE name ='Test Asset Program'];
        Product2 hardwareProd =[SELECT id FROM Product2 WHERE name ='iphone 12 pro max'];  
        Test.startTest();
        
        Asset_Program_Detail__c assetProgramDetail = new Asset_Program_Detail__c(Asset_Program__c = assetProgram.id,Product__c = hardwareProd.id);
        Database.SaveResult saveResult = Database.insert(assetProgramDetail, false);
        System.assertEquals(false, saveResult.isSuccess());
        
        Test.stopTest();
        
    }
}