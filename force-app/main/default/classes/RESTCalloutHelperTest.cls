/**
* Test class for RESTCalloutHelper apex class 
* 
* Version 1.0
* 
*/
@IsTest
public class RESTCalloutHelperTest {

private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
private static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.Vendor;
private static final String END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.End_User;


@testSetup public static void setupTestData() {
    
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
            .withAllowedMinimumDeposit(10)
            .withAllowedMaximumDeposit(10)
            .withAssetProgram(assetProgram.id)
            .insertRecord(true)
            .build();
        
        Financial_Product__c testFinancialProduct = dataFactory.buildFinancialProduct ('Test Financial Product','Core',TRUE);
        
        Document_Library__c testDocLibrary = dataFactory.buildDocumentLibrary('GernalTerms','DLLOTS2021','T&C',testProgram.Id,true);
        
        TestRateBuilder testrateBuilder= new TestRateBuilder();
        Rate__c rate=  testrateBuilder
            .withName('Stibor')
            .withType('Variable')
            .withBackofficeReference('Test')
            .insertRecord(true)
            .build();
        
        TestOfferBuilder offerBuilder = new TestOfferBuilder();
        Offer__c testOffer = offerBuilder
            .withName('Test Offer')
            .withProgram(testProgram.Id)
            .withcoreFinancialProduct(testFinancialProduct.Id)
            .withcurrencyIsoCode('USD')
            .withisRVApplicable(Constants.PURCHASE_OPTION_RV)
            .withisITADApplicable(true)
            .withExtensionCode('A')
            .withSelectableAgreementTerm('10;20;30;40')
            .withVariableRate(rate.id)
            .insertRecord(false)
            .build();
        
        testOffer.General_Terms_and_Conditions__c = testDocLibrary.id;
        insert testOffer;
        
        TestTermBuilder termbuilder = new TestTermBuilder();
        Term__c term = termbuilder
            .withAlias('<= 60 Months')
            .withTermValue(90)
            .withTermDimension('Days')
            .insertRecord(true)
            .build();
        
        Term__c term2 = termbuilder
            .withAlias('<= 60 Months')
            .withTermValue(30)
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
            .withRecordType('Vendor')
            .withName('Test Account')
            .withDoing_Business_As('Test Account')
            .withOrg_No('Sample Org No')
            .withInvoiceFee(800)
            .withStartUpAmount(5000)
            .withStartUpPercent(50)
            .withExtentionFee(8000)
            .withGoesToDLLpartnerStartup('DLL')
            .withStartUpPercent(8)
            .withMarginMatrix(margin.Id)
            .withRegion(testRegion.Id)
            .withExternalId('12435342')
            .withFinalId('124')
            .insertRecord(false)
            .build(); 
        account.Extension_Factor_Percentage__c = 0.5;
        //Insert account;
        TestAccountBuilder accountBuilder2 = new TestAccountBuilder();
        Account account2 = accountBuilder2
            .withRecordType(END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Customer Account')
            .withDoing_Business_As('Test Customer')
            .withOrg_No('Sample Org ')
            .withExternalId('124345667')
            .withFinalId('1645534')
            .insertRecord(false)
            .build(); 
        
        account2.BillingCity='Amstelveen';
        account2.Invoice_Type__c='Letter';
        account2.ShippingStreet='Missouri';
        account2.ShippingCity='Amstelveen';
        account2.ShippingPostalCode='1186js';
        account2.ShippingCountry='Nethderlands';
        //insert account2;
        
        insert new List<Account>{account, account2};
        
        AccountTeamMember accTeamMember = new AccountTeamMember(UserId = adminUser.id, accountId = account.id, TeamMemberRole = 'Account Manager');
        
        Program_Partner_Party__c program_partner_party = new Program_Partner_Party__c(Dealer__c = account.Id, program__c = testprogram.id);
        insert new List<sObject> {program_partner_party, accTeamMember};
            
        BackOffice_Param__c back_officeparam = dataFactory.buildBackOfficeParam (program_partner_party.id,'1','PCC',FALSE);
        BackOffice_Param__c back_officeparam2 = dataFactory.buildBackOfficeParam (program_partner_party.id,'2','SupplierCategory',FALSE);
        BackOffice_Param__c back_officeparam3 = dataFactory.buildBackOfficeParam (program_partner_party.id,'3','SupplierOrganization',FALSE);
        
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
            .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
            .withName('Test Opportunity')
            .withAccount(account.Id)
            .withEndUser(account2.Id)
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
        
        TestRateLineItemBuilder testrateline = new TestRateLineItemBuilder();
        Rate_Line_Item__c rateline = testrateline
            .withRate(rate.id)
            .withTerm(term2.id)
            .withValue(0.7)
            .insertRecord(true)
            .build();
        
        TestProductBuilder productBuilder= new TestProductBuilder(); 
        
        Product2 softCostProd = productBuilder
            .withName('Apple Ipad Air Soft Cost')
            .withFamily('Soft Cost')
            .build();
        
        Product2 hardwareProd1 = productBuilder
            .withName('test macbook pro')
            .withFamily('Asset Soft')
            .build();
        
        Product2 hardwareProd2 = productBuilder
            .withName('test iphone 12 pro max')
            .withFamily('Asset Soft')
            .build();
        
        
        Product2 hardwareProd3 = productBuilder
            .withName('test ipad air')
            .withFamily('Asset Soft')
            .build();
        
        Product2 hardwareProd4 = productBuilder
            .withName('test apple laptop')
            .withFamily('Asset Soft')
            .build();
        
        Product2 hardwareProd5 = productBuilder
            .withName('iPad Air Asset Hard')
            .withFamily('Asset Hard')
            .build();
        
        Product2 hardwareProd6 = productBuilder
            .withName('iPhone 12')
            .withFamily('Asset Hard')
            .build();
        
        Product2 ITADProduct1 = productBuilder
            .withName('Test Tablets, Mobile phone')
            .withFamily('ITAD')
            .build();
        
        Product2 ITADProduct2 = productBuilder
            .withName('Test PC,Workstations')
            .withFamily('ITAD')
            .build();
        
        Product2 ITADProduct3 = productBuilder
            .withName('Test Notebook')
            .withFamily('ITAD')
            .build();
        
        Product2 maintenanceProduct = productBuilder
            .withName('External Maintenance')
            .withFamily('Maintenance')
            .build();
        
        Product2 InstallationProduct = productBuilder
            .withName('Installation')
            .withFamily('Installation')
            .build();
        
        insert new List<Product2>{softCostProd,hardwareProd1, hardwareProd2, hardwareProd3, hardwareProd4,hardwareProd5,hardwareProd6 ,ITADProduct1, ITADProduct2, ITADProduct3, maintenanceProduct,InstallationProduct};
            
        Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);
        
        PricebookEntry pbe1=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct1.Id,1020,'USD',true,10.50,150.00,11.25,6.00,15.50,10.70,9.00,false);
        PricebookEntry pbe2=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct2.Id,1000,'USD',true,11.00, 200.00,20.00,6.00,400.00,40.00,9.00,false);
        PricebookEntry pbe3=dataFactory.buildPricebookEntry(standardPricebook.Id,ITADProduct3.Id,1000,'USD',true,13.00,100.00,10.00,6.00,300.00,30.30,9.00,false);
        PricebookEntry pbe4=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd1.Id,1020,true,'USD',false);
        PricebookEntry pbe5=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd2.Id,1000,true,'USD',false);
        PricebookEntry pbe6=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd3.Id,1020,true,'USD',false);
        PricebookEntry pbe7=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd4.Id,1020,true,'USD',false);            
        PricebookEntry pbe8=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd5.Id,1020,true,'USD',false);
        PricebookEntry pbe9=dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd6.Id,1020,true,'USD',false);
        PricebookEntry pbe10=dataFactory.buildPricebookEntry(standardPricebook.Id,softCostProd.Id,500,true,'USD',false);
        PricebookEntry pbe11=dataFactory.buildPricebookEntry(standardPricebook.Id,maintenanceProduct.Id,500,true,'USD',false);
        
        
        insert new List<PricebookEntry>{pbe1, pbe2, pbe3, pbe4, pbe5, pbe6, pbe7, pbe8,pbe9,pbe10,pbe11};
            
            Contact lesseeContact = new Contact(LastName ='Lessee Contact',Email='Lessee@gmail.com' );
        insert lesseeContact;
                    
        TestQuoteBuilder quoteBuilder = new TestQuoteBuilder(); 
        Quote quote = quoteBuilder
            .withName('Test Quote')
            .withStatus('Calculation')
            .withquoteRate(rate.Id)
            .withQuoteTerm('40')
            .withApplicableOffer(appOffer.Id)
            .withOpportunity(opportunity.Id)
            .withInsuranceDisplayOption('1')
            .withPricebook2Id(standardPricebook.id)
            .withValueDownpayment('12')
            .withFrequency('Monthly')
            .withAmount(500)            
            .insertRecord(false)
            .build();
        
        quote.Rental_Amount__c=23;
        quote.Description='abc';            
        quote.contactid=lesseeContact.Id;
        quote.Payment_Timing__c='in-arrears';
        insert quote;
        
        Special_Terms_and_Conditions__c specialTermsandConditins = new Special_Terms_and_Conditions__c();
        specialTermsandConditins.Type__c = 'Action required';
        specialTermsandConditins.Body__c = 'Test Body';
        specialTermsandConditins.Is_Program_Specific__c = false;
        specialTermsandConditins.Region__c =  testRegion.Id;
        insert specialTermsandConditins;
        
        Special_Terms_and_Conditions__c specialT_C = dataFactory.buildSpecialTermsAndConditions('ABC','Mandatory','Yes',testProgram.Id,null,' ', 'Test');
        specialT_C.Type__c='Action required';
        update specialT_C;
        
        Applicable_Special_Terms_and_Conditions__C applicationSpecialTerms = new Applicable_Special_Terms_and_Conditions__C();
        applicationSpecialTerms.Quote__c = quote.id;
        applicationSpecialTerms.Special_Terms_and_Conditions__c = specialTermsandConditins.id;
        insert applicationSpecialTerms;
        Blob bodyBlob = Blob.valueOf('Some string');
        
        ContentVersion newContent = new ContentVersion();
        newContent.Title = 'Contract';
        newContent.VersionData = bodyBlob;
        newContent.PathOnClient = 'Contract.pdf';
        newContent.Document_Type__c = 'Contract';
        insert newContent;
        
        ContentVersion content = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContent.Id];
        
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = quote.Id;
        docLink.ContentDocumentId = content.ContentDocumentId;
        docLink.ShareType = 'V';
        docLink.Visibility = 'AllUsers';
        insert docLink;    
        
        E_Sign_Information__c eSignInfo = new E_Sign_Information__c(
            Opportunity__c = opportunity.Id,
            Quote__c = quote.Id,
            Document_Type__c = 'Contract',
            Document_Name__c= 'Contract',
            Customer_Email__c = 'test@customer.com',
            Status__c = 'New',
            Signer_Name__c = 'Signer Name', 
            SSN_Number__c = '1234567', 
            ExpirationDate__c = System.today().addMonths(1)
        );
        insert eSignInfo;
        
        Contact contact = new Contact(LastName ='TestContact', AccountId = account.Id);
        insert contact;  
        
        Contact endUserContact = new Contact(LastName ='EndUser Contact', AccountId = account2.Id,Role__c = Constants.ULTIMATE_BENEFICIAL_OWNER_CONTACT_ROLE );
        insert endUserContact;  
        
        
        
        Insurance__c insurance = dataFactory.buildInusrance('Test Insurance','AF10000','Soft Asset',0.50,0.50,testRegion.id);
        
        Insurance_Line_Item__c insuranceLineItem =dataFactory.buildInusranceLineItem(insurance.id,account.id,10000,1,false);
        Insurance_Line_Item__c insuranceLineItem2 =dataFactory.buildInusranceLineItem(insurance.id,account.id,20000,2,false);
        Insurance_Line_Item__c insuranceLineItem3 =dataFactory.buildInusranceLineItem(insurance.id,account.id,30000,3,false);
        
        insert new List<Insurance_Line_Item__c>{insuranceLineItem, insuranceLineItem2, insuranceLineItem3};
            
            
        
        QuoteLineItem qli1 = dataFactory.buildQuoteLineItem(10,quote.id,hardwareProd5.id,100,pbe9.id,'AF1001',10.0,'DW',100.0,3.2,1000,false);            
        QuoteLineItem qli2 = dataFactory.buildQuoteLineItem(10,quote.id,hardwareProd5.id,100,pbe9.id,'AF1001-1',10.0,'DW',100.0,3.2,1000,false);
        QuoteLineItem qli3 = dataFactory.buildQuoteLineItem(10,quote.id,hardwareProd5.id,100,pbe9.id,'AF1001-2',10.0,'DW',100.0,3.2,1000,false);
        QuoteLineItem qli4 = dataFactory.buildQuoteLineItem(10,quote.id,hardwareProd5.id,100,pbe9.id,'AF1001-4',10.0,'DW',100.0,3.2,1000,false);
        QuoteLineItem qli5 = dataFactory.buildQuoteLineItem(10,quote.id,hardwareProd6.id,100,pbe9.id,'',0.0,'DW',100.0,3.2,1000,false);
        QuoteLineItem qli6 = dataFactory.buildQuoteLineItem(10,quote.id,InstallationProduct.id,100,pbe9.id,'AF1001-4',10.0,'DW',100.0,3.2,1000,false);
        QuoteLineItem qli7 = dataFactory.buildQuoteLineItem(10,quote.id,softCostProd.id,100,pbe9.id,'AF1001-4',10.0,'DW',100.0,3.2,1000,false);
        insert new List<QuoteLineItem>{qli1, qli2, qli3, qli4, qli5,qli6,qli7};
            
            RV_Matrix__c rvMatrix1 = dataFactory.buildrvMatrix(account2.id,testProgram.id,'DLL',testRegion.id);
        
        Applicable_RV__c applicableRV = dataFactory.buildapplicableRV(testOffer.id, rvMatrix1.id, true);
        
        Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd1.id,ITADProduct1.id,insurance.id,true,rvMatrix1.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd2.id,ITADProduct2.id,insurance.id,true,rvMatrix1.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail3 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd3.id,ITADProduct3.id,insurance.id,true,rvMatrix1.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail4 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd4.id,ITADProduct3.id,insurance.id,true,rvMatrix1.id,'Laptops',false);            
        Asset_Program_Detail__c assetProgramDetail5 = dataFactory.buildassetProgramDetail(assetProgram.id,hardwareProd5.id,ITADProduct3.id,insurance.id,true,rvMatrix1.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail6 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.id,hardwareProd6.id,null,null,false,null,null,true,false);
        Asset_Program_Detail__c assetProgramDetail7 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.id,hardwareProd5.id,null,insurance.id,true,rvMatrix1.id,'Laptops',false);
        Asset_Program_Detail__c assetProgramDetail8 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.id,maintenanceProduct.id,null,null,false,null,null,false);
        Asset_Program_Detail__c assetProgramDetail9 = dataFactory.buildassetProgramDetail(assetProgram.id,back_officeparam.id,softCostProd.id,null,null,false,null,null,false);
        
        insert new List<Asset_Program_Detail__c>{assetProgramDetail1, assetProgramDetail2, assetProgramDetail3, assetProgramDetail4, assetProgramDetail5, assetProgramDetail6,assetProgramDetail7,assetProgramDetail8,assetProgramDetail9};
            
            
        
        Offer_Special_Terms_Conditions__c offerSpecialT_C = dataFactory.buildOfferSpecialTermsAndConditions(testOffer.Id , specialT_C.Id);
        
        Id profileId = [SELECT Id FROM Profile WHERE Name LIKE 'Nordics Community Profile'].Id;
        
        User user = new User(
            Alias               = 'TestUser', 
            Email               = 'test@ntest.com',
            EmailEncodingKey    = 'UTF-8', 
            LastName            = 'TestPartherUser', 
            LanguageLocaleKey   = 'en_US',
            LocaleSidKey        = 'en_US', 
            ProfileId           = profileId, 
            Country             = 'United States', 
            IsActive            = true,
            ContactId           = contact.Id,
            TimeZoneSidKey      = 'America/Los_Angeles', 
            UserName            = 'TestPartherUser@test.com'
        );
        insert user;
    }
}

