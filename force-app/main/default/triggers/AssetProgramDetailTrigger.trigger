/**
 * This trigger is written on Asset_Program_Detail__c object. the main business logic is kept seperately in a handler class
 *Event: Before Insert, Before update
 * 
 * Version 1.0 @author Elena Sokolova, Anujit Das @date 2021-07-22
 * 
 */
trigger AssetProgramDetailTrigger on Asset_Program_Detail__c (before insert, before update) {
    new AssetProgramDetailTriggerHandler().run();
}