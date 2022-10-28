/**
 * @create: by Traction Team on 04/27/2020
 * 
 */
@IsTest
public class CustomContractTriggerTest {
    public static testmethod void ContractTest_M1(){
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
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        
        system.assertNotEquals(null, sys.id);
        system.assertEquals(sys.Account__c,at.Id);
        Program__c program = new Program__c();
        program.UNQ_Program__c = 'Trac_Program';
        program.Region_Description__c = 'Trac_Program_desc';
        program.Business_Unit_Description__c = 'Trac_ProgramBUDesc';
        program.Legal_Entity_Description__c = 'Trac_Program_EntityDesc';
        insert program;
        
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
        opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='12345';
        insert opp;
        
        
        
        system.assertNotEquals(null, opp.id);
        system.assertEquals( opp.End_User__c,at.Id);
        system.assertEquals( opp.Contact__c,ct.Id);
        system.assertEquals(opp.AccountId,acc.Id);
        
         
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        //cont.Status__c = 'In Approval Process';
        cont.Status_Text__c = 'Draft';
        // cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        //cont.AccountId=acc.id;
        // cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id;   
        insert cont;   
        system.assertNotEquals(null, cont.id);
        system.assertEquals(cont.Customer_Code__c,sys.Id);
        
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
        sys.UNQ_Vendor__c='1234';
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
        opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='FTD004184T';
        insert opp;  
        system.assertNotEquals(null, opp.id);
        system.assertNotEquals(null, sys.id);
        system.assertEquals(sys.Account__c,at.Id);
        
        Program__c program = new Program__c();
        program.UNQ_Program__c = 'Trac_Program';
        program.Region_Description__c = 'Trac_Program_desc';
        program.Business_Unit_Description__c = 'Trac_ProgramBUDesc';
        program.Legal_Entity_Description__c = 'Trac_Program_EntityDesc';
        insert program;
        
        Region__c rg = new Region__c();
		rg.name= 'United States';
        rg.Region_Type__c = 'Country';
        rg.Description__c= 'United States Region';
        insert rg;
        

        Business_Unit__c pbu = new Business_Unit__c();
        pbu.Name=   'DLL'  ;      
        pbu.Description__c = 'he DLL Group Legal Entity. Parent to all DLL Group Business Units.';
        insert pbu;
        
        Business_Unit__c bu = new Business_Unit__c();
        bu.Parent_Business_Unit__c = pbu.id;
        bu.Name = 'Food & Agriculture (F&A)';
        bu.Business_Unit_Flag_API_Name__c = 'Food_and_Ag__c';
        insert bu;
        
        Contract__c cont=new Contract__c();
        cont.UNQ_Opportunity__c='FTD004184T';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.Name='test contract';
        cont.Status_Text__c = 'Draft';
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id;   
        cont.Region_Description__c='United States';
        cont.Business_Unit_Description__c='Food and Agriculture';
        cont.Legal_Entity_Description__c='DLL';
        cont.UNQ_Program__c='Trac_Program';
        insert cont; 
        
        system.assertNotEquals(null, cont.id);
        system.assertEquals(cont.Customer_Code__c,sys.Id);
        
        test.stopTest();
        
    } 
    
