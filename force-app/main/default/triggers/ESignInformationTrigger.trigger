/**
 * This trigger is written on E-Sign Information object. the main business logic is kept seperately in a handler class
 *Event: Before Insert, Before update
 * 
 * Version 1.0 @author Elena Sokolova, Anujit Das @date 2021-07-02
 * 
 */
trigger ESignInformationTrigger on E_Sign_Information__c (before insert, before update) {
    new ESignInformationTriggerHandler().run();
}