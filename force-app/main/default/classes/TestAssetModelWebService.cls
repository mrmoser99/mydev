/**
 * Test class for AssetModelWebService apex class 
 * 
 * Version 1.0 @author Elena Sokolova @date 2021-04-07
 * Version 1.1 @author Ravisha Chugani @date 2021-04-07
 * Version 1.2 @author Elena Sokolova @date 2021-05-21
 * Version 1.3 @author Elena Sokolova @date 2021-09-10
 * Version 1.4 @author Ravisha Chugani @date 2022-01-21
 * 
 */
@IsTest
public class TestAssetModelWebService {  

    /**
    * Name : setupTestData
    * Purpose : Create Test data for the test methods. 
    */
    @testSetup static void setupTestData(){
        TestDataFactory dataFactory = TestDataFactory.getInstance();
        Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
    
        TestRegionBuilder regionBuilder = new TestRegionBuilder();
        Region__c testRegion = regionBuilder
            .withName('Sweden')
            .withIsoCode('SE') 
            .insertRecord(true)
            .build(); 
    
        Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');
    
        Program__c testProgram = new Program__c(Name = 'Test Program', Region__c = testRegion.Id, Asset_Program__c = assetProgram.id, CurrencyIsoCode = 'USD');
        insert testProgram; 
    
        Financial_Product__c Financial_Product = new Financial_Product__c(Name = 'Test Financial Product', Type__c = 'Core');
        insert Financial_Product;
    
        TestOfferBuilder offerBuilder = new TestOfferBuilder();
        Offer__c testOffer = offerBuilder
            .withName('Test Offer')
            .withProgram(testProgram.Id)
            .withcoreFinancialProduct(Financial_Product.Id)
            .withcurrencyIsoCode('USD')
            .withisRVApplicable('DLL or 3rd Party')
            .build();
    
        TestOfferBuilder offerBuilder2 = new TestOfferBuilder();
        Offer__c testOffer2 = offerBuilder2
            .withName('Test Offer')
            .withProgram(testProgram.Id)
            .withcoreFinancialProduct(Financial_Product.Id)
            .withcurrencyIsoCode('USD')
            .withisRVApplicable('Purchase Option')
            .build();

        TestAccountBuilder accountBuilder = new TestAccountBuilder();
        Account account = accountBuilder
            .withRecordType(Constants.VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Account')
            .withRegion(testRegion.Id)
            .build(); 
        
        TestTermBuilder termbuilder = new TestTermBuilder();
            Term__c term = termbuilder
            .withAlias('<= 60 Months')
            .withTermValue(90)
            .withTermDimension('Days')
            .build();
    
        TestTermBuilder termbuilder2 = new TestTermBuilder();
            Term__c term2 = termbuilder2
            .withAlias('<= 30 Months')
            .withTermValue(30)
            .withTermDimension('Days')
            .build();
    
        TestTermBuilder termbuilder3 = new TestTermBuilder();
            Term__c term3 = termbuilder3
            .withAlias('<= 90 Months')
            .withTermValue(60)
            .withTermDimension('Days')
            .build();

        insert new List<SObject>{testOffer, testOffer2, account, term, term2, term3};    
    
        TestApplicableOfferBuilder testapplicableOffer = new TestApplicableOfferBuilder();
        Applicable_Offer__c testApo = testapplicableOffer
            .withName('testAPO')
            .withAccount(account.id)
            .withOffer(testOffer.id)
            .build();
    
        TestApplicableOfferBuilder testapplicableOffer2 = new TestApplicableOfferBuilder();
        Applicable_Offer__c testApo2 = testapplicableOffer2
            .withName('testAPO2')
            .withAccount(account.id)
            .withOffer(testOffer2.id)
            .build();

        insert new List<Applicable_Offer__c>{testApo, testApo2};  

        RV_Matrix__c rvMatrix = dataFactory.buildrvMatrix(account.id,testProgram.Id,'DLL',testRegion.Id, false);
        RV_Matrix__c rvMatrix2 = dataFactory.buildrvMatrix(account.id,testProgram.Id,'DLL',testRegion.Id, false);

        insert new List<RV_Matrix__c>{rvMatrix, rvMatrix2};
    
        RV_Matrix_Line_Item__c rvLineItem = dataFactory.buildrvLineItem(term.Id, rvMatrix.id, 5.0, 'Laptops', false);
        RV_Matrix_Line_Item__c rvLineItem2 = dataFactory.buildrvLineItem(term2.Id, rvMatrix.id, 10.0, 'Laptops', false);
        RV_Matrix_Line_Item__c rvLineItem3 = dataFactory.buildrvLineItem(term3.Id, rvMatrix.id, 15.0, 'Laptops', false);
        RV_Matrix_Line_Item__c rvLineItem4 = dataFactory.buildrvLineItem(term.Id, rvMatrix.id, 2.0, 'Copiers', false);
        RV_Matrix_Line_Item__c rvLineItem5 = dataFactory.buildrvLineItem(term2.Id, rvMatrix.id, 4.0, 'Copiers', false);
        RV_Matrix_Line_Item__c rvLineItem6 = dataFactory.buildrvLineItem(term3.Id, rvMatrix.id, 8.0, 'Copiers', false);
        
       
            
        Applicable_RV__c applicableRV = dataFactory.buildapplicableRV(testOffer.id, RVMatrix.id, false);
        Applicable_RV__c applicableRV2 = dataFactory.buildapplicableRV(testOffer2.id, RVMatrix.id, false);

        insert new List<SObject>{rvLineItem, rvLineItem2, rvLineItem3, rvLineItem4, rvLineItem5, rvLineItem6,applicableRV, applicableRV2};
        
        Program_Partner_Party__c programPartnerParty = new Program_Partner_Party__c(Dealer__c = account.Id, program__c = testprogram.id);
        insert programPartnerParty;
        
        Insurance__c Insurance = new  Insurance__c(Cost__c = 20, Region__c = testRegion.Id, Code__c = '1234567');
        insert Insurance;

        Insurance_Line_Item__c insuranceLineItem = dataFactory.buildInusranceLineItem(insurance.id, account.Id, 10000, 1, false);
        Insurance_Line_Item__c insuranceLineItem2 = dataFactory.buildInusranceLineItem(insurance.id, account.Id, 20000, 2, false);
        Insurance_Line_Item__c insuranceLineItem3 = dataFactory.buildInusranceLineItem(insurance.id, account.Id, 30000, 3, false);
        insert new List<Insurance_Line_Item__c>{insuranceLineItem, insuranceLineItem2, insuranceLineItem3};
    
        Product2 product1 = new  Product2(Brand__c = 'Apple', Name = 'Apple Laptop', Family = 'Asset Soft');
        Product2 product2 = new  Product2(Brand__c = 'Samsung', Name = 'Laptop', Family = 'Asset Soft');
        Product2 product3 = new  Product2(Brand__c = 'Lenovo', Name = 'Phone', Family = 'Asset Soft');
        Product2 product4 = new  Product2(Brand__c = 'Apple', Name = 'IPhone', Family = 'Asset Soft');
        Product2 product5 = new  Product2(Brand__c = 'Apple', Name = 'IPhone12', Family = 'Asset Soft');
        Product2 product6 = new  Product2(Brand__c = 'Samsung', Name = 'S20', Family = 'Asset Soft');
        Product2 product7 = new  Product2(Name = 'Education', Family = 'Soft Cost');
        Product2 product8 = new  Product2(Name = 'Service', Family = 'Maintenance');
        Product2 product9 = new  Product2(Name = 'Copier', Family = 'Asset Hard');
        Product2 product10 = new  Product2(Brand__c = 'Samsung', Name = 'Samsung', Family = 'Asset Soft');

        insert new List<Product2>{product1, product2, product3, product4, product5, product6, product7, product8, product9, product10};
    
        PricebookEntry pbe1=dataFactory.buildPricebookEntry(standardPricebook.Id,Product1.Id,1020,true,'USD', false);
        PricebookEntry pbe2=dataFactory.buildPricebookEntry(standardPricebook.Id,Product2.Id,1000,true,'USD', false);
        PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,Product3.Id,1020,true,'USD', false);
        PricebookEntry pbe4=dataFactory.buildPricebookEntry(standardPricebook.Id,Product4.Id,1000,true,'USD', false);
        PricebookEntry pbe5=dataFactory.buildPricebookEntry(standardPricebook.Id,Product5.Id,1020,true,'USD', false);
        PricebookEntry pbe6=dataFactory.buildPricebookEntry(standardPricebook.Id,Product6.Id,1000,true,'USD', false);
        PricebookEntry pbe7=dataFactory.buildPricebookEntry(standardPricebook.Id,Product7.Id,1500,true,'USD', false);
        PricebookEntry pbe8=dataFactory.buildPricebookEntry(standardPricebook.Id,Product8.Id,1200,true,'USD', false);
        PricebookEntry pbe9=dataFactory.buildPricebookEntry(standardPricebook.Id,Product9.Id,2000,true,'USD', false);
        PricebookEntry pbe10=dataFactory.buildPricebookEntry(standardPricebook.Id,Product10.Id,900,true,'USD', false);
    
        Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product1.id, 'laptops', 'copiers', 'desktop', 'servers', 'tablets', RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product2.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail3 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product3.id, 'laptops', 'tablets', 'smart phones', 'servers', 'desktop', rvMatrix2.id, rvMatrix2.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail4 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product4.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, rvMatrix2.id,rvMatrix2.id, RVMatrix.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail5 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product5.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, rvMatrix2.id, rvMatrix2.id, rvMatrix2.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail6 = dataFactory.buildassetProgramDetail(assetProgram.id, null, null, Product6.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, rvMatrix2.id, rvMatrix2.id, rvMatrix2.id, RVMatrix.id, false, false);
        Asset_Program_Detail__c assetProgramDetail7 = dataFactory.buildassetProgramDetail(assetProgram.id, product7.id, null, null, false, null, null, false);
        Asset_Program_Detail__c assetProgramDetail8 = dataFactory.buildassetProgramDetail(assetProgram.id, product8.id, null, null, false, null, null, true, false);
        Asset_Program_Detail__c assetProgramDetail9 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product9.id, 'copiers', 'laptops', 'desktop', 'servers', 'tablets', RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, true, false);
        Asset_Program_Detail__c assetProgramDetail10 = dataFactory.buildassetProgramDetail(assetProgram.id, null, Insurance.id, Product10.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, rvMatrix2.id, rvMatrix2.id, rvMatrix2.id, RVMatrix2.id, true, false);
		Asset_Program_Detail__c assetProgramDetail11 = dataFactory.buildassetProgramDetail(1,3,3,assetProgram.id, null, Insurance.id, Product2.id, 'laptops', 'smart phones', 'tablets', 'copiers', 'servers', rvMatrix2.Id, RVMatrix.id, RVMatrix.id, RVMatrix.id, RVMatrix.id, true, false);    

