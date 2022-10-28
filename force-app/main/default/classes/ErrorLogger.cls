/**
 * This class is used to store information about callouts as Error_Log__c records
 * 
 * @author Elena Sokolova ~ Integration Logger Merge
 * @author Ravisha Chugani
 * @author Neha Tyagi
 * 
 * @date    v.1 2021-08-06
 *         
 */
public with sharing class ErrorLogger {
    
    
    public static List<LogWrapper> logsList;

    // Set List<LogWrapper> logsList. only initialized once on the first use of the class.
    static {
        logsList = new List<LogWrapper>();
    }
    
    /**
     * This wrapper class stores information about callout
     */
    public class LogWrapper {

        public String calloutName;
        public HttpRequest httpRequest;
        public HttpResponse httpResponse;
        // time difference between sending request and getting response
        public String timeDiff= '';
        public Boolean saveLogsAsync;
        
        public LogWrapper (String calloutName, HttpRequest httpRequest, HttpResponse httpResponse, Integer timeDiff, Boolean saveLogsAsync) {
            this.calloutName = calloutName;
            this.httpRequest = httpRequest;
            this.httpResponse = httpResponse;
            this.timeDiff = String.valueof(timeDiff);
            this.saveLogsAsync = saveLogsAsync;
        }
    }

    /**
     * Method adds instance of LogWrapper, which contains information about callout, to the List<LogWrapper> logsList
     */
    public static void addLog(LogWrapper log) {
        logsList.add(log);
    }

    /**
     * Method iterates List<LogWrapper> logsList, creates Integration Log record for each item and saves result.
     */
    public static void saveLogs(Map<String, Object> params) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        List<Error_Log__c> errorLogsAsync = new List<Error_Log__c>();

        for (LogWrapper log : logsList) {
                Error_Log__c newLog = new Error_Log__c(
                RecordTypeId = Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(Constants.INTEGRATION_ERRORLOG_RECORDTYPE).getRecordTypeId(),
                Callout_Name__c = log.calloutName,
                Status_Code__c = log.httpResponse.getStatusCode(),
                Status__c = log.httpResponse.getStatus(),          
                Request_Body__c = log.httpRequest.getBody().left(Error_Log__c.Request_Body__c.getDescribe().getLength()), 
                Response_Body__c = log.httpResponse.getBody().left(Error_Log__c.Response_Body__c.getDescribe().getLength()), 
                Quote_ID__c = getQuoteIdFromParams(params),
                Time_difference__c = Integer.valueof(log.timeDiff)
            );

            if (log.saveLogsAsync == true) {
                errorLogsAsync.add(newLog);
            } else {
                errorLogs.add(newLog);
            }
        }

       // serialize List<Error_Log__c> integrationLogs because saveLogsAsync() method has @future annotation 
        if (!errorLogs.isEmpty()) {
            saveLogsSync(errorLogs);
        }

        if (!errorLogsAsync.isEmpty()) {
            saveLogsAsync(JSON.serialize(errorLogsAsync));
        }
    }

    /**
     * Method checks if map (input param) contains key 'quoteId' , this id is valid and returns it
     * 
     * @return String quote id
     */
    private static Id getQuoteIdFromParams(Map<String, Object> params) {
        Id quoteId;
        if (params.containsKey('quoteId')) {
            try {
                quoteId = (Id) params.get('quoteId');
            } catch (Exception ex) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(ex, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true); 
            }

            if (String.isNotEmpty(quoteId) && quoteId.getSobjectType() != Schema.Quote.sObjectType) {
                quoteId = null;
            }
        }
        return quoteId;
    }

    /**
     * Method parse String into List<Error_Log__c> and saves Integration Log records, asynchronously.
     */
    @future
    public static void saveLogsAsync(String serializedLogs) {
        List<Error_Log__c> errorLogs = (List<Error_Log__c>) JSON.deserialize(serializedLogs, List<Error_Log__c>.class);
        saveLogsSync(errorLogs);
    }

    /**
     * Method parse String into List<Error_Log__c> and saves Integration Log records, synchronously.
     */
    public static void saveLogsSync(List<Error_Log__c> errorLogs) {
        try {
           
            insert errorLogs;
        } catch (Exception e) {
            //ErrorLogger errorLog = new ErrorLogger();
            //errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE,null, true); 
            system.debug(LoggingLevel.WARN, e.getMessage());
            
        }
    }
    
    /**
     * Method traces error and it's related information and saves Error Log records in database.
     */
    public void logException(Exception e, String recordType, String relatedToId, Boolean saveLogAsync) {
        try {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                
            //Governer Limit of executingQuery 
            String QueryLimit = Constants.QUERY_LIMIT + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String DMLimit = Constants.DML_LIMIT + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String DMLStat = Constants.DML_STAT +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String CPUT = Constants.CPU_TIME + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();

            //Log information in object
            Error_Log__c excp = new Error_Log__c();
            excp.RecordtypeId = Schema.SObjectType.Error_Log__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();           
            excp.Related_To_Number__c=relatedToId;
            excp.Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<String>{QueryLimit, DMLimit,DMLStat,CPUT});
            excp.Exception_Message__c = e.getMessage();
            excp.Exception_Type__c = e.getTypeName();
            excp.Line_Number__c = e.getLineNumber();
            excp.Stack_Trace__c = e.getStackTraceString();
            excp.Method_Name__c=methodName;
            excp.Class_Name__c=className;

            if (saveLogAsync) {
                saveLogsAsync(JSON.serialize(new List<Error_Log__c>{excp}));
            } else {
                saveLogsSync(new List<Error_Log__c>{excp});
            } 
        } catch (Exception ex) {
            system.debug(LoggingLevel.WARN, ex.getMessage());
        }            
    }
    
    public class ErrorLoggerException extends Exception {}
}