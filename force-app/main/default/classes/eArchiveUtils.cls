/*****************************************************************************************************************
 * Dll on Demaind (DD) EARCHIVE UTILITY CLASS
 *
 * Change Log:
 *
 *  10/26/2022 - MRM Created class
 * 11/08/2022 - Dibyendu adding the logic to search documents based on the contract number
 *******************************************************************************************************************/
public with sharing class eArchiveUtils {

public class tokenClass {
    
public String token;
public dateTime expires;
}

/************************************************************************************************************************************************
 * @getPrograms - search the contract documents based on the contract number
 *
 * change log:
 *
 *
 * @return   return programList
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String SearchContractDocs(String contractNumber){
    
	HttpResponse res1;
	String endpoint;
    String jsonString;
    Boolean error=false;
	String ErrorMsg = null;
    system.debug('DDTcontractNumber :'+contractNumber);
    List<JSONSearchDocResults.DocumentInfo> documentsResult = new List<JSONSearchDocResults.DocumentInfo>();
    try{
        
        Contract__c appnumber = [select id,name from Contract__c where id = :contractNumber];
        JSONSearchDoc sDoc = new JSONSearchDoc();
        JSONSearchDoc.SearchParameters dparams = new JSONSearchDoc.SearchParameters();
        JSONSearchDoc.SearchParameter dparam = new JSONSearchDoc.SearchParameter();
        dparam.name = 'Contract Number';
        dparam.operator = '=';
        //dparam.value = appnumber.name;
       dparam.value = '100-10000119';
    	dparams.searchParameter = new List<JSONSearchDoc.SearchParameter>();
        dparams.searchParameter.add(dparam);
        JSONSearchDoc.SearchDocuments searchDoc = new JSONSearchDoc.SearchDocuments();
        searchDoc.searchParameters = dparams;
        searchDoc.searchTemplateName = System.Label.SEARCH_DOCUMENT_TEMPLATE;
    	searchDoc.maxDocumentsReturned=0;
        sDoc.searchDocuments = searchDoc;
        PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();

        endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/earchive/api/v1/searchdoc';
        HttpRequest reqAPI = new HttpRequest();
        if (!Test.isRunningTest()){
            reqAPI = PricingUtils.buildHttpRequest(endpoint);
        }
		
        //HttpRequest reqAPI = buildHttpRequest(endpoint);
        jsonString = JSON.serialize(sDoc,true);
        reqAPI.setBody(jsonString);
        system.debug('Param JSON String : ' + jsonString);
		Http http1 = new Http();
        reqAPI.setTimeout(120000);
		res1 = http1.send(reqAPI);
        
        system.debug('DDT'+res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());
        
    	if (res1.getStatusCode() != 200) {
			ErrorMsg = 'DDTSearchContractDocs: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}
		system.debug('DDT1'+res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());
		JSONSearchDocResults myResponse = (JSONSearchDocResults) System.JSON.deserialize(res1.getBody(),JSONSearchDocResults.class);
		documentsResult = myResponse.SearchDocumentsResult.MatchingDocuments.documentInfo;
		system.debug('DDTResponse'+documentsResult);
    }
    catch (Exception e) {
        if (ErrorMsg == null)
			ErrorMsg = 'Exception in SearchContractDocs:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		system.debug('ERROR DDT'+ErrorMsg);
        error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'searchdoc';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'eArchiveUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'SearchContractDocs';
		if (res1 != null)
			el.Response_body__c = res1.getBody();
		el.status_code__c = null;
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		PricingUtils.saveErrorLog(JSON.serialize(el));
    }
    if (error){
        return null;
    }
    else{
        system.debug('DDT documentsResult :'+documentsResult);
        system.debug('DDT documentsResult serialize:'+JSON.serialize(documentsResult));
		return JSON.serialize(documentsResult); 
    }	
}
    
 /*@future
public static void saveErrorLog(String e) {

	system.debug('*********************** saving error logs');
	Error_Log__c el = (Error_Log__c) JSON.deserialize(e, Error_Log__c.class);
	system.debug('error log: ' + el);
	insert el;
}*/
    /************************************************************************************************************************************************
 * @getPrograms - get the document based on the document number(din number)
 *
 * change log:
 *
 *
 * @return   return programList
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String GetDocument(String dinNumber,String timeStamp){
	HttpResponse res1;
	String endpoint;
    String jsonString;
    Boolean error=false;
	String ErrorMsg = null;
    system.debug('DIN Number Actual:'+dinNumber+timeStamp);
    //system.debug('DIN Number :'+dinNumber.mid(1,dinNumber.length()-2));
    JSONGetDocumentResult.GetDocumentResult getdocResult = new JSONGetDocumentResult.GetDocumentResult();
    try{
        JSONGetDocument getDocParam = new JSONGetDocument();
        JSONGetDocument.GetDocument getDocVar = new JSONGetDocument.GetDocument();
        getDocVar.din = dinNumber.mid(1,dinNumber.length()-2);
        //getDocVar.din = dinNumber;
        system.debug('DIN Number Actual:'+dinNumber);
        getDocVar.maxObjSize = 2147483646;
        //getDocVar.timeStamp=long.valueOf(datetime.now().format('ddMMyyhhmm'));
        //getDocVar.timeStamp=Long.valueOf('1609765803884');
        getDocVar.timeStamp = Long.valueOf(timeStamp.mid(1,timeStamp.length()-2));
        getDocParam.getDocument = getDocVar; 
        PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
        endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/earchive/api/v1/getdoc';
        HttpRequest reqAPI = new HttpRequest();
        if (!Test.isRunningTest()){
            reqAPI = PricingUtils.buildHttpRequest(endpoint);
        }
        //HttpRequest reqAPI = buildHttpRequest(endpoint);
        //PricingUtils pc = new PricingUtils();
		//reqAPI = PricingUtils.buildHttpRequest(endpoint);        
        jsonString = JSON.serialize(getDocParam,true);
        reqAPI.setBody(jsonString);
        system.debug('Param JSON String : ' + jsonString);
		Http http1 = new Http();
		res1 = http1.send(reqAPI);
        system.debug(res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());
        
        if (res1.getStatusCode() != 200) {
			ErrorMsg = 'SearchContractDocs: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}
system.debug('DDT1'+res1.getBody());
		JSONGetDocumentResult myResponse = (JSONGetDocumentResult) System.JSON.deserialize(res1.getBody(),JSONGetDocumentResult.class);
		getdocResult = myResponse.getDocumentResult;
		system.debug('DDTResponse'+myResponse);
    }
    catch (Exception e) {
        if (ErrorMsg == null)
			ErrorMsg = 'Exception in GetDocument:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getdoc';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'eArchiveUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'GetDocument';
		if (res1 != null)
			el.Response_body__c = res1.getBody();
		el.status_code__c = null;
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;

		PricingUtils.saveErrorLog(JSON.serialize(el));
    }
    if (error){
        return null;
    }
    else{
        system.debug('DDT documentsResult :'+getdocResult);
		return JSON.serialize(getdocResult); 
    }	
}
}