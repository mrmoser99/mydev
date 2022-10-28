@isTest
global class Infolease_AccessTokenMockCallout implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req){
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"token_type": "Bearer",    "expires_in": "3599",    "ext_expires_in": "3599",    "expires_on": "1614776586",    "not_before": "1614772686",    "resource": "https://management.azure.com/",    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyIsImtpZCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzA3NzUxZjhiLTk2MTctNDlkNS05MDI0LTg1ZjAzNGY0MDBlYy8iLCJpYXQiOjE2MTQ3NzI2ODYsIm5iZiI6MTYxNDc3MjY4NiwiZXhwIjoxNjE0Nzc2NTg2LCJhaW8iOiJFMlpnWURpem1qdFF2TW52MEhkWndYVWZCT1llQVFBPSIsImFwcGlkIjoiYTNkZjRhYzYtNjRmZS00YWUzLTkwNmUtNDJlMGUwODI5NjEyIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjLyIsIm9pZCI6IjdjN2E1ZTE4LTkxZTQtNGZlMy04Njc5LTQ0MDgxMzVmZDY5NyIsInJoIjoiMC5BVHNBaXg5MUJ4ZVcxVW1RSklYd05QUUE3TVpLMzZQLVpPTktrRzVDNE9DQ2xoSTdBQUEuIiwic3ViIjoiN2M3YTVlMTgtOTFlNC00ZmUzLTg2NzktNDQwODEzNWZkNjk3IiwidGlkIjoiMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjIiwidXRpIjoiX2hqWGk2cUtfRXFWMVc2OV9IRVhBQSIsInZlciI6IjEuMCIsInhtc190Y2R0IjoxMzY2NjQwODI0fQ.basY0BDTzw6In3Kou7KAXac_HoHlarRWt2GBfWaKFPfzXHN5Fh-TzHxy2avRepiGoztw55FscpYZvwTXBwhXaIOk44Y6MfNZ_IElDM9kX75Bfw13IpHLLtml2crxhK319EExICtn7HKBOIEFk3UnKG8n_2Fnvk9zh-NVKbq0f5sTSviUdOifmG5BbhnMcn4Tf1ZsciwZbIE8Te6xpm2u57rd-Ra7HVS7ql4yUr8ffoVHVofMklIp5bK1zUKxcblQNScs9cbhNh1k1V_noPWWVtHwtdh_D_kVzZTpfM3__EJ42RJzbtlTGm6tGIRbyr2TIa62EV1sL9SlVLtlrYL0UQ"}');
        res.setStatusCode(200);
        return res;
        
        
    }
}