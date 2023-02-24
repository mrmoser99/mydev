/**
 * @Created by Traction Team on 09/30/2020.
 */
/**********************************************************************************************************
   Class :  CaseTriggerHelperTest
   Description : Test Class for CaseTriggerHelper

   Date/Sprint		PBI/Description
   PI-23-Q1-1		857117 - Rework: Automation - Updated Case Type and Sub-Type
**********************************************************************************************************/
@isTest
private class CaseTriggerHelperTest {
    
    @isTest static void testAllMilestonesAreClosed() {

        Test.startTest();
        List<RecordType> accrt = [SELECT ID, name FROM RecordType where SobjectType = 'Account' and name = 'End User'];
        List<RecordType> rt = [SELECT Id FROM RecordType where SobjectType = 'Case' and DeveloperName = 'Canada'];
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = accrt[0].id;
        insert acc;
        
        region__c rg = new region__c();
        rg.Region_Type__c = 'Country';
        rg.name = 'Canada';
        rg.Description__c = 'Canada Region';
        insert rg;
        
        Region_Assignment__c rsa = new Region_Assignment__c();//Added Region Assignment to fix Test Class failure
        rsa.Active__c = true;
        rsa.Region__c = rg.Id;
        rsa.User__c = System.UserInfo.getUserId();
        Insert rsa;
        
        Case cs = new Case();
        cs.RecordTypeId = rt[0].Id;
        cs.Type = 'Contract Change';
        cs.Sub_Type__c = 'Update';
        cs.Department__c = 'Portfolio Services';
        cs.End_User_First_Name__c = 'Test First Name';
        cs.End_User_Last_Name__c = 'Test Last Name';
        cs.End_User_Email__c = 'test@test.com';
        cs.Region__c = rg.id;
        insert cs;
        
        cs.Status = 'Closed';
        cs.AccountId = acc.id;
        update cs;
        
        List<CaseMilestone> lstCaseMilestones = [SELECT Id, CaseId, MilestoneTypeId, IsCompleted,completionDate FROM CaseMilestone 
                                                     WHERE caseId = :cs.Id];
        System.assertEquals(true, lstCaseMilestones[0].IsCompleted, 'Milestone is not completed');
        Test.stopTest();
    }
    @isTest static void testFirstResponseClosed() {
        Final string FIRST_RESPONSE_48_HOURS = 'First Response 48 Hours';
        Test.startTest();
        
        List<RecordType> rt = [SELECT Id FROM RecordType where SobjectType = 'Case' and DeveloperName = 'Canada'];
        
        Region__c rg = new Region__c();
        rg.Region_Type__c = 'Country';
        rg.name = 'Canada';
        rg.Description__c = 'Canada Region';
        insert rg;
        
        Region_Assignment__c rsa = new Region_Assignment__c();//Added Region Assignment to fix Test Class failure
        rsa.Active__c = true;
        rsa.Region__c = rg.Id;
        rsa.User__c = System.UserInfo.getUserId();
        Insert rsa;
        
        Case cs = new Case();
        cs.RecordTypeId = rt[0].Id;
        cs.Type = 'Contract Change';
        cs.Sub_Type__c = 'Update';
        cs.Department__c = 'Portfolio Services';
        cs.End_User_First_Name__c = 'Test First Name';
        cs.End_User_Last_Name__c = 'Test Last Name';
        cs.End_User_Email__c = 'test@test.com';
        cs.Region__c = rg.id;
        insert cs;
        
        cs.Status = 'Waiting For Customer';
        update cs;
        
        List<MilestoneType> lstMilestones= [SELECT Id, Name FROM MilestoneType Where Name =: FIRST_RESPONSE_48_HOURS];
        
        List<CaseMilestone> lstCaseMilestones = [SELECT Id, CaseId, MilestoneTypeId, IsCompleted,completionDate FROM CaseMilestone 
                                                     WHERE caseId = :cs.Id AND MilestoneTypeId =: lstMilestones[0].Id];
        System.assertEquals(true, lstCaseMilestones[0].IsCompleted, 'Milestone is not completed');
        Test.stopTest();
    }
}