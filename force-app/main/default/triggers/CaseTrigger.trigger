/**
 * @Created by Traction Team on 09/25/2020.
 */
/**********************************************************************************************************
   Class :  CaseTrigger
   Description : Trigger for Case

   Date/Sprint		PBI/Description
   PI-22-Q4-23		897482 - There is no open case email for the Wayne web channel
 ***********************************************************************************************************/
trigger CaseTrigger on Case (before insert, before update, after update) {
  if(Trigger.isBefore){
        If(Trigger.isInsert) {
            trac_EmailToCaseLoopPrevent.checkEmailToCaseLoop(Trigger.new);
            CaseTriggerHelper.helpBeforeInsert(Trigger.new);	//897482
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