@IsTest static void makeSubmitAppRequestTest1() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    //String paramsOG = '{"oppId":"0061F00000Dg6Vj","insuranceMode":"Displayed separately","oppName":"SE00000018","quoteId":"' + quote.id + '","oppOwner":"Anujit Partner","programBU":"HC","oppCreationDate":"2021-03-17 10:14:03","financialProductName":"Leasing Offer","offerName":"Leasing Standard","oppCurrency":"SEK","qouteTerm":"30","paymentFrequency":"Monthly","advanceArrear":"in-advance","oppFinancedAmount":"22","nominalInterestRate":"8.01","productInfoList":[{"productname": "Apple Ipad Air Soft Cost","productType": "Soft Cost","quantity": "1.00","totalprice": "1000.00","unitprice": "1000.00"},{"productname": "iPad Air Asset Hard","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"}],"serviceInfoList":[{"quantity": "1.00","serviceName": "External Maintenance","totalprice": "200.00","unitprice": "200.00"}],"customerExtId": "559248-1641","customerId": "00102000006uhFbAAI","customerStreet": "Box 3722","customerCity": "Svenshögen","customerPostalCode": "44497","customerLegalName": "Lockberga AB","partnerName": "Anujit Partner","partnerEmail": "anujit.das@cognizant.com","lesseeContact":{"name":"Test Contact","email":"test@rwerw.com","phoneNumber":"123456789"},"deliveryAddress":{"street":"Street","city":"123456","postalCode":"City"}}';
    String params = '{"oppId":"0061F00000Dg6Vj","insuranceMode":"Displayed separately","oppName":"SE00000018","quoteId":"' + quote.id + '","oppOwner":"Anujit Partner","programBU":"HC","oppCreationDate":"2021-03-17 10:14:03","financialProductName":"Leasing Offer","offerName":"Leasing Standard","oppCurrency":"SEK","qouteTerm":"30","paymentFrequency":"Monthly","advanceArrear":"in-advance","oppFinancedAmount":"22","nominalInterestRate":"8.01","productInfoList":[{"productname": "Apple Ipad Air Soft Cost","productType": "Soft Cost","quantity": "1.00","totalprice": "1000.00","unitprice": "1000.00"},{"productname": "iPad Air Asset Hard","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"},{"productname": "iPhone 12","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"}],"serviceInfoList":[{"quantity": "1.00","serviceName": "External Maintenance","totalprice": "200.00","unitprice": "200.00"}],"customerExtId": "559248-1641","customerId": "00102000006uhFbAAI","customerStreet": "Box 3722","customerCity": "Svenshögen","customerPostalCode": "44497","customerLegalName": "Lockberga AB","partnerName": "Anujit Partner","partnerEmail": "anujit.das@cognizant.com","lesseeContact":{"name":"Test Contact","email":"test@rwerw.com","phoneNumber":"123456789"},"deliveryAddress":{"street":"Street","city":"123456","postalCode":"City"}}';
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"contractNumber" : "SE00000018-1"}');
    
    Test.setMock(HttpCalloutMock.class, mock);
    String responseStr;
    Test.startTest();
    object errorFieldTest = RESTCalloutHelper.setErrorField(quote.name);
    try{
        responseStr = RESTCalloutHelper.makeSubmitAppRequest(params, true);
        
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void makeSubmitAppRequestTest2() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params1 = '{"oppId":"0061F00000Dg6Vj","insuranceMode":"Included in rent","oppName":"SE00000018","quoteId":"' + quote.id + '","oppOwner":"Anujit Partner","programBU":"HC","oppCreationDate":"2021-03-17 10:14:03","financialProductName":"Leasing Offer","offerName":"Leasing Standard","oppCurrency":"SEK","qouteTerm":"30","paymentFrequency":"Monthly","advanceArrear":"in-advance","oppFinancedAmount":"22","nominalInterestRate":"8.01","productInfoList":[{"productname": "Apple Ipad Air Soft Cost","productType": "Soft Cost","quantity": "1.00","totalprice": "1000.00","unitprice": "1000.00"},{"productname": "iPad Air Asset Hard","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"}],"serviceInfoList":[{"quantity": "1.00","serviceName": "External Maintenance","totalprice": "200.00","unitprice": "200.00"}],"customerExtId": "559248-1641","customerId": "00102000006uhFbAAI","customerStreet": "Box 3722","customerCity": "Svenshögen","customerPostalCode": "44497","customerLegalName": "Lockberga AB","partnerName": "Anujit Partner","partnerEmail": "anujit.das@cognizant.com","lesseeContact":{"name":"Test Contact","email":"test@rwerw.com","phoneNumber":"123456789"},"deliveryAddress":{"street":"Street","city":"123456","postalCode":"City"}}';
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"contractNumber" : "SE00000018-1"}');
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    String responseStr2;
    Test.startTest();
    object errorFieldTest = RESTCalloutHelper.setErrorField(quote.name);
    try{
        responseStr2 = RESTCalloutHelper.makeSubmitAppRequest(params1, true);
        
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void makeSubmitAppRequestTest3() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params3 = '{"oppId":"0061F00000Dg6Vj","insuranceMode":"Added on invoice","oppName":"SE00000018","quoteId":"' + quote.id + '","oppOwner":"Anujit Partner","programBU":"HC","oppCreationDate":"2021-03-17 10:14:03","financialProductName":"Leasing Offer","offerName":"Leasing Standard","oppCurrency":"SEK","qouteTerm":"30","paymentFrequency":"Monthly","advanceArrear":"in-advance","oppFinancedAmount":"22","nominalInterestRate":"8.01","productInfoList":[{"productname": "Apple Ipad Air Soft Cost","productType": "Soft Cost","quantity": "1.00","totalprice": "1000.00","unitprice": "1000.00"},{"productname": "iPad Air Asset Hard","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"}],"serviceInfoList":[{"quantity": "1.00","serviceName": "External Maintenance","totalprice": "200.00","unitprice": "200.00"}],"customerExtId": "559248-1641","customerId": "00102000006uhFbAAI","customerStreet": "Box 3722","customerCity": "Svenshögen","customerPostalCode": "44497","customerLegalName": "Lockberga AB","partnerName": "Anujit Partner","partnerEmail": "anujit.das@cognizant.com","lesseeContact":{"name":"Test Contact","email":"test@rwerw.com","phoneNumber":"123456789"},"deliveryAddress":{"street":"Street","city":"123456","postalCode":"City"}}';
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"contractNumber" : "SE00000018-1"}');
    
    Test.setMock(HttpCalloutMock.class, mock);
    String responseStr3;
    Test.startTest();
    object errorFieldTest = RESTCalloutHelper.setErrorField(quote.name);
    try{
        responseStr3 = RESTCalloutHelper.makeSubmitAppRequest(params3, true);
        
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void makeSubmitAppRequestTest4() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params4 = '{"oppId":"0061F00000Dg6Vj","oppName":"SE00000018","quoteId":"' + quote.id + '","oppOwner":"Anujit Partner","programBU":"HC","oppCreationDate":"2021-03-17 10:14:03","financialProductName":"Leasing Offer","offerName":"Leasing Standard","oppCurrency":"SEK","qouteTerm":"30","paymentFrequency":"Monthly","advanceArrear":"in-advance","oppFinancedAmount":"22","nominalInterestRate":"8.01","productInfoList":[{"productname": "Apple Ipad Air Soft Cost","productType": "Soft Cost","quantity": "1.00","totalprice": "1000.00","unitprice": "1000.00"},{"productname": "iPad Air Asset Hard","productType": "Asset Hard","quantity": "2.00","totalprice": "3000.00","unitprice": "1500.00"}],"serviceInfoList":[{"quantity": "1.00","serviceName": "External Maintenance","totalprice": "200.00","unitprice": "200.00"}],"customerExtId": "559248-1641","customerId": "00102000006uhFbAAI","customerStreet": "Box 3722","customerCity": "Svenshögen","customerPostalCode": "44497","customerLegalName": "Lockberga AB","partnerName": "Anujit Partner","partnerEmail": "anujit.das@cognizant.com","lesseeContact":{"name":"Test Contact","email":"test@rwerw.com","phoneNumber":"123456789"},"deliveryAddress":{"street":"Street","city":"123456","postalCode":"City"}}';
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"contractNumber" : "SE00000018-1"}');
    
    Test.setMock(HttpCalloutMock.class, mock);
    String responseStr4;
    
    Test.startTest();
    object errorFieldTest = RESTCalloutHelper.setErrorField(quote.name);
    try{
        responseStr4 = RESTCalloutHelper.makeSubmitAppRequest(params4, true);
        
    }catch(Exception e){
        isException = true;
    }
        Test.stopTest();
        System.assertEquals(false, isException);
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testSubmitAppfromInvoiceSrc() { 
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c 
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{}');
    Boolean isException = false;
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    
    Test.startTest();
    try {
        Boolean isUBO = true;
        SubmitApplicationHelper.submitAppfromInvoiceSrc(esignInfo.Id,isUBO,false);
    } catch (Exception e) {
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void makeCreditAssessmentRequestTest() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{}');
        
        Test.setMock(HttpCalloutMock.class, mock);
        String responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.makeCreditAssessmentRequest(quote.id, true);
        }catch(Exception e){
            isException = true;
        }
        
            Test.stopTest();
        
    }
    System.assertEquals(false, isException);
    System.assertEquals('Calculation', [SELECT Status FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1].Status);    
    
}

