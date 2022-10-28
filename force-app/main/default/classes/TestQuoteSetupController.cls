/*****************************************************************************************
Name: TestQuoteSetupController 
===============================================================================================
Purpose: Test class for QuoteSetupController
================================================================================================
================================================================================================
History
-------
VERSION        AUTHOR                  DATE              DETAIL
1.0                Anujit Das          14-01-2021        test class for QuoteSetupController
******************************************************************************************/
@isTest (seeAllData=false)
public class TestQuoteSetupController {
    
    private static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.Vendor;
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
    private static final String END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.End_User;
    
    /** 
* Name : setupTestData
* Purpose : Create Test data for the test methods. 
*/
    @testSetup static void setup() {
        
        Profile prof = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        
        User user = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Anujit',
                             EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = prof.Id, userroleid=portalRole.id,
                             TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com', 
                             Legal_Entity_Description__c = 'DLL');   
        insert user;
        
        // This code runs as the system admin
        system.runAs(user) {
            
            TestTermBuilder termbuilder = new TestTermBuilder();
            Term__c term = termbuilder
                .withAlias('<= 50 Months')
                .withTermValue(50)
                .withTermDimension('Days')
                .insertRecord(true)
                .build();            
           
            TestMarginMatrixBuilder marginmatrixvalue = new TestMarginMatrixBuilder();
            Margin_Matrix__c margin = marginmatrixvalue
                .withName('Test Margin Matrix')
                .withTerm(term.Id)             
                .insertRecord(true)
                .build();
            
          TestMarginMatrixItemBuilder marginmatrixItemvalue = new TestMarginMatrixItemBuilder();
            Margin_Matrix_Item__c testname = marginmatrixItemvalue
                .withMarginMatrix(margin.id)
                .withTerm(term.Id)
                .withAmount(10000.00)
                .withValue(10.00)
                .insertRecord(true)
                .build();  
                
            TestAccountBuilder accountBuilder = new TestAccountBuilder();
            Account account = accountBuilder
                .withRecordType(VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Apple Leasing')
                .withMarginMatrix(margin.Id)
                .build();
            
            
            TestAccountBuilder accountBuilder1 = new TestAccountBuilder();
            Account account1 = accountBuilder1
                .withRecordType(VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Apple')
                .withMarginMatrix(margin.Id)
                .build();
            
            insert new List<Account>{account, account1};
                
                TestDataFactory dataFactory = TestDataFactory.getInstance();
            Contact cont = dataFactory.buildContact('Das','Anujit','Developer',account,'93283282','anujit.das@cognziant.com');
            
            Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];
            
            User portalUser = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Anujit',
                                       EmailEncodingKey='UTF-8', LastName='PartnerCommunityUser', LanguageLocaleKey='en_US', isActive=true,
                                       LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id, 
                                       TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');   
            insert portalUser;
            
            TestRegionBuilder regionBuilder = new TestRegionBuilder();
            Region__c testRegion = regionBuilder
                .withName('Sweden')
                .withActive(true)
                .withType('Country')
                .withIsoCode('SE') 
                .insertRecord(true)
                .build();
            
            TestProductBuilder productBuilder= new TestProductBuilder();              
            Product2 hardwareProd = productBuilder
                .withName('Laptop')
                .withFamily('Asset Soft')
                .build();
            
            Product2 serviceProd = productBuilder
                .withName('Repair')
                .withFamily('Maintenance')
                .build();
            
            Product2 ITADProduct = productBuilder
                .withName('Mobile phone')
                .withFamily('ITAD')
                .build();
            
            insert new List<Product2>{hardwareProd, serviceProd, ITADProduct};
                
                //Instantiate the Pricebook2 record with StandardPricebookId
                Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
            
            PricebookEntry pbe1 = dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,1020,true,'SEK', false);
            PricebookEntry pbe4 = dataFactory.buildPricebookEntry(standardPricebook.Id,serviceProd.Id,1300,true,'SEK', false);
            PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct.Id,1020,'SEK',true,10.50,150.00,11.25,6.00,15.50,10.70,9.00,false);
            insert new List<PricebookEntry>{pbe1, pbe4, pbe3};
                
                Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');
            
