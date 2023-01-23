/**
* @Created by Traction Team on 09/25/2020.
*/
/**********************************************************************************************************
   Class :  CaseTriggerHelper
   Description : Helper Class for Case

   Date/Sprint		PBI/Description
   PI-22-Q4-23		897482 - There is no open case email for the Wayne web channel
 ***********************************************************************************************************/
public class CaseTriggerHelper {
    //897482 - Update Web Email with End user Email
    public static void helpBeforeInsert(List<Case> newCases){
        for(Case cs :newCases){
            if(cs.Origin == 'Web' && cs.SuppliedEmail == NULL){
                cs.SuppliedEmail = cs.End_User_Email__c;
            }
        }
    }
    public static void helpBeforeUpdate(List<Case> newCases, Map<Id,Case> mapOfOldCases) {
        DateTime completionDate = System.now(); 
        Set<Id> closedCases = new Set<Id>();
        
        for (Case c : newCases){
            if (c.isClosed == true || c.Status == 'Closed')
                closedCases.add(c.Id);
        }
        
        if (!closedCases.isEmpty())
            MilestoneUtils.completeMilestone(closedCases, completionDate);
    }
    
    
    public static void helpAfterUpdate(List<Case> newCases, Map<Id,Case> mapOfOldCases) {
        Set<Id> firstMilestoneCases = new Set<Id>();
        for (Case c : newCases){
            if((c.status == 'Waiting For Customer' || c.status == 'Waiting For Internal' 
                || c.status == 'Complete' || c.status == 'Unread Email' || c.status == 'Closed'
                || c.status == 'Closed-Transferred') 
               && (mapOfOldCases.get(c.Id).status == 'In Progress' || mapOfOldCases.get(c.Id).status == 'New')){
                firstMilestoneCases.add(c.Id);
            }
        }
        if(!firstMilestoneCases.isEmpty()){
            MilestoneUtils.completeFirstResponseMilestone(firstMilestoneCases);
        }
    }
}