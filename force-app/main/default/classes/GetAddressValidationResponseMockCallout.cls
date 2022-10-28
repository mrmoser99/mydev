@isTest
global class GetAddressValidationResponseMockCallout implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req){
        if (req.getEndpoint().endsWith('validate-address')) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"validateAddressInformation":{"address":{"country":"US","addressLine1":"1041 PENN CIR APT F203","city":"KING OF PRUSSIA","stateProvince":"PA","postalCode":"19406-1047","residenceNumber":"1041","streetName":"PENN CIR","countyName":"MONTGOMERY"},"failLevel":"0","postalCodeChangedInd":"Y","cityAreaNameChangedInd":"N","streetNameChangedInd":"N","streetComponentsChangedInd":"N","statusCode":"C4-40606060600000400060-78F0F8F0F000007000E0"},"serviceConfirmation":{"returnCode":"000","returnMessage":"success"}}');
            res.setStatusCode(200);
            return res;
        }
        
        if (req.getEndpoint().endsWith('token')) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //res.setBody('{"token_type": "Bearer",    "expires_in": "3599",    "ext_expires_in": "3599",    "expires_on": "1614776586",    "not_before": "1614772686",    "resource": "https://management.azure.com/",    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyIsImtpZCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzA3NzUxZjhiLTk2MTctNDlkNS05MDI0LTg1ZjAzNGY0MDBlYy8iLCJpYXQiOjE2MTQ3NzI2ODYsIm5iZiI6MTYxNDc3MjY4NiwiZXhwIjoxNjE0Nzc2NTg2LCJhaW8iOiJFMlpnWURpem1qdFF2TW52MEhkWndYVWZCT1llQVFBPSIsImFwcGlkIjoiYTNkZjRhYzYtNjRmZS00YWUzLTkwNmUtNDJlMGUwODI5NjEyIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjLyIsIm9pZCI6IjdjN2E1ZTE4LTkxZTQtNGZlMy04Njc5LTQ0MDgxMzVmZDY5NyIsInJoIjoiMC5BVHNBaXg5MUJ4ZVcxVW1RSklYd05QUUE3TVpLMzZQLVpPTktrRzVDNE9DQ2xoSTdBQUEuIiwic3ViIjoiN2M3YTVlMTgtOTFlNC00ZmUzLTg2NzktNDQwODEzNWZkNjk3IiwidGlkIjoiMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjIiwidXRpIjoiX2hqWGk2cUtfRXFWMVc2OV9IRVhBQSIsInZlciI6IjEuMCIsInhtc190Y2R0IjoxMzY2NjQwODI0fQ.basY0BDTzw6In3Kou7KAXac_HoHlarRWt2GBfWaKFPfzXHN5Fh-TzHxy2avRepiGoztw55FscpYZvwTXBwhXaIOk44Y6MfNZ_IElDM9kX75Bfw13IpHLLtml2crxhK319EExICtn7HKBOIEFk3UnKG8n_2Fnvk9zh-NVKbq0f5sTSviUdOifmG5BbhnMcn4Tf1ZsciwZbIE8Te6xpm2u57rd-Ra7HVS7ql4yUr8ffoVHVofMklIp5bK1zUKxcblQNScs9cbhNh1k1V_noPWWVtHwtdh_D_kVzZTpfM3__EJ42RJzbtlTGm6tGIRbyr2TIa62EV1sL9SlVLtlrYL0UQ"}');
            res.setBody('{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1647485004","not_before":"1647481104","resource":"https://management.azure.com/","access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzA3NzUxZjhiLTk2MTctNDlkNS05MDI0LTg1ZjAzNGY0MDBlYy8iLCJpYXQiOjE2NDc0ODExMDQsIm5iZiI6MTY0NzQ4MTEwNCwiZXhwIjoxNjQ3NDg1MDA0LCJhaW8iOiJFMlpnWU5CL3VMc3kyUFduNjF2OVBSMW5IL3NFQVFBPSIsImFwcGlkIjoiYTNkZjRhYzYtNjRmZS00YWUzLTkwNmUtNDJlMGUwODI5NjEyIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjLyIsImlkdHlwIjoiYXBwIiwib2lkIjoiN2M3YTVlMTgtOTFlNC00ZmUzLTg2NzktNDQwODEzNWZkNjk3IiwicmgiOiIwLkFUc0FpeDkxQnhlVzFVbVFKSVh3TlBRQTdFWklmM2tBdXRkUHVrUGF3ZmoyTUJNN0FBQS4iLCJzdWIiOiI3YzdhNWUxOC05MWU0LTRmZTMtODY3OS00NDA4MTM1ZmQ2OTciLCJ0aWQiOiIwNzc1MWY4Yi05NjE3LTQ5ZDUtOTAyNC04NWYwMzRmNDAwZWMiLCJ1dGkiOiJGOGp3MkduQzYwRzFCakRXZFI0RUFBIiwidmVyIjoiMS4wIiwieG1zX3RjZHQiOjEzNjY2NDA4MjR9.SWLBAcDnZ9RBH3ttSa8KJeNUKy44uk5p1TmZwHeKXDYpxJ1wIne0POXxdoUVsc6-tMNrFDPZRslQ_R-RECdRFeekPT8yRCHDRXgtzMbmPEG6pFhiS8_7aQMDzMo-G2LtrrqIrLYl4wiXc7vwJI-Vvj7yFwp8-USRyVi0LiTsyUslc4Jt_c6SNQj9D5Qr4MgD9lHEUHSktgMH8Q3uDF5Iev59lxnyUZItAxQPdvKSTFVUFlXS9wGXhc4DBoytMPkzliIYrtyDc_6QaAvdMTNssrtSkj_mIYhICtR29gEvoG5ENxfc_Y0GzQwhGRhzuEk8hZVRWpn30zass4TCAHvBSg"}');
            res.setStatusCode(200);
            system.debug('inside getaddress token');
            return res;
        }
        return null;
    }
}