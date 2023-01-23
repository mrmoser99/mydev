/**
 * @description       : Apex Test class of ddContentFooterController.
 * @author            : Vinicio Ramos
 * @group             : DLL On demand
 * @last modified on  : 12/15/2022
 * @Changes Log        :
 * Date       - BUG/PBI    - Author           - Description
 * 12/15/2022 - PBI 779222 - Vinicio Ramos    - As a portal user I need to know how I can contact DLL for support.

**/
@IsTest
public class ddContentFooterControllerTest {
    
    @testSetup static void setup() {
        
        User systemAdmin = createUser('System Administrator');
        
        System.runAs(systemAdmin) {
            Account at =new Account();
            at.Name='Portal Account';
            at.RecordTypeId=Schema.SObjectType.account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
            insert at;
            
            contact ct =new contact();
            ct.LastName='Portal Contact';
            ct.AccountId=at.id;
            ct.Business_Unit__c = 'Other';
            insert ct;
            
            User partnerUser = createPartnerUser(ct.id,ct.LastName);
        }
    }
    
    @isTest static void method_M1() {
        
        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];
        
        Test.startTest();
        System.runAs(partnerUser) {
            ddContentFooterController.getContactList(partnerUser.Id);
        }
        Test.stopTest();
    }
    
    private static user createPartnerUser(ID cId, String Name){
        Profile p = [SELECT Id,Name from Profile where Name = 'Partner Admin' LIMIT 1];
        
        user u = New User(
            UserName = 'test_' + math.random() + '@test.com',
            FirstName = 'Test-First',
            LastName = Name,
            Alias = 'test',
            email = 'test' + math.random() + '@test.com',
            CommunityNickName = string.valueOf(math.random()).substring(0,6),
            ProfileID = p.id,
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US',
            Business_Unit__c = 'Other',
            Legal_Entity_Description__c = 'DLL',
            ContactID = cId
        );
        
        insert u;
        
        return u;
    }
    
    private static User createUser(String profileName) {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name =: profileName];
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User u = new User(  FirstName = 'user_first_name',
                          LastName = 'user_last_name',
                          Email = uniqueName + '@test' + orgId + '.org',
                          Username = uniqueName + '@test' + orgId + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueName.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          Legal_Entity_Description__c = 'DLL',
                          UserRoleId = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'PPT_Administrator_Lead' LIMIT 1].Id,
                          ProfileId = p.Id);
        return u;
    }
}