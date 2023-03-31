/*********************************************************************************************
*   This batch program adds new portal users to account team of end users for specified dealer
*
* ChangeLog:
*
*   03/14/2023 - MRM - Created Class PBI 978641
*   03/27/2023 - MRM - added logic to submit for next dealer automatcially.
*
************************************************************************************************/
global class BatchShareEndUserAccounts implements Database.Batchable<sObject>,Database.Stateful{
    
    public String QUERY = 'Select account_1__c, account_1__r.name, account_2__r.name ' +
        ' from Account_Account_Relationship__c ' +
        ' where account_2__c in ( ';
    
    public GetDealerSites sites;

    public ID dealerId, nextDealerId;


    String mode;

    /*********************************************************************************************
    *   CONSTRUCTOR
    *
    *
    ************************************************************************************************/
    global BatchShareEndUserAccounts(String lastDealerId, String mode){   

         
        List<Account> aList;
        List<Account> a2List = new List<Account>();

        if (lastDealerId == null){
             aList = [Select id,name from Account where isDealer__c = true  order by id limit 2];
             a2List = [Select id,name from Account where isDealer__c = true and id > :aList[0].id order by id limit 1]; 
        }
        else {
            aList = [Select id,name from Account where isDealer__c = true and id = :lastDealerId ]; 
            a2List = [Select id,name from Account where isDealer__c = true and id > :lastDealerId order by id limit 1]; 
        }

         

        if (aList.isEmpty())  //we should always have at lease one dealer in the system.
            return;
        
        this.dealerId = aList[0].id;   //set running dealer to the first one in the list

        if (a2List.size() > 0){
            this.nextDealerId = a2List[0].id;  //set next dealer to the second in the list; this will be used to create next batch
        }
        else{
            this.nextDealerId = null;
        }
    
        //mode = update or report       update will add account team members;
        //                              report will just create report data for the dod report;
        this.mode = mode;

        if (mode == null){
            mode = System.Label.DOD_Batch_Share_Mode;  // 'report' or 'update';  //default is report mode
        }

        Set<ID> dealerSet = new Set<ID>();
        dealerSet.add(this.dealerId);  //get all sites for dealer
        sites = new GetDealerSites(dealerSet);

        system.debug('sites list is:' + sites);

        Integer i = 0;
        for (ID s : sites.finalParentSet){
            i++;
            QUERY += '\'' + s + '\'';
            if (i < sites.finalParentSet.size())
                QUERY += ' , ';
        }

        QUERY +=  ' ) ';   
        QUERY +=  ' and account_type__c = ' +  '\'' + 'End User' +  '\'';

        system.debug(QUERY);
    
    }
    /*********************************************************************************************
    *   START
    *
    ************************************************************************************************/               
    global Database.QueryLocator start(Database.BatchableContext c) {  
        
        system.debug('Query is: ' + QUERY);
        return Database.getQueryLocator(QUERY);        
    }
    /*********************************************************************************************
    *   EXECUTE
    *
    *
    ************************************************************************************************/
    global void execute(Database.BatchableContext c, List<Account_Account_Relationship__c> scope) {

    
        
        try{

        

        Set<ID> siteSet = new Set<ID>();

        for (Account_Account_Relationship__c r:scope){
            system.debug('Name: ' + r.account_1__r.name + ' ID: ' + r.account_1__c + ' Site Name:' + r.account_2__r.name + ' Site ID: ' + r.account_2__c);
            siteSet.add(r.account_2__c);
        }

        system.debug('Site Set is: ' + siteSet);
    
        //get a list of contacts that have access to the sites

        List<AccountContactRelation> acrList = [
            SELECT
            AccountId,
            ContactId,  
            Roles
            FROM
            AccountContactRelation
            where AccountId  in :siteSet
   
        ];
        //and roles = 'Partner Admin'


        //create a map that shows which sites a contact has access to

        Map<ID,List<ID>> contactSiteMap = new Map<ID,List<ID>>();
        Map<ID,String> contactRole = new Map<ID,String>();

        for (AccountContactRelation ar:acrList){
            List<ID> tempList = new List<ID>();

    
            if (contactSiteMap.get(ar.ContactId) == null){
                tempList.add(ar.AccountId);
            }
            else{
                tempList = contactSiteMap.get(ar.ContactId);
                tempList.add(ar.AccountId);
            }
            contactSiteMap.put(ar.ContactId,tempList);
            contactRole.put(ar.ContactId,ar.roles);
        }

        system.debug('Contact Site Map: ' + contactSiteMap);


        //get userids of the contacts that need access to the end user account
        List<User> uList = new List<User>();
        uList = [select id, contactID from User where ContactId in : contactSiteMap.keySet() and isActive = true];

        Map<ID,ID> contactUserMap = new Map<ID,ID>();
        Map<ID,ID> userContactMap = new Map<ID,ID>();
        for (User u:uList){
            contactUserMap.put(u.ContactId, u.Id);
            userContactMap.put(u.id, u.ContactId);
        }

        System.debug('Contact User Map: ' + contactUserMap);

        List<AccountTeamMember> deleteAccountTeam = new List<AccountTeamMember>();
        List<AccountTeamMember> insertAccountTeam = new List<AccountTeamMember>();

        Set<ID> endUserAccountSet = new Set<ID>();
        for (Account_Account_Relationship__c r:scope){
            endUserAccountSet.add(r.account_1__c);
        }

        //BATCH LOOP HERE BREAK into Chunks

        //delete account team members
        Map<String,AccountTeamMember> existingMap = new Map<String,AccountTeamMember>();

        List<AccountTeamMember> amList = [select id, accountId, userId from AccountTeamMember where AccountId in :endUserAccountSet];
        for(AccountTeamMember am:amList){
            System.debug('Storing: ' + string.valueOf(am.AccountId) + '-' +  string.valueOf(am.UserId));    
            existingMap.put(string.valueOf(am.accountId) + '-' + string.valueOf(am.userId), am);
        }
        
        List<DOD_End_User_Share_Result__c> rList = new List<DOD_End_User_Share_Result__c>();




        Map<ID,ID> newTeamMembers = new Map<ID,ID>();
        Map<ID,ID> newTeamMembersContactId = new Map<ID,ID>();

        for (Account_Account_Relationship__c r:scope){
            for (ID ct:contactSiteMap.keySet()){
                if (contactSiteMap.get(ct).contains(r.account_2__c)){  //if the relationship record site is in the contact site map, give them access to the end user
                    if (contactUserMap.get(ct) == null){  //don't process contact if no active user id
                        continue;
                    }
                    else{
                        AccountTeamMember a = new AccountTeamMember();
                        a.AccountId = r.account_1__c;
                        a.UserId =  contactUserMap.get(ct);
                        a.accountAccessLevel = 'Read';
                        a.TeamMemberRole =contactRole.get(ct);
                        if (a.TeamMemberRole == null){
                            a.TeamMemberRole = 'Partner Admin';
                        }
                        
                        System.debug('Looking for: ' + string.valueOf(a.AccountId) + '-' +  string.valueOf(a.UserId));
                        
                        if (existingMap.get(string.valueOf(a.AccountId) + '-' +  string.valueOf(a.UserId)) != null)   //don't update if already existing
                             System.debug('Found: ' + string.valueOf(a.AccountId) + '-' +  string.valueOf(a.UserId));
                        else{
                            if (mode == 'report'){
                                DOD_End_User_Share_Result__c sr = new DOD_End_User_Share_Result__c();
                                sr.account__c = a.AccountId;
                                sr.contact__c = ct;
                                rList.add(sr);
                            }
                            system.debug('Adding: ' + ' Account: ' + a.accountId + ' User: ' + a.userId);
                            newTeamMembers.put(a.accountId, a.userId);
                            newTeamMembersContactId.put(a.accountId, ct);
                            insertAccountTeam.add(a);  
                        }
                    }
                }
            }

        }  


        if (mode == 'update') 
            upsert insertAccountTeam;
        

        /*  show some stats to see what happened */
        //system.debug('UPSAccountTeam already found: ' + deleteAccountTeam);
        //system.debug('UPSAccountTeam inserts: ' + insertAccountTeam);
        //system.debug('Accounts impacted: ' + newTeamMembers.keySet());
        //system.debug('Account contact pairs: ' + newTeamMembers);
        //system.debug('UPSAccountTeam #inserts: ' + insertAccountTeam.size());

        if (mode == 'report')
            insert rList;
        
        }
        catch (Exception e) {

            Error_Log__c el = new Error_Log__c();
            el.callout_name__c = 'BatchShareEndUserAccounts dealerId= ' + this.dealerId;
            el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
            el.Class_name__c = 'BatchShareEndUserAccounts';
            el.Method_Name__c = 'BatchShareEndUserAccounts';
            el.status_code__c = 900;
            el.stack_trace__c = e.getStackTraceString();
            el.exception_message__c = string.valueOf(e) + '-' + e.getMessage();
            insert el;
        }

    }
    /*********************************************************************************************
    *   FINISH
    *
    *
    ************************************************************************************************/
    global void finish(Database.BatchableContext c) {



        system.debug('********************* this.nextDealerId = ' + this.nextDealerId);
        if (this.nextDealerId != null){
           id batchinstanceid = database.executeBatch(new BatchShareEndUserAccounts(this.nextDealerId,this.mode),1000); 
        }
        
    }
  
}