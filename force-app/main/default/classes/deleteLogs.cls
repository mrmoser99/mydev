global Class deleteLogs implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('Select Id from Apexlog');
    }
    
    global void execute(Database.BatchableContext BC, list<Apexlog>loglist){       
        for(Apexlog al: loglist){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Url.getOrgDomainUrl().toExternalForm()
                            + '/services/data/v44.0/sobjects/Apexlog/'+al.Id);
            req.setMethod('DELETE');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            HttpResponse res = h.send(req);
            System.debug(res.getStatusCode());
        }
    }
    global void finish(Database.BatchableContext BC) {
        
    }
    
    
}