@IsTest static void getCustomerTestPositive() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String customerInfo = 'organization-number';
    String customerExtId = '559810-0534';
    system.runAs(user) {
        String body = '{"data": [{' +
            '"name": "\'Karl Vilhelm\' Mattias Bengtsson",' +
            '"address": {' +
            '"street": "Magnetitvägen 42 Lgh 1607",' +
            '"city": "Perstorp",' +
            '"postalCode": "28422"' +
            '},' +
            '"legalEntity": {' +
            '"id": "SOLO",' +
            '"name": "SOLO TRADER",' +
            '"url": "https://apiacc.dllgroup.com/v2/legalentities?country="' +
            '},' +
            '"phoneNumbers": [' +
            '{' +
            '"type": "business",' +
            '"number": "0500-49 92 41",' +
            '"areaCode": ""' +
            '}' +
            ']' +
            '}' +
            '],' +
            '"links": {' +
            '"self": "https://apiacc.dllgroup.com/v2/parties?unique_identifier=710328-4555&unique_identifier_type=organization-number&country_of_registration=SE"' +
            '}' +
            '}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);
        
        Test.setMock(HttpCalloutMock.class, mock);
        String responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.getCustomer(quote.id, customerExtId, customerInfo);
        }catch(Exception e){
            isException=true;
        }
        Test.stopTest();
        
        
        SearchPartyResponseBodyWrapper response = (SearchPartyResponseBodyWrapper) JSON.deserialize(responseStr, SearchPartyResponseBodyWrapper.class);
        System.assertEquals(false, isException);
        System.assertEquals('\'Karl Vilhelm\' Mattias Bengtsson', response.data[0].name);
        System.assertEquals('Perstorp', response.data[0].address.city);
        System.assertEquals('Magnetitvägen 42 Lgh 1607', response.data[0].address.street);
        System.assertEquals('28422', response.data[0].address.PostalCode);
        
    }
}

