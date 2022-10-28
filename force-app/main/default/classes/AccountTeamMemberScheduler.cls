/**
   *  @description A scheduler for both account and opportunity records that looks
   *  will look at the last 24 months of prospect accounts to find users to add to
   *  account teams, and for all time for opportunities with owners that are not apart
   *  of the end user and vendor account teams
   *  @author      Newton Sun, Traction on Demand
   *  @date        2020-04-02
 */
global class AccountTeamMemberScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        RecordType prospectRecordType= [SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND Name='Prospect'];
        String accQuery = 'SELECT ' +
                'CreatedById, ' +
                'Id, ' +
                'Business_Unit__c ' +
                'FROM Account ' +
                'WHERE ' +
                'RecordTypeId = ' + '\'' + prospectRecordType.Id + '\'' +
                ' AND (CreatedDate = Last_N_Months:24 OR CreatedDate = THIS_MONTH)';
        AccountAccountTeamMemberBatch aub = new AccountAccountTeamMemberBatch(accQuery);
        Database.executeBatch(aub);
		/*
		 * Commented as per this task #368892
        String oppQuery = 'SELECT ' +
                'Id, ' +
                'End_User__c, ' +
                'AccountId, ' +
                'OwnerId, ' +
                'Business_Unit1__c ' +
                'FROM Opportunity ' +
                'WHERE ' +
                'CreatedDate < THIS_MONTH';

        OpportunityAccountTeamMemberBatch oatmb = new OpportunityAccountTeamMemberBatch(oppQuery);
        Database.executeBatch(oatmb);
		*/
    }
}