            TestProgramBuilder testprogramBuilder= new TestProgramBuilder();
            Program__c prog = testprogramBuilder
                .withName('Test Program')
                .withCurrencyIsoCode('SEK')
                .withAssetProgram(assetProgram.id)
                .withRegion(testRegion.id)
                .build();
            
            TestRateBuilder testrateBuilder= new TestRateBuilder();
            Rate__c rate=  testrateBuilder
                .withName('Stibor')
                .withType('Variable')
                .build();                 
            
              
            
            insert new List<SObject>{prog, rate};   
                
            TestRateLineItemBuilder testratelineitemBuilder= new TestRateLineItemBuilder();
            Rate_Line_Item__c rli= testratelineitemBuilder
                .withRate(rate.id)
                .withTerm(term.id)
                .build();
            
            Financial_Product__c financialProduct = new Financial_Product__c(Name = 'Test Financial Product',Type__c='Core');
            
            insert new List<SObject>{rli, financialProduct};
                
                Integer daysAfterToday = 365;
            Offer__c testOffer= dataFactory.buildOffer(
                'Apple Offer',
                'in-advance',
                'Monthly',
                'SEK',
                prog.id,
                'Standard',
                'Variable',
                'Variable',
                rate.id,
                financialProduct.Id, 
                Date.today(), 
                Date.today().addDays(daysAfterToday),
                false);
            
            
            testOffer.Selectable_Agreement_Term__c ='10;20;30;40';
            testOffer.Default_Agreement_Term__c ='50';
            testOffer.RV_Type__c = Constants.DLL_3RDPARTY_RV;
            insert testOffer;
            
            TestApplicableOfferBuilder testapplicableOffer= new TestApplicableOfferBuilder();
            Applicable_Offer__c testApo = testapplicableOffer
                .withName('testAPO')
                .withAccount(account.id)
                .withOffer(testOffer.id)
                .insertRecord(true)
                .build();
            
            account.PartnerOffer__c = testApo.id;
            update account;  
            
