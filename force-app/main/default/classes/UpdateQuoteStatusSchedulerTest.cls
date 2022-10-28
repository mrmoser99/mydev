/**
 * Test class for UpdateQuoteStatusScheduler
 * 
 * Version 1.0
 * 
 */
@IsTest
public with sharing class UpdateQuoteStatusSchedulerTest {
    @isTest static void schedulerTest() {
    	final String SCHEDULED_TIME = '0 0 0 1/1 * ? *';
        Test.startTest();
        Id jobId = UpdateQuoteStatusScheduler.scheduleBatch(100);
        Test.stopTest();
        Integer jobCount = [SELECT Count() FROM CronTrigger WHERE Id = :jobId LIMIT 10];
        System.assertEquals(1, jobCount);
    }
}