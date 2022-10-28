@IsTest
public class AccounttriggerTest {
    public static testMethod void test_M1() {
        test.StartTest();
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.CleanTech__c=false;
        acc.Commercial_Finance__c=false;
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';   
        insert acc;         
       
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Digital Imaging'].Id;
        u.LastName = 'last';
        u.Email = 'puser000@amamama.com';
        u.Username = 'puser000@amamama.com' + System.currentTimeMillis();
        u.CompanyName = 'TEST';
        u.Title = 'title';
        u.Alias = 'alias';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.Business_Unit__c = 'Digital Imaging';
        u.Legal_Entity_Description__c = 'DLL';
        insert u;
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Digital Imaging'].Id;
        u2.LastName = 'last';
        u2.Email = 'puser000@amamama.com';
        u2.Username = 'puser000@amamama.com' + System.currentTimeMillis();
        u2.CompanyName = 'TEST';
        u2.Title = 'title';
        u2.Alias = 'alias';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        u2.LocaleSidKey = 'en_US';
        u2.Business_Unit__c = 'Digital Imaging';
        u2.Legal_Entity_Description__c = 'DLL';
        insert u2;
        
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = acc.Id;
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'None';
        atm.ContactAccessLevel = 'None';
        atm.OpportunityAccessLevel = 'None';
        atm.UserId = u.Id;
        insert atm;

        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.AccountId = acc.Id;
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'None';
        atm2.ContactAccessLevel = 'None';
        atm2.OpportunityAccessLevel = 'None';
        atm2.UserId = u2.Id;
        insert atm2;
        
        acc.Remove_Account_Team__c = atm2.Id;
        update acc;
        
        List<AccountTeamMember> atmList = [SELECT Id, AccountId, UserId FROM AccountTeamMember];
        System.assertEquals(2, atmList.size());
        }

    public static testMethod void mergeTest(){

        Account masterAcc =new Account();
        masterAcc.Name='test';
        masterAcc.Technology_Solutions__c=false;
        masterAcc.CleanTech__c=false;
        masterAcc.Commercial_Finance__c=false;
        masterAcc.BillingStreet = '3321 LEGION RD';
        masterAcc.BillingCity = 'HOPE MILLS5';
        masterAcc.BillingPostalCode = '28348-1652';
        masterAcc.BillingState = 'North Carolina2';
        masterAcc.BillingCountry = 'US';
        masterAcc.ATS_ID_s__c='1234567890';
        insert masterAcc;
        Account mergeAcc =new Account();
        mergeAcc.Name='test2';
        mergeAcc.Technology_Solutions__c=false;
        mergeAcc.CleanTech__c=false;
        mergeAcc.Commercial_Finance__c=false;
        mergeAcc.BillingStreet = '3321 LEGION RD';
        mergeAcc.BillingCity = 'HOPE MILLS5';
        mergeAcc.BillingPostalCode = '28348-1652';
        mergeAcc.BillingState = 'North Carolina2';
        mergeAcc.BillingCountry = 'US';
        mergeAcc.ATS_ID_s__c='1234567899';
        insert mergeAcc;
        Test.startTest();
        try{
            merge masterAcc mergeAcc;
        } catch(DmlException e){
            System.debug('An unexpected error has occured: ' + e.getMessage());
        }

        Test.stopTest();
        List<Account> master = [SELECT ATS_ID_s__c FROM Account];
        System.assertEquals (master.size(), 1, 'The account was not merged properly');
        System.assertEquals ('1234567899;1234567890', master[0].ATS_ID_s__c, 'The account was not merged properly');
    }

