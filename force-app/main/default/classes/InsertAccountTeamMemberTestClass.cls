@isTest
public class InsertAccountTeamMemberTestClass {
    
    @isTest static void method1(){
        User us = [Select Id from User where Profile.name = 'System Administrator' and isActive = true limit 1];   
        List<User> uslist = new List<User>();
        
            User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'uuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Food and Agriculture',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'); 
        uslist.add(u);
       // insert u;
        
        User w = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'wuser@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Golf & Turf',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'
        ); 
         uslist.add(w);
        //insert w;
        
         UserRole ur = [Select Id from UserRole where Name = 'Sales Support (F&A)'];

            User x = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last1',
            Email = 'puser000@amamama.com1',
            Username = 'wuser@amamama.com1' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Golf & Turf',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines',
            UserRoleId = ur.id
        ); 
        //insert x;
         uslist.add(x);
        system.runAs(us){
            insert uslist;
        }
       
        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
        sr.Sales_Rep__c = u.Id;
        sr.Sales_Rep_ID__c='1234';
        sr.Source_System__c = 'GDW_US_Desmoines';
        insert sr;
        
        Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
        sr2.Sales_Rep__c = w.Id;
        sr2.Sales_Rep_ID__c='1235';
        sr2.Source_System__c = 'GDW_US_Desmoines';
        insert sr2;
        
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Type__c='Dealer';
        sys.Short_Dealer__c = '100';
        sys.Inside_Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
        sys.Outside_Sales_Rep_ID__c = sr2.Sales_Rep_ID__c;
        sys.Source_System__c = 'GDW_US_Desmoines';
        sys.Dealer_Status__c = 'ACTIVE';
        insert sys;
        
        InsertAccountTeamMember sch = new InsertAccountTeamMember();
        Test.startTest();
        sch.execute(null);      
        test.stopTest();
       
        List<System_ID__c> sid = [Select id,Account__c  from system_ID__c where id=:sys.Id];
        List<AccountTeamMember> acctm = [Select Id from AccountTeamMember where AccountId =: sid[0].Account__c];
        system.assertEquals(3, acctm.size());
       
    }
    
    @isTest static void method2(){
      
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'uuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Golf & Turf',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'); 
        insert u;
        
        User w = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'wuser@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Golf & Turf',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'
        ); 
        insert w;

        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
        sr.Sales_Rep__c = u.Id;
        sr.Sales_Rep_ID__c='1234';
        
        sr.Source_System__c = 'GDW_US_Desmoines';
        
        insert sr;
        
        Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
        sr2.Sales_Rep__c = w.Id;
        sr2.Sales_Rep_ID__c='1235';
        
        sr2.Source_System__c = 'GDW_US_Desmoines';
        insert sr2;
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Inside_Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
        sys.Outside_Sales_Rep_ID__c = sr2.Sales_Rep_ID__c;
        sys.Source_System__c = 'GDW_US_Desmoines';
        sys.Dealer_Status__c = 'ACTIVE';
        sys.Type__c='Dealer';
        sys.Short_Dealer__c = '100';
        
        insert sys;
      
        InsertAccountTeamMember sch = new InsertAccountTeamMember();
        Test.startTest();
        sch.execute(null);
        test.stopTest();
        
        List<System_ID__c> sid = [Select id,Account__c  from system_ID__c where id=:sys.Id];
        List<AccountTeamMember> acctm = [Select Id from AccountTeamMember where AccountId =: sid[0].Account__c];
        system.assertEquals(3, acctm.size());
        
    }
    
    @isTest static void method3(){
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'uuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Food and Agriculture',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'); 
        insert u;
        
        User w = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'wuser@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Unit__c = 'Food and Agriculture',
            Legal_Entity_Description__c = 'DLL',
            DB_Region__c =  'USA - Des Moines'
        ); 
        insert w;
                
        
        Sales_Rep_ID__c sr=new Sales_Rep_ID__c();
        sr.Sales_Rep__c = u.Id;
        sr.Sales_Rep_ID__c='1234';
        
        sr.Source_System__c = 'GDW_US_Desmoines';
        
        insert sr;
        
        Sales_Rep_ID__c sr2 =new Sales_Rep_ID__c();
        sr2.Sales_Rep__c = w.Id;
        sr2.Sales_Rep_ID__c='1235';
        
        sr2.Source_System__c = 'GDW_US_Desmoines';
        insert sr2;
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='1234';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Inside_Sales_Rep_ID__c = sr.Sales_Rep_ID__c;
        sys.Outside_Sales_Rep_ID__c = sr2.Sales_Rep_ID__c;
        sys.Source_System__c = 'GDW_US_Desmoines';
        sys.Dealer_Status__c = 'ACTIVE';
        sys.Type__c='Dealer';
        sys.Short_Dealer__c = '100';
        
        insert sys;
        
        InsertAccountTeamMember sch = new InsertAccountTeamMember();
        Test.startTest();
        sch.execute(null);
        test.stopTest();
       
        List<System_ID__c> sid = [Select id,Account__c  from system_ID__c where id=:sys.Id];
        List<AccountTeamMember> acctm = [Select Id from AccountTeamMember where AccountId =: sid[0].Account__c];
        system.assertEquals(3, acctm.size());
        
    }
   
}