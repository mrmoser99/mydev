/*
 * DLL on Demand: Quote list view
 * Author:Geetha
 * 5-31-2022: Modified the Quote list view query : Task 783855
 * 6-30-2022:DOD Home Page- As a portal user I have a section detailing the most recent quote I worked on: PBI 742007
 * 1/31-2023 MRM - added credit check mode; only show primary quotes; also all means just the two
 */

public class QuoteListView {
   
    
    @AuraEnabled
    public static List<Quote> getQuotes(
        Integer rowLimit,
        Integer rowOffset,
        String submittedDate,
        String partnerStatus,
        String searchAllValue,
        String sortBy,
        String sortDirection,
        Boolean ccMode   //credit check appeals process
        ){
            string querySQL;   
            string condition;
            string nullSeq;
            string sortByConvert;
            String   querySQL_2;
            
            Datetime ct;
            Datetime ct2;

            List<String> subStages = new List<String>{'Application Draft','Quoting & Proposal','Quote Draft'};
            

            List<string> substagesEX = new List<string>{'Application Submitted','Quoting & Proposal','Quote Draft','Application Draft'};
             
            system.debug('ccmode is: ' + ccMode);

            if (ccMode == true){
                 substagesEX = subStages;

                
            }

            system.debug('substagesEx' + substagesEX);
            
            Id IntegratedRecType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Integrated').getRecordTypeId();
        
            if(String.isNotBlank(sortDirection)){
                if(sortDirection == 'asc'){
                    nullSeq = 'first';
                }
                else{
                    nullSeq = 'last';
                }
            }


            if(sortBy == 'EndUserURL'){
                sortByConvert = 'Opportunity.End_User_Company_Name__c';
            }
            else if(sortBy == 'QuoteNumberURL'){
                sortByConvert = 'Opportunity.Opportunity_Number__c';
            }
            else if(sortBy == 'createdbyname'){
                sortByConvert = 'Opportunity.CreatedBy.Name';
            }
            else if(sortBy == 'nickName'){
                sortByConvert = 'Opportunity.Nickname__c';
            }
            else if(sortBy == 'substage'){
                sortByConvert = 'Opportunity.Sub_Stage__c';
            }
            
            else{
                sortByConvert = sortBy;
            }
            
           
                      
            list<Quote> quoteList = new List<Quote>(); 

            if(isDateFilter(searchAllValue)){
            
                List<String> dtDates = searchAllValue.split('/');
                Integer year = Integer.valueOf(dtDates[2]);
                Integer day = Integer.valueOf(dtDates[1]);
                Integer month = Integer.valueOf(dtDates[0]);
                ct = Datetime.newInstanceGMT(year,month,day,0,0,0);
                ct2 = Datetime.newInstanceGMT(year,month,day,23,59,59);
                condition = (String.isNotBlank(condition) ? + ' AND ' : '') + ' ((Opportunity.CreatedDate > :ct  and Opportunity.CreatedDate < :ct2) OR (Opportunity.LastModifiedDate > :ct  and Opportunity.LastModifiedDate < :ct2)) ' ;
            }
            
            else{
                 condition= getCondition(rowLimit,rowOffset,submittedDate,partnerStatus,searchAllValue);  
            }

            String ccCondition1 = '';
            String ccCondition2 = '';

            //if (ccMode == true){
                //ccCondition1 = ' Current_Credit_App_Selection__c = true AND ';
                ////ccCondition2 = ' AND Current_Credit_App_Selection__c = true ';
                
            //}
            
            if(String.isNotBlank(condition)){
                if(String.isNotBlank(sortBy)){
                    querySQL ='select OpportunityId, is_primary__c, Opportunity.Opportunity_Number__c, RecordTypeId, Opportunity.End_User_Company_Name__c, Opportunity.End_User__r.name, Opportunity.Nickname__c, Opportunity.Sales_Rep_Name__c, Opportunity.CreatedBy.Name, Opportunity.CreatedBy.Full_Name__c, Opportunity.CreatedDate, '
                              + 'Opportunity.LastModifiedDate, Opportunity.Sub_Stage__c, Opportunity.CreatedBy.FirstName, Opportunity.createdby.LastName, Partner_Sales_Rep__r.Name '
                              + 'from quote where OpportunityId!=null and RecordTypeId = :IntegratedRecType and Opportunity.Sub_Stage__c in :substagesEX AND '
                        	  + ccCondition1 + 
                              + condition + ' ORDER BY ' + sortByConvert  + ' ' + sortDirection + ' NULLS ' + nullSeq 
                        	  + ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
                else {
                    querySQL ='select OpportunityId, is_primary__c, Opportunity.Opportunity_Number__c, RecordTypeId, Opportunity.End_User_Company_Name__c, Opportunity.End_User__r.name, Opportunity.Nickname__c, Opportunity.Sales_Rep_Name__c, Opportunity.CreatedBy.Name, Opportunity.CreatedBy.Full_Name__c, Opportunity.CreatedDate, '
                              + 'Opportunity.LastModifiedDate, Opportunity.Sub_Stage__c, Opportunity.CreatedBy.FirstName, Opportunity.createdby.LastName, Partner_Sales_Rep__r.Name '
                              + 'from quote where OpportunityId!=null and RecordTypeId = :IntegratedRecType and Opportunity.Sub_Stage__c in :substagesEX AND '
                       		  + ccCondition1 +
                              + condition +' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
            }
            else{
                if(String.isNotBlank(sortBy)){
                    querySQL = 'select OpportunityId, is_primary__c ,Opportunity.Opportunity_Number__c, RecordTypeId, Opportunity.End_User_Company_Name__c, Opportunity.End_User__r.name, Opportunity.Nickname__c, Opportunity.Sales_Rep_Name__c, Opportunity.CreatedBy.Name, Opportunity.CreatedBy.Full_Name__c, Opportunity.CreatedDate, '
                              + 'Opportunity.LastModifiedDate, Opportunity.Sub_Stage__c, Opportunity.CreatedBy.FirstName, Opportunity.createdby.LastName, Partner_Sales_Rep__r.Name '
                              + 'from quote where OpportunityId!=null and RecordTypeId = :IntegratedRecType and Opportunity.Sub_Stage__c in :substagesEX '
                              + ccCondition2 +
                              + 'ORDER BY  '
                       		  + sortByConvert + ' ' + sortDirection + ' NULLS ' + nullSeq 
                       		  + ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                }
                else {
                   querySQL = 'select OpportunityId, is_primary__c, Opportunity.Opportunity_Number__c, RecordTypeId, Opportunity.End_User_Company_Name__c, Opportunity.End_User__r.name, Opportunity.Nickname__c, Opportunity.Sales_Rep_Name__c, Opportunity.CreatedBy.Name, Opportunity.CreatedBy.Full_Name__c, Opportunity.CreatedDate, '
                              + 'Opportunity.LastModifiedDate, Opportunity.Sub_Stage__c, Opportunity.CreatedBy.FirstName, Opportunity.createdby.LastName, Partner_Sales_Rep__r.Name '
                              + 'from quote where OpportunityId!=null and RecordTypeId = :IntegratedRecType and Opportunity.Sub_Stage__c in :substagesEX '
                              + ccCondition2
                              + 'ORDER BY Opportunity.CreatedDate desc '
                              + ' LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                   }
            }
        system.debug('querySQL = '+querySQL);
        quoteList = Database.query(querySQL);
        Map<Id, Quote> qlistMap = new Map<Id, Quote>();
            for(Quote qt:quoteList){
                if(!qlistMap.containsKey(qt.OpportunityId)){
                    qlistMap.put(qt.OpportunityId,qt);
                }
            
            }
            
            
        return qlistMap.values();
    }

    @AuraEnabled
    public static Integer getQuotesNum(
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
                querySQL = 'SELECT COUNT() FROM Opportunity where Opportunity_Number__c!=null ';
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
        
        if(String.isNotBlank(submittedDate)){
            if(submittedDate=='30D'){
                condition = 'Opportunity.CreatedDate = ' + ' LAST_N_DAYS:30 ';
            }
            else{
                if(submittedDate=='60D'){
                    condition = 'Opportunity.CreatedDate = ' + ' LAST_N_DAYS:60 ';
                }
                else{
                    if(submittedDate=='6M'){
                        condition = 'Opportunity.CreatedDate = ' + ' LAST_N_MONTHS:6 ';
                    }
                    else{
                        if(submittedDate=='12M'){
                            condition = 'Opportunity.CreatedDate = ' + ' LAST_N_MONTHS:12 ';
                        }
                        else{
                            startDate = submittedDate + '-01-01T00:00:00Z';
                            endDate = submittedDate + '-12-31T23:59:59Z';                         
                            condition = 'Opportunity.CreatedDate >= ' + startDate + ' AND Opportunity.CreatedDate <= ' + endDate;
                        }
                    }
                }
            }
        }  

        if(String.isNotBlank(partnerStatus)){
            if(String.isNotBlank(condition)){
                    condition += ' AND ' + 'Opportunity.Sub_Stage__c =  \'' + partnerStatus + '\'';
            }
            else{
                condition += 'Opportunity.Sub_Stage__c =  \'' + partnerStatus + '\'';
            }
            
        }
        
        
        condition += (String.isNotBlank(searchAllValue)
            ? (String.isNotBlank(condition) ? +' AND ' : '') +
              ' (Opportunity.Opportunity_Number__c LIKE \'' +
              '%' +
              string.escapeSingleQuotes(searchAllValue.trim()) +
              '%\'' + ' OR ' +
              ' Opportunity.End_User_Company_Name__c LIKE \'' +
              '%' +
               string.escapeSingleQuotes(searchAllValue.trim()) +
               '%\'' + ' OR ' +
               'Opportunity.CreatedBy.Name LIKE \'' +
               '%' +
               string.escapeSingleQuotes(searchAllValue.trim()) +
               '%\'' + ' OR ' +
               'Opportunity.Nickname__c LIKE \'' +
               '%' +
               string.escapeSingleQuotes(searchAllValue.trim()) +  
               '%\'' + ' OR ' +
               'Opportunity.Sub_Stage__c LIKE \'' +
               '%' +
               string.escapeSingleQuotes(searchAllValue.trim()) +
              '%\')'
            : '');
        
        return condition;
    }
    
    public static boolean isDateFilter(String dateFilter){
        
        if(String.isNotBlank(dateFilter)){
            String regex = '[0-9]{0,2}/[0-9]{0,2}/[0-9]{4}';
			boolean isDate = Pattern.matches(regex, dateFilter);
        	return isDate;
        }
        else
            return false;
    }
    
    @AuraEnabled
    public static boolean deleteOpp(Id oppId){
        boolean isQuoteDeleted = false;
        Opportunity deleteOpp = new Opportunity();
        if(string.isNotBlank(oppId)){
            
            try{
                List<Quote> delQuoteList = [select id from Quote where OpportunityId =:oppId];
                deleteOpp = [select Id from Opportunity where Id =: oppId];
               //Quote deleteQuote = new Quote(id=deleteOpp.SyncedQuoteId);
                if(delQuoteList.size() > 0){
                    delete delQuoteList;
                    isQuoteDeleted = true;
                  }
                   }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, OppId, true); 
                throw new ErrorLogger.ErrorLoggerException(e.getMessage());
                
            } 
            if(isQuoteDeleted){
                try{
                    delete deleteOpp;
                   
                    return true;
                }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, OppId, true); 
                throw new ErrorLogger.ErrorLoggerException(e.getStackTraceString());
                
            } 
            }else{
                return false;
            }
        }
        return false;
    }
    
    //Get last modified Quote - Home Quote list view : PBI 742007
    @AuraEnabled
    public static List<Opportunity> getTop5Quotes(){
        List<string> substagesEX = new List<string>{'Application Submitted','Quoting & Proposal','Quote Draft','Application Draft'};
        Id IntegratedRecType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Integrated').getRecordTypeId();
        List<Id> top5OppList = new List<Id>();
       List<AggregateResult> groupbyRes = [Select OpportunityId,Opportunity.Sub_Stage__c, RecordTypeId from Quote
                                           group by OpportunityId, Opportunity.Sub_Stage__c, RecordTypeId
                                           having Opportunity.Sub_Stage__c in :substagesEX
                                           and RecordTypeId = :IntegratedRecType 
                                           and OpportunityId!=null ] ;
        
        for(AggregateResult aggr:groupbyRes){
            top5OppList.add((Id)aggr.get('OpportunityId'));
        }
        
        List<Opportunity> retTop5QuoteList = [select Id, Opportunity_Number__c, 
                                              End_User_Company_Name__c, End_User__r.name, 
                                              Nickname__c, Sales_Rep_Name__c, CreatedBy.Name, 
											  CreatedBy.Full_Name__c, CreatedDate, 
                                              LastModifiedDate, Sub_Stage__c,
											  CreatedBy.FirstName, createdby.LastName 
                                              from Opportunity where Id=:top5OppList 
                                              ORDER BY LastModifiedDate desc limit 5];
        return retTop5QuoteList;
    }
	
}