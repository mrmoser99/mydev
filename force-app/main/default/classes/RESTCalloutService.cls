/**
*Name: RESTCalloutService
*
*Purpose: Service class for REST requests. It is used to generate tokens and to perform synchronous and asynchronous callouts.
*
*@author Elena Sokolova @date 2021-01-15
*/
public with sharing class RESTCalloutService {

    private final static Integer RESPONSE_STATUS_CODE = 200;
    private final static Integer NUMBER_OF_CALLOUT_ATTEMPTS = 5;
    private static String accessToken;
    private static String TOKEN_CACHE_KEY;
    private static Map<String, RESTRequestSetting__mdt> settingNameToRESTSetting;
    private static final String CUSTOM_METADATA_NOT_FOUND = 'Unable to query custom metadata. Make sure you\'ve passed the correct developer name.';
    private static final String GENERATE_TOKEN_REQUEST_ERROR = 'Unable to authorize generate token request.';
    private static final String HTTP_REQUEST_FAILED = 'Request "{0}" failed with error: {1} {2}.';
    private static integer retryCount=0;

    static {
        settingNameToRESTSetting = getRESTRequestSettings();
        //accessToken = getAccessTokenFromCache();
    }
    
    /**
    *Name: AuthToken
    *Purpose: In this auth token is created and expiration timestamp is generated.  
    */
    public class AuthToken {

        public String authToken;
        public Integer expirationTimestamp;

        public AuthToken(String authToken, Integer expirationTimestamp) {

            this.authToken = authToken;
            this.expirationTimestamp = expirationTimestamp;
        }

        /**
        *Name: isValid
        *Purpose: This method checks the validity of the expiration timestamp and returns system time.   
        */
        public Boolean isValid() {

            Integer systemTime = (Integer) (System.now().getTime() / 1000);
            return systemTime < expirationTimestamp;
        }
    }

    /**
    *Name: getAccessTokenFromCache
    *Purpose: In this method, it checks the cache utility for token key and if it finds it then assigns that to auth token otherwise returns empty string.   
    */
    private static String getAccessTokenFromCache(String systemName) {
        AuthToken authToken;

        if (CacheUtility.containsKey(systemName)) {
            authToken = (AuthToken) CacheUtility.getCachedObject(systemName);    
            if (string.isNotBlank(authToken.authToken) && authToken.isValid()) 
            {
                return authToken.authToken;
            }
        }
        
        return '';
    }

    /**
    *Name: getRESTRequestSettings
    *Purpose: This method calls a query to fetch the required metadata and returns setting name.    
    */
    private static Map<String, RESTRequestSetting__mdt> getRESTRequestSettings() {

        Map<String, RESTRequestSetting__mdt> settingNameToRESTSetting = new Map<String, RESTRequestSetting__mdt>();

        List<RESTRequestSetting__mdt> restRequestSettings = [
            SELECT DeveloperName, Method__c, URLParameters__c, HeaderParameters__c, Endpoint__c,
            Body__c, Timeout__c, RequestBodyWrapperClassName__c, ResponseBodyWrapperClassName__c, Save_Success_Log__c,System__c,Retry_CallOut__c
            FROM RESTRequestSetting__mdt
        ];

        if (!restRequestSettings.isEmpty()) {
            for (RESTRequestSetting__mdt setting : restRequestSettings) {
                settingNameToRESTSetting.put(setting.DeveloperName, setting);
            }
        }
        
        return settingNameToRESTSetting;
    }

    /**
    *Name: generateToken
    *Purpose: This method generates the auth token and then assigns it to cache utility.      
    */
    private void generateToken(String accessTokenSystem) {
    
        GenerateTokenResponseBodyWrapper responseWrapper =
            (GenerateTokenResponseBodyWrapper) performCallout(accessTokenSystem, null, null, null, true);
        RESTCalloutService.accessToken = responseWrapper.access_token;
        AuthToken authToken = new AuthToken(responseWrapper.access_token, responseWrapper.expires_on);
        TOKEN_CACHE_KEY=accessTokenSystem;
        CacheUtility.setCachedObject(TOKEN_CACHE_KEY, authToken);
    }

    /**
    *Name: createCallout
    *Purpose: In this method, callout is created where header parameters are assigned and body parameters as well. It also displays the request body.    
    */
    private RESTCalloutHandler createCallout(String calloutName, Map<String, Object> params, Map<String, String> headerParams, Map<String, String> urlParams) {
        RESTRequestSetting__mdt setting = settingNameToRESTSetting.get(calloutName);
        RESTCalloutHandler callout = new RESTCalloutHandler(setting);
        
        accessToken = getAccessTokenFromCache(setting.System__c);
        
        if (calloutName != Constants.AZURE && calloutName != Constants.AXWAY && String.isBlank(RESTCalloutService.accessToken)) {       
            generateToken(setting.System__c);
        }
        
        // Authorize
        callout.setAuthorizationHeaderParameter(accessToken);
     
        // Set Header Params
        if (headerParams != null && !headerParams.isEmpty()) {
            for (String headerParamKey : headerParams.keySet()) {
                String headerParamValue = headerParams.get(headerParamKey);
                callout.setHeaderParameter(headerParamKey, headerParamValue);
            }
        }

        if (urlParams != null && !urlParams.isEmpty()) {
            for (String urlParamKey : urlParams.keySet()) {
                String urlParamValue = urlParams.get(urlParamKey);
                callout.setURLParameter(urlParamKey, urlParamValue);
            }
        }

        // Body
        String requestBodyWrapperClassName = setting.RequestBodyWrapperClassName__c;
        
        if (String.isNotBlank(requestBodyWrapperClassName)) {
            BaseRequestBodyWrapper requestBodyWrapper =
                (BaseRequestBodyWrapper) Type.forName(requestBodyWrapperClassName).newInstance();
            requestBodyWrapper.init(params);

            if (callout.getRequestMethod() != 'GET') {
                callout.setRequestBody(requestBodyWrapper.getRequestBodyAsString());
            }
        }
        return callout;
    }

    /**
    *Name: performCallout
    *Purpose: This method is used to perform callout and it returns various status code such as 401,200 according to the response it gets.     
    */
    public BaseResponseBodyWrapper performCallout(String calloutName, Map<String, Object> params, Map<String, String> headerParams, Map<String, String> urlParams, Boolean saveLogsAsync) {

        if (!settingNameToRESTSetting.containsKey(calloutName)) {
            throw new RESTCalloutException(CUSTOM_METADATA_NOT_FOUND);
        }

        RESTCalloutHandler callout = createCallout(calloutName, params, headerParams, urlParams);

        RESTRequestSetting__mdt setting = settingNameToRESTSetting.get(calloutName);

        Boolean saveSuccessLog = setting.Save_Success_Log__c;
        
        // Callout
        Integer requestTime= Limits.getCpuTime();  
        HTTPResponse response = callout.sendRequest();
        Integer responseTime= Limits.getCpuTime();        
        Integer timeDiff= responseTime - requestTime;
        Integer responseStatusCode = response.getStatusCode();

        switch on responseStatusCode {
            when 401 {
                ErrorLogger.addLog(new ErrorLogger.LogWrapper(calloutName, callout.getRequest(), response, timeDiff, saveLogsAsync));
                if (calloutName != Constants.AZURE && calloutName != Constants.AXWAY) {
                    // get new token
                    generateToken(setting.System__c);                    
                    // callout
                    if (Limits.getCallouts() <= NUMBER_OF_CALLOUT_ATTEMPTS) {
                        return performCallout(calloutName, params, headerParams, urlParams, saveLogsAsync);
                    } else {
                        String error = String.format(Label.Callout_Limit_Error, new List<Object>{responseStatusCode, NUMBER_OF_CALLOUT_ATTEMPTS}); 
                        throw new ErrorLogger.ErrorLoggerException(error);
                    }
                } else {
                    ErrorLogger.saveLogs(params);
                    throw new RESTCalloutException(GENERATE_TOKEN_REQUEST_ERROR);
                }
            }
            when else {
                String responseBodyWrapperClassName = setting.ResponseBodyWrapperClassName__c;
                if (String.isNotBlank(responseBodyWrapperClassName)) {
                    BaseResponseBodyWrapper responseWrapper = (BaseResponseBodyWrapper) 
                        Type.forName(responseBodyWrapperClassName).newInstance();
                   
                    //retry callout if there is internal serer error
                     if(responseStatusCode==500){
                        responseWrapper = retryCallOut(calloutName,params,headerParams,saveLogsAsync);                        
                     }
                    
                    responseWrapper.statusCode = responseStatusCode;                        
                    responseWrapper = responseWrapper.deserialize(responseBodyWrapperClassName, response.getBody()); 
                    
                    if (responseStatusCode != 200 || (saveSuccessLog && responseStatusCode == RESPONSE_STATUS_CODE)) {
                        ErrorLogger.logsList = new List<ErrorLogger.LogWrapper>();
                        ErrorLogger.addLog(new ErrorLogger.LogWrapper(calloutName, callout.getRequest(), response, timeDiff, saveLogsAsync));
                        ErrorLogger.saveLogs(params);
                    }
                    
                    return responseWrapper;
                } else {
                    return null;
                }
            }
        }
    }

    /**
    *Name: RESTCalloutHandler
    *Purpose: class is used for handling synchronous callouts.     
    */
    public with sharing class RESTCalloutHandler {

        private String endpointURL;
        private String requestMethod;
        private Integer requestTimeout;
        private String requestBody;
        private Map<String, String> urlParametersMap;
        private Map<String, String> headerParametersMap;
        private HTTPRequest request;

        private final String TYPE_URL_PARAMETERS = 'URL_PARAMETERS';
        private final String TYPE_HEADER_PARAMETERS = 'HEADER_PARAMETERS';

        private RESTRequestSetting__mdt restRequestSetting;

        public RESTCalloutHandler(RESTRequestSetting__mdt setting) {

            this.restRequestSetting = setting;
            initialize();
        }

        /*
        * Initialization of class variables
        */
        private void initialize() {

            urlParametersMap = new Map<String, String>();
            headerParametersMap = new Map<String, String>();
            if(restRequestSetting != null) {
                endpointURL = restRequestSetting.Endpoint__c;
                requestMethod = restRequestSetting.Method__c;
                requestBody = restRequestSetting.Body__c;
                requestTimeout = Integer.valueOf(restRequestSetting.Timeout__c);
                setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, restRequestSetting.URLParameters__c);
                setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, restRequestSetting.HeaderParameters__c);
            }
        }

        public String getEndpointURL() {
            return endpointURL;
        }

        public void setEndpointURL(String endpointURL) {
            this.endpointURL = endpointURL;
        }

        public String getRequestMethod() {
            return requestMethod;
        }

        public void setRequestMethod(String requestMethod) {
            this.requestMethod = requestMethod;
        }

        public String getRequestBody() {
            return requestBody;
        }

        public void setRequestBody(String requestBody) {
            this.requestBody = requestBody;
        }

        public Integer getRequestTimeout() {
            return requestTimeout;
        }

        public void setRequestTimeout(Integer requestTimeout) {
            this.requestTimeout = requestTimeout;
        }

        public String getHeaderParameter(String key) {
            return headerParametersMap.get(key);
        }

        public Map<String, String> getHeaderParameters() {
            return headerParametersMap;
        }

        public void setHeaderParameter(String key, String value) {
            if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
                headerParametersMap.put(key, value);
            }
        }

        public void setAuthorizationHeaderParameter(String accessToken) {
            setHeaderParameter('Authorization', 'Bearer ' + accessToken);
        }

        public void removeHeaderParameter(String key) {
            headerParametersMap.remove(key);
        }

        public String getURLParameter(String key) {
            return urlParametersMap.get(key);
        }

        public Map<String, String> getURLParameters() {
            return urlParametersMap;
        }

        public void setURLParameter(String key, String value) {
            if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
                urlParametersMap.put(key, value);
            } else if(String.isNotEmpty(key)) {
                urlParametersMap.put(key, value);
            }
        }

        public void removeURLParameter(String key) {
            urlParametersMap.remove(key);
        }

        /*
        * This method is used to append the URL parameters at the end of URL
        */
        private void appendURLParameters() {
            Set<String> urlParamKeys = urlParametersMap.keySet();
            if(!urlParamKeys.isEmpty()) {
                endpointURL += '?';
                for(String urlParamKey : urlParamKeys) {
                    endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
                }
                endpointURL = endpointURL.substringBeforeLast('&');
            }
        }

        /*
        * This method is used to set Header parameters using headerParametersMap
        */
        private void addHeaderParameters() {
            for(String key : headerParametersMap.keySet()) {
                request.setHeader(key, headerParametersMap.get(key));
            }
        }

        /**
        *Name: setUrlOrHeaderParameters
        *Purpose: This method is used to set URL or Header parameters from Custom Metadata.     
        */
        private void setUrlOrHeaderParameters(String parameterType, String parameterInfo) {
            if(String.isNotEmpty(parameterInfo)) {
                Map<String, String> parametersMap = new Map<String, String>();
                List<String> parameters = parameterInfo.split('\n');
                for(String urlParam : parameters) {
                    List<String> keyValuePair = urlParam.trim().split(':');
                    if(!keyValuePair.isEmpty()) {
                        if(keyValuePair.size() == 2) {
                            if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                                parametersMap.put(keyValuePair[0], keyValuePair[1]);
                            }
                        } else if(  (keyValuePair.size() == 1) && (parameterType != TYPE_HEADER_PARAMETERS) ) {
                            if(String.isNotEmpty(keyValuePair[0])) {
                                parametersMap.put(keyValuePair[0], '');
                            }
                        }
                    }
                }
                if(parameterType == TYPE_URL_PARAMETERS) {
                    urlParametersMap.putAll(parametersMap);
                } else if(parameterType == TYPE_HEADER_PARAMETERS) {
                    headerParametersMap.putAll(parametersMap);
                }
            }
        }

        private HttpRequest formHTTPRequest() {

            request = new HttpRequest();

            addHeaderParameters();
            if(String.isNotEmpty(endpointURL)) {
                endpointURL = endpointURL.substringBefore('?');
                appendURLParameters();
                request.setEndpoint(endpointURL);
            }
            if(String.isNotEmpty(requestMethod)) {
                request.setMethod(requestMethod);
            }
            if(String.isNotEmpty(requestBody)) {
                request.setBody(requestBody);
            }
            if(requestTimeout!=null) {
                request.setTimeout(requestTimeout);
            }

            return request;
        }

        /*
        * This method forms and returns the HTTP Request without sending (for debugging purposes)
        */
        public HTTPRequest getRequest() {
            formHTTPRequest();
            return request;
        }

        /*
        * This method is used to send HTTP Request and return the response
        */
        public HTTPResponse sendRequest() {
            formHTTPRequest();
            Http http = new Http();
            return http.send(request);
        }
    }

    /**
     * Custom Exception class for callouts, it's used to store error messages.
     */
    public class RESTCalloutException extends Exception {}
    
    /*
    * This method is used to retry callout untill retry attemp maintained in metadata
    */
    public BaseResponseBodyWrapper retryCallOut(String calloutName,Map<String, Object> params,Map<String, String> headerParams, Boolean saveLogsAsync ){
        RESTRequestSetting__mdt setting = settingNameToRESTSetting.get(calloutName);
        BaseResponseBodyWrapper responseBodyWrapper= (BaseResponseBodyWrapper)Type.forName(setting.ResponseBodyWrapperClassName__c).newInstance();
        Integer retryOption = Integer.valueOf(setting.Retry_CallOut__c);
        try {
            if (retryOption==null || retryOption==retryCount) {                               
                return responseBodyWrapper;
            } else {
                retryCount++;
                responseBodyWrapper = performCallout(calloutName, params, headerParams, null, saveLogsAsync);
                
            }
        } catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true);  
        }
        return responseBodyWrapper;     
    }
}