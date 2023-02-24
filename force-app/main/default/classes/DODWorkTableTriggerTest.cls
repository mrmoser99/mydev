/**********************************************************************************************************
Class :  OpportunitytriggerTest
Description : Test class for DODWorkTable Helper Class

Date/Sprint		PBI/Description
PI-23-Q1-02		922613 - Modify Opp Trigger and Develop async process, worktable to update application and asset(Dibyendu)
  
***********************************************************************************************************/
@IsTest
public class DODWorkTableTriggerTest {
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

}