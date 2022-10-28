public class ContractTriggerHandler /* extends TriggerHandler*/ {
    /*
        change log:
            
            1/31/19 - adding lookup population for opportunity and vendor program
    */
    
//    override public void beforeInsert(){
//        setInitialValues((List<Contract>) Trigger.new);
//
//        Set<String> vendorNoSet = new Set<String>();
//        Set<String> customerCodeSet = new Set<String>();
//        Map<String, Contract> appNumberToContractMap = new Map<String, Contract> ();
//        Map<String, System_ID__c> vendorToSystemMap = new Map<String, System_ID__c>();
//        Map<String, System_ID__c> customerToSystemMap = new Map<String, System_ID__c>();
//        Map<String, Id> appNumberToOppIdMap = new Map<String, Id>();
//        Set<Id> relatedAccountIdSet = new Set<Id>();
//        Set<Id> oppIdSet = new Set<Id>();
//        Set<String> appNbrSet = new Set<String>();
//        Set<String> vendorProgramSet = new Set<String>();
//
//        //Extracting Vendor number, customer code and application number
//        for(sObject sObj : Trigger.new) {
//            Contract cont = (Contract)sObj;
//            if(String.isBlank(cont.AccountId) && String.isNotBlank(cont.UNQ_Vendor__c)) {
//                vendorNoSet.add(cont.UNQ_Vendor__c);
//            }
//            if(String.isBlank(cont.End_User__c) && String.isNotBlank(cont.UNQ_Customer__c)) {
//                customerCodeSet.add(cont.UNQ_Customer__c);
//            }
//            if(String.isBlank(cont.Opportunity__c) && String.isNotBlank(cont.UNQ_Opportunity__c)) {
//                appNumberToContractMap.put(cont.UNQ_Opportunity__c, cont);
//            }
//            if(String.isNotBlank(cont.AccountId)) {
//                relatedAccountIdSet.add(cont.AccountId);
//            }
//            if(String.isNotBlank(cont.End_User__c)) {
//                relatedAccountIdSet.add(cont.End_User__c);
//            }
//            if(String.isNotBlank(cont.Opportunity__c)) {
//                oppIdSet.add(cont.Opportunity__c);
//            }
//            /*
//                populate additional sets;
//            */
//            if (String.isNotBlank(cont.UNQ_Opportunity__c))
//                appNbrSet.add(cont.UNQ_Opportunity__c);
//
//            if (String.isNotBlank(cont.UNQ_Vendor_Program__c))
//                vendorProgramSet.add(cont.UNQ_Vendor_Program__c);
//
//            /* end pop maps */
//        }
//
//        for(System_ID__c sys: [SELECT Id, Account__c,Vendor_ID__c,UNQ_Customer__c FROM System_ID__c WHERE Vendor_ID__c IN :vendorNoSet OR UNQ_Customer__c IN :customerCodeSet]) {
//            if(String.isNotBlank(sys.Vendor_ID__c) && sys.Vendor_ID__c!=null) {
//                vendorToSystemMap.put(sys.Vendor_ID__c, sys);
//                system.debug('sys.Vendor_ID__c'+sys.Vendor_ID__c);
//            }
//            if(String.isNotBlank(sys.UNQ_Customer__c)) {
//                system.debug(sys.UNQ_Customer__c);
//                customerToSystemMap.put(sys.UNQ_Customer__c, sys);
//            }
//        }
//
//        /* mrm populate maps */
//        Map<String,Id> oppMap = new Map<String,Id>();
//        List<Opportunity> olist = [select id, UNQ_Opportunity__c from Opportunity where UNQ_Opportunity__c in :appNbrSet];
//        for (Opportunity o:oList)
//            oppMap.put(o.UNQ_Opportunity__c,o.id);
//
//        Map<String,Id> vpMap = new Map<String,Id>();
//        List<Vendor_Program__c> vList = [select id, program_code__c from vendor_program__c where program_code__c in :vendorProgramSet];
//        for (Vendor_Program__c v:vList)
//            vpMap.put(v.program_code__c,v.id);
//
//        /* end pop maps */
//
//        for(sObject sObj : Trigger.new) {
//            Contract cont = (Contract)sObj;
//
//            /* mrm  populated fields */
//            cont.opportunity__c = oppMap.get(cont.UNQ_Opportunity__c);
//            cont.vendor_program__c = vpMap.get(cont.UNQ_Vendor_Program__c);
//            /* end populate fields */
//
//            //Populating matching System Id details using vendor number
//            if(vendorToSystemMap.containsKey(cont.UNQ_Vendor__c)!=null) {
//                if( cont.AccountId==null || String.isBlank(cont.AccountId) && vendorToSystemMap.containsKey(cont.UNQ_Vendor__c)) {
//
//                    if(vendorToSystemMap.get(cont.UNQ_Vendor__c)!=null){
//                        cont.AccountId = vendorToSystemMap.get(cont.UNQ_Vendor__c).Account__c;
//                        cont.Vendor_ID__c = vendorToSystemMap.get(cont.UNQ_Vendor__c).Id;
//                        relatedAccountIdSet.add(cont.AccountId);
//                        system.debug(relatedAccountIdSet);
//
//                    }
//
//                }
//            }
//            //Populating matching System Id details using customer code
//            if(String.isBlank(cont.End_User__c) && customerToSystemMap.containsKey(cont.UNQ_Customer__c)) {
//                cont.End_User__c = customerToSystemMap.get(cont.UNQ_Customer__c).Account__c;
//                cont.Customer_Code__c = customerToSystemMap.get(cont.UNQ_Customer__c).Id;
//                relatedAccountIdSet.add(cont.End_User__c);
//            }
//            //Populating opportunity lookup matching application number
//            if(String.isBlank(cont.Opportunity__c) && appNumberToOppIdMap.containsKey(cont.UNQ_Opportunity__c)) {
//                cont.Opportunity__c = appNumberToOppIdMap.get(cont.UNQ_Opportunity__c);
//
//                oppIdSet.add(cont.Opportunity__c);
//            }
//
//
//        }
//
//
//    }
//    override public void afterInsert(){
//        activateContracts();
//        updateopportunityRelation();
//        updateopportunity();
//
//    }
//
//    override public void beforeUpdate(){
//        for(sObject sObj : Trigger.new) {
//            Contract cont = (Contract) sObj;
//            Contract oldCont = (Contract) Trigger.oldMap.get(cont.Id);
//
//            if(oldCont.Status__c != cont.Status__c && cont.Status != cont.Status__c){
//                cont.Status = cont.Status__c;
//            }
//        }
//    }
//
//    public static void setInitialValues(List<Contract> contracts){
//        for(Contract c : contracts){
//            if(String.isBlank(c.Source_System__c)){
//                c.Source_System__c = 'GDW_Wayne';
//                c.Location__c = 'United States';
//                c.Contract_Number__c = c.UNQ_Contract__c;
//                c.CurrencyIsoCode = 'USD';
//            }
//        }
//    }
//
//    //Activating Contracts after insert
//    public void activateContracts() {
//        List<Contract> updateList = new List<Contract>();
//        for(sObject sObj : Trigger.new) {
//            Contract cont = (Contract)sObj;
//            system.debug(cont);
//            if(cont.Status!=null && String.isNotBlank(cont.Status__c)) {//&& cont.Status.equalsIgnoreCase('Draft')
//                Contract updatedContract = new Contract(Id = cont.Id, Status = cont.Status__c);
//                updateList.add(updatedContract);
//
//            }
//        }
//        if(!updateList.isEmpty()) {
//            system.debug(updateList);
//            update updateList;
//        }
//    }
//
//    public void updateopportunity(){
//        List<Id> op=new List<Id>();
//        Map<id,string> opp1=new Map<id,String>();
//
//        for(sObject sObj:Trigger.New){
//            Contract cont=(Contract)sObj;
//            if(cont.Opportunity__c!=null){
//                opp1.put(cont.Opportunity__c,cont.id);
//                op.add(cont.Opportunity__c);
//            }
//        }
//        list<Opportunity> updateopp=new list<Opportunity>();
//        for(Opportunity opp :[Select Id,ContractId,CloseDate  From Opportunity Where Id IN :op FOR UPDATE]){
//            Opportunity opup=new Opportunity();
//            opup.id=opp.id;
//            opup.ContractId =opp1.get(opp.id);
//            updateopp.add(opup);
//        }
//        if(updateopp.size()>0) {
//            update updateopp;
//        }
//    }
//
//    public  void updateopportunityRelation(){
//        list<Opportunity_Relationship__c> oprl=new list<Opportunity_Relationship__c>();
//
//        List<Opportunity_Relationship__c> lstOppRel=new List<Opportunity_Relationship__c>();
//        List<Opportunity_Relationship__c> lstOppRel2=new List<Opportunity_Relationship__c>();
//
//        list<Contract> contrList=new List<Contract>();
//        Map<String,Contract> contrMap=new Map<String,Contract>();
//        Set<id> oppid=new Set<id>();
//        for(sObject contractas :trigger.new){
//            Contract ct =(Contract) contractas;
//            if(ct.Opportunity__c!=null){
//                contrList.add(ct);
//                oppid.add(ct.Opportunity__c);
//                contrMap.Put(ct.Opportunity__c,ct);
//            }
//        }
//        List<Opportunity_Relationship__c> oppRelList = [SELECT  Contract__r.AccountId,Contract__r.End_User__r.ParentId ,Contract__r.End_User__c,Opportunity_Role__c, Contract__c, Contract_Account__c,Contract_Parent_Account__c,opportunity__c FROM Opportunity_Relationship__c WHERE Opportunity__c IN :oppid FOR UPDATE];
//        system.debug(oppRelList);
//        if(oppRelList.size()>0){
//
//            for(Opportunity_Relationship__c ooR:oppRelList){
//                Contract opt=contrMap.get(ooR.opportunity__c );
//
//                if(ooR.opportunity__c == opt.Opportunity__c)
//                {
//                    // Update Vendor Opportunity Relationship
//                    if(opt.AccountId!=null && opt.End_User__c!=null){
//                        if(ooR.Opportunity_Role__c=='Vendor' && opt.AccountId!=null){
//                            Opportunity_Relationship__c oorr=new Opportunity_Relationship__c();
//                            oorr.id=ooR.id;
//                            oorr.Contract__c = opt.Id;
//                            //Commented by Sam 2/4/2019 obsolete via Datagrid tool oorr.Contract_Account__c = opt.AccountId;
//                            //Commented by Sam 2/4/2019 obsolete via Datagrid tool oorr.Contract_Parent_Account__c = opt.Account.parentId;
//                            lstOppRel.add(oorr);
//                            oprl.add(oorr);
//                        }
//
//
//                    }
//
//                    // Update End User Opportunity Relationship
//
//                    if(ooR.Opportunity_Role__c=='End User' && opt.End_User__c!=null){
//                        Opportunity_Relationship__c oorel=new Opportunity_Relationship__c();
//                        oorel.id=ooR.id;
//                        oorel.Contract__c = opt.Id;
//                        //Commented by Sam 2/4/2019 obsolete via Datagrid tool oorel.Contract_Account__c = opt.End_User__c;
//                        //Commented by Sam 2/4/2019 obsolete via Datagrid tool oorel.Contract_Parent_Account__c =opt.End_User__r.parentId;
//                        lstOppRel.add(oorel);
//                        oprl.add(oorel);
//
//                    }
//                }
//
//            }
//            if(oprl.size()>0) update oprl;
//
//        }
//
//    }
}