@IsTest static void getCustomerTestNegative() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String customerInfo = 'organization-number';
    String customerExtId = '559810-0534';
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(404, 'Resource Not Found', '{}');
        
        Test.setMock(HttpCalloutMock.class, mock);
        String responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.getCustomer(quote.id, customerExtId, customerInfo);
        }catch(Exception e){
            isException=true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);            
        System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
    
}

@IsTest static void calculationAPIRequestTestPositive() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "payments","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":"a0p020000009E6I","financialProductId":"a0w02000000QbwH","assets": [{"productName":"Iphone","quantity": 3,"price": 74624.0,"residualValueAmount":"100","insuranceAmount":"100"}], "maintenance":[{"productName":"Maintenance","quantity":"1","price":"200"}],"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
    
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ], "paymentCalculation":{"rentalPayments":{"amount":1013.8,"principal":816.99,"interestAmount":196.81},"maintenance":{"amount":12000.0}},'+
                                                                                    +'"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"iPad Air Asset Hard"},"quantity":1,"salePrice":432.0,"residualValue":{"value":23.0,"id":"a1t8B00000000srQAA"},"insurances":[{"amount":12}],"financeCalculation":{"financeAmount":432.0,"futureValue":0.0},"consolidatedPayments":[{"amount":19.49}]}]}');           
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }
        catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);           
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
}

