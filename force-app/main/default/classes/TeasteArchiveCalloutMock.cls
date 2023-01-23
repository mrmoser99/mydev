@isTest
global class TeasteArchiveCalloutMock implements HttpCalloutMock {

    global HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('');
        res.setStatusCode(200);
        return res;
    }
}