        insert new List<SObject>{
            pbe1, pbe2, pbe3, pbe4, pbe5, pbe6, pbe7, pbe8, pbe9, pbe10,
            assetProgramDetail1, assetProgramDetail2, assetProgramDetail3, assetProgramDetail4, assetProgramDetail5, assetProgramDetail6, assetProgramDetail7, assetProgramDetail8, assetProgramDetail9, assetProgramDetail10 ,assetProgramDetail11
        };
    }
    
    @isTest static void testGetAssetModelData() {
        
        Applicable_Offer__c applicableOffer = [SELECT Id FROM Applicable_Offer__c WHERE Name LIKE 'testAPO']; 
        Id assetSoftProductId = [SELECT Id, Name FROM Product2 WHERE Name LIKE 'Apple Laptop'].Id;
        Id assetHardProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Copier'].Id;
        Id softCostProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Education'].Id;
        Id maintenanceProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Service'].Id;
        Id RVNotApplicableProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'S20'].Id;
        
        // Set up a test request
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs90.salesforce.com/services/apexrest/assetmodels/' + applicableoffer.id;
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        Test.startTest();
        AssetModelWebService.getAssetModelData(); 
        Test.stopTest();
        String responseStr = RestContext.response.responsebody.tostring().replace('default','default_s').replace('group','group_s');
        Map<String,Object> responseObj = (Map<String,Object>) JSON.deserializeUntyped(responseStr);
    
        List<Object> responseData = (List<Object>) responseObj.get('data');
        System.assertEquals(200, RestContext.response.statusCode);

        Set<Id> productIds = new Set<Id>();
        
        for (Object dataItem : responseData) {
            AssetModelWebService.Data itemData = (AssetModelWebService.Data) JSON.deserialize(JSON.serialize(dataItem), AssetModelWebService.Data.class);
            Id productId = itemData.id;
            productIds.add(productId);

            if (productId == softCostProductId || productId == RVNotApplicableProductId) {
                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];

                    if (groupItem.cashflowType == 'residual') {
                        System.assertEquals(200, groupItem.lookups[0].inputs.numberOfMonths);
                        System.assertEquals(0, groupItem.lookups[0].outputs.default_s);
                    }
                }
            }

            if (productId == assetSoftProductId) {
                System.assertNotEquals(null, itemData.cashflows);

                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];

                    if (groupItem.cashflowType == 'residual') {
                        if (groupItem.lookups[0].inputs.numberOfMonths == 90) {
                            System.assertEquals(5.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 30) {
                            System.assertEquals(10.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 60) {
                            System.assertEquals(15.0, groupItem.lookups[0].outputs.default_s);
                        }
                    }

                    if (groupItem.cashflowType == 'insurance') {
                        //if (groupItem.lookups[0].inputs.salePrice == 1000) {
                        if (groupItem.lookups[0].inputs.financeAmount == 1000) {
                            System.assertEquals(21, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 2000) {
                            System.assertEquals(22, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 3000) {
                            System.assertEquals(23, groupItem.lookups[0].outputs.default_s);
                        }
                    }
                }
            }

            if (productId == assetHardProductId) {
                System.assertNotEquals(null, itemData.cashflows);

                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];
                    if (groupItem.cashflowType == 'residual') {
                        if (groupItem.lookups[0].inputs.numberOfMonths == 90) {
                            System.assertEquals(2.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 30) {
                            System.assertEquals(4.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 60) {
                            System.assertEquals(8.0, groupItem.lookups[0].outputs.default_s);
                        }
                    }

                    if (groupItem.cashflowType == 'insurance') {
                        if (groupItem.lookups[0].inputs.financeAmount == 1000) {
                            System.assertEquals(21, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 2000) {
                            System.assertEquals(22, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 3000) {
                            System.assertEquals(23, groupItem.lookups[0].outputs.default_s);
                        }
                    }
                }
            }
        }

        System.assertEquals(false, productIds.contains(maintenanceProductId));
        System.assertEquals(true, productIds.contains(RVNotApplicableProductId));
        System.assertEquals(true, productIds.contains(assetSoftProductId));
        System.assertEquals(true, productIds.contains(assetHardProductId));
        System.assertEquals(true, productIds.contains(softCostProductId));
    }
    
    @isTest static void testGetAssetModelDataPO() {
        
        Applicable_Offer__c applicableOffer = [SELECT Id FROM Applicable_Offer__c WHERE Name LIKE 'testAPO2']; 
        Id assetSoftProductId = [SELECT Id, Name FROM Product2 WHERE Name LIKE 'Apple Laptop'].Id;
        Id assetHardProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Copier'].Id;
        Id softCostProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Education'].Id;
        Id maintenanceProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'Service'].Id;
        Id RVNotApplicableProductId = [SELECT Id FROM Product2 WHERE Name LIKE 'S20'].Id;
        
        // Set up a test request
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs90.salesforce.com/services/apexrest/assetmodels/' + applicableoffer.id;
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        Test.startTest();
        AssetModelWebService.getAssetModelData(); 
        Test.stopTest();
        String responseStr = RestContext.response.responsebody.tostring().replace('default','default_s').replace('group','group_s');
        Map<String,Object> responseObj = (Map<String,Object>) JSON.deserializeUntyped(responseStr);
    
        List<Object> responseData = (List<Object>) responseObj.get('data');
        System.assertEquals(200, RestContext.response.statusCode);

        Set<Id> productIds = new Set<Id>();
        
        for (Object dataItem : responseData) {
            AssetModelWebService.Data itemData = (AssetModelWebService.Data) JSON.deserialize(JSON.serialize(dataItem), AssetModelWebService.Data.class);
            Id productId = itemData.id;
            productIds.add(productId);

            if (productId == softCostProductId || productId == RVNotApplicableProductId) {
                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];

                    if (groupItem.cashflowType == 'residual') {
                        System.assertEquals(200, groupItem.lookups[0].inputs.numberOfMonths);
                        System.assertEquals(0, groupItem.lookups[0].outputs.default_s);
                    }
                }
            }

            if (productId == assetSoftProductId) {
                System.assertNotEquals(null, itemData.cashflows);

                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];

                    if (groupItem.cashflowType == 'residual') {
                        if (groupItem.lookups[0].inputs.numberOfMonths == 90) {
                            System.assertEquals(5.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 30) {
                            System.assertEquals(10.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 60) {
                            System.assertEquals(15.0, groupItem.lookups[0].outputs.default_s);
                        }
                    }

                    if (groupItem.cashflowType == 'insurance') {
                        if (groupItem.lookups[0].inputs.financeAmount == 1000) {
                            System.assertEquals(21, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 2000) {
                            System.assertEquals(22, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 3000) {
                            System.assertEquals(23, groupItem.lookups[0].outputs.default_s);
                        }
                    }
                }
            }

            if (productId == assetHardProductId) {
                System.assertNotEquals(null, itemData.cashflows);

                for (AssetModelWebService.Cashflow cashflow : itemData.cashflows) {
                    AssetModelWebService.Group_s groupItem = cashflow.group_s[0];
                    if (groupItem.cashflowType == 'residual') {
                        if (groupItem.lookups[0].inputs.numberOfMonths == 90) {
                            System.assertEquals(2.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 30) {
                            System.assertEquals(4.0, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.numberOfMonths == 60) {
                            System.assertEquals(8.0, groupItem.lookups[0].outputs.default_s);
                        }
                    }

                    if (groupItem.cashflowType == 'insurance') {
                        if (groupItem.lookups[0].inputs.financeAmount == 1000) {
                            System.assertEquals(21, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 2000) {
                            System.assertEquals(22, groupItem.lookups[0].outputs.default_s);
                        } else if (groupItem.lookups[0].inputs.financeAmount == 3000) {
                            System.assertEquals(23, groupItem.lookups[0].outputs.default_s);
                        }
                    }
                }
            }
        }

        System.assertEquals(false, productIds.contains(maintenanceProductId));
        System.assertEquals(true, productIds.contains(RVNotApplicableProductId));
        System.assertEquals(true, productIds.contains(assetSoftProductId));
        System.assertEquals(true, productIds.contains(assetHardProductId));
        System.assertEquals(true, productIds.contains(softCostProductId));
    }

    
    @isTest static void testInvalidApplicableOfferId() {
        
        Id applicableoffer = 'a12020000004XYZ'; 
        
        // Set up a test request
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs90.salesforce.com/services/apexrest/assetmodels/' + applicableoffer;
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        Test.startTest();
        AssetModelWebService.getAssetModelData();
        Test.stopTest();
        System.assertEquals(404, RestContext.response.statusCode);
    }
    
    @isTest static void testExceptionApplicableOfferId() {
        
        Id applicableoffer = 'a12020000004/qN'; 
        
        // Set up a test request
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://cs90.salesforce.com/services/apexrest/assetmodels/' + applicableoffer;
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        Test.startTest();
        AssetModelWebService.getAssetModelData();
        Test.stopTest();
        System.assertEquals(500, RestContext.response.statusCode);
    }
}