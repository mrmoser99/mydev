/**
 * This class is used for testing OpportunityGraphController class
 * 
 * @author Elena Sokolova @date 2020-01-15
 */
@isTest
public class OpportunityGraphControllerTest {
    @testSetup
    private static void setupTestData() {

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
            Username = 'testsysadmin39566@salesforce.com', 
            Legal_Entity_Description__c = 'DLL');   
        insert adminUser;

        System.runAs(adminUser) {
            Account account = new Account(Name = 'Test Account');
            Program__c program = new Program__c(Name = 'Test Program', CurrencyIsoCode = 'USD');
            Financial_Product__c financialProduct = new Financial_Product__c(Name = 'Test Financial Product', Type__c = 'Core');
            insert new List<SObject>{account, program, financialProduct};
            
            Offer__c offer          = new Offer__c(
                Name                = 'Test Offer',
                Program__c          = program.Id,
                Offer_Type__c       = 'Standard',
                CurrencyIsoCode     = 'USD',
                Core_Financial_Product__c	= financialProduct.Id
            );
            insert offer;

            Applicable_Offer__c applicableOffer = new Applicable_Offer__c (
                Account__c          = account.Id,
                CurrencyIsoCode     = 'USD',
                Offer__c            = offer.Id
            );
            insert applicableOffer;

            account.PartnerOffer__c = applicableOffer.Id;
            update account; 

            Id profileId = [SELECT Id FROM Profile WHERE Name LIKE 'Nordics Community Profile'].Id;
            Contact contact = new Contact(LastName ='TestContact', AccountId = account.Id);
            insert contact;
                  
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

    @isTest static void getReportApiNameTest() {
        User user = [SELECT Id FROM User WHERE LastName LIKE 'TestPartherUser'];
        system.runAs(user) {
            OpportunityGraphController graphCtr = new OpportunityGraphController();
            String reportName                   = graphCtr.getReportApiName();
            System.assertEquals('Opportunity_Amount_By_Stage_USD', reportName);
        }
    }
}