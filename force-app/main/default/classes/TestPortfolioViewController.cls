/*
 * Test class for PortfolioViewController
 * PortfolioListView + Download Portfolio functionality
 * Author: Mark Moser
 * Author: Geetha Bharadwaj - added test cases for Download portfolio
 */

@isTest(SeeAllData=true)
private class TestPortfolioViewController {
    
    Static testmethod void test1(){

        PortfolioViewController.getRecords(0, '1', 'ALL', 'customerName', 'asc', '');
        PortfolioViewController.getRecords(0, '1', 'ALL', 'contractUrl', 'asc', '');
        
        PortfolioViewController.getRecords(0, '1', 'ALL', 'customerName','asc', '');
        
        PortfolioViewController.getRecords(0, '1', 'ALL', 'endUserURL','asc', '');
        
        PortfolioViewController.getRecords(0, '1', 'ALL', 'contractNumber','asc', '');
        
        PortfolioViewController.getRecords(0, '1', 'ALL', 'customerName','asc', '');
        
        PortfolioViewController.getTotalRecords();
        
        PortfolioViewController.wrapContract w = new PortfolioViewController.wrapContract(null,'a1111','fox');
        
        PortfolioViewController.getTotalRecords();
        
        
        
    }
    
    //- Download Portfolio functionality
    @isTest static void method_M2() {
        
          //Insert account
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;       
        system.assertNotEquals(null, acc.id);
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        system.assertNotEquals(null, parentEnduser.id);
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;
        
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        cont.Status_Text__c = 'BOOKED';
        cont.Name='test contract';
        cont.Account__c = at.id;
        insert cont;   
        
       
        //Insert asset
        Asset__c ast = new Asset__c();
        ast.Contract__c = cont.id;
        ast.Name = '12345';
        insert ast;
        
        Test.startTest();
        PortfolioViewController.getdownloadRecords('LAST_N_DAYS:30','BOOKED','12345');
        Test.stopTest();
    }
    
    @isTest static void method_M3() {
        
          //Insert account
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;       
        system.assertNotEquals(null, acc.id);
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        system.assertNotEquals(null, parentEnduser.id);
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;
        
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        cont.Status_Text__c = 'BOOKED';
        cont.Name='test contract';
        cont.Account__c = at.id;
        insert cont;   
        
       
        //Insert asset
        Asset__c ast = new Asset__c();
        ast.Contract__c = cont.id;
        ast.Name = '12345';
        insert ast;
        
        Test.startTest();
        PortfolioViewController.getdownloadRecords('LAST_N_DAYS:30','BOOKED','contract');
        Test.stopTest();
    }
    
        @isTest static void method_M4() {
        
          //Insert account
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;       
        system.assertNotEquals(null, acc.id);
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        system.assertNotEquals(null, parentEnduser.id);
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;
        
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        cont.Status_Text__c = 'BOOKED';
        cont.Name='test contract';
        cont.Account__c = at.id;
        insert cont;   
        
       
        //Insert asset
        Asset__c ast = new Asset__c();
        ast.Contract__c = cont.id;
        ast.Name = '12345';
        insert ast;
        
        Test.startTest();
        PortfolioViewController.getdownloadRecords('1','BOOKED','contract');
        Test.stopTest();
    }
}