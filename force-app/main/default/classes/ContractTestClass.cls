@isTest(SeeAllData=True)
public class ContractTestClass {   
    
    //PBI:557151-Apex class Version Update + Contract Trigger to deactivate
    public static testmethod void ContractTest_M1()
    {
        test.startTest();
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
       
        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
        insert ct;
      
        system.assertNotEquals(null, ct.id);
       system.assertEquals(ct.AccountId,at.Id);
        
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='123411';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        
        system.assertNotEquals(null, sys.id);
         system.assertEquals(sys.Account__c,at.Id);
        
        Opportunity opp= new Opportunity();
        opp.Type='Overline';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.Accountid=acc.id;
        opp.Contact__c=ct.id;
        opp.CloseDate=system.today()+1;
        opp.Amount=22.0;
        opp.End_User__c=at.id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Vendor__c='1234455';
        opp.UNQ_Opportunity__c='12345';
        insert opp;  
       
        system.assertNotEquals(null, opp.id);
         system.assertEquals( opp.End_User__c,at.Id);
           system.assertEquals( opp.Contact__c,ct.Id);
           system.assertEquals(opp.AccountId,acc.Id);
        
        Contract cont=new Contract();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234887';
        cont.UNQ_Contract__c='1234CONTRACT';
        //cont.Status__c = 'In Approval Process';
        cont.Status = 'Draft';
        // cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        //cont.AccountId=acc.id;
        // cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id; 
        cont.AccountId = at.id;
        insert cont;   
         system.assertNotEquals(null, cont.id);
          system.assertEquals(cont.Customer_Code__c,sys.Id);
        
        Opportunity_Relationship__c oor=new Opportunity_Relationship__c();      
        oor.Opportunity__c=opp.id;
        oor.Opportunity_Role__c='End User';
        oor.Account__c=acc.id;        
        insert oor;
         system.assertNotEquals(null, oor.id);
         system.assertEquals(oor.Opportunity__c,opp.Id);
        
        oor.Contract__c = cont.Id;
        oor.Contract_Account__c = cont.End_User__c;
        update oor;
        test.stopTest();
        
    }
     public static testmethod void ContractTest_M3()
    {
        test.startTest();
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;       
        
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;
        
        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
        insert ct;
        system.assertNotEquals(null, ct.id);
       system.assertEquals(ct.AccountId,at.Id);
        
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234233';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        system.assertNotEquals(null, sys.id);
        Opportunity opp= new Opportunity();
        opp.Type='Overline';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.Accountid=acc.id;
        opp.Contact__c=ct.id;
        opp.CloseDate=system.today()+1;
        opp.Amount=22.0;
        opp.Application_Date__c = date.today();
        opp.End_User__c=at.id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Vendor__c='1234097';
        opp.UNQ_Opportunity__c='FTD004184T123';
        insert opp;  
        system.assertNotEquals(null, opp.id);
        Contract cont=new Contract();
        cont.UNQ_Opportunity__c='112FTD004184T';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234765';
        cont.UNQ_Contract__c='1234CONTRACT';
        //cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        cont.Status = 'Draft';
        //cont.Status__c = 'In Approval Process';
        //cont.AccountId=acc.id;
         //cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id; 
        cont.AccountId = at.id;
        insert cont; 
        
        system.assertNotEquals(null, cont.id);
         system.assertEquals(cont.Customer_Code__c,sys.Id);
        
        Opportunity_Relationship__c oor=new Opportunity_Relationship__c();      
        oor.Opportunity__c=opp.id;
        oor.Opportunity_Role__c='End User';
        oor.Account__c=acc.id;        
        //insert oor;
        oor.Contract__c = cont.Id;
        oor.Contract_Account__c = cont.End_User__c;
        insert oor;
        test.stopTest();
        
    } 
     public static testmethod void ContractTest_M2()
    {
        test.startTest();
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();

        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;

        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;

        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;

        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
        insert ct;
        system.assertNotEquals(null, ct.id);
        system.assertEquals(ct.AccountId,at.Id);

        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234564';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        system.assertNotEquals(null, sys.id);
        Opportunity opp= new Opportunity();
        opp.Type='Overline';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.Accountid=acc.id;
        opp.Contact__c=ct.id;
        opp.CloseDate=Date.today().addDays(1);
        opp.Amount=22.0;
        opp.Application_Date__c = date.today();
        opp.End_User__c=at.id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Vendor__c='12677434';
        opp.UNQ_Opportunity__c='FTD004184T65';
        insert opp;

        Contract cont=new Contract();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1463234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.Opportunity__c=opp.id;
        //cont.Status__c = 'In Approval Process';
        cont.Status = 'Draft';
        cont.StartDate = Date.today();
        cont.Name='test contract';
        cont.AccountId=acc.id;
        cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id;

        insert cont;

        Opportunity_Relationship__c oor=new Opportunity_Relationship__c();
        oor.Opportunity__c=opp.id;
        oor.Opportunity_Role__c='End User';
        oor.Account__c=acc.id;
        oor.Contract__c = cont.Id;
        oor.Contract_Account__c = cont.End_User__c;
        insert oor;
        test.stopTest();
    }
   
    
}