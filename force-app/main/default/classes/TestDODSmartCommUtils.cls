@isTest
private class TestDODSmartCommUtils {
    
    @testSetup
    static void setup(){
        
        
        Account a = new Account(name = 'Test');
        a.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();
        
        insert a;
        
        Account v = new Account(name = 'Test Vendor', originating_site_id__c = '0000105570-0001');
        v.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        
        insert v;
        
        Contact c = new Contact(firstName = 'Test', lastName = 'Dog', accountId = v.id, role__c='Partner Sales Rep');
        insert c;
        
        Opportunity o = new Opportunity( nickname__c = 'dog1', amount = 10000.00, Name='jack', accountId = v.id, StageName = 'Quoting', CloseDate = date.today().addDays(30));
        o.recordtypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
        system.debug('o is: ' + o);
        insert o;
        
        
        Quote q = new Quote (name = 'dog1', opportunityId = o.id, lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly', payment_timing__c = 'in-arrears');
        insert q;
        
        Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
        insert ql;
    }
    
    Static testmethod void test1(){
        
        Opportunity o = [select id From Opportunity];
        
        
        
        Test.setMock(HttpCalloutMock.class, new GetSmartCommPdfMock());
        //SmartCommUtils.testBooster();
        
        Test.startTest();
        SmartCommUtils.mapProposal(990380852, o.Id, 'CustomerProposal');
        SmartCommUtils.buildHttpRequest('endpoint');
        SmartCommUtils.getSmartCommDoc(990380852, o.Id, 'CustomerProposal');
        
        Test.stopTest();
    }
    
    //Geetha - Test coverage
    
    public class GetSmartCommPdfMock implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            if (req.getEndpoint().endsWith('includeDocumentData=true')) {
                
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('while(1);{"numberTransactions":1,"dataModelValuesLocation":null,"previewKey":null,"envelopes":[{"masterChannel":{"pageCount":1,"channelType":2,"channelName":"Print","documentName":"NAM_Quote_MasterDocument","data":"dGVzdCBkYXRh","properties":[{"name":"isProduction","value":"false"},{"name":"resource version","value":"990,568,120"},{"name":"SCEnvironment","value":"Specimen - DEV"},{"name":"preview.exclude","value":"True"}],"channelId":2,"mimeType":"application/pdf"},"slaveChannels":[{"pageCount":0,"channelType":2,"channelName":"Print","documentName":"Price Quote_SC","properties":[{"name":"isProduction","value":"false"},{"name":"resource version","value":"1.0.0"},{"name":"SCEnvironment","value":"Specimen - DEV"},{"name":"display-width","value":"11.5in"}],"channelId":2,"mimeType":"application/pdf"}]}],"exceptions":[],"jobMessages":[{"batchID":0,"docID":2,"channelID":-1,"transactionNo":1,"destID":-1,"msgID":4065,"msgType":"E","msgText":"A logic/data error occurred in the assembly: name and keywords are blank and no Metadata Query was specified","msgDate":"May 12, 2022, 12:55:41 AM","packageID":-1,"args":["1123828173","name and keywords are blank and no Metadata Query was specified","990347563"]}]}');
                res.setStatusCode(200);
                return res;
            }
            
            if (req.getEndpoint().endsWith('token')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                //res.setBody('{"token_type": "Bearer",    "expires_in": "3599",    "ext_expires_in": "3599",    "expires_on": "1614776586",    "not_before": "1614772686",    "resource": "https://management.azure.com/",    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyIsImtpZCI6Im5PbzNaRHJPRFhFSzFqS1doWHNsSFJfS1hFZyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzA3NzUxZjhiLTk2MTctNDlkNS05MDI0LTg1ZjAzNGY0MDBlYy8iLCJpYXQiOjE2MTQ3NzI2ODYsIm5iZiI6MTYxNDc3MjY4NiwiZXhwIjoxNjE0Nzc2NTg2LCJhaW8iOiJFMlpnWURpem1qdFF2TW52MEhkWndYVWZCT1llQVFBPSIsImFwcGlkIjoiYTNkZjRhYzYtNjRmZS00YWUzLTkwNmUtNDJlMGUwODI5NjEyIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjLyIsIm9pZCI6IjdjN2E1ZTE4LTkxZTQtNGZlMy04Njc5LTQ0MDgxMzVmZDY5NyIsInJoIjoiMC5BVHNBaXg5MUJ4ZVcxVW1RSklYd05QUUE3TVpLMzZQLVpPTktrRzVDNE9DQ2xoSTdBQUEuIiwic3ViIjoiN2M3YTVlMTgtOTFlNC00ZmUzLTg2NzktNDQwODEzNWZkNjk3IiwidGlkIjoiMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjIiwidXRpIjoiX2hqWGk2cUtfRXFWMVc2OV9IRVhBQSIsInZlciI6IjEuMCIsInhtc190Y2R0IjoxMzY2NjQwODI0fQ.basY0BDTzw6In3Kou7KAXac_HoHlarRWt2GBfWaKFPfzXHN5Fh-TzHxy2avRepiGoztw55FscpYZvwTXBwhXaIOk44Y6MfNZ_IElDM9kX75Bfw13IpHLLtml2crxhK319EExICtn7HKBOIEFk3UnKG8n_2Fnvk9zh-NVKbq0f5sTSviUdOifmG5BbhnMcn4Tf1ZsciwZbIE8Te6xpm2u57rd-Ra7HVS7ql4yUr8ffoVHVofMklIp5bK1zUKxcblQNScs9cbhNh1k1V_noPWWVtHwtdh_D_kVzZTpfM3__EJ42RJzbtlTGm6tGIRbyr2TIa62EV1sL9SlVLtlrYL0UQ"}');
                res.setBody('{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1647485004","not_before":"1647481104","resource":"https://management.azure.com/","access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzA3NzUxZjhiLTk2MTctNDlkNS05MDI0LTg1ZjAzNGY0MDBlYy8iLCJpYXQiOjE2NDc0ODExMDQsIm5iZiI6MTY0NzQ4MTEwNCwiZXhwIjoxNjQ3NDg1MDA0LCJhaW8iOiJFMlpnWU5CL3VMc3kyUFduNjF2OVBSMW5IL3NFQVFBPSIsImFwcGlkIjoiYTNkZjRhYzYtNjRmZS00YWUzLTkwNmUtNDJlMGUwODI5NjEyIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMDc3NTFmOGItOTYxNy00OWQ1LTkwMjQtODVmMDM0ZjQwMGVjLyIsImlkdHlwIjoiYXBwIiwib2lkIjoiN2M3YTVlMTgtOTFlNC00ZmUzLTg2NzktNDQwODEzNWZkNjk3IiwicmgiOiIwLkFUc0FpeDkxQnhlVzFVbVFKSVh3TlBRQTdFWklmM2tBdXRkUHVrUGF3ZmoyTUJNN0FBQS4iLCJzdWIiOiI3YzdhNWUxOC05MWU0LTRmZTMtODY3OS00NDA4MTM1ZmQ2OTciLCJ0aWQiOiIwNzc1MWY4Yi05NjE3LTQ5ZDUtOTAyNC04NWYwMzRmNDAwZWMiLCJ1dGkiOiJGOGp3MkduQzYwRzFCakRXZFI0RUFBIiwidmVyIjoiMS4wIiwieG1zX3RjZHQiOjEzNjY2NDA4MjR9.SWLBAcDnZ9RBH3ttSa8KJeNUKy44uk5p1TmZwHeKXDYpxJ1wIne0POXxdoUVsc6-tMNrFDPZRslQ_R-RECdRFeekPT8yRCHDRXgtzMbmPEG6pFhiS8_7aQMDzMo-G2LtrrqIrLYl4wiXc7vwJI-Vvj7yFwp8-USRyVi0LiTsyUslc4Jt_c6SNQj9D5Qr4MgD9lHEUHSktgMH8Q3uDF5Iev59lxnyUZItAxQPdvKSTFVUFlXS9wGXhc4DBoytMPkzliIYrtyDc_6QaAvdMTNssrtSkj_mIYhICtR29gEvoG5ENxfc_Y0GzQwhGRhzuEk8hZVRWpn30zass4TCAHvBSg"}');
                res.setStatusCode(200);
                system.debug('inside getSmartcomm token');
                return res;
            }
            return null;
        }
    }
    
}