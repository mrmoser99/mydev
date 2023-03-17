/*********************************************************************************************
*	This executes the sai extraction 
*
* ChangeLog:
*
*	03/14/2023 - MRM - Created Class PBI 978641
*
************************************************************************************************/
global class ExecuteBatchShareEndUserAccounts implements Schedulable{ 

	global void execute(SchedulableContext SC){

        //	DOD_Batch_Share_Mode report - report only update - update account newTeamMembers

        id batchinstanceid = database.executeBatch(new BatchShareEndUserAccounts(null, System.Label.DOD_Batch_Share_Mode),1000); 

    }
}