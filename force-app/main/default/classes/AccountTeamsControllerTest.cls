@isTest
public class AccountTeamsControllerTest {
    static testmethod void testgetAccountTeamList() {
       
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
       
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Digital Imaging'].Id;
        u.LastName = 'last';
        u.Email = 'puser000@amamama.com';
        u.Username = 'puser000@amamama.com' + System.currentTimeMillis();
        u.CompanyName = 'TEST';
        u.Title = 'title';
        u.Alias = 'alias';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.Business_Unit__c = 'Digital Imaging';
        u.Legal_Entity_Description__c = 'DLL';
        insert u;
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Digital Imaging'].Id;
        u2.LastName = 'last';
        u2.Email = 'puser000@amamama.com';
        u2.Username = 'puser000@amamama.com' + System.currentTimeMillis();
        u2.CompanyName = 'TEST';
        u2.Title = 'title';
        u2.Alias = 'alias';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        u2.LocaleSidKey = 'en_US';
        u2.Business_Unit__c = 'Digital Imaging';
        u2.Legal_Entity_Description__c = 'DLL';
        insert u2;
        
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = acc.Id;
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'None';
        atm.ContactAccessLevel = 'None';
        atm.OpportunityAccessLevel = 'None';
        atm.UserID = u.Id;
        insert atm;

        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.AccountId = acc.Id;
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'None';
        atm2.ContactAccessLevel = 'None';
        atm2.OpportunityAccessLevel = 'None';
        atm2.UserID = u2.Id;
        insert atm2;
        
        List<AccountTeamMember> atmList = AccountTeamsController.getAccountTeamsList(acc.Id);
        
        Map<String,String> atmDeleteResponse = AccountTeamsController.deleteTeamList(atm.Id, acc.Id);
      

  }
        
 }