@IsTest static void calculationAPIRequestTestNegative() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "payments","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":"a0p020000009E6I","financialProductId":"a0w02000000QbwH","assets": [{"productName":"Iphone","quantity": 3,"price": 74624.0,"residualValueAmount":"100","insuranceAmount":"100"}], "maintenance":[{"productName":"Maintenance","quantity":"1","price":"200"}],"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
    
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(400, 'Success', '{"id": "business_rule_violation", "message": "Residual value [a1t8B00000000spQAAa2A8B000000CcakUAC: 500] is not within boundaries for the asset; brandName = [], modelName = [iMac]; minimum 1 % sale-price [700], maximum 30 % sale-price [21000]"}');
                                                                                    
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }
        catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);           
        System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
}

@IsTest static void calculationAPIRequestTestWithOutAsset() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Applicable_Offers__r.Offer__r.Program__c FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "payments","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":\"'+quote.Applicable_Offers__r.Offer__r.Program__c+'\","financialProductId":"a0w02000000QbwH","assets":null,"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
       
    system.runAs(user) {
        //MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ]}');
        
        
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ], "paymentCalculation":{"rentalPayments":{"amount":1013.8,"principal":816.99,"interestAmount":196.81},"maintenance":{"amount":12000.0}},'+
                                                                                    +'"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"iPad Air Asset Hard"},"quantity":1,"salePrice":432.0,"residualValue":{"value":23.0,"id":"a1t8B00000000srQAA"},"insurances":[{"amount":12}],"financeCalculation":{"financeAmount":432.0,"futureValue":0.0},"consolidatedPayments":[{"amount":19.49}]}]}');           
        
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
}

@IsTest static void calculationAPIRequestTestWithOutAssetException() {
    
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Applicable_Offers__r.Offer__r.Program__c FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "payments","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":\"'+quote.Applicable_Offers__r.Offer__r.Program__c+'\","financialProductId":"a0w02000000QbwH","assets":null,"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
       
    system.runAs(user) {
        //MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ]}');
        
        
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"1234",financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ], "paymentCalculation":{"rentalPayments":{"amount":1013.8,"principal":816.99,"interestAmount":196.81},"maintenance":{"amount":12000.0}},'+
                                                                                    +'"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"iPad Air Asset Hard"},"quantity":1,"salePrice":432.0,"residualValue":{"value":23.0,"id":"a1t8B00000000srQAA"},"insurances":[{"amount":12}],"financeCalculation":{"financeAmount":432.0,"futureValue":0.0},"consolidatedPayments":[{"amount":19.49}]}]}');           
        
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);
        System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
}

@IsTest static void testCreateOrderPositive() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c, Quote__c,Document_Type__c,Document_Name__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'
        LIMIT   1  
    ];
    
    String responseBody = '{"Item":{"OrderID":"a2D1F000002OjY1UAK","TransRef":"009DC117A2478C5DCDFD1140F1F4D345EA209FC1","OrderDescription":null,"OrderStatus":0,"SearchHits":"1","SigningProcessResults":{"SigningProcessResult":[{"SigningProcessId":5716916,"Status":0,"LocalWebContextRef":"webcontext-ref","LocalSignerReference":"Signer Name","LocalOrganizationRef":null,"DocumentDetails":{"DocumentStatus":0,"LocalDocumentReference":"Contract","Presentation":{"Title":"Contract","Description":"TestDescription"},"DocType":0},"Attachments":null,"SignURL":"https://www.sign-preprod1.nets.eu/sign/index.html?ref=E9D6B027E3D6179CE8EC2CA04194737D90B942F9","SigningTime":null,"SignerSSN":null}]}},"MerchantID":1587,"Time":"2021-06-25T12:46:20+00:00","MessageID":"97c91629-989f-4ea2-bd25-cc6a9e5559e0","AdditionalInfo":null}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        RESTCalloutHelper.createOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
    Test.stopTest();
    System.assertEquals(false, isException);
    //System.assertNotEquals(esignInfo.Status__c, [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);    
    System.assertEquals(Constants.ACTIVE_STATUS, [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);
    
}

