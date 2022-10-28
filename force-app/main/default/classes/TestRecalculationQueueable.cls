/**
 * Test class for RecalculationQueueable class
 * 
 * Version 1.0
 * 
 */
@IsTest
public with sharing class TestRecalculationQueueable {

    @TestSetup 
    static void setupTestData() {
        
        UserRole userRole = new UserRole(DeveloperName = 'UserRole', Name = 'User Role');
        insert userRole;
        
        User adminUser = [
            SELECT  Id, UserRoleId, IsActive 
            FROM    User Where Profile.Name 
            LIKE    'System Administrator' 
            LIMIT   1
        ];
        adminUser.UserRoleId    = userRole.Id;
        adminUser.IsActive      = true;
        adminUser.Legal_Entity_Description__c = 'DLL';
        adminUser.Legacy_ID__c = 'DLL';
        update adminUser;
        
        System.runAs(adminUser) {
        TestDataFactory dataFactory = TestDataFactory.getInstance();

        TestRegionBuilder regionBuilder = new TestRegionBuilder();
        Region__c testRegion = regionBuilder
            .withName('Sweden')
            .withIsoCode('SE') 
            .insertRecord(true)
            .build();
        
        Business_Unit__c businessUnit = new Business_Unit__c(Name= 'Test Business Unit');
        insert businessUnit;

        Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');

        TestProgramBuilder programBuilder = new TestProgramBuilder();
        Program__c testProgram = programBuilder
            .withName('Test Program')
            .withRegion(testRegion.Id)
            .withBusinessUnit(businessUnit.id)
            .withcurrencyIsoCode('USD')
            .withAssetProgram(assetProgram.id)
            .withAllowedMinimumDeposit(1000)
            .withAllowedMaximumDeposit(10000)
            .insertRecord(true)
            .build(); 
        
        Financial_Product__c testFinancialProduct = dataFactory.buildFinancialProduct ('Test Financial Product','Core',TRUE);

        TestOfferBuilder offerBuilder = new TestOfferBuilder();
        Offer__c testOffer = offerBuilder
            .withName('Test Offer')
            .withProgram(testProgram.Id)
            .withcoreFinancialProduct(testFinancialProduct.Id)
            .withcurrencyIsoCode('USD')
            .withisRVApplicable('None')
            .withisITADApplicable(true)
            .insertRecord(false)
            .build();
            testOffer.Selectable_Agreement_Term__c = '12;36;48;64;180';
            
            insert testOffer;
        
        TestTermBuilder termbuilder = new TestTermBuilder();
        Term__c term = termbuilder
            .withAlias('<= 60 Months')
            .withTermValue(90)
            .withTermDimension('Days')
            .insertRecord(true)
            .build();
        
        TestMarginMatrixBuilder marginmatrixvalue = new TestMarginMatrixBuilder();
        Margin_Matrix__c margin = marginmatrixvalue
            .withName('Test Margin Matrix')
            .withTerm(term.Id)
            .insertRecord(true)
            .build();

        TestAccountBuilder accountBuilder = new TestAccountBuilder();
        Account account = accountBuilder
            .withRecordType(Constants.VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Account')
            .withDoing_Business_As('Test Account')
            .withOrg_No('Sample Org No')
            .withInvoiceFee(800)
            .withStartUpAmount(5000)
            .withStartUpPercent(50)
            .withExtentionFee(8000)
            .withMarginMatrix(margin.Id)
            .withRegion(testRegion.Id)
            .withFinalId('124')
            .insertRecord(false)
            .build();

        TestAccountBuilder accountBuilder2 = new TestAccountBuilder();
        Account customerAccount = accountBuilder
            .withRecordType(Constants.END_USER_RECORD_TYPE_NAME)
            .withName('Test Customer Account')
            .withRegion(testRegion.Id)
            .withBillingStreet('Test Street')
            .withBillingCity('Test City')
            .withBillingPostalCode('123456')
            .withExternalId('1234-5678')
            .withFinalId('1645534')
            .insertRecord(false)
            .build(); 
            
        insert new List<Account>{account, customerAccount};
            
        AccountTeamMember accTeamMember = new AccountTeamMember(UserId = adminUser.id, accountId = account.id, TeamMemberRole = 'Account Manager');
        
        Program_Partner_Party__c program_partner_party = new Program_Partner_Party__c(Dealer__c = account.Id, program__c = testprogram.id);
        insert new List<sObject> {program_partner_party, accTeamMember};
        
        BackOffice_Param__c back_officeparam = dataFactory.buildBackOfficeParam (program_partner_party.id,'1',FALSE);
        BackOffice_Param__c back_officeparam2 = dataFactory.buildBackOfficeParam (program_partner_party.id,'2',FALSE);
        BackOffice_Param__c back_officeparam3 = dataFactory.buildBackOfficeParam (program_partner_party.id,'3',FALSE);
        
        insert new List<BackOffice_Param__c>{back_officeparam, back_officeparam2, back_officeparam3};
                    
        TestApplicableOfferBuilder appOfferBuilder = new TestApplicableOfferBuilder();
        Applicable_Offer__c appOffer = appOfferBuilder
            .withName('Test Applicable Offer')
            .withAccount(account.Id)
            .withOffer(testOffer.Id)
            .insertRecord(true)
            .build();  
            
        TestOpportunityBuilder oppBuilder = new TestOpportunityBuilder();
        Opportunity opportunity = oppBuilder
            .withRecordType(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Opportunity')
            .withAccount(account.Id)
            .withEndUser(customerAccount.Id)
            .withCurrencyIsoCode('USD')
            .insertRecord(true)
            .build();
        
        TestMarginMatrixItemBuilder marginmatrixItemvalue = new TestMarginMatrixItemBuilder();
        Margin_Matrix_Item__c testname = marginmatrixItemvalue
            .withMarginMatrix(margin.id)
            .withTerm(term.Id)
            .withAmount(1000.00)
            .withValue(10.00)
            .insertRecord(true)
            .build();    
    
        TestRateBuilder testrateBuilder= new TestRateBuilder();
        Rate__c rate=  testrateBuilder
            .withName('Stibor')
            .withType('Variable')
            .withBackofficeReference('Test')
            .insertRecord(true)
            .build();
                    
        TestRateLineItemBuilder testrateline = new TestRateLineItemBuilder();
        Rate_Line_Item__c rateline = testrateline
            .withRate(rate.id)
            .withTerm(term.id)
            .withValue(0.7)
            .insertRecord(true)
            .build();

        Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);    

        TestQuoteBuilder quoteBuilder = new TestQuoteBuilder();
        Quote quote = quoteBuilder
            .withName('Test Quote')
            .withStatus('Calculation')
            .withquoteRate(rate.Id)
            .withQuoteTerm('90')
            .withApplicableOffer(appOffer.Id)
            .withOpportunity(opportunity.Id)
            .withValueTerm('12')
            .withFrequency('Monthly')
            .withValueDownpayment('10000')
            .withPricebook2Id(standardPricebook.Id)
            .withPaymentTiming('in-advance')
            .insertRecord(true)
            .build();
        
        TestProductBuilder productBuilder= new TestProductBuilder(); 

        Product2 hardwareProd = productBuilder
            .withName('test macbook pro')
            .withFamily('Asset Soft')
            .build();
        
        Product2 hardwareProd2 = productBuilder
                          .withName('iPad Air Asset Hard')
                          .withFamily('Asset Hard')
                          .build();
            
        Product2 hardwareProd3 = productBuilder
                          .withName('macbook Air')
                          .withFamily('Asset Hard')
                          .build();
        
        Product2 maintenanceProduct = productBuilder
            .withName('Maintenance')
            .withFamily('Maintenance')
            .build();

        Product2 ITADProduct = productBuilder
            .withName('Test Tablets, Mobile phone')
            .withFamily('ITAD')
            .build();   
            
        Product2 ITADProduct2 = productBuilder
                          .withName('Test Notebook')
                          .withFamily('ITAD')
                          .build();
        
        insert new List<Product2>{hardwareProd, hardwareProd2,hardwareProd3,maintenanceProduct, ITADProduct, ITADProduct2};
        
        PricebookEntry pbe1=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd2.Id,1020,true,'USD',false);
        PricebookEntry pbe2=dataFactory.buildPricebookEntry(standardPricebook.Id,maintenanceProduct.Id,500,true,'USD',false);
        PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct.Id,1020,'USD',true,10.50,150.00,11.25,6.00,15.50,10.70,9.00,false);
        PricebookEntry pbe4=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,1020,true,'USD',false);
        PricebookEntry pbe5=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct2.Id,1020,true,'USD',false);
        PricebookEntry pbe6=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd3.Id,1020,true,'USD',false);
        insert new List<PricebookEntry>{pbe1, pbe2, pbe3, pbe4, pbe5,pbe6};

        QuoteLineItem qli1 = new QuoteLineItem(Product2Id = maintenanceProduct.id, QuoteId = quote.Id, PricebookEntryId = pbe1.Id, Quantity = 2, UnitPrice = 500, Periodic_Amount__c = 600, Financed_Amount__c = 1400);
        QuoteLineItem qli2 = new QuoteLineItem(Product2Id = hardwareProd.id, QuoteId = quote.Id, PricebookEntryId = pbe2.Id, Quantity = 5, UnitPrice = 1000, Periodic_Amount__c = 700,Financed_Amount__c = 1500);

        insert new List<QuoteLineItem>{qli1, qli2};

        Insurance__c insurance = dataFactory.buildInusrance('Test Insurance','AF10000','Soft Asset',0.50,0.50,testRegion.id);
        
        Insurance_Line_Item__c insuranceLineItem =dataFactory.buildInusranceLineItem(insurance.id,account.id,10000,1,true);

        RV_Matrix__c rvMatrix = dataFactory.buildrvMatrix(customerAccount.id,testProgram.id,'DLL',testRegion.id);
        
        Applicable_RV__c applicableRV = dataFactory.buildapplicableRV(testOffer.id, rvMatrix.id, true);
        
        Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.Id,hardwareProd.id,ITADProduct.id,insurance.id,true,rvMatrix.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.Id,maintenanceProduct.id,null,null,false,null,null,false);
        Asset_Program_Detail__c assetProgramDetail3 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd2.id,ITADProduct2.id,insurance.id,true,rvMatrix.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail4 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd3.id,true,false);  
        insert new List<Asset_Program_Detail__c>{assetProgramDetail1, assetProgramDetail2, assetProgramDetail3,assetProgramDetail4};  
       }
    }

    @IsTest 
    static void calculationAPIRequestRecalculationTest() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
        Boolean isException = false;
       //MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeInput":{"calculate":"payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"startDate":"2021-07-22","endDate":"2023-07-22","paymentFrequency":"monthly","paymentTiming":"in-advance","paymentMethod":"direct-debit"},"assets":[{"modelIdentifier":{"masterAssetTypeName":"string","categoryName":"string","typeName":"string","brandName":"string","modelName":"string"},"quantity":1,"salePrice":10000.0,"listPrice":0.0,"condition":"new","yearOfManufacturing":2021,"subLeased":false}]},"financeCalculation":{"financeAmount":10000.0,"futureValue":0.0,"rates":{"nominalInterestRate":8.0,"nominalCustomerRateIncludingFees":8.0,"nominalCustomerRate":8.0,"compoundingFrequency":"monthly","effectiveInterestRate":8.3,"effectiveCustomerRateIncludingFees":8.3,"effectiveCustomerRate":8.3}},"consolidatedPayments":[{"numberOfPayments":24,"amount":449.28,"startDate":"2021-07-22","monthStart":0,"type":"regular"}],"payments":[{"paymentDate":"2021-07-22","balanceOutstanding":9550.72,"rentalPayment":{"amount":449.28,"principal":449.28,"interestAmount":0.0}},{"paymentDate":"2021-08-22","balanceOutstanding":9165.12,"rentalPayment":{"amount":449.28,"principal":385.61,"interestAmount":63.67}},{"paymentDate":"2021-09-22","balanceOutstanding":8776.94,"rentalPayment":{"amount":449.28,"principal":388.18,"interestAmount":61.1}},{"paymentDate":"2021-10-22","balanceOutstanding":8386.17,"rentalPayment":{"amount":449.28,"principal":390.77,"interestAmount":58.51}},{"paymentDate":"2021-11-22","balanceOutstanding":7992.8,"rentalPayment":{"amount":449.28,"principal":393.37,"interestAmount":55.91}},{"paymentDate":"2021-12-22","balanceOutstanding":7596.81,"rentalPayment":{"amount":449.28,"principal":395.99,"interestAmount":53.29}},{"paymentDate":"2022-01-22","balanceOutstanding":7198.18,"rentalPayment":{"amount":449.28,"principal":398.63,"interestAmount":50.65}},{"paymentDate":"2022-02-22","balanceOutstanding":6796.89,"rentalPayment":{"amount":449.28,"principal":401.29,"interestAmount":47.99}},{"paymentDate":"2022-03-22","balanceOutstanding":6392.92,"rentalPayment":{"amount":449.28,"principal":403.97,"interestAmount":45.31}},{"paymentDate":"2022-04-22","balanceOutstanding":5986.27,"rentalPayment":{"amount":449.28,"principal":406.66,"interestAmount":42.62}},{"paymentDate":"2022-05-22","balanceOutstanding":5576.9,"rentalPayment":{"amount":449.28,"principal":409.37,"interestAmount":39.91}},{"paymentDate":"2022-06-22","balanceOutstanding":5164.8,"rentalPayment":{"amount":449.28,"principal":412.1,"interestAmount":37.18}},{"paymentDate":"2022-07-22","balanceOutstanding":4749.95,"rentalPayment":{"amount":449.28,"principal":414.85,"interestAmount":34.43}},{"paymentDate":"2022-08-22","balanceOutstanding":4332.34,"rentalPayment":{"amount":449.28,"principal":417.61,"interestAmount":31.67}},{"paymentDate":"2022-09-22","balanceOutstanding":3911.95,"rentalPayment":{"amount":449.28,"principal":420.4,"interestAmount":28.88}},{"paymentDate":"2022-10-22","balanceOutstanding":3488.75,"rentalPayment":{"amount":449.28,"principal":423.2,"interestAmount":26.08}},{"paymentDate":"2022-11-22","balanceOutstanding":3062.73,"rentalPayment":{"amount":449.28,"principal":426.02,"interestAmount":23.26}},{"paymentDate":"2022-12-22","balanceOutstanding":2633.87,"rentalPayment":{"amount":449.28,"principal":428.86,"interestAmount":20.42}},{"paymentDate":"2023-01-22","balanceOutstanding":2202.15,"rentalPayment":{"amount":449.28,"principal":431.72,"interestAmount":17.56}},{"paymentDate":"2023-02-22","balanceOutstanding":1767.55,"rentalPayment":{"amount":449.28,"principal":434.6,"interestAmount":14.68}},{"paymentDate":"2023-03-22","balanceOutstanding":1330.06,"rentalPayment":{"amount":449.28,"principal":437.5,"interestAmount":11.78}},{"paymentDate":"2023-04-22","balanceOutstanding":889.65,"rentalPayment":{"amount":449.28,"principal":440.41,"interestAmount":8.87}},{"paymentDate":"2023-05-22","balanceOutstanding":446.3,"rentalPayment":{"amount":449.28,"principal":443.35,"interestAmount":5.93}},{"paymentDate":"2023-06-22","balanceOutstanding":0.0,"rentalPayment":{"amount":449.28,"principal":446.3,"interestAmount":2.98}},{"paymentDate":"2023-07-22","balanceOutstanding":0.0,"rentalPayment":{"amount":0.0,"principal":0.0,"interestAmount":0.0}}],"paymentCalculation":{"rentalPayments":{"amount":10782.72,"principal":10000.04,"interestAmount":782.68}},"assetCalculations":[{"modelIdentifier":{"typeName":"String","modelName":"String"},"minimumRegularPaymentAmount":false,"quantity":14,"salePrice":500.0,"residualValue":{"value":85.0,"id":"a1t8B00000000sXQAQa2A8B000000CcakUAC"},"insurances":[{"amount":17.5,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}],"vatAmount":0.0,"financeCalculation":{"financeAmount":7000.0,"futureValue":1190.0},"consolidatedPayments":[{"numberOfPayments":24,"amount":269.79,"startDate":"2022-02-05","monthStart":1,"type":"regular"}]}]}');
MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success','{"financeInput":{"calculate":"payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"startDate":"2022-01-05","endDate":"2024-01-05","paymentFrequency":"monthly","paymentTiming":"in-arrears","paymentMethod":"direct-debit"},"maintenance":[{"amount":1,"id":"Maintenance"}],"assets":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"test macbook pro"},"quantity":5,"productName":"test macbook pro","salePrice":500,"listPrice":500,"condition":"new","yearOfManufacturing":2022,"subLeased":false,"residualValue":{"value":85,"id":"a1t8B00000000sXQAQa2A8B000000CcakUAC"},"insurances":[{"amount":17.5,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}],"id":"01t8B0000001fHGQAY"}]},"financeCalculation":{"financeAmount":7000,"futureValue":1190,"rates":{"nominalInterestRate":7.75,"nominalCustomerRateIncludingFees":7.75,"nominalCustomerRate":7.75,"compoundingFrequency":"monthly","effectiveInterestRate":8.03,"effectiveCustomerRateIncludingFees":8.03,"effectiveCustomerRate":8.03}},"consolidatedPayments":[{"numberOfPayments":24,"amount":269.79,"startDate":"2022-02-05","monthStart":1,"type":"regular"}],"payments":[{"paymentDate":"2022-01-05","balanceOutstanding":7000,"rentalPayment":{"amount":0,"principal":0,"interestAmount":0}},{"paymentDate":"2022-02-05","balanceOutstanding":6775.41,"rentalPayment":{"amount":269.79,"principal":224.58,"interestAmount":45.21},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-03-05","balanceOutstanding":6549.38,"rentalPayment":{"amount":269.79,"principal":226.03,"interestAmount":43.76},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-04-05","balanceOutstanding":6321.88,"rentalPayment":{"amount":269.79,"principal":227.49,"interestAmount":42.3},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-05-05","balanceOutstanding":6092.92,"rentalPayment":{"amount":269.79,"principal":228.96,"interestAmount":40.83},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-06-05","balanceOutstanding":5862.47,"rentalPayment":{"amount":269.79,"principal":230.44,"interestAmount":39.35},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-07-05","balanceOutstanding":5630.54,"rentalPayment":{"amount":269.79,"principal":231.93,"interestAmount":37.86},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-08-05","balanceOutstanding":5397.11,"rentalPayment":{"amount":269.79,"principal":233.43,"interestAmount":36.36},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-09-05","balanceOutstanding":5162.17,"rentalPayment":{"amount":269.79,"principal":234.93,"interestAmount":34.86},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-10-05","balanceOutstanding":4925.72,"rentalPayment":{"amount":269.79,"principal":236.45,"interestAmount":33.34},"maintenance":[{"amount":0.08,"id":"Maintenance"},{"amount":0.08,"id":"External Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-11-05","balanceOutstanding":4687.74,"rentalPayment":{"amount":269.79,"principal":237.98,"interestAmount":31.81},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2022-12-05","balanceOutstanding":4448.22,"rentalPayment":{"amount":269.79,"principal":239.51,"interestAmount":30.28},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-01-05","balanceOutstanding":4207.15,"rentalPayment":{"amount":269.79,"principal":241.06,"interestAmount":28.73},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-02-05","balanceOutstanding":3964.53,"rentalPayment":{"amount":269.79,"principal":242.62,"interestAmount":27.17},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-03-05","balanceOutstanding":3720.34,"rentalPayment":{"amount":269.79,"principal":244.19,"interestAmount":25.6},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-04-05","balanceOutstanding":3474.57,"rentalPayment":{"amount":269.79,"principal":245.76,"interestAmount":24.03},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-05-05","balanceOutstanding":3227.22,"rentalPayment":{"amount":269.79,"principal":247.35,"interestAmount":22.44},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-06-05","balanceOutstanding":2978.27,"rentalPayment":{"amount":269.79,"principal":248.95,"interestAmount":20.84},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-07-05","balanceOutstanding":2727.71,"rentalPayment":{"amount":269.79,"principal":250.56,"interestAmount":19.23},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-08-05","balanceOutstanding":2475.53,"rentalPayment":{"amount":269.79,"principal":252.17,"interestAmount":17.62},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-09-05","balanceOutstanding":2221.72,"rentalPayment":{"amount":269.79,"principal":253.8,"interestAmount":15.99},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-10-05","balanceOutstanding":1966.28,"rentalPayment":{"amount":269.79,"principal":255.44,"interestAmount":14.35},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-11-05","balanceOutstanding":1709.18,"rentalPayment":{"amount":269.79,"principal":257.09,"interestAmount":12.7},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2023-12-05","balanceOutstanding":1450.43,"rentalPayment":{"amount":269.79,"principal":258.75,"interestAmount":11.04},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]},{"paymentDate":"2024-01-05","balanceOutstanding":1190,"rentalPayment":{"amount":269.79,"principal":260.42,"interestAmount":9.37},"maintenance":[{"amount":0.08,"id":"Maintenance"}],"insurances":[{"assetModelIdentifier":{"masterAssetTypeName":"","categoryName":"","typeName":"Asset Soft","brandName":"","modelName":"test macbook pro"},"amount":20.42,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}]}],"paymentCalculation":{"rentalPayments":{"amount":6474.96,"principal":5809.89,"interestAmount":665.07},"maintenance":{"amount":3.84},"insurances":{"amount":490.08}},"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"test macbook pro"},"minimumRegularPaymentAmount":false,"quantity":5,"productName":"test macbook pro", "salePrice":500,"residualValue":{"value":85,"id":"a1t8B00000000sXQAQa2A8B000000CcakUAC"},"insurances":[{"amount":17.5,"id":"a1t8B00000000sXQAQa238B0000004CpuQAE"}],"vatAmount":0,"financeCalculation":{"financeAmount":7000,"futureValue":1190},"consolidatedPayments":[{"numberOfPayments":24,"amount":269.79,"startDate":"2022-02-05","monthStart":1,"type":"regular"}]}]}');

	  Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();

        try {
            System.enqueueJob(new RecalculationQueueable(new List<Id>{quote.Id}, 'calculation'));
        } catch (Exception e) {
            isException = true;
        }

        Test.stopTest();

        Quote updatedQuote = [SELECT Financed_Amount__c, Rental_Amount__c FROM Quote WHERE Id = :quote.Id];

        System.assertEquals(false, isException);
    }

    @IsTest 
    static void submitAppRequestRecalculationTest() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
        quote.Financed_Amount__c = 10000;
        update quote;

        Boolean isException = false;
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"contractNumber" : "SWE0000058-5"}');

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();

        try {
            System.enqueueJob(new RecalculationQueueable(new List<Id>{quote.Id}, 'submitApplication'));
        } catch (Exception e) {
            isException = true;
        }

        Test.stopTest();

        Quote updatedQuote = [SELECT Status, Case_Number__c FROM Quote WHERE Id = :quote.Id];

        System.assertEquals(false, isException);
    }

    @IsTest
    static void creditAssessmentRequestRecalculationTest() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
        quote.Status = 'Assessment';
        update quote;

        Boolean isException = false;
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '');

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();

        try {
            System.enqueueJob(new RecalculationQueueable(new List<Id>{quote.Id}, 'creditAssessment'));
        } catch (Exception e) {
            isException = true;
        }

        Test.stopTest();

        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :quote.Id];

        System.assertEquals(false, isException);
        System.assertNotEquals('Calculation', updatedQuote.Status);
    }
}