    public static testMethod void mergeTestWithDuplicates(){

        Account masterAcc =new Account();
        masterAcc.Name='test';
        masterAcc.Technology_Solutions__c=false;
        masterAcc.CleanTech__c=false;
        masterAcc.Commercial_Finance__c=false;
        masterAcc.BillingStreet = '3321 LEGION RD';
        masterAcc.BillingCity = 'HOPE MILLS5';
        masterAcc.BillingPostalCode = '28348-1652';
        masterAcc.BillingState = 'North Carolina2';
        masterAcc.BillingCountry = 'US';
        masterAcc.ATS_ID_s__c='1234567890;1234567899';
        insert masterAcc;
        Account mergeAcc =new Account();
        mergeAcc.Name='test2';
        mergeAcc.Technology_Solutions__c=false;
        mergeAcc.CleanTech__c=false;
        mergeAcc.Commercial_Finance__c=false;
        mergeAcc.BillingStreet = '3321 LEGION RD';
        mergeAcc.BillingCity = 'HOPE MILLS5';
        mergeAcc.BillingPostalCode = '28348-1652';
        mergeAcc.BillingState = 'North Carolina2';
        mergeAcc.BillingCountry = 'US';
        mergeAcc.ATS_ID_s__c='1234567899;1234567898';
        insert mergeAcc;
        Test.startTest();
        try{
            merge masterAcc mergeAcc;
        } catch(DmlException e){
            System.debug('An unexpected error has occured: ' + e.getMessage());
        }

        Test.stopTest();
        List<Account> master = [SELECT ATS_ID_s__c FROM Account];
        System.assertEquals (master.size(), 1, 'The account was not merged properly');
        System.assertEquals ('1234567898;1234567890;1234567899', master[0].ATS_ID_s__c, 'The account was not merged properly');
    }

    public static testMethod void mergeTestCharacterLimit(){

        Account masterAcc =new Account();
        masterAcc.Name='test';
        masterAcc.Technology_Solutions__c=false;
        masterAcc.CleanTech__c=false;
        masterAcc.Commercial_Finance__c=false;
        masterAcc.BillingStreet = '3321 LEGION RD';
        masterAcc.BillingCity = 'HOPE MILLS5';
        masterAcc.BillingPostalCode = '28348-1652';
        masterAcc.BillingState = 'North Carolina2';
        masterAcc.BillingCountry = 'US';
        masterAcc.ATS_ID_s__c='123456.7893;123456.7894;123456.7895;123456.7896;123456.7897;123456.7898;123456.7899';
        insert masterAcc;
        Account mergeAcc =new Account();
        mergeAcc.Name='test2';
        mergeAcc.Technology_Solutions__c=false;
        mergeAcc.CleanTech__c=false;
        mergeAcc.Commercial_Finance__c=false;
        mergeAcc.BillingStreet = '3321 LEGION RD';
        mergeAcc.BillingCity = 'HOPE MILLS5';
        mergeAcc.BillingPostalCode = '28348-1652';
        mergeAcc.BillingState = 'North Carolina2';
        mergeAcc.BillingCountry = 'US';
        mergeAcc.ATS_ID_s__c='123456.7860;123456.7880;123456.7881;123456.7882;123456.7883;123456.7884;123456.7885;123456.7886;123456.7887;123456.7888;123456.7889;123456.7890;123456.7891;123456.7892;123456.7833';
        insert mergeAcc;
        Test.startTest();
        try{
            merge masterAcc mergeAcc;
        } catch(DmlException e){
            System.debug('An unexpected error has occured: ' + e.getMessage());
        }

        Test.stopTest();
        List<Account> master = [SELECT ATS_ID_s__c FROM Account];
        System.assertEquals (master.size(), 1, 'The account was not merged properly');
        System.assertEquals ('123456.7892;123456.7891;123456.7890;123456.7889;123456.7888;123456.7887;123456.7886;123456.7885;123456.7884;123456.7883;123456.7882;123456.7881;123456.7880;123456.7860;123456.7893;123456.7894;123456.7895;123456.7896;123456.7897;123456.7898;123456.7899', master[0].ATS_ID_s__c, 'The account was not merged properly');
    }



