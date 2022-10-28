/** 
* Test class for ContractPrintPDFController Apex class
* Built for DLL on Demand
* Author : Geetha Bharadwaj
*/

@isTest
public class ContractPrintPDFControllerTest {
    
    @isTest static void method_M1() {
        
        
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
        
        system.assertNotEquals(null, at.id);
        system.assertEquals(at.ParentId,parentEnduser.Id);
        
        //Insert contact
        contact con = new contact();
        con.AccountId = at.id;
        con.LastName = 'Testcon';
        insert con;
        
        //Insert partner User
       /* User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Admin'].Id,
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
            ContactId = con.id
        );
        insert u;*/
        
        
        //Insert Contract
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        cont.Status_Text__c = 'Draft';
        cont.Name='test contract';
        cont.Account__c = at.id;
        insert cont;   
        
        system.assertNotEquals(null, cont.id);    
        system.assertNotEquals(null, cont.id);
        system.assertEquals(cont.Account__c,at.Id);
        
        //Insert asset
        Asset__c ast = new Asset__c();
        ast.Contract__c = cont.id;
        ast.Name = '12345';
        insert ast;
        
        Test.startTest();
        ContractPrintPDFController.getContractsAssets(cont.id);
        Test.stopTest();
    }
}