@IsTest static void testCreateOrderNegative() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    // esignInfo.Status__c = 'Complete';
    //update esignInfo;
    
    String responseBody = '{"Message":"Invalid OrderId. There is already an order with this OrderId ' + esignInfo.Id + ' in the system."}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(500, 'Internal Server Error', responseBody);
    
    Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    try {
        RESTCalloutHelper.createOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
        Test.stopTest();
    System.assertEquals(false, isException);
    //System.assertEquals('Complete', [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

    @IsTest static void testCreateOrderException() {
        
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c, Quote__c,Document_Type__c,Document_Name__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'
        LIMIT   1  
    ];
    
    String responseBody = '{"123",Item":{"OrderID":"a2D1F000002OjY1UAK","TransRef":"009DC117A2478C5DCDFD1140F1F4D345EA209FC1","OrderDescription":null,"OrderStatus":0,"SearchHits":"1","SigningProcessResults":{"SigningProcessResult":[{"SigningProcessId":5716916,"Status":0,"LocalWebContextRef":"webcontext-ref","LocalSignerReference":"Signer Name","LocalOrganizationRef":null,"DocumentDetails":{"DocumentStatus":0,"LocalDocumentReference":"Contract","Presentation":{"Title":"Contract","Description":"TestDescription"},"DocType":0},"Attachments":null,"SignURL":"https://www.sign-preprod1.nets.eu/sign/index.html?ref=E9D6B027E3D6179CE8EC2CA04194737D90B942F9","SigningTime":null,"SignerSSN":null}]}},"MerchantID":1587,"Time":"2021-06-25T12:46:20+00:00","MessageID":"97c91629-989f-4ea2-bd25-cc6a9e5559e0","AdditionalInfo":null}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        RESTCalloutHelper.createOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
        Test.stopTest();
    System.assertEquals(false, isException);
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testCancelOrderPositive() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    String responseBody = '{"Item":{"OrderID":"a2D1F000002OjY1UAK","TransRef":"685E82D7C2303762827367980F0A0ECE51C2B244"},"MerchantID":1587,"Time":"2021-06-25T13:16:48+00:00","MessageID":"00000000-0000-0000-0000-000000000000","AdditionalInfo":null}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);
    String message;
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        message = RESTCalloutHelper.cancelOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
    Test.stopTest();
    System.assertEquals(false, isException);
    //System.assertNotEquals(esignInfo.Status__c, [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);
    System.assertEquals(Constants.CANCELLED_STATUS, [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);
    System.assertEquals(Label.Order_has_been_canceled, ((Map<String,Object>) JSON.deserializeUntyped(message)).get('Success message'));
    
}

@IsTest static void testCancelOrderNegative() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    
    
    String responseBody = '{"Message":"Unable to perform CancelOrder request. Order with OrderId [' + esignInfo.Id + '] has the following Status [Orderstatus=CancelledByMerchant]. Reason: Order is not in Active state"}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(500, 'Internal Server Error', responseBody);
    String message;
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        message = RESTCalloutHelper.cancelOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
    Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(esignInfo.Status__c, [SELECT Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].Status__c);
    System.assertNotEquals(null, ((Map<String,Object>) JSON.deserializeUntyped(message)).get('Error message'));
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testCancelOrderException() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    String responseBody = '{"123",Item":{"OrderID":"a2D1F000002OjY1UAK","TransRef":"685E82D7C2303762827367980F0A0ECE51C2B244"},"MerchantID":1587,"Time":"2021-06-25T13:16:48+00:00","MessageID":"00000000-0000-0000-0000-000000000000","AdditionalInfo":null}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);
    String message;
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        message = RESTCalloutHelper.cancelOrder(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
        Test.stopTest(); 
    System.assertEquals(false, isException);
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testGetSDOPositive() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    String responseBody = '{"OrderID":"a2D1F000002OiXjUAK","B64SDOBytes":"SDO String","PAdESSignedDocumentBytes":"PAdES String"}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', responseBody);
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    
    
    Test.startTest();
    try {
        RESTCalloutHelper.getSDOCallout(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
        Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(2, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :esignInfo.Id].size());
    
}

@IsTest static void testGetSDONegative() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    String responseBody = '{"Message":"Invalid GetSDO request. OrderId [a2D1F000002OiXjUAK] does not exist or might be deleted for MerchantID=1587"}';
    Boolean isException = false;
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(500, 'Internal Server Error', responseBody);
    
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        RESTCalloutHelper.getSDOCallout(esignInfo.Id);
    } catch (Exception e) {
        isException = true;
    }
    
    Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(0, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :esignInfo.Id].size());
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testSendCodePositive() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'OK', '{}');
    Boolean isException = false;
    Test.setMock(HttpCalloutMock.class, mock);
    String message;
    
    Test.startTest();
    try {
        message = RESTCalloutHelper.sendCode('{"code":"12345678", "additional_info":"'+ esignInfo.Id +'"}');
    } catch (Exception e) {
        isException = true;
    }
    
    
    System.assertEquals(false, isException);
    System.assertNotEquals(null, ((Map<String,Object>) JSON.deserializeUntyped(message)).get('Success message'));
    System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}

@IsTest static void testSendCodeNegative() {
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
    
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(404, 'Resource Not Found', '{}');
    Boolean isException = false;
    String message;
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        message = RESTCalloutHelper.sendCode('{"code":"12345678", "additional_info":"'+ esignInfo.Id +'"}');
    } catch (Exception e) {
        isException = true;
    }
        Test.stopTest();
    System.assertEquals(false, isException);
    System.assertNotEquals(null, ((Map<String,Object>) JSON.deserializeUntyped(message)).get('Error message'));
    
}

