/*PBI:665017:Opportunity Team - End User Visibility Enable: DLL on Demand
 * Opportunity access automaticall shared. Enduser account is apex shared.
 * version1: Geetha Bharadwaj
 * Commenting out the logic for Apex Sharing for DLL on Demand
 */
@isTest
public class OpportunityTeamMemberTriggerTest {
   /* @isTest static void oppTeamMem_M1(){
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
        insert x;
        system.debug('x= ' +x);
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
        
        //insert Opp team member - Test Sharing
        
        OpportunityTeamMember oppTeamMem = new OpportunityTeamMember();
        oppTeamMem.OpportunityId = opp.Id;
        oppTeamMem.OpportunityAccessLevel = 'read';
        oppTeamMem.TeamMemberRole = 'Partner Admin';
        oppTeamMem.UserId = x.Id;
        insert oppTeamMem;
         
       
        
       
        List<OpportunityShare> oppshareList = [SELECT Id,OpportunityAccessLevel,OpportunityId,RowCause,UserOrGroup.FirstName 
                                               FROM OpportunityShare 
                                               where OpportunityId = :opp.Id
                                               and RowCause = 'Team'
                                               and OpportunityAccessLevel = 'read' ];
        system.debug('oppshareList ' +oppshareList);
        system.assertEquals(1, oppshareList.size());
        
        //delete OppteamMember
        
        List<OpportunityTeamMember> opptmlist = [select id from OpportunityTeamMember 
                                                 where OpportunityId = :opp.Id
                                                 and  UserId = :x.Id];
        
        delete opptmlist;
        
        List<OpportunityShare> oppshareList1 = [SELECT Id,OpportunityAccessLevel,OpportunityId,RowCause,UserOrGroup.FirstName 
                                               FROM OpportunityShare 
                                               where OpportunityId = :opp.Id
                                               and RowCause = 'Team'
                                               and OpportunityAccessLevel = 'read' ];
        
        system.assertEquals(0,oppshareList1.size());
        
    } */
}