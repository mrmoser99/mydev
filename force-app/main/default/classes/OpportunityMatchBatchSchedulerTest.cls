@isTest
public class OpportunityMatchBatchSchedulerTest {
    

    @isTest
    public static void OpportunityMatchUpdatesTest(){
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
 

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.End_User__c = acc.Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        insert opp;

        Opportunity match = new Opportunity();
        match.Name = opp.Name;
        match.End_User__c = acc.Id;
        match.StageName = 'On Hold';
        opp.Type ='New';
        match.Existing_Match__c = opp.Id;
        match.Sales_Rep_ID__c = 'DIFF';
        match.Amount = 1;
        match.UNQ_Opportunity__c = 'DIFFAPPNUM';
        match.Application_Date__c = Date.today().addMonths(1);
        insert match;

        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opp.Id);
        oppIds.add(match.Id);

        OpportunityMatchBatchScheduler scheduler = new OpportunityMatchBatchScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<Opportunity> updatedOpps = [SELECT Id, Sales_Rep_ID__c FROM Opportunity WHERE Id IN: oppIds];

        System.assertEquals(1, updatedOpps.size());
        System.assertEquals(match.Sales_Rep_ID__c, updatedOpps[0].Sales_Rep_ID__c);
    }

}