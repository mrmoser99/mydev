/**
*   trac_EmailToCaseLoopPrevent trigger
*   @description Prevent Email To Case Loop
*   @author Graham Barnard, Traction on Demand
*/
trigger trac_EmailToCaseLoopPrevent on Case (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        trac_EmailToCaseLoopPrevent.checkEmailToCaseLoop(Trigger.new);
    }
}