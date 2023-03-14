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


        id batchinstanceid = database.executeBatch(new BatchShareEndUserAccounts(null,'report'),100); 

    }
}