            TestAccountBuilder accountBuilder2 = new TestAccountBuilder();
            Account account2 = accountBuilder2
                .withRecordType(END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Customer Account')
                .withDoing_Business_As('Test Customer')
                .withOrg_No('Sample Org ')
                .withExternalId('124345667')
                .withFinalId('1645534')
                .insertRecord(true)
                .build(); 
            
            Insurance__c insurance = dataFactory.buildInusrance('Test Insurance','AF10000','Soft Asset',0.50,0.50,testRegion.id);
            
            Insurance_Line_Item__c insuranceLineItem =dataFactory.buildInusranceLineItem(insurance.id,account.id,10000,1,false);
            Insurance_Line_Item__c insuranceLineItem2 =dataFactory.buildInusranceLineItem(insurance.id,account.id,20000,2,false);
            Insurance_Line_Item__c insuranceLineItem3 =dataFactory.buildInusranceLineItem(insurance.id,account.id,30000,3,false);
            
            insert new List<Insurance_Line_Item__c>{insuranceLineItem, insuranceLineItem2, insuranceLineItem3};
                
                RV_Matrix__c rvMatrix1 = dataFactory.buildrvMatrix(account2.id,prog.id,'DLL',testRegion.id);
            
            Applicable_RV__c applicableRV = dataFactory.buildapplicableRV(testOffer.id, rvMatrix1.id, true);
            
            Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id, hardwareProd.Id,true ,false);
            Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id, serviceProd.id, false);
            Asset_Program_Detail__c assetProgramDetail3 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd.id,ITADProduct.id,insurance.id,true,rvMatrix1.id,'Laptops',false);
            insert new List<Asset_Program_Detail__c>{assetProgramDetail1, assetProgramDetail2, assetProgramDetail3};
                
                // This code runs as the partner community user
                system.runAs(portalUser) {
                    TestOpportunityBuilder testOppBuilder1 = new TestOpportunityBuilder();
                    Opportunity testOpp = testOppBuilder1
                        .withName('testOpp')
                        .withStage('Quoting')
                        .withCloseDate(system.today()+20)
                        .withType('New')
                        .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                        .withAccount(account.id)
                        .withAmount(100)
                        .withStandardPricebook(standardPricebook.id)
                        .build();
                    
                    TestOpportunityBuilder testOppBuilder2 = new TestOpportunityBuilder();
                    Opportunity testOpp2 = testOppBuilder2
                        .withName('testOpp2')
                        .withStage('Quoting')
                        .withCloseDate(system.today()+20)
                        .withType('New')
                        .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                        .withAccount(account.id)
                        .withAmount(500)
                        .withStandardPricebook(standardPricebook.id)
                        .build();
                    
                    insert new List<Opportunity>{testOpp, testOpp2};    
                        
                        Quote testQuote = dataFactory.buildQuote('Version-1','Monthly','Variable','24',testApo.id,'Calculation',1000,5000,1.25,'in-advance',testopp.id,standardPricebook.id);
                    
                    testOpp.SyncedQuoteid = testQuote.id; 
                    update testOpp;
                    
                    QuoteLineItem qli = dataFactory.buildQuoteLineItem(10,testQuote.id,hardwareProd.id,100,pbe1.id, false);
                    QuoteLineItem qli2 = dataFactory.buildQuoteLineItem(10,testQuote.id,serviceProd.id,100,pbe1.id, false); 
                    insert new List<QuoteLineItem>{qli, qli2};
                        } 
        }
        
    }
    
    @IsTest 
    static void testRecordSearchPositive() {
        Offer__c testOffer = [select name,id,isvalid__c,Program__r.Asset_Program__c,Program__r.Asset_Program__r.Name,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c                
                              from Offer__c where Name='Apple Offer' limit 1];                              
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        
        system.runAs(partnerUser) {
            
            string testOfferStr = '\''+ testOffer.id+ '\'';
            
            Test.StartTest();
            
            QuoteSetupController.SearchInputWrapper searchWrap1 = new QuoteSetupController.SearchInputWrapper();
            searchWrap1.objectKey = 'Offer__c';
            searchWrap1.selectedIds = new list<string>{testOffer.id};
                searchWrap1.behaveOnUserId = partnerUser.Id;            
            List<LookupSearchResult> results1 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap1));
            System.assertEquals('Apple Offer', results1[0].title);
            System.assertEquals('Offer__c', results1[0].sObjectType);
            
            QuoteSetupController.SearchInputWrapper searchWrap2 = new QuoteSetupController.SearchInputWrapper();
            searchWrap2.objectKey = 'Product2';
            searchWrap2.searchTerm = 'Laptop';
            searchWrap2.tableName = 'Product';
            searchWrap2.offerId = testOffer.id;
            List<LookupSearchResult> results2 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap2));
            System.assertEquals('Laptop', results2[0].title);
            System.assertEquals('Asset Soft', results2[0].productType);
            System.assertEquals('Product2', results2[0].sObjectType);
            
            QuoteSetupController.SearchInputWrapper searchWrap3 = new QuoteSetupController.SearchInputWrapper();
            searchWrap3.objectKey = 'Product2';
            searchWrap3.searchTerm = 'Laptop';
            searchWrap3.selectedIds = new list<string>{[SELECT Id FROM Product2 WHERE Name = 'Laptop' LIMIT 1].Id};
                List<LookupSearchResult> results3 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap3));
            System.assertEquals('Laptop', results3[0].title);
            System.assertEquals('Asset Soft', results3[0].productType);
            System.assertEquals('Product2', results3[0].sObjectType);
            
            QuoteSetupController.SearchInputWrapper searchWrap4 = new QuoteSetupController.SearchInputWrapper();
            searchWrap4.objectKey = 'Quote';
            searchWrap4.searchTerm = 'Version-1';
            List<LookupSearchResult> results4 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap4));
            System.assertEquals('Version-1', results4[0].title);
            System.assertEquals('Quote', results4[0].sObjectType);
            
            Test.StopTest();
        }
    }
    
    @IsTest 
    static void testRecordSearchNegative() {
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        
        System.runAs(partnerUser) {
            Test.StartTest();
            
            QuoteSetupController.SearchInputWrapper searchWrap1 = new QuoteSetupController.SearchInputWrapper();
            searchWrap1.objectKey = 'NotExistingObject';
            searchWrap1.searchTerm = 'Name';
            
            Boolean exception1 = false;
            try {
                List<LookupSearchResult> results1 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap1));
            } catch (Exception e) {
                exception1 = true;
            }
            
            System.assertEquals(true, exception1);
            
            QuoteSetupController.SearchInputWrapper searchWrap2 = new QuoteSetupController.SearchInputWrapper();
            searchWrap2.objectKey = 'Offer__c';
            searchWrap2.searchTerm = 'Some Offer';
            searchWrap2.selectedIds = new list<string>{'12345'};
                searchWrap2.behaveOnUserId = partnerUser.Id;
            
            Boolean exception2 = false;
            try {
                List<LookupSearchResult> results2 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap2));
            } catch (Exception e) {
                exception2 = true;
            }
            
            System.assertEquals(true, exception2);
            
            QuoteSetupController.SearchInputWrapper searchWrap3 = new QuoteSetupController.SearchInputWrapper();
            searchWrap3.objectKey = 'Product2';
            searchWrap3.searchTerm = 'Laptop';
            searchWrap3.selectedIds = new list<string>{'12345'};
                
                Boolean exception3 = false;
            try {
                List<LookupSearchResult> results3 = QuoteSetupController.recordsSearch(JSON.serialize(searchWrap3));
            } catch (Exception e) {
                exception3 = true;
            }
            
            System.assertEquals(true, exception3);
            
            Test.StopTest();
        }
    }
    
    @isTest 
    static void testSaveQuoteDetailPositive() {        
        /* Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
from account where Name='Apple Leasing' LIMIT 1];*/
        
        Offer__c testOffer = [select name,id,isvalid__c,Program__r.Asset_Program__c,Program__r.Asset_Program__r.Name,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c                
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id,ownerid from Opportunity where Type = 'New' limit 1];  
        Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id;                   
        
        QuoteLineItem testQL = [select id,Product2id from QuoteLineItem where quoteId=:testQuote.id limit 1];
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            
            String testOfferStr = '\''+ testOffer.id+ '\'';
            QuoteSetupController.SubmitAppWrapperCls subAddWrCls;
            
            Test.StartTest();
            //save quote
            String offeridstr = '{"uid":"1","Offer__c":"'+testOffer.id+'","offername":"Leasing Standard","term":"24","frequency":"Monthly","interest":"Variable","paymentTiming":"in-advance","curencycode":"€","programId":"a0p020000009E6IAAU","viewRentPerMonth":true,"applicableOfferId":"'+applbleOfrid +'" }';
            String productdetails = '[{"uid":1,"Product":"01t02000001mdBKAAY","productname":"IPhone 12","specification":"Apple Phone","quantity":"2.00","unitprice":"5.00","totalprice":"10.00","curencycode":"€ ","operation":"update","quotelineid":"'+testQL.Id+'","isDelBtnHide":true},{"uid":2,"Product":"01t02000001mdBAAAY","productname":"Lenovo Laptop","specification":"Lenovo Laptop","quantity":"4.00","unitprice":"5.00","totalprice":"20.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91hGAC","isDelBtnHide":false},{"uid":3,"Product":"01t02000001md9fAAA","productname":"iphone X","specification":"iphone apple","quantity":"5.00","unitprice":"5.00","totalprice":"25.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91iGAC","isDelBtnHide":false}]';
            String servicedetails = '[{"uid":1,"Product":"01t02000001mdBKAAY","productname":"IPhone 12","specification":"Apple Phone","quantity":"2.00","unitprice":"5.00","totalprice":"10.00","curencycode":"€ ","operation":"update","quotelineid":"'+testQL.Id+'","isDelBtnHide":true},{"uid":2,"Product":"01t02000001mdBAAAY","productname":"Lenovo Laptop","specification":"Lenovo Laptop","quantity":"4.00","unitprice":"5.00","totalprice":"20.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91hGAC","isDelBtnHide":false},{"uid":3,"Product":"01t02000001md9fAAA","productname":"iphone X","specification":"iphone apple","quantity":"5.00","unitprice":"5.00","totalprice":"25.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91iGAC","isDelBtnHide":false}]';
            String quoteid = testQuote.id;
            String quoteAmount = '{"financeAmount":"1000","rentalAmount":"40","nominalInterestRate":"1.55"}';
            String opptyId = testopp.id;
            try{
                subAddWrCls  = QuoteSetupController.doSaveQuoteDetail(offeridstr,productdetails,servicedetails,quoteid,quoteAmount,false,new list<string>(),opptyId,partnerUser.id );
            }
            catch(Exception ex){
                isException = true;
            }
            
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
            System.assertEquals('24', subAddWrCls.qouteTerm, 'correct quoteTerm');
        }              
    } 
    
    @isTest 
    static void testSaveQuoteDetailNegative() {
        Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
                           from account where Name='Apple Leasing' LIMIT 1];
        
        Offer__c testOffer = [select name,id,isvalid__c,Program__r.Asset_Program__c,Program__r.Asset_Program__r.Name,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c                
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id,ownerid from Opportunity where Type = 'New' limit 1];  
        Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id;                   
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            
            String testOfferStr = '\''+ testOffer.id+ '\'';
            
            Test.StartTest();
            
            //save quote
            String offeridstr = '{"12344","uid":"1","Offer__c":"'+testOffer.id+'","offername":"Leasing Standard","term":"24","frequency":"Monthly","interest":"Variable","paymentTiming":"in-advance","curencycode":"€","programId":"a0p020000009E6IAAU","applicableOfferId":"'+applbleOfrid +'" }';
            String productdetails = '[{"uid":1,"Product":"01t02000001mdBKAAY","productname":"IPhone 12","specification":"Apple Phone","quantity":"2.00","unitprice":"5.00","totalprice":"10.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91gGAC","isDelBtnHide":true},{"uid":2,"Product":"01t02000001mdBAAAY","productname":"Lenovo Laptop","specification":"Lenovo Laptop","quantity":"4.00","unitprice":"5.00","totalprice":"20.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91hGAC","isDelBtnHide":false},{"uid":3,"Product":"01t02000001md9fAAA","productname":"iphone X","specification":"iphone apple","quantity":"5.00","unitprice":"5.00","totalprice":"25.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91iGAC","isDelBtnHide":false}]';
            String servicedetails = '[{"uid":1,"Product":"01t02000001mdBKAAY","productname":"IPhone 12","specification":"Apple Phone","quantity":"2.00","unitprice":"5.00","totalprice":"10.00","curencycode":"€ ","operation":"update","quotelineid":"0QL02000000A91gGAC","isDelBtnHide":true},{"uid":2,"Product":"01t02000001mdBAAAY","productname":"Lenovo Laptop","specification":"Lenovo Laptop","quantity":"4.00","unitprice":"5.00","totalprice":"20.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91hGAC","isDelBtnHide":false},{"uid":3,"Product":"01t02000001md9fAAA","productname":"iphone X","specification":"iphone apple","quantity":"5.00","unitprice":"5.00","totalprice":"25.00","curencycode":"€ ","operation":"none","quotelineid":"0QL02000000A91iGAC","isDelBtnHide":false}]';
            String quoteid = testQuote.id;
            String quoteAmount = '{"financeAmount":"1000","rentalAmount":"40","nominalInterestRate":"1.55"}';
            String opptyId = testopp.id;
            
            
            try {
                QuoteSetupController.SubmitAppWrapperCls subAddWrCls = QuoteSetupController.doSaveQuoteDetail(offeridstr,productdetails,servicedetails,quoteid,quoteAmount,false,new list<string>(),opptyId,partnerUser.id );
            } catch (Exception e) {
                isException = true;
                System.assertEquals('Some error happened while getting deserializing JSON.', e.getMessage());
            }
            
            Test.StopTest();
            System.assertEquals(true, isException);
            System.assertEquals(1, [SELECT Id FROM Error_Log__c].size());
        } 
        
    }
    
    @isTest 
    static void testCreateNewDeal() {            
        Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
                           from account where Name='Apple Leasing' LIMIT 1];            
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c 
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id from Opportunity where amount=500 limit 1];                         
        
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id; 
        
        Product2 laptopProduct = [SELECT Id FROM Product2 WHERE Name = 'Laptop'];
        Product2 maintenanceProduct = [SELECT Id FROM Product2 WHERE Name = 'Repair'];
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            String testOfferStr = '\''+ testOffer.id+ '\'';
            Test.StartTest();
            QuoteSetupController.SubmitAppWrapperCls subAddWrCls;
            
            
            //save quote
            String offeridstr = '{"uid":"1","Offer__c":"'+testOffer.id+'","offername":"Leasing Standard","term":"24","frequency":"Monthly","interest":"Variable","paymentTiming":"in-advance","curencycode":"€","programId":"a0p020000009E6IAAU","viewRentPerMonth":true,"applicableOfferId":"'+applbleOfrid +'" }';
            String productdetails = '[{"uid":1,"Product":"'+ laptopProduct.Id + '","productname":"Laptop","specification":"Laptop","quantity":"5.00","unitprice":"5.00","totalprice":"25.00","curencycode":"€ ","operation":"add","quotelineid":"","isDelBtnHide":false}]';
            String servicedetails = '[{"uid":1,"Product":"'+ maintenanceProduct.Id + '","productname":"Repair","specification":"Repair","quantity":"2.00","unitprice":"5.00","totalprice":"10.00","curencycode":"€ ","operation":"add","quotelineid":"0QL02000000A91gGAC","isDelBtnHide":true}]';
            String quoteAmount = '{"financeAmount":"1000","rentalAmount":"40","nominalInterestRate":"1.55"}';
            String opptyId = testopp.id;
            try{
                subAddWrCls = QuoteSetupController.doSaveQuoteDetail(offeridstr,productdetails,servicedetails,'',quoteAmount,false,new list<string>(),opptyId,partnerUser.id );
            }
            catch(Exception ex){
                isException = true;
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
            System.assertEquals('24',subAddWrCls.qouteTerm , 'correct quoteTerm');
        }        
    }
    
    @isTest 
    static void testOtherMethods() {        
        Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
                           from account where Name='Apple Leasing' LIMIT 1];
        
        Offer__c testOffer = [select name,id,isvalid__c,Program__r.Asset_Program__c,Program__r.Asset_Program__r.Name,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c                
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id,name,ownerid from Opportunity where Type = 'New' limit 1];  
        Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id;                   
        
        QuoteLineItem testQL = [select id,Product2id from QuoteLineItem where quoteId=:testQuote.id limit 1];
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            
            String testOfferStr = '\''+ testOffer.id+ '\'';
            
            Test.StartTest();
            try{
                //new QuoteSetupController.WoSSelector().getProductsFromProgram(testOffer.id,'Laptop');
               //new QuoteSetupController.WoSSelector().queryQuoteDetails(testQuote.id);
                 
                QuoteSetupController.getDetailsForQuickCalculationScreen();
                QuoteSetupController.getOfferDetails(testOpp.id,0,partnerUser.id);
                QuoteSetupController.getOfferDetails(testOpp.id,1000,partnerUser.id);
                QuoteSetupController.getLatestQuoteVersion(new list<quote>{testQuote});
                
                
                QuoteSetupController.getQuoteDetailsOnChange(testQuote.id);
                QuoteSetupController.doCopyQuoteDetails(testQuote.id,partnerUser.id);     
                QuoteSetupController.getMyOpportunties(testOpp.ownerid,testOpp.name);
                QuoteSetupController.createOpportunity(100.00,testAcc.id,testOffer.currencyISOCode,partnerUser.id);
            }
            catch(Exception ex){
                isException = true; 
            }       
            
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }              
    } 
    
    @isTest 
    static void testOtherMethodNegative() {        
       
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            Test.StartTest();
            try{
                QuoteSetupController.doCopyQuoteDetails('abc',null);     
               
            }
            catch(Exception ex){
                isException = true; 
            }       
            
            Test.StopTest();
            System.assertEquals(true, isException);
            System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        }              
    } 
    
    @isTest 
    static void testOfferDetailsOnNewVersionPositive() {            
        
        Boolean isException = false;
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        
        system.runAs(partnerUser) {
            Test.StartTest();
            try {
                QuoteSetupController.getOfferDetailsOnNewVersion(partnerUser.id);   
            }catch(Exception e){
                isException = true;            
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
    }
    
    @isTest 
    static void testOfferDetailsOnNewVersionNegative() {            
        
        Boolean isException = false;
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        
        system.runAs(partnerUser) {
            Test.StartTest();
            try {
                QuoteSetupController.getOfferDetailsOnNewVersion(null);   
            }catch(Exception e){
                isException = true;            
            }
            Test.StopTest();
            System.assertEquals(true, isException);
            System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
    }
    
    @isTest 
    static void testfindOfferDetailsOnChangePositive() {            
        Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
                           from account where Name='Apple Leasing' LIMIT 1];            
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c 
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id from Opportunity where amount=500 limit 1];                         
        
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id; 
        
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            
            Test.StartTest();
            try {
                QuoteSetupController.findOfferDetailsOnChange(testOffer.id,null,testAcc.id,true,partnerUser.id);   
            }catch(Exception e){
                isException = true;
                
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
        
    }
    
    @isTest 
    static void testfindOfferDetailsOnChangeNegative() {            
        Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode
                           from account where Name='Apple Leasing' LIMIT 1];            
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c 
                              from Offer__c where Name='Apple Offer' limit 1];
        
        Opportunity testOpp = [select id from Opportunity where amount=500 limit 1];                         
        
        Applicable_Offer__c testApo = [select id from Applicable_Offer__c where Name='testAPO' limit 1];
        String applbleOfrid = testApo.id; 
        
        
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            Test.StartTest();
            try {
                QuoteSetupController.findOfferDetailsOnChange(testOffer.id,null,testAcc.id,true,null);   
            }catch(Exception e){
                isException = true;
                
            }
            Test.StopTest();
            
            System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
    }
    
    @isTest 
    static void testGetRateDetails() {
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Base_Rate__c,Default_Payment_Frequency__c,Default_Agreement_Term__c 
                              from Offer__c where Name='Apple Offer' limit 1];
        
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            
            Test.StartTest();
            try {
                QuoteSetupController.getRateDetails(testOffer.id,testOffer.Default_Agreement_Term__c,testOffer.Default_Payment_Frequency__c,testOffer.Default_Base_Rate__c);   
            }catch(Exception e){
                isException = true;
                
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
        
    }
    
    @isTest 
    static void testGetMarginMatrixValue() {            
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c,Default_Agreement_Term__c 
                              from Offer__c where Name='Apple Offer' limit 1];
        
        
        // This code runs as the partner community user
        User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            Test.StartTest();
            try {
                QuoteSetupController.getMarginMatrixValue(partnerUser.Id,Integer.valueOf(testOffer.Default_Agreement_Term__c),1000);   
            }catch(Exception e){
                isException = true;
                
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
    }
    
    @isTest 
    static void testGetRVandInsuranceValues() {            
        
        Offer__c testOffer = [select name,id,CurrencyIsoCode,Default_Payment_Timing__c,Default_Payment_Frequency__c,Default_Agreement_Term__c ,RV_Type__c
                              from Offer__c where Name='Apple Offer' limit 1];
        
        
        List<Id> productdetails = new List<Id>{[ SELECT  Product__c FROM Asset_Program_Detail__c where Product__r.Family = :Constants.ASSET_SOFT_PRODUCT_TYPE limit 1].Product__c};
            
            
            // This code runs as the partner community user
            User partnerUser = [SELECT Id FROM User WHERE LastName = 'PartnerCommunityUser'];
        Boolean isException = false;
        system.runAs(partnerUser) {
            Test.StartTest();
            try {
                QuoteSetupController.getRVandInsuranceValues(testOffer.id,productdetails,Integer.valueOf(testOffer.Default_Agreement_Term__c));   
            }catch(Exception e){
                isException = true;
                
            }
            Test.StopTest();
            System.assertEquals(false, isException);
            System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        }
    }
    
}