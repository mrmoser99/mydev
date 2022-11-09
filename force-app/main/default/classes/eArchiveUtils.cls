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
    List<JSONSearchDocResults.DocumentInfo> documentsResult = new List<JSONSearchDocResults.DocumentInfo>();
    try{
        JSONSearchDoc sDoc = new JSONSearchDoc();
        JSONSearchDoc.SearchParameters dparams = new JSONSearchDoc.SearchParameters();
        JSONSearchDoc.SearchParameter dparam = new JSONSearchDoc.SearchParameter();
        dparam.name = 'Contract Number';
        dparam.operator = '=';
        dparam.value = contractNumber;
    	dparams.searchParameter = new List<JSONSearchDoc.SearchParameter>();
        dparams.searchParameter.add(dparam);
        JSONSearchDoc.SearchDocuments searchDoc = new JSONSearchDoc.SearchDocuments();
        searchDoc.searchParameters = dparams;
        searchDoc.searchTemplateName = 'DLL_US_CONTRACTS';//custom label****
    	searchDoc.maxDocumentsReturned=0;
        sDoc.searchDocuments = searchDoc;
        PartnerPortal__mdt pp = getPartnerPortalSettings();

        endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/earchive/api/v1/searchdoc';
		
        HttpRequest reqAPI = buildHttpRequest(endpoint);
        jsonString = JSON.serialize(sDoc,true);
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

		JSONSearchDocResults myResponse = (JSONSearchDocResults) System.JSON.deserialize(res1.getBody(),JSONSearchDocResults.class);
		documentsResult = myResponse.SearchDocumentsResult.MatchingDocuments.documentInfo;
		//system.debug('DDTResponse'+documentsResult);
    }
    catch (Exception e) {
        if (ErrorMsg == null)
			ErrorMsg = 'Exception in SearchContractDocs:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
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

		saveErrorLog(JSON.serialize(el));
    }
    if (error){
        return null;
    }
    else{
        system.debug('DDT documentsResult :'+documentsResult);
		return JSON.serialize(documentsResult); 
    }	
}
    
 @future
public static void saveErrorLog(String e) {

	system.debug('*********************** saving error logs');
	Error_Log__c el = (Error_Log__c) JSON.deserialize(e, Error_Log__c.class);
	system.debug('error log: ' + el);
	insert el;
}
    /************************************************************************************************************************************************
 * @getPrograms - get the document based on the document number(din number)
 *
 * change log:
 *
 *
 * @return   return programList
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String GetDocument(String dinNumber){
	HttpResponse res1;
	String endpoint;
    String jsonString;
    Boolean error=false;
	String ErrorMsg = null;
    JSONGetDocumentResult.GetDocumentResult getdocResult = new JSONGetDocumentResult.GetDocumentResult();
    try{
        JSONGetDocument getDocParam = new JSONGetDocument();
        JSONGetDocument.GetDocument getDocVar = new JSONGetDocument.GetDocument();
        getDocVar.din = dinNumber;
        getDocVar.maxObjSize = 2147483646;
        getDocVar.timeStamp=long.valueOf(datetime.now().format('ddMMyyhhmm'));
        getDocParam.getDocument = getDocVar; 
        PartnerPortal__mdt pp = getPartnerPortalSettings();
        endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/earchive/api/v1/getdoc';
        HttpRequest reqAPI = buildHttpRequest(endpoint);
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

		JSONGetDocumentResult myResponse = (JSONGetDocumentResult) System.JSON.deserialize(res1.getBody(),JSONGetDocumentResult.class);
		getdocResult = myResponse.getDocumentResult;
		//system.debug('DDTResponse'+myResponse);
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

		saveErrorLog(JSON.serialize(el));
    }
    if (error){
        return null;
    }
    else{
        system.debug('DDT documentsResult :'+getdocResult);
		return JSON.serialize(getdocResult); 
    }	
}

    /************************************************************************************************************************************************
 * buildHTTPRequest
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   httprequest
 *
 *****************************************************************************************************************************************************/
public static HttpRequest buildHttpRequest(String endpoint){

	HttpRequest reqAPI = new HttpRequest();

	reqAPI.setEndpoint(endpoint);
	reqAPI.setMethod('GET');
	reqAPI.setHeader('Content-Type', 'application/json');

	PartnerPortal__mdt pp = [SELECT Integration_Ocp_Apim_Subscription_Key__c
	                         FROM PartnerPortal__mdt
	                         where developername = 'PartnerAuthorization' ];


	reqAPI.setHeader('Ocp-Apim-Subscription-Key', pp.Integration_Ocp_Apim_Subscription_Key__c);
	//temporarily put this here to allow testing.

	reqAPI.setHeader('Authorization',  getToken());

	//reqAPI.setHeader('SourceSystem', sourceSystem); out as per suman 11/2/21
	//reqAPI.setHeader('Token', getToken('Regional'));
	//reqAPI.setHeader('env',env); out as per suman 11/2/21
	reqAPI.setTimeout(120000);

	system.debug('reqapi:' + reqAPI);

	return reqAPI;

}
/************************************************************************************************************************************************
 * getToken - checks cache for token.  if not found or expired, creates new token.
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   token
 *
 *****************************************************************************************************************************************************/
