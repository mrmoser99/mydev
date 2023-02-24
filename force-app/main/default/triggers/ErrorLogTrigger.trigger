trigger ErrorLogTrigger on Error_Log__c (before insert) {

    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            ErrorLogTriggerHandler.processNewErrorLogs(Trigger.new);
        }
    }

}