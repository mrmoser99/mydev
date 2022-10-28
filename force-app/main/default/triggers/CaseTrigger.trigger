/**
 * @Created by Traction Team on 09/25/2020.
 */
trigger CaseTrigger on Case (before insert, before update, after update, after insert) {
  if(Trigger.isBefore){
        If(Trigger.isInsert) {
            trac_EmailToCaseLoopPrevent.checkEmailToCaseLoop(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CaseTriggerHelper.helpBeforeUpdate(Trigger.new,Trigger.oldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate) {
            CaseTriggerHelper.helpAfterUpdate(Trigger.new,Trigger.oldMap);
        }
    }
}