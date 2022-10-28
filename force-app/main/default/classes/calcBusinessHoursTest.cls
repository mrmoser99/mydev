/**
 * Created by ssun on 12/9/2019.
 */

@IsTest
private class calcBusinessHoursTest {
    @IsTest
    static void priorityLowest() {
        /*Case c = new Case();
        c.Priority = 'Low';
        Test.startTest();
        insert c;
        Test.stopTest();
        BusinessHours stdBusinessHours = [select id from businesshours where isDefault = true];
        Case cToCheck = [SELECT SLA_Due_Date_Time__c, CreatedDate FROM Case WHERE Id =:c.Id LIMIT 1];
        System.assertEquals(cToCheck.SLA_Due_Date_Time__c, BusinessHours.add(stdBusinessHours.id, cToCheck.CreatedDate, 79200000));
        System.debug(cToCheck);*/
    }
    /*@IsTest
    static void priorityMedium() {
        /*Case c2 = new Case();
        c2.Priority = 'Medium';
        c2.SLA_Business_Unit__c = 'Construction, Transportation, and Industrial';
        c2.Business_Unit_Override__c = true;
        Test.startTest();
        insert c2;
        Test.stopTest();
        BusinessHours stdBusinessHours = [select id from businesshours where isDefault = true];
        Case cToCheck = [SELECT SLA_Due_Date_Time__c, CreatedDate, Priority FROM Case WHERE Id =:c2.Id LIMIT 1];
        System.debug(cToCheck.Priority);
        System.assertEquals(cToCheck.SLA_Due_Date_Time__c, BusinessHours.add(stdBusinessHours.id,  cToCheck.CreatedDate, 39600000));

    }

    @IsTest
    static void priorityHigh() {
        /*Case c3 = new Case();
        c3.Priority = 'High';
        c3.Type = 'End of Lease';
        c3.Sub_Type__c = 'Trade Up';
        Test.startTest();
        insert c3;
        Test.stopTest();
        BusinessHours stdBusinessHours = [select id from businesshours where isDefault = true];
        Case cToCheck = [SELECT SLA_Due_Date_Time__c, CreatedDate FROM Case WHERE Id =:c3.Id LIMIT 1];
        System.assertEquals(cToCheck.SLA_Due_Date_Time__c, BusinessHours.add(stdBusinessHours.id,  cToCheck.CreatedDate, 14400000));
        System.debug(cToCheck);
    }*/
}