global class TesteArchiveCalloutMock3 implements HttpCalloutMock {
    private string returned_SJSONResult;
    public TesteArchiveCalloutMock3(string returned_SJSONResult) {
            this.returned_SJSONResult = returned_SJSONResult;
        }
    global HttpResponse respond(HttpRequest req){
        String jsonString;
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type','application/json');
        JSONSearchDoc sDoc = new JSONSearchDoc();
        jsonString = JSON.serialize(sDoc,true);
        res.setBody(returned_SJSONResult);
        //res.setBody('{"searchDocumentsResult": {"statusCode": 0,"statusCodeName": "OK","error": {"message": ""},"matchingDocuments": {"documentInfo": [{"din": "4C6213DD-6A01-AA5D-E1B3-B89A50EC2B51","timeStamp": 1609765803884,"indexValues": {"indexValue": [{"name": "Contract Number","value": "100-10000119"}]},"url": ""}]}}}');
        res.setStatusCode(200);
        return res;
}
}