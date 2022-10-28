public class YieldPricingResponse {
    
    public static void pricing(){
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://login.microsoftonline.com/07751f8b-9617-49d5-9024-85f034f400ec/oauth2/token');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Authorization','Basic Og==');
        req.setBody('client_id=a3df4ac6-64fe-4ae3-906e-42e0e0829612&client_secret=AOarZPdFNuEgPNa_-3Gxk2_9Iy.s~3J0.d&resource=https://management.azure.com/&grant_type=client_credentials');
        req.setTimeout(Integer.valueOf(120000));
        
        Map<String, Object> token = new Map<String, object>();
        Http http = new Http();
        HTTPResponse res = http.send(req);
        token = (Map<String, Object>)JSON.deserializeUntyped(res.getbody());
        String tokenValue = (String)token.get('access_token');
        system.debug('Tokenvalue => ' +tokenValue);
        String accessToken = 'Bearer '+tokenValue;
        
        HttpRequest reqforResponse = new HttpRequest();
        reqforResponse.setMethod('POST');
        reqforResponse.setEndpoint('https://msc-apm-wcrm-dev.azure-api.net/globalcrmdata/priceQuote/sites/1.NA.PI.{{PartnerSiteId}}/programs/{{ProgramId}}/yieldBasedPricing?feature=Credit-Application-Inquiry');
        reqforResponse.setHeader('Content-Type','application/json');
        reqforResponse.setHeader('Ocp-Apim-Subscription-Key', '595f7a998c3948028bcb0f2103c6a0b6');
        reqforResponse.setHeader('Authorization', accessToken);
        reqforResponse.setHeader('SourceSystem', 'WAYNE-PartnerPriceQuote');
        reqforResponse.setHeader('Token','eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IkJVOHlXamxhdFdiR2lldFFtU0wyUWE5NG03UVBibjRUcXhVOWgyVzNIMUEifQ.eyJpc3MiOiJodHRwczovL21zY2IyY3BhcmF1dHByZC5iMmNsb2dpbi5jb20vMDIwOGRlNjAtMWM3ZC00YjE1LTkzNjUtNGEzYTBlZDg0ZDFjL3YyLjAvIiwiZXhwIjoxNjMzNjQwOTcwLCJuYmYiOjE2MzM1NTQ1NzAsImF1ZCI6IjdkZmE5MDVkLWQ3NjktNGIzNC1hNDFlLWI5MTc4Zjg1M2Q1NSIsImVtYWlsIjoiRExMR1JPVVBUZXN0LkFQSUVAZ21haWwuY29tIiwic3ViIjoiMDk0OTQxNmQtYzU4ZS00NmE3LWJiZWYtZDdlMjEzMWIxMmNjIiwibmFtZSI6IkRMTEdST1VQVGVzdCBBUEktRSIsImdpdmVuX25hbWUiOiJETExHUk9VUFRlc3QiLCJmYW1pbHlfbmFtZSI6IkFQSS1FIiwibG9jYWxlIjoiZW4tVVMiLCJsYXN0TG9nb24iOjE2MzM1NTQ1MjAsIm9yZ2FuaXNhdGlvbkNvbnRleHQiOiJ7XCJpZGVudGlmaWVyc1wiOltdfSIsInNpZ25Jbk1ldGhvZCI6InNpZ24taW4iLCJ0ZnAiOiJCMkNfMUFfRFVQU19TaWduSW4iLCJ0aWQiOiIwMjA4ZGU2MC0xYzdkLTRiMTUtOTM2NS00YTNhMGVkODRkMWMiLCJzY3AiOiJ2aWV3X2ZpbmFuY2lhbF9jb25maWd1cmF0aW9uIiwiYXpwIjoiNTJlMjEyZjktYWQ2My00ZDJlLTg4ODItMzQzZDBmOTRmOGJjIiwidmVyIjoiMS4wIiwiaWF0IjoxNjMzNTU0NTcwfQ.T48RhczujZkRqq9PTrx8gecgKDUsIad6w8bR1aGdARYMKKn8TjHsoKmKVp68oXT8TGqe7plkKHkOKI77xiyDQHyvVIETy_5_oyPQLCGkxW8yBdPPMaZIwsasuwQMvB8y0Ykb7OB2qNuZLcBdtnJ-2uyeipD0suzHOH9h02z6zqe1wiRaEVhdrW4dCP644SJsFX0BJbLTuldHDLlxUNlx6C0W4BCYHXlyNyZsxkSN30i2XUfGPelOF9LNsPTo_j0W-HqaqInE5lnP9pfJpNgCcczsI98NzDRx6GsHe22K_A_3NbIK9bOAoXYPbYWIOX3nEW3HYY4cTDYlrlwQyZZPPg');
        reqforResponse.setTimeout(Integer.valueOf(120000));
        
        
        string requestBody = '{"numberOfMonths": 12,"paymentFrequency": "MONTHLY","purchaseOption": "$1BO","assets": [{"sequenceId": 1,"condition": "new","quantity": 1,"equipmentCost": 2500,"modelId": "1000","assetTypeId": "2000","brandId": "3000","msrp": 2805,"interest": {"nominalRate": 10}}],"paymentTiming": "ADVANCE","contractStartDate": "2021-04-15","paymentStartDate": "2020-04-15","requestedRates": [{"rate": 10}]}';
   		reqforResponse.setBody(requestBody);
      
        Http http2 = new Http();
       // HTTPResponse azureResponse = http2.send(reqforResponse);
      //  Integer statusCode = azureResponse.getStatusCode();
        
      //  system.debug('azureResponse => ' +azureResponse);
       // system.debug('statuscode =>' +statusCode);
      //  Map<String,Object> level1Details = (Map<String, Object>)JSON.deserializeUntyped(azureResponse.getbody());
      //  system.debug('level1Details => ' +level1Details);
    }

}