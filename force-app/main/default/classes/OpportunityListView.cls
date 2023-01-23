/*
 * OpportunityListView
 * The controller for the OpportunityListView LWC
 *
 * change log:
 * 2022-07-01: HV patched the Application Number sorting column issue.
 */

public with sharing class OpportunityListView {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(
        Integer rowLimit,
        Integer rowOffset,
        String submittedDate,
        String partnerStatus,
        String searchAllValue,
        String sortBy,
        String sortDirection
        ){
            string querySQL;   
            string condition;
            string nullSeq;
            string sortByConvert;
            
            List<string> substagesEX = new List<string>{'Booked', 'Calculation', 'Cash', 'Competitor', 'Customer Not Ready', 'Quote Draft', 'Quoting & Proposal'};

            if(String.isNotBlank(sortDirection)){
                if(sortDirection == 'asc'){
                    nullSeq = 'first';
                }
                else{
                    nullSeq = 'last';
                }
            }

            // Handle field mapping for columns where the variable doesn't match the field name.
            if(sortBy == 'EndUserURL') {
                sortByConvert = 'End_User_Company_Name__c';
            }else if(sortBy == 'quoteNumberURL') {
                sortByConvert = 'Opportunity_Number__c';            
            }else if(sortBy == 'ApplicationNumberUrl'){

                // Double column sorting supports defaulting the application number to the nickname when it's empty.
                sortByConvert = 'Application_Number__c, Nickname__c';
            } else {
                sortByConvert = sortBy;
            } 
                      
            list<Opportunity> oppList = new List<Opportunity>(); 
                     
            condition= getCondition(rowLimit,rowOffset,submittedDate,partnerStatus,searchAllValue);  
            if(String.isNotBlank(condition)){
                if(String.isNotBlank(sortBy)){
                    querySQL ='SELECT Id,Application_Number__c,Nickname__c,Amount,End_User__c,End_User_Company_Name__c,Sub_Stage__c,Application_Date__c,Approval_Letter_Expiration_Date__c,Partner_Sales_Rep__r.Name, Opportunity_Number__c '+
                ' FROM Opportunity WHERE Sub_Stage__c not in :substagesEX and ' + condition + ' ORDER BY ' + sortByConvert  + ' ' + sortDirection + ' NULLS ' + nullSeq +
                ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
                else {
                    querySQL ='SELECT Id,Application_Number__c,Nickname__c,Amount,End_User__c,End_User_Company_Name__c,Sub_Stage__c,Application_Date__c,Approval_Letter_Expiration_Date__c,Partner_Sales_Rep__r.Name, Opportunity_Number__c '+
                ' FROM Opportunity WHERE Sub_Stage__c not in :substagesEX and ' + condition + ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
            } 
            else{
                if(String.isNotBlank(sortBy)){
                    querySQL = 'SELECT Id,Application_Number__c,Nickname__c,Amount,End_User__c,End_User_Company_Name__c,Sub_Stage__c,Application_Date__c,Approval_Letter_Expiration_Date__c,Partner_Sales_Rep__r.Name, Opportunity_Number__c '+
                ' FROM Opportunity WHERE Sub_Stage__c not in :substagesEX '+ ' ORDER BY ' + sortByConvert + ' ' + sortDirection + ' NULLS ' + nullSeq +
                ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
                else {
                    querySQL = 'SELECT Id,Application_Number__c,Nickname__c,Amount,End_User__c,End_User_Company_Name__c,Sub_Stage__c,Application_Date__c,Approval_Letter_Expiration_Date__c,Partner_Sales_Rep__r.Name, Opportunity_Number__c '+
                ' FROM Opportunity WHERE Sub_Stage__c not in :substagesEX ' + ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
            }

        oppList = Database.query(querySQL);

        // Default the Application # to the nickname if it's blank.
        if(oppList.size() > 0){
            for(Opportunity opp : oppList){
                if(opp.Application_Number__c == null || opp.Application_Number__c == ''){
                    opp.Application_Number__c = opp.Nickname__c;
                }
            }
        }

        return oppList;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getOpportunitiesNum(
        Integer rowLimit,
        Integer rowOffset,
        String submittedDate,
        String partnerStatus,
        String searchAllValue
        ){
            String querySQL;
            string condition;
            Integer totalNumberOfRows;

            condition= getCondition(rowLimit,rowOffset,submittedDate,partnerStatus,searchAllValue);  
            if(String.isNotBlank(condition)){
                querySQL = 'SELECT COUNT() FROM Opportunity WHERE ' + condition;
            }
            else{
                querySQL = 'SELECT COUNT() FROM Opportunity';
            }
            totalNumberOfRows = Database.countQuery(querySQL);
            return totalNumberOfRows;
        }


    public static string getCondition(
        Integer rowLimit,
        Integer rowOffset,
        String submittedDate,
        String partnerStatus,
        String searchAllValue
    ){
        String condition = '';
        String startDate;
        String startDateFormat;
        String endDate;
        String endDateFormat;

        System.debug('submittedDate ' + submittedDate);

        if(String.isNotBlank(submittedDate)){
            if(submittedDate=='30D'){
                condition = 'Application_Date__c = ' + ' LAST_N_DAYS:30 ';
            }
            else{
                if(submittedDate=='60D'){
                    condition = 'Application_Date__c = ' + ' LAST_N_DAYS:60 ';
                }
                else{
                    if(submittedDate=='6M'){
                        condition = 'Application_Date__c = ' + ' LAST_N_MONTHS:6 ';
                    }
                    else{
                        if(submittedDate=='12M'){
                            condition = 'Application_Date__c = ' + ' LAST_N_MONTHS:12 ';
                        }
                        else{
                            startDate = submittedDate + '-01-01';
                            endDate = submittedDate + '-12-31';                         
                            condition = 'Application_Date__c >= ' + startDate + ' AND Application_Date__c <= ' + endDate;
                        }
                    }
                }
            }
        }  

        if(String.isNotBlank(partnerStatus)){
            system.debug('FNS condition::'+ condition);
            if(partnerStatus=='Cancelled'){
                if(String.isNotBlank(condition)){
                    condition += ' AND ' + '(Sub_Stage__c =  \'' + 'Cancelled' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Cash' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Competitor' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Customer Not Ready' + '\')';
                }
                else{
                    condition += '(Sub_Stage__c =  \'' + 'Cancelled' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Cash' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Competitor' + '\'' + ' OR ' + 'Sub_Stage__c =  \'' + 'Customer Not Ready' + '\')';
                }
            }
            else{
                if(String.isNotBlank(condition)){
                    condition += ' AND ' + 'Sub_Stage__c =  \'' + partnerStatus + '\'';
                    system.debug('FNS condition::'+ condition);
                }
                else{
                    condition += 'Sub_Stage__c =  \'' + partnerStatus + '\'';
                    system.debug('FNS condition::'+ condition);
                }
            }
        }

        condition += (String.isNotBlank(searchAllValue)
            ? (String.isNotBlank(condition) ? +' AND ' : '') +
              ' (Application_Number__c LIKE \'' +
              '%' +
              searchAllValue +
              '%\'' + ' OR ' +
              ' End_User_Company_Name__c LIKE \'' +
              '%' +
              searchAllValue +
              '%\')'
            : '');
        System.debug('condition ' + condition);
        
        //Start: PBI - 829854 - Author: Fernando Nereu de Souza
        if(String.isNotBlank(condition)){
            condition += ' AND RecordType.DeveloperName = \'Retail\'';
        }
        else{
            condition += 'RecordType.DeveloperName = \'Retail\'';
        }
        //End: PBI - 829854 - Author: Fernando Nereu de Souza
        return condition;
    }
}