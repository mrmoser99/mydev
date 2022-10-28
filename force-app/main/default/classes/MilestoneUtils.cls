/**
 * @Created by Traction Team on 09/25/2020.
 */
public class MilestoneUtils {
    private static Final string FIRST_RESPONSE_48_HOURS = 'First Response 48 Hours';
    
    public static void completeMilestone(Set<Id> caseIds, DateTime complDate) {  
        List<CaseMilestone> cmsToUpdate = [select Id, completionDate
                                           from CaseMilestone cm
                                           where caseId in :caseIds and completionDate = null limit 1];
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.completionDate = complDate;
            }
            update cmsToUpdate;
        }
    }
    
    public static void completeFirstResponseMilestone(Set<Id> caseIds){
        DateTime completionDate = System.now(); 
        List<MilestoneType> lstMilestones= [SELECT Id, Name FROM MilestoneType Where Name =: FIRST_RESPONSE_48_HOURS];
        
        if(!lstMilestones.isEmpty()){
            List<CaseMilestone> lstCaseMilestones = [SELECT Id, CaseId, MilestoneTypeId, IsCompleted,completionDate FROM CaseMilestone 
                                                     WHERE caseId in :caseIds AND MilestoneTypeId =: lstMilestones[0].Id AND IsCompleted = FALSE ];
            for(CaseMilestone cm: lstCaseMilestones){
                cm.completionDate = completionDate;
            }
            
            Database.update(lstCaseMilestones);
            
        }
    }
}