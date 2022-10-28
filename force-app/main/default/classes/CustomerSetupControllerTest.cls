/**
 * Test class for CustomerSetupController apex class 
 * 
 * Version 1.0
 * 
 */
@IsTest
public class CustomerSetupControllerTest {
    private static final String RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME = System.Label.Retail;
    private static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.Vendor;

    @testSetup static void setupTestData() {

        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];

        UserRole userRole = new UserRole(DeveloperName = 'UserRole', Name = 'User Role');
        insert userRole;

        User adminUser = new User(
            Alias = 'alias', 
            Email='sysadmin@salesforce.com', 
            FirstName='FirstName', 
            EmailEncodingKey='UTF-8', 
            LastName='LastNAme', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = adminProfile.Id, 
            userroleid = userRole.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            Username = 'testsysadmin547946@salesforce.com', 
            Legal_Entity_Description__c = 'DLL');   
        insert adminUser;

        System.runAs(adminUser) {
            TestRegionBuilder regionBuilder = new TestRegionBuilder();
            Region__c testRegion = regionBuilder
                .withName('Sweden')
                .withIsoCode('SE') 
                .insertRecord(true)
                .build();

            Program__c testProgram = new Program__c(Name = 'Test Program', Region__c = testRegion.Id); 
            Financial_Product__c financialProduct = new Financial_Product__c(Name = 'Test Financial Product', Type__c = 'Core');
            insert new List<SObject>{testProgram, financialProduct};

            TestOfferBuilder offerBuilder = new TestOfferBuilder();
            Offer__c testOffer = offerBuilder
                .withName('Test Offer')
                .withProgram(testProgram.Id)
                .withcoreFinancialProduct(financialProduct.Id)
                .build();

            TestAccountBuilder accountBuilder = new TestAccountBuilder();
            Account account = accountBuilder
                .withRecordType(VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Account')
                .withRegion(testRegion.Id)
                .build();  

            insert new List<SObject>{testOffer, account};  

            TestApplicableOfferBuilder appOfferBuilder = new TestApplicableOfferBuilder();
            Applicable_Offer__c appOffer = appOfferBuilder
                .withName('Test Applicable Offer')
                .withAccount(account.Id)
                .withOffer(testOffer.Id)
                .build();    
                
            TestOpportunityBuilder oppBuilder = new TestOpportunityBuilder();
            Opportunity opportunity = oppBuilder
                .withRecordType(RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Opportunity')
                .withAccount(account.Id)
                .build(); 

            insert new List<SObject>{appOffer, opportunity};      

            TestQuoteBuilder quoteBuilder = new TestQuoteBuilder();
            Quote quote = quoteBuilder
                .withName('Test Quote')
                .withStatus('Calculation')
                .withOpportunity(opportunity.Id)
                .withApplicableOffer(appOffer.Id)
                .insertRecord(true)
                .build();
        }
    }

    @IsTest static void saveAndReturnAccountInfoTest() {
        Quote quote = [SELECT Id FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
        String customerInfo = '{"phoneNumbers":[{"type":"business","phoneNumber":"0520-32 70 21","areaCode":""}],"name":"Nya Scintillentia AB","legalEntity":null,"address":{"street":"Tranåsvägen 17 A Lgh 1607","postalCode":"45231","city":"Strömstad"}}';
        String customerExtId = '559810-0534';

        Test.startTest();
        String customerId = CustomerSetupController.saveAccountAndUpdateDeal(customerInfo, customerExtId, quote.Id);
        String customerId2 = CustomerSetupController.saveAccountAndUpdateDeal(customerInfo, customerExtId, quote.Id);
        String selectedCustomerInfo = CustomerSetupController.getCustomerScreenInfo(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, customerId);
        System.assertEquals(customerId, customerId2);
        System.assertEquals(
            customerId, 
            [SELECT End_User__c FROM Opportunity WHERE Id IN (SELECT OpportunityId FROM Quote WHERE Id = :quote.Id)].End_User__c
        ); 

        Opportunity opp = (Opportunity) JSON.deserialize(selectedCustomerInfo, Opportunity.class);
        System.assertEquals('Nya Scintillentia AB', opp.End_User__r.Name); 
        System.assertNotEquals(null, opp.End_User__r.Name); 
    }

    @IsTest static void updateQuoteStatusTest() {
        Quote quote = [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1];
        String qouteStatusBeforeUpdate = quote.Status;

        Test.startTest();
        CustomerSetupController.updateQuoteStatus(quote.Id, 'Assessment');
        Test.stopTest();

        System.assertNotEquals(qouteStatusBeforeUpdate, [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1].Status);
        System.assertEquals('Assessment', [SELECT Id, Status FROM Quote WHERE Name LIKE 'Test Quote' LIMIT 1].Status);
    }

}