    public static testMethod void mergeTestWithoutEntity(){

        Account masterAcc =new Account();
        masterAcc.Name='test';
        masterAcc.Technology_Solutions__c=false;
        masterAcc.CleanTech__c=false;
        masterAcc.Commercial_Finance__c=false;
        masterAcc.BillingStreet = '3321 LEGION RD';
        masterAcc.BillingCity = 'HOPE MILLS5';
        masterAcc.BillingPostalCode = '28348-1652';
        masterAcc.BillingState = 'North Carolina2';
        masterAcc.BillingCountry = 'US';
        masterAcc.ATS_ID_s__c='1234567890;1234567899';
        insert masterAcc;
        Account mergeAcc =new Account();
        mergeAcc.Name='test2';
        mergeAcc.Technology_Solutions__c=false;
        mergeAcc.CleanTech__c=false;
        mergeAcc.Commercial_Finance__c=false;
        mergeAcc.BillingStreet = '3321 LEGION RD';
        mergeAcc.BillingCity = 'HOPE MILLS5';
        mergeAcc.BillingPostalCode = '28348-1652';
        mergeAcc.BillingState = 'North Carolina2';
        mergeAcc.BillingCountry = 'US';
        insert mergeAcc;
        Test.startTest();
        try{
            merge masterAcc mergeAcc;
        } catch(DmlException e){
            System.debug('An unexpected error has occured: ' + e.getMessage());
        }

        Test.stopTest();
        List<Account> master = [SELECT ATS_ID_s__c FROM Account];
        System.assertEquals (master.size(), 1, 'The account was not merged properly');
        System.assertEquals ('1234567890;1234567899', master[0].ATS_ID_s__c, 'The account was not merged properly');
    }

    //3-20-2020: New test cases for adding the user to a new prospect account
    public static testMethod void prospectAccountCreationTest() {
        List<RecordType> types1=[SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND Name='Prospect'];
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c ='123456';
        acc.BillingCountry = 'Test';
        acc.BillingCity = 'San Francisco';
        acc.Phone = 'Wrong';
        acc.BillingState = 'CA';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode='96543';
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId=types1[0].Id;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance',
                Legal_Entity_Description__c = 'DLL'
            
        );
        insert u;
        System.runAs(u) {
            Test.startTest();
            insert acc;
            Test.stopTest();
            AccountTeamMember atm = [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :acc.Id];
            System.assertEquals('Sales Rep - Commercial Finance', atm.TeamMemberRole, 'The team member\'s role was not added properly');
            System.assertEquals(UserInfo.getUserId(), atm.UserId, 'The incorrect user was added to the account team members');
        }
    }

    public static testMethod void prospectAccountCreationTestBatch() {
        List<RecordType> types1=[SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND Name='Prospect'];
        List<Account> accsToInsert = new List<Account>();
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c ='123456';
        acc.BillingCountry = 'Test';
        acc.BillingCity = 'San Francisco';
        acc.Phone = 'Wrong';
        acc.BillingState = 'CA';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode='96543';
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId=types1[0].Id;
        accsToInsert.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Test2';
        //acc.UNQ_Customer__c ='123456';
        acc2.BillingCountry = 'Test';
        acc2.BillingCity = 'San Francisco';
        acc2.Phone = 'Wrong';
        acc2.BillingState = 'CA';
        acc2.BillingStreet = 'Test Street';
        acc2.BillingPostalCode='96543';
        acc2.Business_Unit__c = 'Technology';
        acc2.RecordTypeId=types1[0].Id;
        accsToInsert.add(acc2);
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance',
                Legal_Entity_Description__c = 'DLL'
        );
        insert u;
        System.runAs(u) {
            Test.startTest();
            insert accsToInsert;
            Test.stopTest();
            AccountTeamMember atm1 = [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :acc.Id];
            AccountTeamMember atm2 = [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :acc2.Id];
            System.assertEquals('Sales Rep - Commercial Finance', atm1.TeamMemberRole, 'The team member\'s role was not added properly');
            System.assertEquals(UserInfo.getUserId(), atm1.UserId, 'The incorrect user was added to the account team members');
            System.assertEquals('Sales Rep - Technology', atm2.TeamMemberRole, 'The team member\'s role was not added properly');
            System.assertEquals(UserInfo.getUserId(), atm2.UserId, 'The incorrect user was added to the account team members');
        }
    }
 }