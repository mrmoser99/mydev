/*
 * Test class for QuoteListView
 * Author: Geetha Bharadwaj
 */

@isTest
public class QuoteListViewTest {
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
        opp2.Sub_Stage__c='Cash';
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
        opp3.Sub_Stage__c='Competitor';
        opp3.Application_Date__c=system.today();
        opp3.UNQ_Customer__c='A3';
        opp3.UNQ_Vendor__c='A3';
        opp3.UNQ_Opportunity__c='A3';
        oppList.add(opp3);

        Opportunity opp4= new Opportunity();
        opp4.application_number__c='A4';
        opp4.Type='Overline';
        opp4.Name='Service';
       
        opp4.Accountid=at.id;
        opp4.Contact__c=ct.id;
        opp4.CloseDate=system.today()+1;
        opp4.Amount=44.0;
        opp4.End_User__c=at.id;
        opp4.End_User_Company_Name__c = 'DANIEL INC.';
        opp4.Business_Unit1__c='Digital Imaging';
        opp4.Sub_Stage__c='Customer Not Ready';
        opp4.Application_Date__c=system.today();
        opp4.UNQ_Customer__c='A4';
        opp4.UNQ_Vendor__c='A4';
        opp4.UNQ_Opportunity__c='A4';
        
        opp4.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
opp4.Nickname__c = 'testOpp';
opp4.StageName = 'Quoting';
opp4.Sub_Stage__c = 'Quoting & Proposal';
opp4.ForecastCategoryName = 'Omitted';
opp4.Amount = 0;
opp4.CurrencyIsoCode = 'USD';
        
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
        
         Quote q = new Quote();
        q.Name = 'Quote5';
		q.OpportunityId = opp5.id;      
        insert q;

    }

    @isTest static  void QuoteListView_M1(){
        test.startTest();

        //query all opportunities
        List<Quote> oppList1 = QuoteListView.getQuotes(5,0,'','','','','');
        Integer totalNum1 = QuoteListView.getQuotesNum(5,0,'','','');
        system.debug('oppList1==>'+oppList1);
       
        
        //query all opportunities with sort in asc order
        List<Quote> oppList2 = QuoteListView.getQuotes(5,0,'','','','OpportunityId','asc');
        Integer totalNum2 = QuoteListView.getQuotesNum(5,0,'','','');
        //query opportunities in last 30 days with sort in asc order
        List<Quote> oppList3 = QuoteListView.getQuotes(5,0,'30D','','','OpportunityId','asc');
        Integer totalNum3 = QuoteListView.getQuotesNum(5,0,'30D','','');
      
        //query cancelled opportunities in last 60 days with sort in desc order
        List<Quote> oppList4 = QuoteListView.getQuotes(5,0,'60D','Cancelled','','OpportunityId','desc');
        Integer totalNum4 = QuoteListView.getQuotesNum(5,0,'60D','Cancelled','');
      
        //query opportunities in last 6 months with status filter
        List<Quote> oppList5 = QuoteListView.getQuotes(5,0,'6M','Booked','','','');
        Integer totalNum5 = QuoteListView.getQuotesNum(5,0,'6M','Booked','');
      
        //query opportunities in last 12 months with searched application id
        List<Quote> oppList6 = QuoteListView.getQuotes(5,0,'12M','','A1','','');
        Integer totalNum6 = QuoteListView.getQuotesNum(5,0,'12M','','A1');
        
        //query opportunities in this year with searched customer name
        Integer thisYear = system.today().year();
        String thisYearString = string.valueof(thisYear);
        List<Quote> oppList7 = QuoteListView.getQuotes(5,0,thisYearString,'','DANIEL','','');
        Integer totalNum7 = QuoteListView.getQuotesNum(5,0,'2021','','DANIEL');
        
       
        
        //query cancelled opportunities 
        List<Quote> oppList8 = QuoteListView.getQuotes(5,0,'','Cancelled','','','');
        Integer totalNum8 = QuoteListView.getQuotesNum(5,0,'','Cancelled','');
        
        
        //query opportunities with status filter
        List<Quote> oppList9 = QuoteListView.getQuotes(5,0,'','Booked','','','');
        Integer totalNum9 = QuoteListView.getQuotesNum(5,0,'','Booked','');
        
         //query opportunities in this year with searched date value
        Integer thisYear1 = system.today().year();
        String thisYearString1 = string.valueof(thisYear);
        List<Quote> oppList10 = QuoteListView.getQuotes(5,0,thisYearString,'','05/12/2022','','');
        Integer totalNum10 = QuoteListView.getQuotesNum(5,0,'2021','','05/12/2022');
        
        
        //delete Quote scenario
       Opportunity opp5 = [select id from Opportunity where  application_number__c = 'A5'];
       QuoteListView.deleteOpp(opp5.id);
       
        test.stopTest();
    }
    
    @isTest static  void QuoteListView_M2(){
        Opportunity opp5 = [Select id from Opportunity where application_number__c = 'A5'];
        test.startTest();
         try{
             delete opp5;
             QuoteListView.deleteOpp(opp5.id);
             
        }catch(Exception e){
            system.debug('in catch Quotelistviewtest');
        }
        test.stopTest();
        
    }
    
    @isTest static  void QuoteListView_M3(){
        Quote q = [Select id from quote where Name = 'Quote5'];
        Opportunity opp5 = [Select id from Opportunity where application_number__c = 'A5'];
        test.startTest();
        try{
              delete q;
             QuoteListView.deleteOpp(opp5.id);
           
             
        }catch(Exception e){
            system.debug('in catch Quotelistviewtest');
        }
         
         test.stopTest();
       
        
        
        
    }
}