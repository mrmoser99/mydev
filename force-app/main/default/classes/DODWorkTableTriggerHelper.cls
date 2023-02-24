/**
 * Created by Dibyendu on 02/02/2023.
 */
/**********************************************************************************************************
   Class :  DODWorkTableTriggerHelper
   Description : Helper Class for Opportunity

   Date/Sprint		PBI/Description
   PI-23-Q1-02		922613 - Modify Opp Trigger and Develop async process, worktable to update application and asset(Dibyendu)*/

public class DODWorkTableTriggerHelper {
    public static void helpAfterInsert(List<DOD_API_Worktable__c> newWorktableMap) {
        //DOD_API_Worktable__c newWorkTable = newOppMap.get(oldOpp.Id);
        DODAsyncUpdate dodAsync = new DODAsyncUpdate(newWorktableMap);
        //ID jobID = System.enqueueJob(dodAsync);
        //system.debug('DDT Job ID'+jobID);
    }
}