@IsTest static void testSendCDocumentsToDCVPositive() { 
    
    E_Sign_Information__c esignInfo = [ SELECT  Id, Status__c,Opportunity__r.Name,Quote__r.Name FROM  E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name'];
    
    //Quote quote = [SELECT Id,Name,Opportunity.Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Resource Not Found', '{}');
    Boolean isException = false;
    String message;
    Test.setMock(HttpCalloutMock.class, mock);
    
    Test.startTest();
    try {
        Map<String,Object> sendDocParam = new Map<String,Object>();
        sendDocParam.put('orderId', esignInfo.id);
        sendDocParam.put('documents',  new Map<String,String>{'SDO' => 'ABCD'});
        sendDocParam.put('documentType', Constants.SMARTCOMM_DOCTYPE_CONTRACT);                
        sendDocParam.put('oppName', esignInfo.Opportunity__r.Name);
        sendDocParam.put('quoteName', esignInfo.Opportunity__r.Name);                
        sendDocParam.put('type', Constants.UNSIGNED_DOCUMENT_TYPE);
        RESTCalloutHelper.sendDocumentsToDCV(sendDocParam);
    } catch (Exception e) {
        isException = true;
    }
        Test.stopTest();
    System.assertEquals(false, isException);
    System.assertEquals(Constants.UNSIGNED_STATUS_SENT, [SELECT UnSigned_Doc_Status__c FROM E_Sign_Information__c WHERE Signer_Name__c = 'Signer Name' LIMIT 1].UnSigned_Doc_Status__c);
    
    //System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
}

@IsTest static void testSendCDocumentsToDCVNegative() { 
    
    Quote quote = [SELECT Id,Name,Opportunity.Name FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(404, 'Resource Not Found', '{}');
    Boolean isException = false;
    String message;
    Test.setMock(HttpCalloutMock.class, mock);
    
        Test.startTest();
    try {
        
        Map<String,Object> sendDocParam = new Map<String,Object>();
        //sendDocParam.put('orderId', esignInfo.Id);
        //sendDocParam.put('documents', new Map<String,String>{unsignedPdf[0].Title => EncodingUtil.base64Encode(unsignedPdf[0].VersionData)});
        sendDocParam.put('documentType', Constants.SMARTCOMM_DOCTYPE_CONTRACT);                
        sendDocParam.put('oppName', quote.Opportunity.Name);
        sendDocParam.put('quoteName', quote.Name);                
        sendDocParam.put('type', Constants.UNSIGNED_DOCUMENT_TYPE);
        
        RESTCalloutHelper.sendDocumentsToDCV(sendDocParam);   
    } catch (Exception e) {
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
    
}


@IsTest static void calculationITAD_DW() {
    
    Program__c testProgram = [SELECT Name FROM  Program__c WHERE Name = 'Test Program'];
    Applicable_Offer__c appOffer = [SELECT ID FROM  Applicable_Offer__c WHERE Name = 'Test Applicable Offer'];
    list<Product2> prodList = [SELECT id,Name FROM Product2 WHERE Name In (:'Test Tablets, Mobile phone','Test PC,Workstations','Test Notebook') ORDER BY Name];
    Boolean isException = false;
    map<string,integer> productNameToQuantityMap = new map<string,integer>();
    productNameToQuantityMap.put('test macbook pro',51);
    productNameToQuantityMap.put('test iphone 12 pro max',90);
    productNameToQuantityMap.put('test ipad air',40);
    productNameToQuantityMap.put('test apple laptop',200);
    List<CalculationRequestBodyWrapper.FeesWrapperClass> dataWipingRes;
    
    Test.startTest();
    try{
        dataWipingRes = CalculationRequestBodyWrapper.findItadApplicableInOffer(testProgram.id,appOffer.id,productNameToQuantityMap,'Data Wiping');  
    }catch(Exception e){
        isException = true;
    }
    
    Test.stopTest();
    DatedConversionRate rate = [SELECT Conversionrate FROM DatedConversionRate WHERE isoCode =: label.Current_Currency ORDER BY NextStartDate DESC limit 1];
    
    System.assertEquals(false, isException);
    for (CalculationRequestBodyWrapper.FeesWrapperClass eachdataItem : dataWipingRes) {
        if (eachdataItem.id == (prodList[0].Name).toLowerCase()) {
            System.assertEquals(Math.roundToLong((200 + 40) * 13 * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[1].Name).toLowerCase()){
            System.assertEquals(Math.roundToLong(90 * 11 * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[2].Name).toLowerCase()){
            System.assertEquals(Math.roundToLong(51 * 10.5 * rate.Conversionrate),eachdataItem.amount);
            
        }
    }  
}

@IsTest static void calculationITAD_OP() {
    
    Program__c testProgram = [SELECT ID FROM  Program__c WHERE Name = 'Test Program'];
    Applicable_Offer__c appOffer = [SELECT ID FROM  Applicable_Offer__c WHERE Name = 'Test Applicable Offer'];
    list<Product2> prodList = [SELECT id,Name FROM Product2 WHERE Name In (:'Test Tablets, Mobile phone','Test PC,Workstations','Test Notebook') ORDER BY Name];
    Boolean isException = false;
    map<string,integer> productNameToQuantityMap = new map<string,integer>();
    productNameToQuantityMap.put('test macbook pro',51);
    productNameToQuantityMap.put('test iphone 12 pro max',90);
    productNameToQuantityMap.put('test ipad air',40);
    productNameToQuantityMap.put('test apple laptop',200);
    List<CalculationRequestBodyWrapper.FeesWrapperClass> OnSitePackagingRes;
    
    Test.startTest();
    try{
        OnSitePackagingRes = CalculationRequestBodyWrapper.findItadApplicableInOffer(testProgram.id,appOffer.id,productNameToQuantityMap,'Onsite Packaging');
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    

    DatedConversionRate rate = [SELECT Conversionrate FROM DatedConversionRate WHERE isoCode =: label.Current_Currency ORDER BY NextStartDate DESC limit 1];
    
    System.assertEquals(false, isException);
    for (CalculationRequestBodyWrapper.FeesWrapperClass eachdataItem : OnSitePackagingRes) {
        if (eachdataItem.id == (prodList[0].Name).toLowerCase()) {
            System.assertEquals(Math.roundToLong((240 * 13 + 50 * 30.3 + 190 * 9) * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[1].Name).toLowerCase()){
            System.assertEquals(Math.roundToLong((400 + 90 * 11 + 40 * 40 + 40 * 9) * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[2].Name).toLowerCase()){
            System.assertEquals(Math.roundToLong((51 * 10.5 + 50 * 10.7 + 1 * 9) * rate.Conversionrate),eachdataItem.amount);
            
        }
    }
    
}

@IsTest static void calculationITAD_RL() {
    
    Program__c testProgram = [SELECT ID FROM  Program__c WHERE Name = 'Test Program'];
    Applicable_Offer__c appOffer = [SELECT ID FROM  Applicable_Offer__c WHERE Name = 'Test Applicable Offer'];
    list<Product2> prodList = [SELECT id,Name FROM Product2 WHERE Name In (:'Test Tablets, Mobile phone','Test PC,Workstations','Test Notebook') ORDER BY Name];
    Boolean isException = false;
    map<string,integer> productNameToQuantityMap = new map<string,integer>();
    productNameToQuantityMap.put('test macbook pro',51);
    productNameToQuantityMap.put('test iphone 12 pro max',90);
    productNameToQuantityMap.put('test ipad air',40);
    productNameToQuantityMap.put('test apple laptop',200);
    List<CalculationRequestBodyWrapper.FeesWrapperClass> ReversedLogisticsRes;
    
    Test.startTest();
    try{
        ReversedLogisticsRes = CalculationRequestBodyWrapper.findItadApplicableInOffer(testProgram.id,appOffer.id,productNameToQuantityMap,'Reversed Logistics');
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
    DatedConversionRate rate = [SELECT Conversionrate FROM DatedConversionRate WHERE isoCode =: label.Current_Currency ORDER BY NextStartDate DESC limit 1];
    
    for (CalculationRequestBodyWrapper.FeesWrapperClass eachdataItem : ReversedLogisticsRes) {
        if (eachdataItem.id == (prodList[0].Name).toLowerCase()) {
            System.assertEquals(Math.roundToLong((240 * 13 + 50 * 10 + 190 * 6) * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[1].Name).toLowerCase()){
            System.assertEquals(Math.roundToLong((200 + 90 * 11 + 40 * 20 + 40 * 6) * rate.Conversionrate),eachdataItem.amount);
        }
        else if(eachdataItem.id == (prodList[2].Name).toLowerCase()){ 
            System.assertEquals(Math.roundToLong((51 * 10.5 + 50 * 11.25 + 1 * 6) * rate.Conversionrate),eachdataItem.amount);
        
        }
    }
    
}

@IsTest static void CalculationReqWrapperTest() {
    Boolean isException = false;
    CalculationRequestBodyWrapper crb = new CalculationRequestBodyWrapper();
    Map<String, Object> params = new Map<String, Object>();
    params.put('paymentFrequency','monthly');
    params.put('paymentFrequency','quarterly');
    params.put('terms',12);
    Test.startTest();
    try{
        crb.prepareCalculationPayments(params);
    }catch(Exception e){
        isException = true;
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
}

@IsTest static void CalculationReqWrapperTest1() {
    Boolean isException = false;
    CalculationRequestBodyWrapper crb = new CalculationRequestBodyWrapper();
    Map<String, Object> params = new Map<String, Object>();   
    params.put('paymentFrequency','annually');
    params.put('terms',12);
    Test.startTest();
    try{
        crb.prepareCalculationPayments(params);
    }catch(Exception e){
        isException = true; 
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
}

@IsTest static void CalculationReqWrapperTest2() {
    Boolean isException = false;
    CalculationRequestBodyWrapper crb = new CalculationRequestBodyWrapper();
    Map<String, Object> params = new Map<String, Object>();
    params.put('paymentFrequency','monthly');
    params.put('terms',12);
    Test.startTest();
    try{
        crb.prepareCalculationPayments(params);
    }catch(Exception e){
        isException = true; 
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
}

@IsTest static void CalculationReqWrapperTest3() {
    Boolean isException = false;
    CalculationRequestBodyWrapper crb = new CalculationRequestBodyWrapper();
    Map<String, Object> params = new Map<String, Object>();
    params.put('paymentFrequency','semi-annually');
    params.put('terms',12);
    Test.startTest();
    try{
        
        crb.prepareCalculationPayments(params);
    }catch(Exception e){
        isException = true; 
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
}

/* @IsTest static void TestsmartcommDocCallout() {
    
    Boolean isException = false;
    CalculationRequestBodyWrapper crb = new CalculationRequestBodyWrapper();
    Map<String, Object> params = new Map<String, Object>();
    params.put('paymentFrequency','semi-annually');
    params.put('terms',12);
    Test.startTest();
    try{
        
        RESTCalloutHelper.smartcommDocCallout (params,true);
        //SmartCommHelper.saveDocument(params,response);
    }catch(Exception e){
        isException = true; 
    }
    Test.stopTest();
    System.assertEquals(false, isException);
    
    
}
@IsTest static void TestcalculationAPIRequestTestNegative1() {
        
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "payments","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":"a0p020000009E6I","financialProductId":"a0w02000000QbwH","assets": [{"productName":"Iphone","quantity": 3,"price": 74624.0,"residualValueAmount":"100","insuranceAmount":"100"}], "maintenance":[{"productName":"Maintenance","quantity":"1","price":"200"}],"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
    
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(400, 'Success', '{"id": "business_rule_violation", "message": "Insurance"}');
                                                                                    
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        Test.startTest();
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }
        catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);           
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    }
}

    @IsTest static void TestgetSDO() {
    
        List<Id> orderIds = new List<Id>(); 
    
    E_Sign_Information__c esignInfo = [
        SELECT  Id, Status__c
        FROM    E_Sign_Information__c
        WHERE   Signer_Name__c = 'Signer Name'  
    ];
        orderIds.add(esignInfo.id);
    Boolean isException = false;
        Test.startTest();
                try{
            RESTCalloutHelper.getSDO(orderIds);
        }
        catch(Exception e){
            isException = true;
        }
        Test.stopTest();
        System.assertEquals(false, isException);           
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        
    //}
}
//Adding methods to Cover Calculation API helper class Author @monika Valavala
@IsTest static void calculationAPIRequestTestPositive1() {
    Test.startTest();
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "finance-amount","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":"a0p020000009E6I","financialProductId":"a0w02000000QbwH","assets": [{"productName":"Iphone","quantity": 3,"price": 74624.0,"residualValueAmount":"100","insuranceAmount":"100"}], "maintenance":[{"productName":"Maintenance","quantity":"1","price":"200"}],"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
    
    system.runAs(user) {
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "finance-amount","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ], "paymentCalculation":{"rentalPayments":{"amount":1013.8,"principal":816.99,"interestAmount":196.81},"maintenance":{"amount":12000.0}},'+
                                                                                    +'"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"iPad Air Asset Hard"},"quantity":1,"salePrice":432.0,"residualValue":{"value":23.0,"id":"a1t8B00000000srQAA"},"insurances":[{"amount":12}],"financeCalculation":{"financeAmount":432.0,"futureValue":0.0},"consolidatedPayments":[{"amount":19.49}]}]}');           
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }
        catch(Exception e){
            isException = true;
        }
        
        System.assertEquals(false, isException);           
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        Test.stopTest();
    }
}
    @IsTest static void calculationAPIRequestTestWithOutAssetException1() {
    Test.startTest();
    User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
    Quote quote = [SELECT Id,Applicable_Offers__r.Offer__r.Program__c FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
    Boolean isException = false;
    String params = '{"calculate": "finance-amount","numberOfMonths": 24,"amount":1234,"paymentFrequency": "quarterly","paymentTiming": "in-advance","programId":\"'+quote.Applicable_Offers__r.Offer__r.Program__c+'\","financialProductId":"a0w02000000QbwH","assets":null,"isInsuranceApplicable":true, "isPurchaseOptionApplicable":true}';
        system.debug('params'+params);
    system.runAs(user) {
        //MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "payments","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ]}');
        
        
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', '{"1234",financeCalculation" : {"financeAmount" : 0.0,"futureValue":10.0,"rates" : {"nominalInterestRate" : 3.2}},"financeInput" : {"calculate" : "finance-amount","financeStructure":{"numberOfMonths":24,"numberOfPayments":24,"paymentFrequency":"monthly" },"maintenance" : [ { "id" : "External Maintenance","amount" : 43200.0 } ],"assets" : [{"salePrice" : 100.0,"quantity" : 10,"modelIdentifier" : {"modelName" : "MacBook Pro"},"residualValue" : {"id" : "ascmbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]},{"salePrice" : 300.0,"quantity" : 20,"modelIdentifier" : {"modelName" : "iPad Air Asset Hard"},"residualValue" : {"id" : "ascfdbbsdgkg325fdb56", "value" : 23.0},"insurances" : [{"amount" : 12 }]}]},"payments" : [{"insurances" : [{"amount" : 15 }]},{"maintenance" : [{"amount" : 15 }]}],"consolidatedPayments" : [ {"amount" : 100.0} ], "paymentCalculation":{"rentalPayments":{"amount":1013.8,"principal":816.99,"interestAmount":196.81},"maintenance":{"amount":12000.0}},'+
                                                                                    +'"assetCalculations":[{"modelIdentifier":{"typeName":"Asset Soft","modelName":"iPad Air Asset Hard"},"quantity":1,"salePrice":432.0,"residualValue":{"value":23.0,"id":"a1t8B00000000srQAA"},"insurances":[{"amount":12}],"financeCalculation":{"financeAmount":432.0,"futureValue":0.0},"consolidatedPayments":[{"amount":19.49}]}]}');           
        
        Test.setMock(HttpCalloutMock.class, mock);
        //RESTCalloutHelper.CalculationOutputWrapper responseStr;
        CalculationAPIHelper.CalculationOutputWrapper responseStr;
        
        try{
            responseStr = RESTCalloutHelper.sendCalloutToCalculationApi(params, true);
        }catch(Exception e){
            isException = true;
        }
        
        System.assertEquals(false, isException);
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
        Test.stopTest();
    }
}*/





}