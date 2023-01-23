@isTest
global class TesteArchiveCalloutMock implements HttpCalloutMock  {
    private string returned_SJSONResult;
    public TesteArchiveCalloutMock(string returned_SJSONResult) {
            this.returned_SJSONResult = returned_SJSONResult;
        }
    global HttpResponse respond(HttpRequest req){
        String jsonString;
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type','application/json');
        JSONSearchDoc sDoc = new JSONSearchDoc();
        jsonString = JSON.serialize(sDoc,true);
        res.setBody(returned_SJSONResult);
        res.setStatusCode(200);
        return res;
        }

}