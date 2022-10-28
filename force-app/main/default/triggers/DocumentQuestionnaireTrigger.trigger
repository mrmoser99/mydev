/**
 * This trigger is written on Document Questionnaire object. the main business logic is kept seperately in a handler class
 * Event: Before Insert, Before update
 * 
 * Version 1.0 @author - Ravisha Chugani @date 23-11-2021
 * 
 */
trigger DocumentQuestionnaireTrigger on Document_Questionnaire__c (before insert, before update) {
	new DocumentQuestionnaireTriggerHandler().run();
}