public static String getToken(){

	FINAL String PARTITION = 'local.DLLonDemand';
	FINAL String KEY = 'PricingAuthtoken';

	DDCacheUtilityPartition.sessionInfo s = new DDCacheUtilityPartition.sessionInfo();

	if (DDcacheUtilityPartition.containsKey(PARTITION,KEY)) {                 //returns true or false
		s = (DDCacheUtilityPartition.sessionInfo)CacheUtilityPartition.getCachedObject(PARTITION,KEY);                 //returns the object in cache
		if (system.now() > s.sessionExpiration) {
			system.debug('*************************** CACHE TOKEN EXPIRED');

			DDCacheUtilityPartition.clearCache(PARTITION, KEY);                 //expired  expired  aunt problems

			tokenClass t = new tokenClass();
			t = getAuthToken();


			system.debug('************************************* STORED CACHE EXPIRED');
			//Create and Store new token
			s.sessionToken =  t.token;

			s.sessionExpiration = t.expires;

			DDCacheUtilityPartition.setCachedObject(PARTITION,KEY, s);

			return s.sessionToken;

		}
		else{
			system.debug('************************ FOUND CACHE' + ' ' + s.sessionToken);
			return s.sessionToken;                 //USE THIS TOKEN
		}
	}
	else{

		tokenClass t = new tokenClass();
		t = getAuthToken();


		//Create and Store new token
		s.sessionToken =  t.token;
		s.sessionExpiration = t.expires;

		system.debug('******************************** STORED CACHE' + s.sessionToken);
		DDCacheUtilityPartition.setCachedObject(PARTITION, KEY, s);

		return s.sessionToken;

	}
}
    /************************************************************************************************************************************************
 * getAuthTOken
 *
 * change log:
 *
 * 11/2/2021 - MRM Created
 *
 *
 * @return   return token
 *****************************************************************************************************************************************************/

public static tokenClass getAuthToken(){


	tokenClass t = new tokenClass();

	HttpRequest reqAPI = new HttpRequest();
	Http http = new Http();

	PartnerPortal__mdt pp = getPartnerPortalSettings();


	reqAPI.setEndpoint('https://login.microsoftonline.com/07751f8b-9617-49d5-9024-85f034f400ec/oauth2/token');
	reqAPI.setMethod('POST');
	reqAPI.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	reqAPI.setHeader('Authorization', 'Basic Og==');
	system.debug('client id/secret=' +pp.Integration_Client_Id__c + '/' + pp.Integration_Client_Secret__c );
	reqAPI.setBody('client_id='+ pp.Integration_Client_Id__c +
	               '&client_secret='+ pp.Integration_Client_Secret__c +
	               '&grant_type=client_credentials' +
	               '&resource=https://management.azure.com/' +
	               '&scope=' + 'api://api-scopes.dllgroup.com/.default');

	reqAPI.setTimeout(120000);

	HTTPResponse res = http.send(reqAPI);

	system.debug('Body' + res.getBody());


	if(res.getStatusCode()==200 ) {

		JSONParser parser = JSON.createParser(res.getBody());
		//Extract the access token string  from the body
		while (parser.nextToken() != null) {
			if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
				parser.nextToken();
				t.token = parser.getText();
			}

		}

		JSONParser parser2 = JSON.createParser(res.getBody());
		while (parser2.nextToken() != null) {
			if((parser2.getCurrentToken() == JSONToken.FIELD_NAME) && (parser2.getText() == 'expires_in')) {
				// Get the value.
				parser2.nextToken();
				String s = parser2.getText();
				Integer sec = integer.valueOf(s);
				dateTime d = system.now().addSeconds(sec);
				t.expires = d;


			}
		}
	}

	return t;

}
/************************************************************************************************************************************************
 *   get partner portal settings
 *****************************************************************************************************************************************************/

public static PartnerPortal__mdt getPartnerPortalSettings(){

	return [SELECT Azure_Api_Environment__c
	        , Integration_Client_Id__c
	        , Integration_Client_Secret__c

	        ,Integration_Ocp_Apim_Subscription_Key__c
	        FROM PartnerPortal__mdt
	        where developername = 'PartnerAuthorization' ];
}
}