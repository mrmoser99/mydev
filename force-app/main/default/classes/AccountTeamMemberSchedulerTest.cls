/**
 *  @description Test class used to test the batch jobs created for back filling account team members
 *  @author      Newton Sun, Traction on Demand.
 *  @date        2020-04-08
 **/


@IsTest
public class AccountTeamMemberSchedulerTest {
    public static final Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
    public static final Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    public static final Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();


    public static List<Opportunity> setupOpportunity(Integer amt, Id userId, List<Account> accIds, List<Account> endUserIds){
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for(Integer i = 0; i < amt; i++) {
            Opportunity opp = new Opportunity();
            if(accIds != null) opp.AccountId = accIds[i].Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.OwnerId = userId;
            if(endUserIds != null)opp.End_User__c = endUserIds[i].Id;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            oppsToInsert.add(opp);
        }
        return oppsToInsert;

    }

    public static User setupUser(String type){
        User v = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = : type].Id,
                LastName = 'last1',
                Email = 'puser001@amamama.com',
                Username = 'puser001@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance'
        );
        return v;
    }

    public static List<Account> setupAccount(Integer amt, Id recordType){
        List<Account> accToInsert = new List<Account>();
        for(Integer i = 0; i < amt; i++) {
            Account acc = new Account();
            acc.Name = 'test' + i;
            acc.Technology_Solutions__c = false;
            acc.CleanTech__c = false;
            acc.Commercial_Finance__c = false;
            acc.BillingStreet = '3321 LEGION RD';
            acc.BillingCity = 'HOPE MILLS5';
            acc.BillingPostalCode = '28348-1652';
            acc.BillingState = 'North Carolina2';
            acc.BillingCountry = 'US';
            acc.RecordTypeId = recordType;
            acc.Business_Unit__c = 'Commercial Finance';
            accToInsert.add(acc);
        }
        return accToInsert;
    }

    @IsTest
    public static void AccountTeamSanity() {
        Account acc = setupAccount(1,RecordTypeIdAccountProspect )[0];
        insert acc;
        List<AccountTeamMember> atmInitial = [SELECT UserId FROM AccountTeamMember];
        delete atmInitial;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atm = [SELECT UserId, AccountId FROM AccountTeamMember WHERE AccountId =: acc.Id];
        System.assertEquals(1, atm.size(), 'more than 1 team member was inserted');
        System.assertEquals(UserInfo.getUserId(), atm[0].UserId, 'The incorrect User was inserted');
    }

    @IsTest
    public static void AccountTeamMulitpleAccounts() {
        List<Account> accs = AccountTeamMemberSchedulerTest.setupAccount(10, RecordTypeIdAccountProspect);
        insert accs;
        List<AccountTeamMember> atmInitial = [SELECT UserId FROM AccountTeamMember];
        delete atmInitial;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atm = [SELECT UserId, AccountId, TeamMemberRole FROM AccountTeamMember];
        System.assertEquals(10, atm.size(), 'more than 1 team member was inserted');
        System.assertEquals(UserInfo.getUserId(), atm[0].UserId, 'The incorrect User was inserted');
        System.assertEquals('Sales Rep - Commercial Finance', atm[0].TeamMemberRole, 'The team member role was not inserted properly');
    }

    @IsTest
    public static void AccountTeamMemberAccountsOutofScopeDate() {
        List<Account> accToInsert = AccountTeamMemberSchedulerTest.setupAccount(10, RecordTypeIdAccountProspect);
        insert accToInsert;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(accToInsert[3].Id, threeYears);
        Test.setCreatedDate(accToInsert[4].Id, twoYears);
        List<AccountTeamMember> atmInitial = [SELECT UserId FROM AccountTeamMember];
        delete atmInitial;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atm = [SELECT UserId, AccountId, TeamMemberRole FROM AccountTeamMember];
        System.assertEquals(9, atm.size(), 'more than 1 team member was inserted');
        System.assertEquals(UserInfo.getUserId(), atm[0].UserId, 'The incorrect User was inserted');
        System.assertEquals('Sales Rep - Commercial Finance', atm[0].TeamMemberRole, 'The team member role was not inserted properly');
    }

    @IsTest
    public static void AccountTeamMemberAccountsOutofScopeCreatedBy() {
        User u = AccountTeamMemberSchedulerTest.setupUser('API Integration');
        System.runAs(u){
            List<Account> accToInsert = AccountTeamMemberSchedulerTest.setupAccount(10,RecordTypeIdAccountProspect);
            insert accToInsert;
        }

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atm = [SELECT UserId, AccountId, TeamMemberRole FROM AccountTeamMember];
        System.assertEquals(0, atm.size(), 'more than 1 team member was inserted');
    }

    @IsTest
    public static void AccountTeamMemberAccountsAllCases() {
        List<Account> accToInsertByUser = AccountTeamMemberSchedulerTest.setupAccount(10, RecordTypeIdAccountProspect);
        insert accToInsertByUser;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(accToInsertByUser[2].Id, threeYears);
        Test.setCreatedDate(accToInsertByUser[3].Id, twoYears);
        List<AccountTeamMember> atmInitial = [SELECT UserId, AccountId FROM AccountTeamMember];
        for(AccountTeamMember atm : atmInitial){
            if(atm.AccountId == accToInsertByUser[2].Id || atm.AccountId == accToInsertByUser[3].Id){
                delete atm;
            }
        }
        //delete atmInitial[9];
        User u = AccountTeamMemberSchedulerTest.setupUser('API Integration');
        System.runAs(u){
            List<Account> accToInsertByIntegration = AccountTeamMemberSchedulerTest.setupAccount(10,RecordTypeIdAccountProspect);
            insert accToInsertByIntegration;
        }

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atm = [SELECT UserId, AccountId, TeamMemberRole FROM AccountTeamMember];
        System.assertEquals(9, atm.size(), 'more than 1 team member was inserted');
    }

    /*@IsTest
     * Commented as per this task #368892
    public static void AccountTeamMemberOpportunitySanity() {
        List<Account> accsVendor = AccountTeamMemberSchedulerTest.setupAccount(2,RecordTypeIdAccountVendor );
        List<Account> accsEndUser = AccountTeamMemberSchedulerTest.setupAccount(2, RecordTypeIdAccountEndUser);
        insert accsVendor;
        insert accsEndUser;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, accsVendor, accsEndUser );
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(4, atmResults.size() , 'The team members were not added properly');
    }
	
    @IsTest
    public static void AccountTeamMemberOpportunityOnlyVendor() {
        List<Account> accsVendor = AccountTeamMemberSchedulerTest.setupAccount(2,RecordTypeIdAccountVendor );
        insert accsVendor;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, accsVendor, null);
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(2, atmResults.size() , 'The team members were not added properly');
    }
    
    @IsTest
    public static void AccountTeamMemberOpportunityOnlyEndUser() {
        List<Account> accsEndUser = AccountTeamMemberSchedulerTest.setupAccount(2, RecordTypeIdAccountEndUser);
        insert accsEndUser;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, null, accsEndUser);
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(2, atmResults.size() , 'The team members were not added properly');
    }

    @IsTest
    public static void AccountTeamMemberOpportunityNoAccounts() {
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, null, null);
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(0, atmResults.size() , 'The team members were not added properly');
    }

    @IsTest
    public static void AccountTeamMemberOpportunitySameAccounts() {
        List<Account> accsEndUser = AccountTeamMemberSchedulerTest.setupAccount(2, RecordTypeIdAccountEndUser);
        insert accsEndUser;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, accsEndUser, accsEndUser);
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm;

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(2, atmResults.size() , 'The team members were not added properly');
    }

    @IsTest
    public static void AccountTeamMemberOpportunityExistingATMFull() {
        List<Account> accsVendor = AccountTeamMemberSchedulerTest.setupAccount(2,RecordTypeIdAccountVendor );
        List<Account> accsEndUser = AccountTeamMemberSchedulerTest.setupAccount(2, RecordTypeIdAccountEndUser);
        insert accsVendor;
        insert accsEndUser;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, accsVendor, accsEndUser );
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(4, atmResults.size() , 'The team members were not added properly');
    }

    @IsTest
    public static void AccountTeamMemberOpportunityExistingATMPartial() {
        List<Account> accsVendor = AccountTeamMemberSchedulerTest.setupAccount(2,RecordTypeIdAccountVendor );
        List<Account> accsEndUser = AccountTeamMemberSchedulerTest.setupAccount(2, RecordTypeIdAccountEndUser);
        insert accsVendor;
        insert accsEndUser;
        User u = AccountTeamMemberSchedulerTest.setupUser('System Administrator');
        insert u;
        List<Opportunity> opps = AccountTeamMemberSchedulerTest.setupOpportunity(2, u.Id, accsVendor, accsEndUser );
        insert opps;
        Datetime threeYears = Datetime.now().addYears(-3);
        Datetime twoYears = Datetime.now().addYears(-2);
        Test.setCreatedDate(opps[1].Id, threeYears);
        Test.setCreatedDate(opps[0].Id, twoYears);
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember];
        delete atm[0];
        delete atm[2];

        AccountTeamMemberScheduler scheduler = new AccountTeamMemberScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
        
        List<AccountTeamMember> atmResults = [SELECT UserId, AccountId FROM AccountTeamMember];
        System.assertEquals(4, atmResults.size() , 'The team members were not added properly');
    }
	*/
}