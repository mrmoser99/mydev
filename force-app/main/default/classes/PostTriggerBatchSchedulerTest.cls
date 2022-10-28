/**
 * Created by samuelmeyers on 1/2/19.
 */
@isTest
public class PostTriggerBatchSchedulerTest {

    @isTest
    public static void SetAccountFlagsTest(){
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.CleanTech__c=false;
        acc.Commercial_Finance__c=false;
        acc.CT_and_I__c=false;
        acc.Healthcare__c=false;
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';
        insert acc;

        Account_Business_Unit_Mapping__c abumTechSolution = new Account_Business_Unit_Mapping__c(
                Account__c = acc.Id,
                Technology_Solutions__c = true,
            	Legal_Entity_Description__c = 'Test Legal Desc'
        );

        Account_Business_Unit_Mapping__c abumCleanTech = new Account_Business_Unit_Mapping__c(
                Account__c = acc.Id,
                CleanTech__c = true
        );

        insert new List<Account_Business_Unit_Mapping__c>{abumTechSolution, abumCleanTech};

        PostTriggerBatchScheduler scheduler = new PostTriggerBatchScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        acc = [SELECT Technology_Solutions__c, CleanTech__c, Commercial_Finance__c,Legal_Entity_Description__c FROM Account WHERE Id =: acc.Id LIMIT 1];
        List<Account_Business_Unit_Mapping__c> abums = [SELECT Id FROM Account_Business_Unit_Mapping__c];

        System.assertEquals(0, abums.size());
        System.assertEquals(true, acc.Technology_Solutions__c);
        System.assertEquals(true, acc.CleanTech__c);
        System.assertEquals(false, acc.Commercial_Finance__c);
        System.assertEquals('Test Legal Desc', acc.Legal_Entity_Description__c);
    }

    @isTest
    public static void SetAccountFlagsTest2(){
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.CleanTech__c=false;
        acc.Commercial_Finance__c=false;
        acc.CT_and_I__c=false;
        acc.Healthcare__c=false;
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';
        insert acc;

        Account_Business_Unit_Mapping__c abumComFi = new Account_Business_Unit_Mapping__c(
                Account__c = acc.Id,
                Commercial_Finance__c = true
        );

        Account_Business_Unit_Mapping__c abumCTI = new Account_Business_Unit_Mapping__c(
                Account__c = acc.Id,
                CT_and_I__c = true
        );

        Account_Business_Unit_Mapping__c abumHealth = new Account_Business_Unit_Mapping__c(
                Account__c = acc.Id,
                Healthcare__c = true
        );

        insert new List<Account_Business_Unit_Mapping__c>{abumComFi, abumCTI, abumHealth};

        PostTriggerBatchScheduler scheduler = new PostTriggerBatchScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        acc = [SELECT Technology_Solutions__c, Commercial_Finance__c, CT_and_I__c, Healthcare__c FROM Account WHERE Id =: acc.Id LIMIT 1];
        List<Account_Business_Unit_Mapping__c> abums = [SELECT Id FROM Account_Business_Unit_Mapping__c];

        System.assertEquals(0, abums.size());
        System.assertEquals(false, acc.Technology_Solutions__c);
        System.assertEquals(true, acc.CT_and_I__c);
        System.assertEquals(true, acc.Commercial_Finance__c);
        System.assertEquals(true, acc.Healthcare__c);
    }
}