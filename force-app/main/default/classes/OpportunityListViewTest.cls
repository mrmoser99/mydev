@isTest
public class OpportunityListViewTest {
    @testSetup static void setup() {
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Account at =new Account();
        at.Name='Service';
        insert at;
        
        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
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
        oppList.add(opp1);

        Opportunity opp2= new Opportunity();
        opp2.application_number__c='A2';
        opp2.Type='Overline';
        opp2.Name='Service';
        opp2.StageName='Closed Lost';
        opp2.Accountid=at.id;
        opp2.Contact__c=ct.id;
        opp2.CloseDate=system.today()+1;
        opp2.Amount=22.0;
        opp2.End_User__c=at.id;
        opp2.End_User_Company_Name__c = 'Tech Packaging,INC.';
        opp2.Business_Unit1__c='Digital Imaging';
        opp2.Sub_Stage__c='Application Draft';
        opp2.Application_Date__c=system.today();
        opp2.UNQ_Customer__c='A2';
        opp2.UNQ_Vendor__c='A2';
        opp2.UNQ_Opportunity__c='A2';
        oppList.add(opp2);

        Opportunity opp3= new Opportunity();
        opp3.application_number__c='A3';
        opp3.Type='Overline';
        opp3.Name='Service';
        opp3.StageName='Closed Lost';
        opp3.Accountid=at.id;
        opp3.Contact__c=ct.id;
        opp3.CloseDate=system.today()+1;
        opp3.Amount=33.0;
        opp3.End_User__c=at.id;
        opp3.End_User_Company_Name__c = 'stuffed Puffs LLC';
        opp3.Business_Unit1__c='Digital Imaging';
        opp3.Sub_Stage__c='Application Draft';
        opp3.Application_Date__c=system.today();
        opp3.UNQ_Customer__c='A3';
        opp3.UNQ_Vendor__c='A3';
        opp3.UNQ_Opportunity__c='A3';
        oppList.add(opp3);

        Opportunity opp4= new Opportunity();
        opp4.application_number__c='A4';
        opp4.Type='Overline';
        opp4.Name='Service';
        opp4.StageName='Closed Lost';
        opp4.Accountid=at.id;
        opp4.Contact__c=ct.id;
        opp4.CloseDate=system.today()+1;
        opp4.Amount=44.0;
        opp4.End_User__c=at.id;
        opp4.End_User_Company_Name__c = 'DANIEL INC.';
        opp4.Business_Unit1__c='Digital Imaging';
        opp4.Sub_Stage__c='Application Draft';
        opp4.Application_Date__c=system.today();
        opp4.UNQ_Customer__c='A4';
        opp4.UNQ_Vendor__c='A4';
        opp4.UNQ_Opportunity__c='A4';
        oppList.add(opp4);

        Opportunity opp5= new Opportunity();
        opp5.application_number__c='A5';
        opp5.Type='Overline';
        opp5.Name='Service';
        opp5.StageName='Closed Lost';
        opp5.Accountid=at.id;
        opp5.Contact__c=ct.id;
        opp5.CloseDate=system.today()+1;
        opp5.Amount=55.0;
        opp5.End_User__c=at.id;
        opp5.End_User_Company_Name__c = 'WIND&WAVE INC.';
        opp5.Business_Unit1__c='Digital Imaging';
        opp5.Sub_Stage__c='Cancelled';
        opp5.Application_Date__c=system.today();
        opp5.UNQ_Customer__c='A5';
        opp5.UNQ_Vendor__c='A5';
        opp5.UNQ_Opportunity__c='A5';
        oppList.add(opp5); 
        
        insert oppList;

    }

    @isTest static  void OpportunityListView_M1(){
        test.startTest();

        //query all opportunities
        List<Opportunity> oppList1 = OpportunityListView.getOpportunities(5,0,'','','','','');
        Integer totalNum1 = OpportunityListView.getOpportunitiesNum(5,0,'','','');
        system.debug('oppList1==>'+oppList1);
        system.assertequals(4, oppList1.size());
        system.assertequals(5, totalNum1);
        
        //query all opportunities with sort in asc order
        List<Opportunity> oppList2 = OpportunityListView.getOpportunities(5,0,'','','','application_number__c','asc');
        Integer totalNum2 = OpportunityListView.getOpportunitiesNum(5,0,'','','');
        system.debug('oppList1==>'+oppList2);
        system.assertequals(4, oppList1.size());
        system.assertequals(5, totalNum1);

        //query opportunities in last 30 days with sort in asc order
        List<Opportunity> oppList3 = OpportunityListView.getOpportunities(5,0,'30D','','','application_number__c','asc');
        Integer totalNum3 = OpportunityListView.getOpportunitiesNum(5,0,'30D','','');
        system.debug('oppList2==>'+oppList3);
        system.assertequals(4, oppList3.size());
        system.assertequals(4, totalNum3);

        //query opportunities in last 12 months with searched application id
        List<Opportunity> oppList6 = OpportunityListView.getOpportunities(5,0,'12M','','A1','','');
        Integer totalNum6 = OpportunityListView.getOpportunitiesNum(5,0,'12M','','A1');
        system.debug('oppList6==>'+oppList6);
        system.assertequals(0, oppList6.size());
        system.assertequals(1, totalNum6);

        test.stopTest();
    }
}