/**
 * Test class for OfferWebService 
 * 
 * @Version 1.0 author Alexander Kondral  
 * @Version 1.1 author Neha Tyagi @date 2021-04-14
 * @Version 1.2 author Elena Sokolova @date 2021-05-27 (product with Maintenance type has been added to test web service)
 * 
 */
@isTest
public with sharing class TestOfferWebService {

    @testSetup
    private static void setupTestData() {
        TestDataFactory dataFactory = TestDataFactory.getInstance();
        dataFactory.buildTerm('Months', 12)
            .buildRegion('Test Region', 'SE')
            .buildMarginMatrix('Test Matrix')
            .buildVendorAccount('Test Account')
            .buildProgram('Test Program')
            .buildOffer('Test Offer')
            .buildApplicableOffer('Test Applicable Offer');
        
       Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
        
       TestProductBuilder productBuilder= new TestProductBuilder();
        
       Product2 hardwareProd = productBuilder
                          .withName('macbook pro')
                          .withFamily('Asset Soft')
                          .build();
                          
        Product2 hardwareProd2 = productBuilder
                          .withName('iphone 12 pro max')
                          .withFamily('Asset Hard')
                          .build();
       
        Product2 hardwareProd3 = productBuilder
                          .withName('ipad air')
                          .withFamily('Asset Hard')
                          .build();
        
        Product2 hardwareProd4 = productBuilder
                          .withName('macbook air')
                          .withFamily('Asset Soft')
                          .build();

        Product2 serviceProd = productBuilder
                          .withName('Service')
                          .withFamily('Maintenance')
                          .build();  
        
       Product2 ITADProduct = productBuilder
                          .withName('PC,Workstations')
                          .withFamily('ITAD')
                          .build();
       Product2 ITADProduct2 = productBuilder
                          .withName('Tablets, Mobile phone')
                          .withFamily('ITAD')
                          .build();
      Product2 ITADProduct3 = productBuilder
                          .withName('Flat panel display monitors')
                          .withFamily('ITAD')
                          .build();
        
      
     insert new List<Product2>{hardwareProd, hardwareProd2, hardwareProd3,hardwareProd4,serviceProd,ITADProduct,ITADProduct2,ITADProduct3}; 
         
     PricebookEntry pbe1=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,1020,true,'USD',false);
     PricebookEntry pbe2=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd2.Id,1000,true,'USD',false);
     PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd3.Id,1020,true,'USD',false);
     PricebookEntry pbe4=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct.Id,1020,true,'USD',false);
     PricebookEntry pbe5=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct2.Id,1000,true,'USD',false);
     PricebookEntry pbe6=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct3.Id,1020,true,'USD',false);
     PricebookEntry pbe7=dataFactory.buildPricebookEntry(standardPricebook.Id,serviceProd.Id,200,true,'USD',false);
     PricebookEntry pbe8=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd4.Id,200,true,'USD',false);
     insert new List<PricebookEntry>{pbe1, pbe2, pbe3,pbe4,pbe5,pbe6,pbe7,pbe8};

     Id region = [SELECT id FROM Region__c WHERE Name = 'Test Region'].id;
        
     Id account= [SELECT id FROM Account WHERE Name = 'Test Account'].id;
     Offer__c offer =   [SELECT id FROM Offer__c WHERE Name = 'Test Offer'];
     //offer.IS_RV_Applicable__c = true; 
    // update offer;
        
     Insurance__c insurance = dataFactory.buildInusrance('Test Insurance','AF10000','Soft Asset',0.50,0.50,region);
     Insurance_Line_Item__c insuranceLineItem =dataFactory.buildInusranceLineItem(insurance.id,account,10000,1,false);
     Insurance_Line_Item__c insuranceLineItem2 =dataFactory.buildInusranceLineItem(insurance.id,account,20000,2,false);
     Insurance_Line_Item__c insuranceLineItem3 =dataFactory.buildInusranceLineItem(insurance.id,account,30000,3,false);
     insert new List<Insurance_Line_Item__c>{insuranceLineItem, insuranceLineItem2, insuranceLineItem3};  
     
     Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');
     
     Program__c testProgram= [SELECT id FROM Program__c WHERE Name = 'Test Program'];
     testProgram.Asset_Program__c = assetProgram.id;
     testProgram.CurrencyIsoCode = 'USD';
     update testProgram;
     
     RV_Matrix__c rvMatrix = dataFactory.buildrvMatrix(account,testProgram.id,'DLL',region);
        
     Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd4.id,true,false);   
     Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd.id,ITADProduct.id,insurance.id,true,rvMatrix.id,'Laptops',false);
     Asset_Program_Detail__c assetProgramDetail3 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd2.id,ITADProduct2.id,insurance.id,true,rvMatrix.id,'Laptops',false);
     Asset_Program_Detail__c assetProgramDetail4 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd3.id,ITADProduct3.id,insurance.id,true,rvMatrix.id,'Laptops',false);
     Asset_Program_Detail__c assetProgramDetail5 = dataFactory.buildassetProgramDetail(assetProgram.id,serviceProd.id,null,null,false,null,null,false);
     insert new List<Asset_Program_Detail__c>{assetProgramDetail1,assetProgramDetail2, assetProgramDetail3,assetProgramDetail4,assetProgramDetail5};
     
    }

    @isTest
    public static void testNotExistingOffer() {
        String endpoint = Site.getBaseUrl() + '/services/apexrest/offer/';
        Id recordId = [SELECT Id FROM Offer__c LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestUri = endpoint + recordId;
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        OfferWebService.getOfferById();

        String jsonResponse = String.valueOf(RestContext.response.responseBody);
        
        System.assert(jsonResponse == null);
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    public static void testFullOffer() {
        String endpoint = Site.getBaseUrl() + '/services/apexrest/offer/';
        Id recordId = [SELECT Id FROM Applicable_Offer__c LIMIT 1].Id;
        Offer__c offer = [SELECT Id, Name FROM Offer__c LIMIT 1];
        Margin_Matrix__c marginMatrix = [SELECT Id, Name FROM Margin_Matrix__c LIMIT 1];
        RestRequest request = new RestRequest();
        request.requestUri = endpoint + recordId;
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        OfferWebService.getOfferById();

        System.assertEquals(200, RestContext.response.statuscode);
        String jsonResponse = RestContext.response.responseBody.toString();
        OfferWebService.OfferWrapper offerWrapper = (OfferWebService.OfferWrapper) JSON.deserialize(jsonResponse, OfferWebService.OfferWrapper.class);

        System.assert(offerWrapper != null);
        System.assertEquals(offer.Id, offerWrapper.id);
        System.assertEquals(offer.Name, offerWrapper.name);
        System.assertEquals(2, offerWrapper.rates.size());
        
        String regex = '\\{'
        + '"validUntil":"\\d{4}-\\d{2}-\\d{2}",'
        + '"validFrom":"\\d{4}-\\d{2}-\\d{2}",'
        + '"rates":\\[\\{'
        + '"rateType":"cost-of-funds",'
        + '"id":"[a-zA-Z0-9]+",'
        + '"lookups":\\[\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"numberOfMonths":\\d+"variable":false\\}\\},'
        + '\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"numberOfMonths":\\d+,"variable":false\\}\\},'
        + '\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"numberOfMonths":\\d+,"variable":false\\}\\},'
        + '\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"paymentFrequency":"Days Term","variable":true\\}\\},'
        + '\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"paymentFrequency":"Days Term","variable":true\\}\\},'
        + '\\{"output":\\{"default":\\d+\\.00\\},"input":\\{"paymentFrequency":"Days Term","variable":true\\}\\}\\]'
        + '\\},\\{'
        + '"rateType":"margin",'
        + '"name":"Test Matrix",'
        + '"id":"[a-zA-Z0-9]+",'
        + '"lookups":\\[\\{"output":\\{"rate":\\d+\\.00\\},"input":\\{"term":\\d+,"financeAmount":\\d+\\}\\},'
        + '\\{"output":\\{"rate":\\d+\\.00\\},"input":\\{"term":\\d+,"financeAmount":\\d+\\}\\},'
        + '\\{"output":\\{"rate":\\d+\\.00\\},"input":\\{"term":\\d+,"financeAmount":\\d+\\}\\}'
        + '\\]\\}\\],'
        + '"paymentTimings":null,'
        + '"paymentProfiles":\\[\\{'
        + '"profileType":"initial-pause",'
        + '"paymentPattern":\\[\\{"valuePercentageOf":"sale-price","value":0,"paymentType":"regular","paymentNumber":0,"numberOfPayments":0,"notApplicableForMonthsAtStart":0,"month":"january"\\}\\],'
        + '"outputs":\\{"options":\\["option1"\\],"default":"default"\\},'
        + '"name":"name",'
        + '"interpolation":"interpolation",'
        + '"inputs":\\{"paymentFrequency":"frequency","numberOfMonths":\\d+\\},'
        + '"id":"id"'
        + '\\}\\],'
        + '"paymentFrequencies":null,'
        + '"name":"Test Offer",'
        + '"id":"[a-zA-Z0-9]+",'
        + '"assets":\\[\\{"modelId":"modelId","insurances":\\[\\{"id":"id"\\}\\]\\}\\]'
        + '\\}';
        Pattern offerPattern = Pattern.compile(regex);
        Matcher offerMatcher = offerPattern.matcher(jsonResponse);
        
    }
    
    @isTest
    public static void testExceptionFullOffer() {
        String endpoint = Site.getBaseUrl() + '/services/apexrest/offer/';
        Id recordId = [SELECT Id FROM Applicable_Offer__c LIMIT 1].Id;
        Offer__c offer = [SELECT Id, Name FROM Offer__c LIMIT 1];
        RestRequest request = new RestRequest();
        request.requestUri = null;
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        test.startTest();
        OfferWebService.getOfferById();
        test.stopTest();
        
        System.assertEquals(500, RestContext.response.statuscode);
      }
    
}