/*New Scheduler to run Opportunity Match Batch every 15minutes.
 * PBI:531473. To avoid duplicate Opportunities stay in system for long time.
 */
global class OpportunityMatchBatchScheduler implements Schedulable{
    
    global void execute(SchedulableContext sc) {
        //Select Opportunities with an existing match
        //PBI:446238:Update OpportunityMatchUpdateBatch to correct field mapping:added Sub_Stage__c in Query:Geetha
        //PBI:531473: New Scheduler to run every 15 minutes everyday
        String matchingOppsQuery = 'SELECT '+
                'AccountId, '+
                'End_User__c, '+
                'Sales_Rep_ID__c, '+
                'Sales_Rep_Name__c, '+
                'Amount, '+
                'UNQ_Opportunity__c, '+
                'Application_Date__c, '+
                'Vendor_Program__c, '+
            	'Program__c, '+
                'Risk_Grade__c, '+
                'StageName, '+
                'Sub_Stage__c, '+
                'Purchase_Option__c, '+ 
                'End_User_Phone__c, '+                
                'Existing_Match__c, '+
                'Existing_Match__r.isDeleted, '+
                'Source_System__c, ' +
                'Application_Approval_Date__c, '+
                'Funded_Date__c, '+ 
                'UNQ_Customer__c, '+
                'UNQ_Program__c, '+
                'Business_Unit__c, '+
                'Application_Number__c, '+
                'Business_Unit_Description__c, '+
                'CloseDate, '+
                'Contract__c, '+
                'Customer_Code__c, '+
                'End_User_Company_Name__c, '+
                'Legal_Entity_Description__c, '+
                'Region_Relationship__c, '+
                'Region_Description__c, '+
                'Sales_Rep_ID_2__c, '+
                'Sales_Rep_Name_2__c, '+
                'UNQ_Vendor__c, '+
                'Vendor_ID__c '+
                'FROM Opportunity '+
                'WHERE Existing_Match__c != null ORDER BY LastModifiedDate';
        OpportunityMatchUpdateBatch omub = new OpportunityMatchUpdateBatch(matchingOppsQuery);
        database.executeBatch(omub);
    }

}