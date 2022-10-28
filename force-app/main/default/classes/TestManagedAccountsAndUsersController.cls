/*****************************************************************************************
Name: TestManagedAccountsAndUsersController
===============================================================================================
Purpose: test class for ManagedAccountsAndUsersController (US-672464).
================================================================================================
================================================================================================
History
------- 
VERSION        AUTHOR                  DATE              
******************************************************************************************/

@IsTest
public with sharing class TestManagedAccountsAndUsersController {
    @TestSetup
    static void makeData(){
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = :Constants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];

        UserRole userRole = new UserRole(DeveloperName = 'UserRole', Name = 'User Role');
        insert userRole;

        User adminUser = new User(
            Alias = 'admin', 
            Email='sysadmin@salesforce.com', 
            FirstName='FirstName', 
            EmailEncodingKey='UTF-8', 
            LastName='LastNAme', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = adminProfile.Id, 
            UserRoleId = userRole.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            Username = 'testsysadmin@salesforce.com', 
            Legal_Entity_Description__c = 'DLL');   
        insert adminUser;

        // This code runs as the system admin
        system.runAs(adminUser) {
            TestAccountBuilder accountBuilder = new TestAccountBuilder();
            Account vendorAccount = accountBuilder
                .withRecordType(Constants.VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Test Vendor Account')
                .build(); 
                
            Account customerAccount = accountBuilder
                .withRecordType(Constants.END_USER_RECORD_TYPE_NAME)
                .withName('Test Customer Account')
                .build();     

            insert new List<Account>{vendorAccount, customerAccount}; 

            Contact partnerContact = new Contact(
                LastName = 'Partner Contact', 
                AccountId = vendorAccount.Id 
            );
            insert partnerContact; 

            Profile internalMemberProfile = [SELECT Id FROM Profile WHERE Name = :Constants.NORDICS_INTERNAL_DLL_MEMBER LIMIT 1];
            Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = :Constants.NORDICS_PROFILE_NAME LIMIT 1];
            UserRole partnerUserRole = [SELECT Id, Name FROM UserRole WHERE Name LIKE '%Partner User' LIMIT 1];
        
            User portalUser = new User(
                Alias = 'prtnr', 
                Email = 'test.email@test.com',
                FirstName = 'User',
                EmailEncodingKey = 'UTF-8',
                LastName = 'PartnerCommunity', 
                LanguageLocaleKey = 'en_US', 
                isActive = true,
                LocaleSidKey = 'en_US', 
                ProfileId = partnerProfile.Id, 
                ContactId = partnerContact.id, 
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'PartnerCommunityTestUser123@test.com'
                //,UserRoleId = partnerUserRole.Id
            ); 
            
            User internalUser = new User(
                Alias = 'intrnl', 
                Email = 'internal.test.email@test.com',
                FirstName = 'User',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Internal', 
                LanguageLocaleKey = 'en_US', 
                isActive = true,
                LocaleSidKey = 'en_US', 
                ProfileId = internalMemberProfile.Id, 
                TimeZoneSidKey='America/Los_Angeles',
                Username = 'InternalMemberTestUser123@test.com'
            );

            insert new List<User>{portalUser, internalUser};
            
            AccountTeamMember accountTeamMember = new AccountTeamMember(
                UserId = internalUser.Id, 
                AccountId = vendorAccount.Id, 
                TeamMemberRole = 'Account Manager'
            );
            insert accountTeamMember;
        }   
    }

    @IsTest
    static void testGetSObjectList() {
        User internalUser = [SELECT Id FROM User WHERE Alias = 'intrnl' LIMIT 1];
        Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Test Vendor Account' LIMIT 1];
        User partnerUser = [SELECT Id FROM User WHERE Alias = 'prtnr' LIMIT 1];

        System.runAs(internalUser) {
            List<String> accountInfoResult = ManagedAccountsAndUsersController.getSObjectList(new List<Id>{internalUser.Id});
            List<AccountTeamMember> parsedAccountInfoResult = (List<AccountTeamMember>) JSON.deserialize(accountInfoResult[0], List<AccountTeamMember>.class);
            System.assertEquals(vendorAccount.Id, parsedAccountInfoResult[0].AccountId);

            List<String> userInfoResult = ManagedAccountsAndUsersController.getSObjectList(new List<Id>{vendorAccount.Id});
            List<User> parsedUserInfoResult = (List<User>) JSON.deserialize(userInfoResult[0], List<User>.class);
            System.assertEquals(partnerUser.Id, parsedUserInfoResult[0].Id);  
        }
    }

}