    public static testmethod void ContractTest_M2(){
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
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        
        system.assertNotEquals(null, sys.id);
        system.assertEquals(sys.Account__c,at.Id);
        Program__c program = new Program__c();
        program.UNQ_Program__c = 'Trac_Program';
        program.Region_Description__c = 'Trac_Program_desc';
        program.Business_Unit_Description__c = 'Trac_ProgramBUDesc';
        program.Legal_Entity_Description__c = 'Trac_Program_EntityDesc';
        insert program;
        
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
        opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='12345';
        insert opp;
        
        
        
        system.assertNotEquals(null, opp.id);
        system.assertEquals( opp.End_User__c,at.Id);
        system.assertEquals( opp.Contact__c,ct.Id);
        system.assertEquals(opp.AccountId,acc.Id);
        
        Region__c rg = new Region__c();
		rg.name= 'Unknown';
       // rg.Region_Type__c = 'Country';
        rg.Description__c= 'Default value for unknown Business Units';
        insert rg;
        
       
        Business_Unit__c bu = new Business_Unit__c();
        bu.Name = 'Unknown';
        //bu.Business_Unit_Flag_API_Name__c = 'Food_and_Ag__c';
        bu.Description__c='Default value for unknown Business Units';
        insert bu;
        
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='Trac_Program';
        //cont.Status__c = 'In Approval Process';
        cont.Status_Text__c = 'Draft';
        // cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        //cont.AccountId=acc.id;
        // cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id;   
        cont.Region_Description__c='';
        cont.Business_Unit_Description__c='Unknown';
        cont.Legal_Entity_Description__c='DLL';
        insert cont;   
        system.assertNotEquals(null, cont.id);
        system.assertEquals(cont.Customer_Code__c,sys.Id);
        
        test.stopTest();
    }
    
    public static testmethod void ContractTest_M4(){
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
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        
        system.assertNotEquals(null, sys.id);
        system.assertEquals(sys.Account__c,at.Id);
        Program__c program = new Program__c();
        program.UNQ_Program__c = 'Trac_Program';
        program.Region_Description__c = 'Trac_Program_desc';
        program.Business_Unit_Description__c = 'Trac_ProgramBUDesc';
        program.Legal_Entity_Description__c = 'Trac_Program_EntityDesc';
        insert program;
        
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
        opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='12345';
        insert opp;
        
        
        
        system.assertNotEquals(null, opp.id);
        system.assertEquals( opp.End_User__c,at.Id);
        system.assertEquals( opp.Contact__c,ct.Id);
        system.assertEquals(opp.AccountId,acc.Id);
        
        Region__c rg = new Region__c();
		rg.name= 'Unknown';
       // rg.Region_Type__c = 'Country';
        rg.Description__c= 'Default value for unknown Business Units';
        insert rg;
        
       
        Business_Unit__c bu = new Business_Unit__c();
        bu.Name = 'Unknown';
        //bu.Business_Unit_Flag_API_Name__c = 'Food_and_Ag__c';
        bu.Description__c='Default value for unknown Business Units';
        insert bu;
        
        Contract__c cont = new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.UNQ_Program__c='';
        //cont.Status__c = 'In Approval Process';
        cont.Status_Text__c = 'Draft';
        // cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        //cont.AccountId=acc.id;
        // cont.End_User__c=at.id;
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id;   
      //  cont.Region_Description__c='';
      //  cont.Business_Unit_Description__c='';
      //  cont.Legal_Entity_Description__c='';
        insert cont;   
        system.assertNotEquals(null, cont.id);
        system.assertEquals(cont.Customer_Code__c,sys.Id);
        
        test.stopTest();
    }
    //commented below for Apex sharing logic
   /* public static testmethod void ContractTest_M5(){
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
         
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.Technology_Solutions__c=false;
        insert at;
        
        contact ct =new contact();
        ct.LastName='Testlast';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
        insert ct;
        
      
        User u = new User( ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Admin'].Id,LastName = 'Testlast',
            Email = 'testadmin.last@test.com',Username = 'testadmin.last@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', Legal_Entity_Description__c = 'DLL', 
            EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US',Business_Unit__c = 'Commercial Finance',
            contactId = ct.id              
        );
        insert u;
        
        test.startTest();
       
        
        Contract__c cont=new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234887';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.Name='test contract';
        cont.Amount__c=10;
        cont.Account__c = at.id;
        cont.End_User__c = at.id;
             
        insert cont;
        
        List<Contract_Team__c> ctm = [SELECT Contract_Access__c,Contract__c,Id,IsDeleted,Name,OwnerId,SystemModstamp,Team_Role__c,User__c 
                                      FROM Contract_Team__c
                                      where contract__c =: cont.id];
        
        system.assertEquals(1, ctm.size());
        
        
        
        test.stopTest();
    }*/
}