/*
* CustomerInstallAddressesTest: The test class.
* 2022-07-19: Created
*/
@IsTest
public with sharing class CustomerInstallAddressesTest {

    @testSetup static void setup() {

        Account at =new Account();
        at.Name='Service';
        insert at;

        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='hans.vedo@dllgroup.com';
        insert ct;

        Opportunity opp1= new Opportunity();
        opp1.application_number__c='A1';
        opp1.Type='Overline';
        opp1.Name='Service';
        opp1.StageName='Closed Won';
        opp1.Accountid=at.id;
        opp1.Contact__c=ct.id;
        opp1.CloseDate=system.today()+1;
        opp1.Amount=11.0;
        opp1.End_User__c=at.id;
        opp1.End_User_Company_Name__c = 'DANIEL INC.';
        opp1.Business_Unit1__c='Digital Imaging';
        opp1.Sub_Stage__c='Booked';
        opp1.Application_Date__c=system.today().addMonths(-3);
        opp1.UNQ_Customer__c='A1';
        opp1.UNQ_Vendor__c='A1';
        opp1.UNQ_Opportunity__c='A1';
        insert opp1;

        Opportunity_Line_Item__c oppLine = new Opportunity_Line_Item__c();
        oppLine.Line_Item_Type__c = 'Asset';
        oppline.Name = 'Test';
        oppLine.Opportunity__c = opp1.Id;
        oppLine.Planned_Install_City__c = 'Test';
        oppLine.Planned_Install_State__c = 'Test';
        oppLine.Planned_Install_Street__c = 'Test';
        oppLine.Planned_ZIP_Code__c = 'Test';
        insert oppLine;

        Quote q = new Quote();
        q.Name = 'Quote5';
        q.OpportunityId = opp1.id;
        insert q;

        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        cont.Status_Text__c = 'BOOKED';
        cont.Name='test contract';
        cont.Account__c = at.id;
        cont.End_User__c = at.id;
        insert cont;

        //Insert asset
        Asset__c ast = new Asset__c();
        ast.Contract__c = cont.id;
        ast.Name = '12345';
        ast.Asset_City_Install_Address__c = 'Test';
        ast.Asset_Install_Address_Line_1__c = 'Test';
        ast.Asset_Install_Address_Line_2__c = 'Test';
        ast.Asset_Postal_Code_Install_Address__c = 'Test';
        ast.Asset_State_Install_Address__c = 'Test';
        insert ast;
    }

    @isTest static void testGetAddresses() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
            Map<String, String> addresses = CustomerInstallAddresses.getAddresses(opp.Id);
        Test.stopTest();
    }
}