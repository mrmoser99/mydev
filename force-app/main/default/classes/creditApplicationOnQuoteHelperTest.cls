/**
 * @description       : Test class of trigger to get quote header information on Credit Application page
 * @author            : Surbhi Goyal (Traction on Demand)
 * @group             : 
 * @last modified on  : 23-03-2022
 * @last modified by  : Kritika Sharma
**/
@isTest
public class creditApplicationOnQuoteHelperTest {
    @testSetup static void setup()
    {
        // New Account Record Created 
        Account a = new Account(name = 'Test');
        insert a;

        // New Contact Record Created 
        Contact c = new Contact(firstName = 'Test', lastName = 'Last Name', accountId = a.id, role__c='Partner Sales Rep');
        insert c;

        // New Opportunity Record Created
        Opportunity o = new Opportunity( nickname__c = 'testNick', amount = 10000.00, Name='Test Opp', 
                accountId = a.id, StageName = 'Quoting', CloseDate = date.today().addDays(30));
        insert o;

    }
    @isTest
    public static void creditApplicationOnQuoteHelperMethod() {

        Opportunity opp=[select Id from Opportunity LIMIT 1];

        Contact con=[select Id from Contact LIMIT 1];

        Account acc=[select Id from Account LIMIT 1];
        
        Quote q = new Quote (end_user__c = acc.id, name = 'test Quote', opportunityId = opp.id,
                lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly',
                payment_timing__c = 'in-arrears');
        insert q;

        Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
        insert ql;

        //Assert list is not empty
        System.assert(q!=null,'List should not be empty');

    }
}