/**
 * Test class for RESTCalloutService apex class 
 * 
 * Version 1.0
 * 
 */
@isTest
public with sharing class TestRESTCalloutService {

    private static Map<String, Object> requestParams() {

        Map<String, Object> params = new Map<String, Object>();
        params.put('programId', '001N00000208cLKIAY');
        params.put('applicableOfferId', '001N00000208cLKIAY');
        params.put('selectedRateId', '001N00000208cLKIAY');
        params.put('paymentOrFinance', 'payments');
        params.put('paymentFrequency', 'monthly');
        params.put('paymentTiming', 'in-advance');
        params.put('amount', 500);
        params.put('terms', 24);

        Map<String, Object> asset1 = new Map<String, Object>();
        asset1.put('quantity', 10);
        asset1.put('typeName', 'hardware');
        asset1.put('modelName', 'iPhone');
        asset1.put('salePrice', 11);

        params.put('assets', new List<Map<String, Object>>{asset1});
        
        
        Map<String, Object> maintenance = new Map<String, Object>();
        maintenance.put('id', 'iPhone');
        maintenance.put('amount',20);       
        
        params.put('maintenance', new List<Map<String, Object>>{maintenance});

        return params;
    }

    @isTest
    public static void testCalculationWithoutTokenPositive() {

        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;

        // Remove token from cache
        CacheUtility.clearCache('authToken');

        // Generate response for access token
        GenerateTokenResponseBodyWrapper resp1Body = new GenerateTokenResponseBodyWrapper();
        resp1Body.access_token = 'access_token';
        resp1Body.expires_on = (Integer) (System.now().getTime() / 1000) + 3600;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp1Body));
        responseList.add(mockResponse);

        // Generate response for calculation API
        String calculate = 'payments';
        Integer financeAmount = 100;
        CalculationResponseBodyWrapper resp2Body = new CalculationResponseBodyWrapper();
        resp2Body.financeInput.calculate = calculate;
        resp2Body.financeCalculation.financeAmount = financeAmount;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp2Body));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Map<String, Object> params = requestParams();
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        RESTCalloutService calloutService = new RESTCalloutService();
        CalculationResponseBodyWrapper response
            = (CalculationResponseBodyWrapper) calloutService.performCallout('calculation', params,headerParams,urlParams,true);
        
        System.assertEquals(calculate, response.financeInput.calculate);
        System.assertEquals(financeAmount, response.financeCalculation.financeAmount);
    }

    @isTest
    public static void testCalculationWithTokenPositive() {

        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;

        // Save token to cache with expiration date after an hour
        Integer expires = (Integer) (System.now().getTime() / 1000) + 3600;
        RESTCalloutService.AuthToken authToken = new RESTCalloutService.AuthToken('access_token', expires);
        CacheUtility.setCachedObject('authToken', authToken);
        
         // Generate response for access token
        GenerateTokenResponseBodyWrapper resp1Body = new GenerateTokenResponseBodyWrapper();
        resp1Body.access_token = 'access_token';
        resp1Body.expires_on = (Integer) (System.now().getTime() / 1000) + 3600;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp1Body));
        responseList.add(mockResponse);

        // Generate response for calculation API
        String calculate = 'payments';
        Integer financeAmount = 100;
        CalculationResponseBodyWrapper resp2Body = new CalculationResponseBodyWrapper();
        resp2Body.financeInput.calculate = calculate;
        resp2Body.financeCalculation.financeAmount = financeAmount;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp2Body));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Map<String, Object> params = requestParams();
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        RESTCalloutService calloutService = new RESTCalloutService();
        CalculationResponseBodyWrapper response
            = (CalculationResponseBodyWrapper) calloutService.performCallout('calculation', params,headerParams,urlParams,true);
        
        System.assertEquals(calculate, response.financeInput.calculate);
        System.assertEquals(financeAmount, response.financeCalculation.financeAmount);
    }

    @isTest
    public static void testCalculationWithInvalidTokenPositive() {

        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;

        // Save expired token to cache
        Integer expires = (Integer) (System.now().getTime() / 1000) - 1;
        RESTCalloutService.AuthToken authToken = new RESTCalloutService.AuthToken('access_token', expires);
        CacheUtility.setCachedObject('authToken', authToken);

        // Generate response for access token
        GenerateTokenResponseBodyWrapper resp1Body = new GenerateTokenResponseBodyWrapper();
        resp1Body.access_token = 'access_token';
        resp1Body.expires_on = (Integer) (System.now().getTime() / 1000) + 3600;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp1Body));
        responseList.add(mockResponse);

        // Generate response for calculation API
        String calculate = 'payments';
        Integer financeAmount = 100;
        CalculationResponseBodyWrapper resp2Body = new CalculationResponseBodyWrapper();
        resp2Body.financeInput.calculate = calculate;
        resp2Body.financeCalculation.financeAmount = financeAmount;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp2Body));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Map<String, Object> params = requestParams();
        
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        
        RESTCalloutService calloutService = new RESTCalloutService();
        CalculationResponseBodyWrapper response
            = (CalculationResponseBodyWrapper) calloutService.performCallout('calculation', params,headerParams,urlParams,true);
        
        System.assertEquals(calculate, response.financeInput.calculate);
        System.assertEquals(financeAmount, response.financeCalculation.financeAmount);
    }

    @isTest
    public static void testCalculationWithToken500Negative() {

        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;

        // Save token to cache with expiration date after an hour
        Integer expires = (Integer) (System.now().getTime() / 1000) + 3600;
        RESTCalloutService.AuthToken authToken = new RESTCalloutService.AuthToken('access_token', expires);
        CacheUtility.setCachedObject('azure', authToken);

        // Generate response for calculation API
        CalculationResponseBodyWrapper resp2Body = new CalculationResponseBodyWrapper();
        mockResponse = new MockHttpTestResponseGenerator(400, 'Bad Request', JSON.serialize(resp2Body));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Map<String, Object> params = requestParams();
        
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        
        RESTCalloutService calloutService = new RESTCalloutService();
        CalculationResponseBodyWrapper response = (CalculationResponseBodyWrapper) calloutService.performCallout('calculation', params,headerParams,urlParams,true);
        
        System.assertEquals(400, response.statusCode);
    }
    
    @isTest
    public static void testCalculationWithToken401Negative() {

        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;
        Boolean exception1 = false;

        // Save token to cache with expiration date after an hour
        Integer expires = (Integer) (System.now().getTime() / 1000) + 3600;
        RESTCalloutService.AuthToken authToken = new RESTCalloutService.AuthToken('access_token', expires);
        CacheUtility.setCachedObject('authToken', authToken);

        // Generate response for calculation API

        String responseBody = '{"message":"The session ID or OAuth token used has expired or is invalid.","errorCode":"401"}';
        mockResponse = new MockHttpTestResponseGenerator(401, 'Bad Request', JSON.serialize(responseBody));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        
        
        Map<String, Object> params = requestParams();
        try{
            RESTCalloutService calloutService = new RESTCalloutService();
            CalculationResponseBodyWrapper response = (CalculationResponseBodyWrapper) calloutService.performCallout('calculation', params,headerParams,urlParams,true);
        
        }
        catch(Exception e){
            exception1 = true;
            
        }
        System.assertEquals(true, exception1);
    }

    @isTest
    public static void testGettersAndSetters() {
        String endpointURL = 'https://';
        String requestMethod = 'GET';
        Integer requestTimeout = 10;
        String requestBody = 'test body';
        String headerKey = 'Header';
        String headerValue = 'Header Value';
        String urlKey = 'foo';
        String urlValue = 'bar';

        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        calloutHandler.setEndpointURL(endpointURL);
        calloutHandler.setRequestMethod(requestMethod);
        calloutHandler.setRequestBody(requestBody);
        calloutHandler.setRequestTimeout(requestTimeout);
        calloutHandler.setHeaderParameter(headerKey, headerValue);
        calloutHandler.setURLParameter(urlKey, urlValue);

        System.assertEquals(endpointURL, calloutHandler.getEndpointURL());
        System.assertEquals(requestMethod, calloutHandler.getRequestMethod());
        System.assertEquals(requestBody, calloutHandler.getRequestBody());
        System.assertEquals(requestTimeout, calloutHandler.getRequestTimeout());
        System.assertEquals(headerValue, calloutHandler.getHeaderParameter(headerKey));
        System.assertEquals(urlValue, calloutHandler.getURLParameter(urlKey));
        System.assertEquals(new Map<String,String>{headerKey => headerValue}, calloutHandler.getHeaderParameters());
        System.assertEquals(new Map<String,String>{urlKey => urlValue}, calloutHandler.getURLParameters());

        calloutHandler.removeHeaderParameter(headerKey);
        calloutHandler.removeURLParameter(urlKey);

        System.assertEquals(null, calloutHandler.getHeaderParameter(headerKey));
        System.assertEquals(null, calloutHandler.getURLParameter(urlKey));
    }
    
    static testMethod void testCreateOrder(){
        String params = '{"OrderId" : "012iw90quw","document" : "VGVzdCBEb2N1bWVudCA=","documentName" : "Test_Order.pdf","documentTitle" : "Test Order","DocumentDescription" : "Test Order Description", "signerName" : "Test Signer","signerSSN" : "4378024094", "orderExpiry" : "2022-01-01"}';
        Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('quoteId', '0Q01F000000LuB6SAK');
        
        HttpResponse resp = new HttpResponse();
        resp.setStatus('Call Success');
        resp.setStatusCode(200);
        resp.setBody('{}');
        
        HttpRequest req = new HttpRequest();
        req.setBody(params);
                
    }
    
    @isTest
    public static void testRetryCallOut() {
		
        List<HttpCalloutMock> responseList = new List<HttpCalloutMock>();
        MockHttpTestResponseGenerator mockResponse;

        // Save token to cache with expiration date after an hour
        Integer expires = (Integer) (System.now().getTime() / 1000) + 3600;
        RESTCalloutService.AuthToken authToken = new RESTCalloutService.AuthToken('access_token', expires);
        CacheUtility.setCachedObject('azure', authToken);
        
        // Generate response for calculation API
        String calculate = 'payments';
        Integer financeAmount = 100;
        CalculationResponseBodyWrapper resp2Body = new CalculationResponseBodyWrapper();
        resp2Body.financeInput.calculate = calculate;
        resp2Body.financeCalculation.financeAmount = financeAmount;
        mockResponse = new MockHttpTestResponseGenerator(200, 'Complete', JSON.serialize(resp2Body));
        responseList.add(mockResponse);
        MultiRequestMock multiCalloutMock = new MultiRequestMock(responseList);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Map<String, Object> params = requestParams();
        
        RESTCalloutService.RESTCalloutHandler calloutHandler = new RESTCalloutService.RESTCalloutHandler(null);
        testGettersAndSetters();
        Map<String, String> headerParams = calloutHandler.getHeaderParameters();
        Map<String, String> urlParams = calloutHandler.getURLParameters();
        
        RESTCalloutService calloutService = new RESTCalloutService();
        BaseResponseBodyWrapper response = (BaseResponseBodyWrapper) calloutService.retryCallOut('calculation', params,headerParams,true);
        
        System.assertEquals(null, response.statuscode);
    }
}