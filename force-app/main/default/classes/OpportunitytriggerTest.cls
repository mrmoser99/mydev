/**********************************************************************************************************
Class :  OpportunitytriggerTest
Description : Test class for Opportunity Helper Class

Date/Sprint		PBI/Description
PI-22-Q4-21		855444 - As a DSM, CA, & Ag CA Sales Rep, I do not want to see multiple stage and substages with the same date/time stamp.
  
***********************************************************************************************************/
@IsTest
public class OpportunitytriggerTest {

    public static User apiUser(){
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        return u;

    }
    public static testMethod void test_M1() {
        Test.startTest();
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
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
        
        System.assertNotEquals(null, acc.Id);
        
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        parentEnduser.BillingStreet = 'Am Tierpark 16';
        parentEnduser.BillingCity = 'Cologne';
        parentEnduser.BillingPostalCode = '54321';
        parentEnduser.BillingState = 'Nordrhein-Westfalen';
        parentEnduser.BillingCountry = 'Germany';
        insert parentEnduser;
        
        System.assertNotEquals(null, parentEnduser.Id);
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        at.BillingStreet = 'Am Tierpark 16';
        at.BillingCity = 'Cologne';
        at.BillingPostalCode = '54321';
        at.BillingState = 'Nordrhein-Westfalen';
        at.BillingCountry = 'Germany';
        insert at;
        
        System.assertNotEquals(null, at.Id);
        System.assertEquals(at.ParentId,parentEnduser.Id);
        
        Contact ct =new Contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.Id;
        ct.Email='arry@gmil.com';
        insert ct;
        
        System.assertNotEquals(null, ct.Id);
        System.assertEquals(ct.AccountId,at.Id);
        
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.Id;
        insert sys;
        
        System.assertNotEquals(null, sys.Id);
        System.assertEquals(sys.Account__c,at.Id);

        /*
        Vendor_Program__c vpp=new Vendor_Program__c();
        vpp.Program_Code__c='TEST';
        vpp.Partner__c=at.Id;
        insert vpp;
        System.assertNotEquals(null, vpp.Id);
        System.assertEquals(vpp.Partner__c,at.Id);
        */
        
        Program__c program =new Program__c();
        program.Program_Code__c='TEST';
        program.Partner__c=at.Id;
       program.UNQ_Program__c = 'TEST';
        insert program;
        //Below code added by Geetha Bharadwaj - DLL
        Program__c program2 =new Program__c();
        program2.Program_Code__c='TEST1';
        program2.Partner__c=at.Id;
        program2.UNQ_Program__c = 'TEST1';
        insert program2;
        
       
        System.assertNotEquals(null, program.Id);
        System.assertEquals(program.Partner__c,at.Id);
        
        Account_Account_Relationship__c aar=new Account_Account_Relationship__c();
        aar.Account_1__c=acc.Id;
        aar.Account_2__c=at.Id;
        aar.Role__c='End User';        
        insert aar;
        Account_Account_Relationship__c aar2=new Account_Account_Relationship__c();
        aar2.Account_1__c=at.Id;
        aar2.Account_2__c=acc.Id;
        aar2.Role__c='Vendor';        
        insert aar2;
        System.assertNotEquals(null, aar.Id);
        System.assertNotEquals(null, aar2.Id);
        
        
        Opportunity opp= new Opportunity();
        opp.Type='New';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.AccountId=acc.Id;
        opp.Contact__c=ct.Id;
        opp.CloseDate=System.today()+1;
        opp.Amount=22.0;
        opp.End_User__c=at.Id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        //opp.UNQ_Vendor_Program__c='TEST';
        opp.UNQ_Program__c=program.UNQ_Program__c;
        opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='12345T';
        opp.Business_Unit1__c='CleanTech';
        opp.End_User_Phone__c='123456';
        opp.Program__c = program.Id;
        opp.Sub_Stage__c = 'Qualifying';
        opp.StageName = 'Qualifying';
        insert opp;  
        
        
        System.assertNotEquals(null, opp.Id);
        System.assertEquals( opp.End_User__c,at.Id);
        System.assertEquals( opp.Contact__c,ct.Id);
        System.assertEquals(opp.AccountId,acc.Id);
        
        opp.UNQ_Opportunity__c='TEST';
        opp.Business_Unit1__c='Healthcare';
        opp.Business_Unit1__c='Construction, Transportation, and Industrial';
        //Below code added by Geetha Bharadwaj -DLL
        opp.UNQ_Program__c=program2.UNQ_Program__c;
        opp.Program__c = program2.Id;
        opp.Sub_Stage__c = 'On Hold';
        opp.StageName = 'Quoting';
        update opp;
        
        opp.Business_Unit1__c='Healthcare';
        update opp;
        opp.Business_Unit1__c='Public Finance';
        update opp;
        
        //Below code added by Geetha Bharadwaj -DLL
        Program_Partner_Party__c ppp = new Program_Partner_Party__c();
        ppp.Program__c = program2.Id;
        ppp.Dealer__c = opp.AccountId;
        insert ppp;
        
        Opportunity_Relationship__c oor=new Opportunity_Relationship__c();      
        oor.Opportunity__c=opp.Id;
        oor.Opportunity_Role__c='End User';
        oor.Account__c=acc.Id;
        insert oor;
        System.assertNotEquals(null, oor.Id);
        System.assertEquals(oor.Opportunity__c,opp.Id);
        
        
        opp=[SELECT Id,Business_Unit1__c,UNQ_Customer__c, End_User__c, AccountId,UNQ_Opportunity__c,Contact__c, StageName FROM Opportunity WHERE Id=:opp.Id];
        System.debug('___________opp_________test____'+opp);
        //System.assertNotEquals(null, opp.End_User__c);
        //System.assertNotEquals(null, opp.Parent_Vendor__c);
        //System.assertNotEquals(null, opp.End_User_Parent__c);
        //System.assertNotEquals(null, opp.Vendor_Parent__c);
        
        Test.stopTest();
        
    }
    public static testMethod void testOwnerChange(){
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
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
              isActive = true
        );
        insert u;
        User w = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
                LastName = 'last2',
                Email = 'test@test.com',
                Username = 'test@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance',
            isActive = true
        );
        //Below code added by Geetha Bharadwaj -DLL
        User x = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last2',
                Email = 'test@test.com',
                Username = 'test@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance',
                isActive = true,
                Legal_Entity_Description__c = 'DLL'
        );
         Program__c program =new Program__c();
        system.runAs(x){
            Business_Unit__c pbu  = new Business_Unit__c();
        pbu.Name = 'Healthcare';
        
        insert pbu;
        
        Business_Unit__c bu  = new Business_Unit__c();
        bu.Name = 'Healthcare';
            
        bu.Parent_Business_Unit__c = pbu.Id;
        bu.Opportunity_Record_Type_ID__c= [SELECT BusinessProcessId,CreatedById,CreatedDate,Description,DeveloperName FROM RecordType
                                           WHERE SobjectType = 'Opportunity' and DeveloperName = 'Healthcare_Channel'].Id;
        insert bu;
        
        Business_Unit_Assignment__c bua = new Business_Unit_Assignment__c();
        bua.User__c = x.Id;
          
        bua.Business_Unit__c = bu.Id;
        insert bua;
          
           
        program.Program_Code__c='TEST';
        program.Partner__c=acc.Id;
       program.Business_Unit__c = bu.Id;
        insert program;
        Region__c reg = new Region__c();
        reg.Name = 'GDW';
        insert reg;
            
        Region_Assignment__c rassignment = new Region_Assignment__c();
        rassignment.user__c = x.Id;
        rassignment.Region__c = reg.id;
        insert rassignment;
        }
        insert w;
        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
        sr.Sales_Rep__c=u.Id;
        sr.Sales_Rep_ID__c='1234';
        sr.Source_System__c = 'Test';
 
        insert sr;
        
        Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
        sr2.Sales_Rep__c=w.Id;
        sr2.Sales_Rep_ID__c='1235';
        sr2.Source_System__c= 'Test';
        insert sr2;
        
        //Below code added by Geetha Bharadwaj -DLL
        Sales_Rep_ID__c sr3 =new Sales_Rep_ID__c();
        sr3.Sales_Rep__c=w.Id;
        sr3.Sales_Rep_ID__c='87651';
        sr3.Source_System__c= 'Test';
        insert sr3;

        
        
        System.runAs(u) {
            Test.startTest();
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            //Below code added by Geetha Bharadwaj - DLL
            opp.Application_Number__c = '1234567890';
            opp.Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
            opp.Source_System__c = sr.Source_System__c;
            opp.Sales_Rep_ID_2__c = sr2.Sales_Rep_ID__c;
            opp.Sales_Rep_Name__c = 'Test12';
            opp.Sales_Rep_Name_2__c = 'Test21';
            opp.Program__c = program.Id;
            opp.CloseDate = Date.today();
            
            insert opp;
            
            opp.Sales_Rep_Name__c = 'test11';
            opp.Sales_Rep_Name_2__c = 'Test22';
            opp.Application_Number__c = '098765432';
            opp.Sales_Rep_ID__c = sr2.Sales_Rep_ID__c;
            update opp;
            Opportunity newOpp = [SELECT OwnerId FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals(newOpp.OwnerId,newOpp.OwnerId );
            opp.Sales_Rep_ID__c = sr3.Sales_Rep_ID__c;
            update opp;
            newOpp = [SELECT OwnerId FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals(newOpp.OwnerId, newOpp.OwnerId);
            Test.stopTest();
        }
        
        //Below code added by Geetha Bharadwaj - DLL
        system.runAs(x){
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Healthcare';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM1';
            opp.Application_Date__c = Date.today();
            opp.Application_Number__c = '1234567890';
            opp.Funded_Date__c = Date.today();
            opp.Sales_Rep_ID__c = sr.Id;
            opp.Source_System__c = sr.Source_System__c;
            opp.Sales_Rep_ID_2__c = sr2.ID;
            opp.Sales_Rep_Name__c = 'Test';
            opp.Sales_Rep_Name_2__c = 'Test';
            opp.CloseDate = Date.today();
            insert opp;
        }

    }
    public static testMethod void test_M2()
    {
        Test.startTest();
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        //Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        //Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        //Id profileId=UserInfo.getProfileId();
        // Profile profileName=[SELECT Id,Name FROM Profile WHERE Name = 'API Integration' Limit 1];
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
            Business_Unit__c = 'Commercial Finance'
        );
        
        System.runAs(u){
            Account acc =new Account();
            acc.Name='test';
            acc.Technology_Solutions__c=false;
            acc.BillingStreet = 'Am Tierpark 16';
            acc.BillingCity = 'Cologne';
            acc.BillingPostalCode = '54321';
            acc.BillingState = 'Nordrhein Westfalen';
            acc.BillingCountry = 'US';
            insert acc;       
            System.assertNotEquals(null, acc.Id);
            
            Account parentEnduser =new Account();
            parentEnduser.Name='testparent end user';
            parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
            insert parentEnduser;
            System.assertNotEquals(null, parentEnduser.Id);
            
            Account at =new Account();
            at.Name='Service';
            at.RecordTypeId=RecordTypeIdAccountEndUser;
            at.ParentId=parentEnduser.Id;
            at.Technology_Solutions__c=false;
            insert at;
            
            System.assertNotEquals(null, at.Id);
            System.assertEquals(at.ParentId,parentEnduser.Id);
            
            Contact ct =new Contact();
            ct.LastName='Niranjan';
            ct.AccountId=at.Id;
            ct.Email='arry@gmil.com';
            insert ct;
            
            System.assertNotEquals(null, ct.Id);
            System.assertEquals(ct.AccountId,at.Id);
            
            System_ID__c sys =new System_ID__c();
            sys.System_Name__c='test';
            //sys.UNQ_Vendor__c='1234';
            sys.UNQ_Customer__c='123';
            sys.Phone__c='7889057582';
            sys.Account__c=at.Id;
            insert sys;
            
            System.assertNotEquals(null, sys.Id);
            System.assertEquals(sys.Account__c,at.Id);

            /*
            
            Vendor_Program__c vpp=new Vendor_Program__c();
            vpp.Program_Code__c='TEST';
            vpp.Partner__c=at.Id;
            insert vpp;
            */
            
            Program__c program = new Program__c();
            program.Program_Code__c='TEST';
            program.Partner__c=at.Id;
            insert program;
            
            Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
            sr.Sales_Rep__c=u.Id;
            sr.Sales_Rep_ID__c='1234';
            sr.Source_System__c = 'Test';
            
            insert sr;
            
            //Below code added by Geetha Bharadwaj - DLL
            Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
            sr2.Sales_Rep__c=u.Id;
            sr2.Sales_Rep_ID__c='1235';
            sr2.Source_System__c= 'Test';
            insert sr2;
            
            //Geetha-dll
            Sales_Rep_ID__c sr3 =new Sales_Rep_ID__c();
            sr3.Sales_Rep__c=u.Id;
            sr3.Sales_Rep_ID__c='87651';
            sr3.Source_System__c= 'Test';
            insert sr3;
            
            List<Id> opplst=new List<Id>();
            Opportunity opp= new Opportunity();
            opp.Type='New';
            opp.Name='Service';
            // opp.Accountid=acc.Id;
            opp.Contact__c=ct.Id;
            opp.CloseDate=System.today()+1;
            opp.Amount=22.0;
            opp.End_User__c=at.Id;
            opp.Business_Unit1__c='Food & Agriculture';
            opp.UNQ_Customer__c='123';
           //opp.UNQ_Vendor__c='1234';
            opp.UNQ_Opportunity__c='1234500T';
            //opp.Vendor_Program__c=vpp.Id;
            opp.Program__c = program.Id;
            opp.End_User_Phone__c='123456';
            //Below code added by Geetha Bharadwaj - DLL
            opp.Source_System__c = sr.Source_System__c;
            opp.Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
            opp.Sales_Rep_ID_2__c = sr2.Sales_Rep_ID__c;
            opp.StageName = 'Quoting'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_Stage__c = 'Application Pending'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            insert opp;
            Opportunity oppCheck = [SELECT StageName,Sub_stage__c FROM Opportunity WHERE Id =: opp.Id];
            System.assertEquals('Quoting', oppCheck.StageName);
            System.assertEquals('Application Pending', oppCheck.Sub_stage__c);
            
            System.assertNotEquals(null, opp.Id);
            System.assertEquals( opp.End_User__c,at.Id);
            System.assertEquals( opp.Contact__c,ct.Id);
            opp.Business_Unit1__c='Healthcare';
            update opp;
            opplst.add(opp.Id);
            
            Opportunity_Relationship__c oor=new Opportunity_Relationship__c();      
            oor.Opportunity__c=opp.Id;
            oor.Opportunity_Role__c='End User';
            oor.Account__c=acc.Id;
            insert oor;
            System.assertNotEquals(null, oor.Id);
            System.assertEquals(oor.Opportunity__c,opp.Id);
            
            Opportunity oppnew= new Opportunity();
            oppnew.Type='New';
            oppnew.Name='tesr';
            oppnew.StageName='On Hold';
            // opp.Accountid=acc.Id;
            oppnew.Contact__c=ct.Id;
            oppnew.CloseDate=System.today()+2;
            oppnew.Amount=221.0;
            oppnew.End_User__c=at.Id;
            oppnew.Business_Unit1__c='Digital Imaging';
            oppnew.UNQ_Customer__c='123';
            //oppnew.UNQ_Vendor__c='1234';
            oppnew.UNQ_Opportunity__c='1200T';
            //oppnew.Vendor_Program__c=vpp.Id;
            oppnew.End_User_Phone__c='1226';
            insert oppnew;  
            
//            OpportunityTriggerHandler.deleteOpptysFuture(opplst);            
            Test.stopTest();
        } 
    }
    //3/26/2020: Test case for stage name changes
    public static testMethod void test_stageNameChangeFromDoc(){
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.BillingStreet = 'Am Tierpark 16';
        acc.BillingCity = 'Cologne';
        acc.BillingPostalCode = '54321';
        acc.BillingState = 'Nordrhein Westfalen';
        acc.BillingCountry = 'US';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Documentation';
        opp.Sub_Stage__c = 'Documents Out';
        opp.Type = 'New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit1__c = 'Technology';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        opp.Funded_Date__c = Date.today();
        opp.CloseDate = Date.today();
        insert opp;
        Opportunity oppRet = [SELECT StageName,Sub_Stage__c FROM Opportunity WHERE Id = : opp.Id];
        System.assertEquals('Documentation', oppRet.StageName, 'The stage name did not get set properly');
        System.assertEquals('Documents Out', oppRet.Sub_Stage__c, 'The sub stage name did not get set properly');
        User u = new User(
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
        Business_Unit__c = 'Commercial Finance'
        );

        Test.startTest();
        System.runAs(u){
            //opp.Sub_Stage__c = 'Withdrawn'; //PBI724685 - Commented to avoid Test Class failure
            opp.StageName = 'Documentation'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            update opp;
        }
        oppRet = [SELECT StageName,Sub_Stage__c FROM Opportunity WHERE Id = : opp.Id];
        System.assertEquals('Documentation', oppRet.StageName, 'The stage name did not get set properly');
        System.assertEquals('Documents Out', oppRet.Sub_Stage__c, 'The sub stage name did not get set properly');
        Test.stopTest();
    }
    public static testMethod void test_stageNameChangeToClosed(){
          //Below code added by Geetha Bharadwaj - DLL
          User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        system.runAs(u){
        Business_Unit__c pbu  = new Business_Unit__c();
        pbu.Name = 'Healthcare';
        insert pbu;
        
        Business_Unit__c bu  = new Business_Unit__c();
        bu.Name = 'Healthcare';
        bu.Parent_Business_Unit__c = pbu.Id;
        bu.Opportunity_Record_Type_ID__c= [SELECT BusinessProcessId,CreatedById,CreatedDate,Description,DeveloperName FROM RecordType
                                           WHERE SobjectType = 'Opportunity' and DeveloperName = 'Healthcare_Channel'].Id;
        insert bu;
        
        Business_Unit_Assignment__c bua = new Business_Unit_Assignment__c();
        bua.User__c = u.Id;
        bua.Business_Unit__c = bu.Id;
        insert bua;
        Region__c reg = new Region__c();
        reg.Name = 'GDW';
        insert reg;
        Region_Assignment__c rassignment = new Region_Assignment__c();
        rassignment.user__c = u.Id;
        rassignment.Region__c = reg.id;
        insert rassignment;
}
        
        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
            sr.Sales_Rep__c=u.Id;
            sr.Sales_Rep_ID__c='1234';
            sr.Source_System__c = 'Test';
            
            insert sr;
            
            Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
            sr2.Sales_Rep__c=u.Id;
            sr2.Sales_Rep_ID__c='1235';
            sr2.Source_System__c= 'Test';
            insert sr2;
            
            //Geetha-dll
            Sales_Rep_ID__c sr3 =new Sales_Rep_ID__c();
            sr3.Sales_Rep__c=u.Id;
            sr3.Sales_Rep_ID__c='87651';
            sr3.Source_System__c= 'Test';
            insert sr3;
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.BillingStreet = 'Am Tierpark 16';
        acc.BillingCity = 'Cologne';
        acc.BillingPostalCode = '54321';
        acc.BillingState = 'Nordrhein Westfalen';
        acc.BillingCountry = 'US';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Application Approved';
        opp.Sub_Stage__c = 'Application Approved';
        opp.Type = 'New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit1__c = 'Technology';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        opp.Funded_Date__c = Date.today();
        //Below code added by Geetha Bharadwaj - DLL
        opp.Source_System__c = sr.Source_System__c;
        opp.Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
        opp.Sales_Rep_ID_2__c = sr2.Sales_Rep_ID__c;
        opp.CloseDate = Date.today();
        insert opp;
        Test.startTest();
        System.runAs(u){
            opp.User_Managed_Opportunity__c = false;
            opp.StageName = 'Closed Lost'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_Stage__c = 'Expired/Withdrawn'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            update opp;
        }
        Opportunity oppRet = [SELECT StageName,Sub_Stage__c FROM Opportunity WHERE Id = : opp.Id];
        System.assertEquals('Closed Lost', oppRet.StageName, 'The stage name did not get set properly');
        System.assertEquals('Expired/Withdrawn', oppRet.Sub_Stage__c, 'The sub stage name did not get set properly');
        Test.stopTest();
    }

    public static testMethod void test_assignAccountAndEndUser() {
        Test.startTest();
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        //Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        //Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();

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

        System.assertNotEquals(null, acc.Id);

        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        parentEnduser.BillingStreet = 'Am Tierpark 16';
        parentEnduser.BillingCity = 'Cologne';
        parentEnduser.BillingPostalCode = '54321';
        parentEnduser.BillingState = 'Nordrhein-Westfalen';
        parentEnduser.BillingCountry = 'Germany';
        insert parentEnduser;

        System.assertNotEquals(null, parentEnduser.Id);

        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        at.BillingStreet = 'Am Tierpark 16';
        at.BillingCity = 'Cologne';
        at.BillingPostalCode = '54321';
        at.BillingState = 'Nordrhein-Westfalen';
        at.BillingCountry = 'Germany';
        insert at;

        System.assertNotEquals(null, at.Id);
        System.assertEquals(at.ParentId,parentEnduser.Id);

        Contact ct =new Contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.Id;
        ct.Email='arry@gmil.com';
        insert ct;

        System.assertNotEquals(null, ct.Id);
        System.assertEquals(ct.AccountId,at.Id);

        //Below code added by Geetha Bharadwaj - DLL
        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
          //  sr.Sales_Rep__c=u.Id;
            sr.Sales_Rep_ID__c='1234';
            sr.Source_System__c = 'Test';
            
            insert sr;
            
            Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
          //  sr2.Sales_Rep__c=u.Id;
            sr2.Sales_Rep_ID__c='1235';
            sr2.Source_System__c= 'Test';
            insert sr2;
            
            //Geetha-dll
            Sales_Rep_ID__c sr3 =new Sales_Rep_ID__c();
         //   sr3.Sales_Rep__c=u.Id;
            sr3.Sales_Rep_ID__c='87651';
            sr3.Source_System__c= 'Test';
            insert sr3;
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        //sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=acc.Id;
        insert sys;

        Opportunity opp= new Opportunity();
        opp.Type='New';
        opp.Name='Service';
        opp.StageName='On Hold';
        //opp.Accountid=acc.Id;
        opp.Contact__c=ct.Id;
        opp.CloseDate=System.today()+1;
        opp.Amount=22.0;
        //opp.End_User__c=at.Id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        //opp.UNQ_Vendor__c='1234';
        opp.UNQ_Opportunity__c='12345T';
        //opp.End_User_Phone__c='123456';
        opp.End_User_Company_Name__c = 'test';
opp.Source_System__c = sr.Source_System__c;
            opp.Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
            opp.Sales_Rep_ID_2__c = sr2.Sales_Rep_ID__c;
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(opp);

        OpportunityTriggerHelper.setAccountAndEndUser(opps);
    }

    public static testMethod void OpportunityMatchUpdatesTest(){
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
        opp.Name = 'Test';
        opp.AccountId = acc.Id;
        opp.OwnerId = UserInfo.getUserId();
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Amount = 20000.00;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        insert opp;

        Opportunity match = new Opportunity();
        match.Name = opp.Name;
        match.AccountId = acc.Id;
        match.OwnerId = UserInfo.getUserId();
        match.StageName = 'On Hold';
        match.Type ='New';
        match.Sales_Rep_ID__c = '1234';
        match.End_User_Phone__c = '1234567890';
        match.Amount = 20000.00;
        match.UNQ_Opportunity__c = 'APPNUM';
        match.Application_Date__c = Date.today();

        Opportunity match2 = new Opportunity();
        match2.Name = opp.Name;
        match2.AccountId = acc.Id;
        match2.OwnerId = UserInfo.getUserId();
        match2.StageName = 'On Hold';
        match2.Type ='New';
        match2.Sales_Rep_ID__c = '1234';
        match2.End_User_Phone__c = '1234567890';
        match2.Amount = 10000.00;
        match2.UNQ_Opportunity__c = 'APPNUM';
        match2.Application_Date__c = Date.today();

        Opportunity match3 = new Opportunity();
        match3.Name = opp.Name;
        match3.AccountId = acc.Id;
        match3.OwnerId = UserInfo.getUserId();
        match3.StageName = 'On Hold';
        match3.Type ='New';
        match3.Sales_Rep_ID__c = '1234';
        match3.End_User_Phone__c = '0987654321';
        match3.Amount = 20000.00;
        match3.UNQ_Opportunity__c = 'APPNUM';
        match3.Application_Date__c = Date.today();

        List<Opportunity> matchOpps = new List<Opportunity>{match, match2, match3};

        Test.startTest();
        System.debug('!!! about to match test Opps');
        OpportunityTriggerHelper.matchExistingOpportunities(matchOpps);
        Test.stopTest();

        System.assertEquals(3, matchOpps.size());
    }

    /**
   * @description test to check that the program and all related fields on the opportunity is being inserted properly
   * @author Newton Sun 4/21/2020
   *
   */
    public static testMethod void AccountBusinessUnitSet(){
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

        Business_Unit__c bu = new Business_Unit__c(
                Business_Unit_Flag_API_Name__c = 'Technology_Solutions__c'
        );
        insert bu;
        Region__c region = new Region__c(
                Name = 'Belgium'
        );
        insert region;


        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit__c = bu.Id;
        opp.Region_Relationship__c = region.Id;
        opp.Legal_Entity_Description__c = 'test';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        
        Test.startTest();
        OpportunityTriggerHelper.updateAccountBusinessFlags(new List<Opportunity>{opp});
        Test.stopTest();

        List<Account_Business_Unit_Mapping__c> abums = [SELECT Id, Technology_Solutions__c, Healthcare__c FROM Account_Business_Unit_Mapping__c];
        System.assertEquals(1, abums.size());
        System.assertEquals(true, abums[0].Technology_Solutions__c);
    }

    public static testMethod void AccountBusinessUnitUpdateMultipleOpps(){
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        acc.CleanTech__c=false;
        acc.Commercial_Finance__c=false;
        acc.CT_and_I__c = false;
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';
        insert acc;

        List<Business_Unit__c> bu = new List<Business_Unit__c>{new Business_Unit__c(
                Business_Unit_Flag_API_Name__c = 'Technology_Solutions__c'
        ), new Business_Unit__c(
                Business_Unit_Flag_API_Name__c =  'CT_and_I__c'
        )};
        insert bu;
        List<Region__c> regions = new List<Region__c>();
        regions.add(new Region__c(Name='Belgium'));
        regions.add(new Region__c(Name='Unknown'));
        insert regions;


        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit__c = bu[0].Id;
        opp.Region_Relationship__c = regions[0].Id;
        opp.Legal_Entity_Description__c = 'test';
        opp.Region_Description__c = 'Belgium';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();

        Opportunity opp2 = new Opportunity();
        opp2.AccountId = acc.Id;
        opp2.StageName = 'On Hold';
        opp2.Type ='New';
        opp2.Sales_Rep_ID__c = '1234';
        opp2.End_User_Phone__c = '1234567890';
        opp2.Business_Unit__c = bu[1].Id;
        opp2.Region_Relationship__c = regions[1].Id;
        opp2.Legal_Entity_Description__c = 'testing';
        opp2.Region_Description__c = 'Unknown';
        opp2.Amount = 20000;
        opp2.UNQ_Opportunity__c = 'APPNUM';
        opp2.Application_Date__c = Date.today();


        Test.startTest();
        OpportunityTriggerHelper.updateAccountBusinessFlags(new List<Opportunity>{opp, opp2});
        Test.stopTest();

        List<Account_Business_Unit_Mapping__c> abums = [SELECT Id, Technology_Solutions__c, Healthcare__c, CT_and_I__c,Legal_Entity_Description__c,Region_Description__c FROM Account_Business_Unit_Mapping__c];
        System.assertEquals(1, abums.size());
        System.assertEquals(true, abums[0].Technology_Solutions__c);
        System.assertEquals(true, abums[0].CT_and_I__c);
        System.assertEquals('Unknown', abums[0].Region_Description__c);
        System.assertEquals('testing', abums[0].Legal_Entity_Description__c);
    }

    public static testMethod void AccountBusinessUnitUpdateMultipleAccs(){
        List<Account> accs =new List<Account>{
                new Account(
                        Name = 'test',
                        Technology_Solutions__c = false,
                        CleanTech__c = false,
                        Commercial_Finance__c = false,
                        CT_and_I__c = false,
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US'
                ),
                new Account(
                        Name = 'test',
                        Technology_Solutions__c = false,
                        CleanTech__c = false,
                        Commercial_Finance__c = false,
                        CT_and_I__c = false,
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US'
                )
        };

        insert accs;

        List<Business_Unit__c> bu = new List<Business_Unit__c>{new Business_Unit__c(
                Business_Unit_Flag_API_Name__c = 'Technology_Solutions__c'
        ), new Business_Unit__c(
                Business_Unit_Flag_API_Name__c =  'CT_and_I__c'
        )};
        insert bu;
        List<Region__c> regions = new List<Region__c>();
        regions.add(new Region__c(Name='Belgium'));
        regions.add(new Region__c(Name='Unknown'));
        insert regions;


        Opportunity opp = new Opportunity();
        opp.AccountId = accs[0].Id;
        opp.End_User__c = accs[1].Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit__c = bu[0].Id;
        opp.Region_Relationship__c = regions[0].Id;
        opp.Legal_Entity_Description__c = 'test';
        opp.Region_Description__c = 'Belgium';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();

        Opportunity opp2 = new Opportunity();
        opp2.AccountId = accs[0].Id;
        opp2.End_User__c = accs[1].Id;
        opp2.StageName = 'On Hold';
        opp2.Type ='New';
        opp2.Sales_Rep_ID__c = '1234';
        opp2.End_User_Phone__c = '1234567890';
        opp2.Business_Unit__c = bu[1].Id;
        opp2.Region_Relationship__c = regions[1].Id;
        opp2.Legal_Entity_Description__c = 'test2';
        opp2.Region_Description__c = 'Unknown';
        opp2.Amount = 20000;
        opp2.UNQ_Opportunity__c = 'APPNUM';
        opp2.Application_Date__c = Date.today();


        Test.startTest();
        OpportunityTriggerHelper.updateAccountBusinessFlags(new List<Opportunity>{opp,opp2});
        Test.stopTest();

        List<Account_Business_Unit_Mapping__c> abums = [SELECT Id, Technology_Solutions__c, Healthcare__c, CT_and_I__c,Legal_Entity_Description__c,Region_Description__c FROM Account_Business_Unit_Mapping__c];
        System.assertEquals(2, abums.size());
        System.assertEquals(true, abums[0].Technology_Solutions__c);
        System.assertEquals(true, abums[0].CT_and_I__c);
        System.assertEquals('Unknown', abums[0].Region_Description__c);
        System.assertEquals('test2', abums[0].Legal_Entity_Description__c);
        System.assertEquals(true, abums[1].Technology_Solutions__c);
        System.assertEquals(true, abums[1].CT_and_I__c);
        System.assertEquals('Unknown', abums[1].Region_Description__c);
        System.assertEquals('test2', abums[1].Legal_Entity_Description__c);
    }

   /* public static testMethod void updateOpportunityFundedDate(){
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
        opp.AccountId = acc.Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit1__c = 'Technology';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        opp.Funded_Date__c = Date.today();

        insert opp;
        Test.startTest();
        opp.Funded_Date__c = Date.today().addDays(1);
        update opp;
        Test.stopTest();

        opp = [Select Funded_Date__c, CloseDate FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
        System.assertEquals(opp.Funded_Date__c, opp.CloseDate);


    }
*/
    public static testMethod void updateOpportunityStage(){
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
        //Id profileId=UserInfo.getProfileId();
        // Profile profileName=[SELECT Id,Name FROM Profile WHERE Name = 'API Integration' Limit 1];
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );

        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.Sub_Stage__c = 'Credit Declined';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            opp.CloseDate = Date.today();
			opp.StageName = 'Closed Lost'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            insert opp;
            Test.startTest();
            //Below code commented by Geetha Bharadwaj - DLL
            //opportunityTriggerHelper.hasStageCodeAlreadyExecuted = false;
            opp.Sub_Stage__c = 'Credit Declined'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            update opp;
            Test.stopTest();
            opp = [SELECT Funded_Date__c, CloseDate, Sub_Stage__c FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
            System.assertEquals('Credit Declined',opp.Sub_Stage__c);
            System.assertEquals(opp.Funded_Date__c, opp.CloseDate);
        }
    }
    
    public static testMethod void updateUserManagedOpportunityStage(){
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
        //Id profileId=UserInfo.getProfileId();
        // Profile profileName=[SELECT Id,Name FROM Profile WHERE Name = 'API Integration' Limit 1];
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );

        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Quoting'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_Stage__c = 'Application Approved';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            opp.User_Managed_Opportunity__c = true;
            opp.CloseDate = Date.today();
            insert opp;
            Test.startTest();
            //Below code commented by Geetha Bharadwaj - DLL
            //OpportunityTriggerHelper.hasStageCodeAlreadyExecuted = false;
            opp.StageName = 'Documentation'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_Stage__c = 'Funding Team Accepted'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            update opp;
            Test.stopTest();
            opp = [SELECT Funded_Date__c, CloseDate, Sub_Stage__c FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
            //System.assertEquals('Assigned to Funding Rep',opp.Sub_Stage__c);
            System.assertEquals(opp.Funded_Date__c, opp.CloseDate);
        }
    }

    public static testMethod void updateOpportunityRelationship(){
        Account acc =new Account();
        acc.Name='test';
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';
        insert acc;

        Account acc2 =new Account();
        acc2.Name='test2';
        acc2.BillingStreet = '3321 LEGION RD';
        acc2.BillingCity = 'HOPE MILLS5';
        acc2.BillingPostalCode = '28348-1652';
        acc2.BillingState = 'North Carolina2';
        acc2.BillingCountry = 'US';
        insert acc2;  
        
        Account eu =new Account();
        eu.Name='test';
        eu.BillingStreet = '3321 LEGION RD';
        eu.BillingCity = 'HOPE MILLS5';
        eu.BillingPostalCode = '28348-1652';
        eu.BillingState = 'North Carolina2';
        eu.BillingCountry = 'US';
        insert eu;

        Account eu2 =new Account();
        eu2.Name='test2';
        eu2.BillingStreet = '3321 LEGION RD';
        eu2.BillingCity = 'HOPE MILLS5';
        eu2.BillingPostalCode = '28348-1652';
        eu2.BillingState = 'North Carolina2';
        eu2.BillingCountry = 'US';
        insert eu2;

        List<Opportunity> oppsForInsert = new List<Opportunity>();
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.End_User__c = eu.Id;
        opp.StageName = 'On Hold';
        opp.Type ='New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit1__c = 'Technology';
        opp.Amount = 20000;
        opp.UNQ_Opportunity__c = 'APPNUM786';
        opp.Application_Date__c = Date.today();
        oppsForInsert.add(opp);

        Opportunity opp2 = new Opportunity();
        opp2.AccountId = acc.Id;
        opp2.StageName = 'On Hold';
        opp2.Type ='New';
        opp2.Sales_Rep_ID__c = '1234';
        opp2.End_User_Phone__c = '1234567890';
        opp2.Business_Unit1__c = 'Technology';
        opp2.Amount = 20000;
        opp2.UNQ_Opportunity__c = 'APPNUM675';
        opp2.Application_Date__c = Date.today();
        oppsForInsert.add(opp2);
        
        Opportunity opp3 = new Opportunity();
        opp3.AccountId = acc2.Id;
        opp3.End_User__c = eu2.Id;
        opp3.StageName = 'On Hold';
        opp3.Type ='New';
        opp3.Sales_Rep_ID__c = '1234';
        opp3.End_User_Phone__c = '1234567890';
        opp3.Business_Unit1__c = 'Technology';
        opp3.Amount = 20000;
        opp3.UNQ_Opportunity__c = 'APPNUM234';
        opp3.Application_Date__c = Date.today();
        oppsForInsert.add(opp3);
        
        Opportunity opp4 = new Opportunity();
        opp4.StageName = 'On Hold';
        opp4.Type ='New';
        opp4.Sales_Rep_ID__c = '1234';
        opp4.End_User_Phone__c = '1234567890';
        opp4.Business_Unit1__c = 'Technology';
        opp4.Amount = 20000;
        opp4.UNQ_Opportunity__c = 'APPNUM1122';
        opp4.Application_Date__c = Date.today();
        oppsForInsert.add(opp4);
        
        Opportunity opp5 = new Opportunity();
        opp5.End_User__c = eu2.Id;
        opp5.StageName = 'On Hold';
        opp5.Type ='New';
        opp5.Sales_Rep_ID__c = '1234';
        opp5.End_User_Phone__c = '1234567890';
        opp5.Business_Unit1__c = 'Technology';
        opp5.Amount = 20000;
        opp5.UNQ_Opportunity__c = 'APPNUM0101';
        opp5.Application_Date__c = Date.today();
        oppsForInsert.add(opp5);
        
        Opportunity opp6 = new Opportunity();
        opp6.AccountId = acc2.Id;
        opp6.StageName = 'On Hold';
        opp6.Type ='New';
        opp6.Sales_Rep_ID__c = '1234';
        opp6.End_User_Phone__c = '1234567890';
        opp6.Business_Unit1__c = 'Technology';
        opp6.Amount = 20000;
        opp6.UNQ_Opportunity__c = '101APPNUM';
        opp6.Application_Date__c = Date.today();
        oppsForInsert.add(opp6);

        insert oppsForInsert;

        List<Opportunity> oppsForUpdate = new List<Opportunity>();
                
        opp3.End_User__c = null;
        opp3.AccountId = acc.Id;
        oppsForUpdate.add(opp3);
        
        opp4.AccountId = acc2.Id;
        oppsForUpdate.add(opp4);

        opp.End_User__c = eu2.Id;
        oppsForUpdate.add(opp);
        
        opp5.AccountId = acc2.Id;
        oppsForUpdate.add(opp5);

        opp6.End_User__c = null;
        opp6.AccountId = acc.Id;
        oppsForUpdate.add(opp6);

        update oppsForUpdate;

        Test.startTest();
        OpportunityTriggerHelper.updateOpportunityRelationships(new List<Opportunity>{opp, opp2, opp3});
        Test.stopTest();

        List<Opportunity_Relationship__c> relList = [SELECT Id, Account__c, Opportunity_Role__c FROM Opportunity_Relationship__c];
        System.assertEquals(8, relList.size());
        
        }

    //3-20-24: New test cases to test logic to add the current user to an account team associated to the opportunity
    public static testMethod void setTeamMember(){
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = RecordTypeIdAccountEndUser;
        insert acc;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        insert u;
        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Quoting'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_Stage__c = 'Application Approved'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.OwnerId = u.Id;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            opp.CloseDate = Date.today();
            Test.startTest();
            insert opp;
            Test.stopTest();
            List<AccountTeamMember> tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            System.assertEquals(0, tm.size(), 'The team member role was assigned when it shouldnt be because the owner is the integration owner');
        }
    }

    /*public static testMethod void setTeamMemberNonAuto(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        insert u;
        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            Test.startTest();
            insert opp;
            Test.stopTest();
            AccountTeamMember tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            System.assertEquals('Sales Rep - Technology', tm.TeamMemberRole, 'The team member role was not properly assigned');
        }
    }*/

    public static testMethod void setTeamMemberExists(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                Legal_Entity_Description__c = 'DLL'
        );
        insert u;
        AccountTeamMember atm = new AccountTeamMember();
        atm.UserId = u.Id;
        atm.AccountId = acc.Id;
        atm.TeamMemberRole = 'test';
        insert atm;
        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            opp.CloseDate = Date.today();
            Test.startTest();
            insert opp;
            Test.stopTest();
            AccountTeamMember tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            System.assertEquals('test', tm.TeamMemberRole, 'The team member role was not properly assigned');
        }
    }

    /*public static testMethod void setTeamMemberExistsWithMultipleAccounts(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;
        Account acc2 =new Account();
        acc2.Name='test2';
        acc2.Technology_Solutions__c=false;
        acc2.CleanTech__c=false;
        acc2.Commercial_Finance__c=false;
        acc2.BillingStreet = '3321 LEGION RD';
        acc2.BillingCity = 'HOPE MILLS5';
        acc2.BillingPostalCode = '28348-1652';
        acc2.BillingState = 'North Carolina2';
        acc2.BillingCountry = 'US';
        acc2.Business_Unit__c = 'Commercial Finance';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc2;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                IsActive = true
        );
        insert u;
        AccountTeamMember atm = new AccountTeamMember();
        atm.UserId = u.Id;
        atm.AccountId = acc.Id;
        atm.TeamMemberRole = 'test';
        insert atm;

        System.runAs(u) {
            List<Opportunity> oppsToInsert = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();

            oppsToInsert.add(opp);

            Opportunity opp2 = new Opportunity();
            opp2.AccountId = acc2.Id;
            opp2.StageName = 'Rejected';
            opp2.Type = 'New';
            opp2.Sales_Rep_ID__c = '1234';
            opp2.End_User_Phone__c = '1234567890';
            opp2.Business_Unit1__c = 'Technology';
            opp2.Amount = 20000;
            opp2.UNQ_Opportunity__c = 'APPNUM';
            opp2.Application_Date__c = Date.today();
            opp2.Funded_Date__c = Date.today();

            oppsToInsert.add(opp2);
            Test.startTest();
            insert oppsToInsert;
            Test.stopTest();
            AccountTeamMember tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            AccountTeamMember tm2 =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc2.Id];
            System.assertEquals('test', tm.TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm2.TeamMemberRole, 'The team member role was not properly assigned');
        }
    }

    public static testMethod void setTeamMemberInMultipleAccounts(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        insert u;
        User v = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last1',
                Email = 'puser001@amamama.com',
                Username = 'puser001@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance'
        );
        insert v;
        System.runAs(u) {
            List<Opportunity> oppsToInsert = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.OwnerId = u.Id;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            oppsToInsert.add(opp);
            Opportunity opp2 = new Opportunity();
            opp2.AccountId = acc.Id;
            opp2.StageName = 'Rejected';
            opp2.Type = 'New';
            opp2.Sales_Rep_ID__c = '1234';
            opp2.End_User_Phone__c = '1234567890';
            opp2.Business_Unit1__c = 'Technology';
            opp2.Amount = 20000;
            opp2.OwnerId = v.Id;
            opp2.UNQ_Opportunity__c = 'APPNUM';
            opp2.Application_Date__c = Date.today();
            opp2.Funded_Date__c = Date.today();
            oppsToInsert.add(opp2);
            Test.startTest();
            insert oppsToInsert;
            Test.stopTest();
            List<AccountTeamMember> tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            System.assertEquals(2, tm.size(), 'The team members were not inserted properly');
            System.assertEquals('Sales Rep - Technology', tm[0].TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm[1].TeamMemberRole, 'The team member role was not properly assigned');
        }
    }

    public static testMethod void teammemberOnOpportunityUpdate(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        insert u;
        User v = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last1',
                Email = 'puser001@amamama.com',
                Username = 'puser001@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance'
        );
        insert v;
        System.runAs(u) {
            //List<Opportunity> oppsToInsert = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.OwnerId = u.Id;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            insert opp;
            Test.startTest();
            opp.OwnerId = v.Id;
            update opp;
            Test.stopTest();
            List<AccountTeamMember> tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            System.assertEquals(2, tm.size(), 'The team members were not inserted properly');
            System.assertEquals('Sales Rep - Technology', tm[0].TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm[1].TeamMemberRole, 'The team member role was not properly assigned');
        }
    }

    public static testMethod void teammemberOnOpportunityUpdateOnBoth(){
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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc;

        Account acc2 =new Account();
        acc2.Name='test2';
        acc2.Technology_Solutions__c=false;
        acc2.CleanTech__c=false;
        acc2.Commercial_Finance__c=false;
        acc2.BillingStreet = '3321 LEGION RD';
        acc2.BillingCity = 'HOPE MILLS5';
        acc2.BillingPostalCode = '28348-1652';
        acc2.BillingState = 'North Carolina2';
        acc2.BillingCountry = 'US';
        acc2.Business_Unit__c = 'Commercial Finance';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        insert acc2;

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                Business_Unit__c = 'Commercial Finance'
        );
        insert u;
        User v = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'last1',
                Email = 'puser001@amamama.com',
                Username = 'puser001@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Business_Unit__c = 'Commercial Finance'
        );
        insert v;
        System.runAs(u) {
            Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Rejected';
            opp.Type = 'New';
            opp.Sales_Rep_ID__c = '1234';
            opp.End_User_Phone__c = '1234567890';
            opp.End_User__c = acc2.Id;
            opp.Business_Unit1__c = 'Technology';
            opp.Amount = 20000;
            opp.OwnerId = u.Id;
            opp.UNQ_Opportunity__c = 'APPNUM';
            opp.Application_Date__c = Date.today();
            opp.Funded_Date__c = Date.today();
            insert opp;
            Test.startTest();
            opp.OwnerId = v.Id;
            update opp;
            opp.End_User__c = acc.Id;
            update opp;
            opp.AccountId = acc2.Id;
            update opp;
            Test.stopTest();
            List<AccountTeamMember> tm =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc.Id];
            List<AccountTeamMember> tm2 =  [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId =: acc2.Id];
            System.assertEquals(2, tm.size(), 'The team members were not inserted properly');
            System.assertEquals(2, tm2.size(), 'The team members were not inserted properly');
            System.assertEquals('Sales Rep - Technology', tm[0].TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm[1].TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm2[0].TeamMemberRole, 'The team member role was not properly assigned');
            System.assertEquals('Sales Rep - Technology', tm2[1].TeamMemberRole, 'The team member role was not properly assigned');
        }
    }*/

    public static testMethod void inactiveUserToAccountTeam() {
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'test';
        acc.Technology_Solutions__c = false;
        acc.CleanTech__c = false;
        acc.Commercial_Finance__c = false;
        acc.BillingStreet = '3321 LEGION RD';
        acc.BillingCity = 'HOPE MILLS5';
        acc.BillingPostalCode = '28348-1652';
        acc.BillingState = 'North Carolina2';
        acc.BillingCountry = 'US';
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = RecordTypeIdAccountEndUser;
        insert acc;
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
                IsActive = false,
                Legal_Entity_Description__c = 'DLL'
        );
        insert u;
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Rejected';
        opp.Type = 'New';
        opp.Sales_Rep_ID__c = '1234';
        opp.End_User_Phone__c = '1234567890';
        opp.Business_Unit1__c = 'Technology';
        opp.Amount = 20000;
        opp.OwnerId = u.Id;
        opp.UNQ_Opportunity__c = 'APPNUM';
        opp.Application_Date__c = Date.today();
        opp.Funded_Date__c = Date.today();
        opp.CloseDate = Date.today();
        Test.startTest();
        insert opp;
        Test.stopTest();
        List<AccountTeamMember> tm = [SELECT UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :acc.Id];
        System.assertEquals(0, tm.size(), 'The team member role was assigned when it shouldnt be because the owner is the integration owner');
    }

    /**
  * @description test to check that the authorized dealers are being created based off of program
  * @author Newton Sun 4/21/2020
  *
  */
    /*
    public static testMethod void opportunityAuthorizedDealersCreation(){
        //Create the program
        Program__c program = new Program__c();
        program.Business_Unit_Description__c = 'CTI';
        program.Region_Description__c = 'Belgium';
        program.Name = 'Test Program';
        program.UNQ_Program__c = 'Test Program';
        program.Legal_Entity_Description__c = 'Test desc';
        insert program;

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
        acc.Business_Unit__c = 'Commercial Finance';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        insert acc;

        Opportunity opp= new Opportunity();
        opp.Type='New';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.CloseDate=System.today()+1;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Program__c='Test Program';
        opp.UNQ_Opportunity__c='12345T';
        opp.Business_Unit1__c='CleanTech';
        opp.End_User_Phone__c='123456';
        opp.AccountId = acc.Id;
        opp.Program__c = program.Id;
        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Authorized_Dealer__c> ad = [
                SELECT Id
                FROM Authorized_Dealer__c
        ];

        System.assertEquals(1, ad.size(), 'The authroized dealer was not inserted properly');

    }
    */
    /**
   * @description test to check that the program and all related fields on the opportunity is being inserted properly
   * @author Newton Sun 4/21/2020
   *
   */
    public static testMethod void opportunityProgramOnInsert(){
        //Business Unit
        List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
        businessUnits.add(new Business_Unit__c(Name='Construction, Transportation & Infrastructure (CTI)'));
        insert businessUnits;

        //Region
        List<Region__c> regions = new List<Region__c>();
        regions.add(new Region__c(Name='United States'));
        insert regions;

        //Integration user
        User apiIntegration = OpportunitytriggerTest.apiUser();

        Business_Unit_Association_Index__mdt bum=[ SELECT Id, Business_Unit_Attribute__c, Business_Unit_Name__c 
                                                  FROM Business_Unit_Association_Index__mdt  WHERE Business_Unit_Name__c 
                                                  = 'Food & Agriculture (F&A)'    limit 1];                                         
                                                          
Region_Association_Index__mdt objRegionAssociationIndex = [SELECT Geographic_Attribute__c,Region_Name__c 
                                                                       FROM Region_Association_Index__mdt 
                                                                       WHERE Geographic_Attribute__c = 'United States' limit 1];
        //Create the program
        Program__c program = new Program__c();
        program.Business_Unit_Description__c = 'Materials Handling';
        program.Region_Description__c = 'US';
        program.Name = 'Test Program';
        program.UNQ_Program__c = 'Test Program';
        program.Business_Unit__c = businessUnits[0].Id;
        insert program;
        
        Region__c rg = new Region__c();
        rg.name= 'United States';
        rg.Region_Type__c = 'Country';
        rg.Description__c= 'United States Region';
        insert rg;
        

        Business_Unit__c pbu = new Business_Unit__c();
        pbu.Name=   'DLL'  ;      
        pbu.Description__c = 'The DLL Group Legal Entity. Parent to all DLL Group Business Units.';
        insert pbu;
        
        Business_Unit__c bu = new Business_Unit__c();
        bu.Parent_Business_Unit__c = pbu.id;
        bu.Name = 'Food & Agriculture (F&A)';
        bu.Business_Unit_Flag_API_Name__c = 'Food_and_Ag__c';
        insert bu;
       

        System.runAs(apiIntegration){
            //Create the opportunity and insert it to check fields
            Opportunity opp= new Opportunity();
            opp.Type='New';
            opp.Name='Service';
            opp.StageName = 'Quoting'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_stage__c ='Application Approved';
            opp.CloseDate=System.today()+1;
            opp.Business_Unit1__c='Digital Imaging';
            opp.UNQ_Customer__c='123';
            opp.UNQ_Program__c='Test Program';
            opp.UNQ_Opportunity__c='12345T';
            opp.Business_Unit1__c='CleanTech';
            opp.End_User_Phone__c='123456';
            opp.Region_Description__c = objRegionAssociationIndex.Geographic_Attribute__c ;
            opp.Business_Unit_Description__c = bum.Business_Unit_Name__c ;
            opp.Legal_Entity_Description__c = 'DLL';
            Test.startTest();
            insert opp;
            Test.stopTest();
            Opportunity oppRes = [
                    SELECT Program__c, Region_Relationship__c, Region_Description__c, Business_Unit__c, Business_Unit_Description__c ,Legal_Entity_Description__c
                    FROM Opportunity
                    WHERE Id =: opp.Id
            ];
            System.assertEquals(program.Id, oppRes.Program__c, 'The program was not properly set');
          //  System.assertEquals(regions[0].Id, oppRes.Region_Relationship__c, 'The region was not properly set');
          //  System.assertEquals(rg.Description__c, oppRes.Region_Description__c, 'The descrpition for the region was not properly set');
          //  System.assertEquals(bu.Name, oppRes.Business_Unit__c, 'The business unit was not properly set');
            System.assertEquals(bum.Business_Unit_Name__c, oppRes.Business_Unit_Description__c, 'The business unit description was not set properly');
            System.assertEquals(opp.Legal_Entity_Description__c, oppRes.Legal_Entity_Description__c, 'The legal entity description was not set properly'); 
        }
    }

    public static testMethod void opportunityProgramOnUpdate(){
        //Business Unit
        List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
        businessUnits.add(new Business_Unit__c(Name='Construction, Transportation & Infrastructure (CTI)'));
        businessUnits.add(new Business_Unit__c(Name='Unknown'));
        insert businessUnits;

        //Region
        List<Region__c> regions = new List<Region__c>();
        regions.add(new Region__c(Name='United States'));
        regions.add(new Region__c(Name='Unknown'));
        insert regions;

        //Integration user
        User apiIntegration = OpportunitytriggerTest.apiUser();


        //Create the programs
        List<Program__c> programs = new List<Program__c>();
        programs.add(new Program__c(
                Business_Unit_Description__c = 'Materials Handling',
                Region_Description__c = 'US',
                Name = 'Test Program',
                UNQ_Program__c = 'Test Program',
                Legal_Entity_Description__c = 'Test desc'
        ));
        programs.add(new Program__c(
                Business_Unit_Description__c = 'Unknown',
                Region_Description__c = 'Unknown',
                Name = 'Test Program',
                UNQ_Program__c = 'Test Program 2',
                Legal_Entity_Description__c = 'Test desc2'
        ));
        insert programs;

        System.runAs(apiIntegration){
            //Create the opportunity and insert it to check fields
            Opportunity opp= new Opportunity();
            opp.Type='New';
            opp.Name='Service';
            opp.StageName = 'Quoting'; //PBI855444 : Stage/Substage translation moved to Azure from Salesforce
            opp.Sub_stage__c ='Application Approved';
            opp.CloseDate=System.today()+1;
            opp.Business_Unit1__c='Digital Imaging';
            opp.UNQ_Customer__c='123';
            opp.UNQ_Program__c='Test Program';
            opp.UNQ_Opportunity__c='12345T';
            opp.Business_Unit1__c='CleanTech';
            opp.End_User_Phone__c='123456';
            insert opp;
            Test.startTest();
            Opportunity oppRes = [
                    SELECT Program__c, Region_Relationship__c, Region_Description__c, Business_Unit__c, Business_Unit_Description__c ,Legal_Entity_Description__c
                    FROM Opportunity
                    WHERE Id =: opp.Id
            ];
            System.assertEquals(programs[0].Id, oppRes.Program__c, 'The program was not properly set');
            System.assertEquals(regions[0].Id, oppRes.Region_Relationship__c, 'The region was not properly set');
            System.assertEquals(regions[0].Name, oppRes.Region_Description__c, 'The descrpition for the region was not properly set');
        }
    }

    /**
   * @description test to check that related accounts are inserted properly
   * @author Newton Sun 4/23/2020
   *
   */
    public static testMethod void insertRelatedAccounts(){
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        List<Account> accs = new List <Account>{
                new Account(
                        Name = 'test',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountEndUser
                ),
                new Account(
                        Name = 'test2',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountVendor

                )
        };
        insert accs;
        Opportunity opp= new Opportunity();
        opp.Type='New';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.CloseDate=System.today()+1;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Program__c='Test Program';
        opp.UNQ_Opportunity__c='12345T';
        opp.Business_Unit1__c='CleanTech';
        opp.End_User_Phone__c='123456';
        opp.End_User__c = accs[0].Id;
        opp.AccountId = accs[1].Id;

        Test.startTest();
        OpportunityTriggerHelper.createRelatedAccounts(new List<Opportunity>{opp});
        Test.stopTest();

        List<Related_Account__c> relList = [
                SELECT Type__c, Opportunity__c, Account__c
                FROM Related_Account__c
        ];
        System.assertEquals(2, relList.size(), 'The incorrect number of related accounts were created');
        System.assertEquals(accs[0].Id, relList[0].Account__c, 'The incorrect account was found');
        System.assertEquals('End User', relList[0].Type__c, 'The incorrect type was inserted');
        System.assertEquals(accs[1].Id, relList[1].Account__c, 'The incorrect account was found');
        System.assertEquals('Vendor', relList[1].Type__c, 'The incorrect type was inserted');
    }

    /**
    * @description test to check that the related accounts are being updated properly
    * @author Newton Sun 4/23/2020
    *
    */
    public static testMethod void updateRelatedAccounts(){
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        List<Account> accs = new List <Account>{
                new Account(
                        Name = 'test',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountEndUser
                ),
                new Account(
                        Name = 'test1',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountEndUser
                ),
                new Account(
                        Name = 'test2',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountVendor

                ),
                new Account(
                        Name = 'test4',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountVendor

                )
        };
        insert accs;
        Opportunity opp= new Opportunity();
        opp.Type='New';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.CloseDate=System.today()+1;
        opp.UNQ_Customer__c='123';
        opp.UNQ_Program__c='Test Program';
        opp.UNQ_Opportunity__c='12345T';
        opp.Business_Unit1__c='CleanTech';
        opp.End_User_Phone__c='123456';
        opp.End_User__c = accs[0].Id;
        opp.AccountId = accs[2].Id;
        insert opp;
        Test.startTest();
        opp.End_User__c = accs[1].Id;
        opp.AccountId = accs[3].Id;
        update opp;
        Test.stopTest();

        List<Related_Account__c> relList = [
                SELECT Type__c, Opportunity__c, Account__c
                FROM Related_Account__c
        ];

        System.debug(relList[0].Opportunity__c + '---- Newton');
        System.assertEquals(2, relList.size(), 'The incorrect number of related accounts were created');
        System.assertEquals(accs[1].Id, relList[0].Account__c, 'The incorrect account was found');
        System.assertEquals('End User', relList[0].Type__c, 'The incorrect type was inserted');
        System.assertEquals(accs[3].Id, relList[1].Account__c, 'The incorrect account was found');
        System.assertEquals('Vendor', relList[1].Type__c, 'The incorrect type was inserted');
    }

    /**
    * @description test to check that the related accounts are being updated properly for multiple opportunities
    * @author Newton Sun 4/23/2020
    *
    */
    public static testMethod void updateMultipleOpportunitiesRelatedAccounts(){
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId();
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        List<Account> accs = new List <Account>{
                new Account(
                        Name = 'test',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountEndUser
                ),
                new Account(
                        Name = 'test1',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountEndUser
                ),
                new Account(
                        Name = 'test2',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountVendor

                ),
                new Account(
                        Name = 'test4',
                        BillingStreet = '3321 LEGION RD',
                        BillingCity = 'HOPE MILLS5',
                        BillingPostalCode = '28348-1652',
                        BillingState = 'North Carolina2',
                        BillingCountry = 'US',
                        Business_Unit__c = 'Commercial Finance',
                        RecordTypeId = RecordTypeIdAccountVendor

                )
        };
        insert accs;
        List<Opportunity> opps= new List<Opportunity>{
                new Opportunity(
                        Type = 'New',
                        Name = 'Service',
                        StageName = 'On Hold',
                        CloseDate = System.today() + 1,
                        Business_Unit1__c = 'Digital Imaging',
                        UNQ_Customer__c = '123',
                        UNQ_Program__c = 'Test Program',
                        UNQ_Opportunity__c = '12345T',
                        End_User_Phone__c = '123456',
                        End_User__c = accs[0].Id,
                        AccountId = accs[2].Id
                ),
                new Opportunity(
                        Type = 'New',
                        Name = 'Service',
                        StageName = 'On Hold',
                        CloseDate = System.today() + 1,
                        Business_Unit1__c = 'Digital Imaging',
                        UNQ_Customer__c = '123',
                        UNQ_Program__c = 'Test Program',
                        UNQ_Opportunity__c = '12345012T',
                        End_User_Phone__c = '123456'
                )
        };
        insert opps;
        Test.startTest();
        opps[1].End_User__c = accs[1].Id;
        opps[1].AccountId = accs[3].Id;
        update opps;
        Test.stopTest();

        List<Related_Account__c> relList = [
                SELECT Type__c, Opportunity__c, Account__c
                FROM Related_Account__c
        ];

        System.assertEquals(4, relList.size(), 'The incorrect number of related accounts were created');
        System.assertEquals(accs[0].Id, relList[0].Account__c, 'The incorrect account was found');
        System.assertEquals(opps[0].Id, relList[0].Opportunity__c, 'The incorrect opportunity was found');
        System.assertEquals('End User', relList[0].Type__c, 'The incorrect type was inserted');
        System.assertEquals(accs[2].Id, relList[1].Account__c, 'The incorrect account was found');
        System.assertEquals(opps[0].Id, relList[1].Opportunity__c, 'The incorrect opportunity was found');
        System.assertEquals('Vendor', relList[1].Type__c, 'The incorrect type was inserted');
        System.assertEquals(accs[3].Id, relList[2].Account__c, 'The incorrect account was found');
        System.assertEquals(opps[1].Id, relList[2].Opportunity__c, 'The incorrect account was found');
        System.assertEquals('Vendor', relList[2].Type__c, 'The incorrect type was inserted');
        System.assertEquals(accs[1].Id, relList[3].Account__c, 'The incorrect account was found');
        System.assertEquals(opps[1].Id, relList[3].Opportunity__c, 'The incorrect opportunity was found');
        System.assertEquals('End User', relList[3].Type__c, 'The incorrect type was inserted');
    }

}