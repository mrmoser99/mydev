/**
 * Created by samuelmeyers on 12/31/18.
 * @update: Updated by Traction Team on 04/22/2020
 * 			Added Region and Legal_Entity_Description fields in query
 */

global class PostTriggerBatchScheduler implements Schedulable {
  
    global void execute(SchedulableContext sc) {
        //Select all Account Business Unit Mapping (After this batch runs, all will be deleted)
        //PBI:446085:Account Business Unit Mapping: Golf and Turf:Added Golf_and_Turf__c in Query:Geetha
        String accBUMapQuery = 'SELECT '+
                'Account__c, '+
                'CleanTech__c, '+
                'Commercial_Finance__c, '+
                'Digital_Imaging__c, '+
                'CT_and_I__c, '+
                'Healthcare__c, '+
                'Technology_Solutions__c, '+
                'Food_and_Ag__c,' +
                'Golf_and_Turf__c,'+
            	'Legal_Entity_Description__c, '+
            	'Region_Description__c,'+
            	'Region_SFDC_ID__c '+
                'FROM Account_Business_Unit_Mapping__c';
        AccountUpdateBatch aub = new AccountUpdateBatch(accBUMapQuery);
        database.executeBatch(aub);
    }
}